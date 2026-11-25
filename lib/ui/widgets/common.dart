import 'dart:math' as math;

import 'package:flutter/material.dart';

String fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:${m.padLeft(2, '0')}:$s' : '$m:$s';
}

class TrackAvatar extends StatelessWidget {
  const TrackAvatar({
    super.key,
    required this.seed,
    this.size = 52,
    this.overlay,
  });
  final String seed;
  final double size;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final h = (seed.hashCode % 360).abs().toDouble();
    Color c(double dh) => HSLColor.fromAHSL(1, (h + dh) % 360, .65, .5).toColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c(0), c(50)],
        ),
      ),
      alignment: Alignment.center,
      child: overlay ??
          Text(
            seed.isEmpty ? '♪' : seed.characters.first.toUpperCase(),
            style: TextStyle(
              fontSize: size * .42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
    );
  }
}

/// Animated equalizer bars; animates only while [active].
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({super.key, required this.active, this.size = 20});
  final bool active;
  final double size;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(EqualizerBars old) {
    super.didUpdateWidget(old);
    widget.active ? _c.repeat() : _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const phases = [0.0, .33, .66, .15];
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final ph in phases)
              Container(
                width: widget.size / 7,
                height: widget.size *
                    (widget.active
                        ? .25 + .75 * (0.5 + 0.5 * math.sin((_c.value + ph) * 2 * math.pi))
                        : .25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
