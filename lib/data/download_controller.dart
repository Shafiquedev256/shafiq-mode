import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../core/network_guard.dart';
import 'library_controller.dart';
import 'youtube_service.dart';

enum DlStatus { running, done, failed, cancelled }

class DownloadTask {
  DownloadTask(this.video, this.label);
  final Video video;
  final String label;
  final cancel = CancelToken();
  double progress = 0;
  DlStatus status = DlStatus.running;
  String? error;
}

class DownloadController extends ChangeNotifier {
  DownloadController(this._youtube, this._library);

  final YoutubeService _youtube;
  final LibraryController _library;
  final List<DownloadTask> tasks = [];

  int get activeCount =>
      tasks.where((t) => t.status == DlStatus.running).length;

  Future<void> start(Video video, AudioOnlyStreamInfo stream) async {
    final task = DownloadTask(
      video,
      '${stream.bitrate.kiloBitsPerSecond.round()} kbps · ${extensionFor(stream)}',
    );
    tasks.insert(0, task);
    notifyListeners();
    try {
      final dir = await _library.downloadsDir();
      var last = 0.0;
      final file = await _youtube.download(
        video: video,
        stream: stream,
        dir: dir,
        cancel: task.cancel,
        onProgress: (x) {
          task.progress = x;
          if (x - last >= 0.01 || x >= 1) {
            last = x;
            notifyListeners();
          }
        },
      );
      await _library.addDownloaded(
        file,
        title: video.title,
        artist: video.author,
        durationMs: video.duration?.inMilliseconds,
      );
      task.status = DlStatus.done;
    } on DownloadCancelled {
      task.status = DlStatus.cancelled;
    } on NetworkBlockedException catch (e) {
      task.status = DlStatus.failed;
      task.error = e.toString();
    } catch (e) {
      debugPrint('Download failed: $e');
      task.status = DlStatus.failed;
      task.error = 'Download failed. Check your connection and try again.';
    }
    notifyListeners();
  }

  void cancel(DownloadTask t) => t.cancel.cancelled = true;

  void remove(DownloadTask t) {
    tasks.remove(t);
    notifyListeners();
  }

  void clearFinished() {
    tasks.removeWhere((t) => t.status != DlStatus.running);
    notifyListeners();
  }
}
