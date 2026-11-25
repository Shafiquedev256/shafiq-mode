import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart'
    show AudioOnlyStreamInfo, Video;

import '../core/network_guard.dart';
import '../data/download_controller.dart';
import '../data/settings_controller.dart';
import '../data/youtube_service.dart';
import 'widgets/common.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});
  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _ctrl = TextEditingController();
  List<Video> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    final yt = context.read<YoutubeService>();
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await yt.search(q);
      if (mounted) setState(() => _results = r);
    } on NetworkBlockedException catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } catch (_) {
      if (mounted) {
        setState(() => _error = "Couldn't reach YouTube. Check your connection.");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Discover',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'Search or paste a link. Only downloads you start use the internet. Download only content you have the rights to.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (settings.blockNetwork)
              Expanded(child: _BlockedCard(settings: settings))
            else ...[
              TextField(
                controller: _ctrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Song, artist or YouTube link',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _search,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final v = _results[i];
                    return ListTile(
                      leading: TrackAvatar(seed: v.title),
                      title: Text(v.title,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${v.author}${v.duration == null ? '' : ' · ${fmt(v.duration!)}'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.download_rounded),
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => _QualitySheet(video: v),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (30 * (i % 10)).ms)
                        .slideY(begin: .08, curve: Curves.easeOut);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BlockedCard extends StatelessWidget {
  const _BlockedCard({required this.settings});
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(.92, .92), end: const Offset(1.05, 1.05),
                  duration: 1200.ms),
          const SizedBox(height: 16),
          const Text('Internet is blocked for this app',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => settings.setBlockNetwork(false),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }
}

class _QualitySheet extends StatefulWidget {
  const _QualitySheet({required this.video});
  final Video video;
  @override
  State<_QualitySheet> createState() => _QualitySheetState();
}

class _QualitySheetState extends State<_QualitySheet> {
  late final Future<List<AudioOnlyStreamInfo>> _future =
      context.read<YoutubeService>().qualities(widget.video.id);

  void _pick(AudioOnlyStreamInfo s) {
    context.read<DownloadController>().start(widget.video, s);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download started — see Downloads tab')),
    );
  }

  String _desc(AudioOnlyStreamInfo s) =>
      '${s.bitrate.kiloBitsPerSecond.round()} kbps · ${extensionFor(s)} · '
      '${s.size.totalMegaBytes.toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<List<AudioOnlyStreamInfo>>(
          future: _future,
          builder: (_, snap) {
            if (snap.hasError) {
              return Text(
                snap.error is NetworkBlockedException
                    ? snap.error.toString()
                    : "Couldn't load audio options.",
              );
            }
            if (!snap.hasData) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final all = snap.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                for (final t in QualityTier.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.label),
                    subtitle: Text(_desc(pickStream(all, t))),
                    trailing: const Icon(Icons.download),
                    onTap: () => _pick(pickStream(all, t)),
                  ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('All available streams'),
                  children: [
                    for (final s in all.reversed)
                      ListTile(
                        dense: true,
                        title: Text(_desc(s)),
                        onTap: () => _pick(s),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
