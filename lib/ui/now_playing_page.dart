import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../audio/player_controller.dart';
import 'widgets/common.dart';

class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key});

  static Route<void> route() => PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) => const NowPlayingPage(),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<PlayerController>();
    final t = pc.current;
    final accent = Theme.of(context).colorScheme.primary;
    if (t == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold();
    }
    final p = pc.player;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent.withAlpha(90), const Color(0xFF0B0B12)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const Spacer(),
                _PulsingArt(seed: t.title, playing: pc.playing),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey(t.id),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(t.artist,
                            style: const TextStyle(color: Colors.white60)),
                      ],
                    ),
                  ),
                ),
                if (pc.lastError != null)
                  Text(pc.lastError!,
                      style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 12),
                _SeekBar(player: p),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.shuffle,
                          color: p.shuffleModeEnabled ? accent : Colors.white54),
                      onPressed: pc.toggleShuffle,
                    ),
                    IconButton(
                      iconSize: 38,
                      icon: const Icon(Icons.skip_previous),
                      onPressed: p.seekToPrevious,
                    ),
                    GestureDetector(
                      onTap: pc.toggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withAlpha(pc.playing ? 140 : 60),
                              blurRadius: pc.playing ? 28 : 12,
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (c, a) =>
                              ScaleTransition(scale: a, child: c),
                          child: Icon(
                            pc.playing ? Icons.pause : Icons.play_arrow,
                            key: ValueKey(pc.playing),
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 38,
                      icon: const Icon(Icons.skip_next),
                      onPressed: p.seekToNext,
                    ),
                    IconButton(
                      icon: Icon(
                        p.loopMode == LoopMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: p.loopMode == LoopMode.off
                            ? Colors.white54
                            : accent,
                      ),
                      onPressed: pc.cycleRepeat,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.speed),
                      label: Text('${p.speed}x'),
                      onPressed: () => _speedSheet(context, pc),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.bedtime_outlined),
                      label: Text(pc.sleepEndsAt == null ? 'Sleep' : 'On'),
                      onPressed: () => _sleepSheet(context, pc),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _speedSheet(BuildContext context, PlayerController pc) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 8,
            children: [
              for (final s in [0.75, 1.0, 1.25, 1.5, 2.0])
                ChoiceChip(
                  label: Text('${s}x'),
                  selected: pc.player.speed == s,
                  onSelected: (_) {
                    pc.setSpeed(s);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _sleepSheet(BuildContext context, PlayerController pc) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in [15, 30, 45, 60])
              ListTile(
                title: Text('Stop after $m min'),
                onTap: () {
                  pc.setSleepTimer(Duration(minutes: m));
                  Navigator.pop(context);
                },
              ),
            ListTile(
              title: const Text('Off'),
              onTap: () {
                pc.setSleepTimer(null);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.player});
  final AudioPlayer player;
  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: widget.player.durationStream,
      builder: (_, d) {
        final total = (d.data ?? Duration.zero).inMilliseconds.toDouble();
        return StreamBuilder<Duration>(
          stream: widget.player.positionStream,
          builder: (_, s) {
            final pos = (_drag ?? (s.data?.inMilliseconds ?? 0).toDouble())
                .clamp(0.0, total <= 0 ? 1.0 : total);
            return Column(
              children: [
                Slider(
                  value: pos,
                  max: total <= 0 ? 1 : total,
                  onChanged: total <= 0 ? null : (v) => setState(() => _drag = v),
                  onChangeEnd: (v) {
                    widget.player.seek(Duration(milliseconds: v.round()));
                    setState(() => _drag = null);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fmt(Duration(milliseconds: pos.round())),
                          style: const TextStyle(color: Colors.white60)),
                      Text(fmt(Duration(milliseconds: total.round())),
                          style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PulsingArt extends StatefulWidget {
  const _PulsingArt({required this.seed, required this.playing});
  final String seed;
  final bool playing;
  @override
  State<_PulsingArt> createState() => _PulsingArtState();
}

class _PulsingArtState extends State<_PulsingArt>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingArt old) {
    super.didUpdateWidget(old);
    widget.playing ? _c.repeat(reverse: true) : _c.animateTo(0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width * .72;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(
        scale: 0.94 + 0.06 * Curves.easeInOut.transform(_c.value),
        child: child,
      ),
      child: Hero(tag: 'art', child: TrackAvatar(seed: widget.seed, size: w)),
    );
  }
}
