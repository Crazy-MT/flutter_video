import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class PlaybackSpeedButton extends StatelessWidget {
  const PlaybackSpeedButton({super.key, required this.player});

  final Player player;
  static const speeds = [0.5, 1.0, 2.0, 3.0];

  static String label(double speed) =>
      '${speed == speed.roundToDouble() ? speed.toInt() : speed}倍速';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: player.stream.rate,
      initialData: player.state.rate,
      builder: (context, snapshot) => PopupMenuButton<double>(
        tooltip: '播放倍速',
        initialValue: snapshot.data,
        onSelected: (speed) => player.setRate(speed),
        itemBuilder: (_) => speeds
            .map(
              (speed) => PopupMenuItem(value: speed, child: Text(label(speed))),
            )
            .toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(
            label(snapshot.data ?? 1),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class HoldToSpeed extends StatefulWidget {
  const HoldToSpeed({super.key, required this.player, required this.child});

  final Player player;
  final Widget child;

  @override
  State<HoldToSpeed> createState() => _HoldToSpeedState();
}

class _HoldToSpeedState extends State<HoldToSpeed> {
  double? _previousRate;

  void _start() {
    if (!widget.player.state.playing || _previousRate != null) return;
    _previousRate = widget.player.state.rate;
    widget.player.setRate(2);
    setState(() {});
  }

  void _restore() {
    final rate = _previousRate;
    if (rate == null) return;
    _previousRate = null;
    widget.player.setRate(rate);
  }

  void _end() {
    if (_previousRate == null) return;
    _restore();
    setState(() {});
  }

  @override
  void dispose() {
    _restore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (_) => _start(),
      onLongPressEnd: (_) => _end(),
      onLongPressCancel: _end,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (_previousRate != null)
            const Positioned(
              top: 48,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        '2 倍速播放中',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
