import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/download_controller.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dc = context.watch<DownloadController>();
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Downloads',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                    onPressed: dc.clearFinished, child: const Text('Clear done')),
              ],
            ),
          ),
          Expanded(
            child: dc.tasks.isEmpty
                ? const Center(child: Text('Nothing downloading'))
                : ListView.builder(
                    itemCount: dc.tasks.length,
                    itemBuilder: (_, i) {
                      final t = dc.tasks[i];
                      final running = t.status == DlStatus.running;
                      return ListTile(
                        title: Text(t.video.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(switch (t.status) {
                              DlStatus.running =>
                                '${t.label} · ${(t.progress * 100).round()}%',
                              DlStatus.done => '${t.label} · Saved',
                              DlStatus.cancelled => 'Cancelled',
                              DlStatus.failed => t.error ?? 'Failed',
                            }),
                            if (running)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(end: t.progress),
                                  duration: const Duration(milliseconds: 250),
                                  builder: (_, v, __) => LinearProgressIndicator(
                                    value: v,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(running ? Icons.close : Icons.delete_outline),
                          onPressed: () => running ? dc.cancel(t) : dc.remove(t),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
