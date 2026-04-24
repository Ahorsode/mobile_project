import 'package:flutter/material.dart';

class TactileButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color baseColor;
  final double width;
  final double height;

  const TactileButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.baseColor = Colors.blueAccent,
    this.width = 240,
    this.height = 60,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _depthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _depthAnimation = Tween<double>(begin: 6.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _depthAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onPressed();
          },
          onTapCancel: () => _controller.reverse(),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.baseColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                // Bottom Shadow (Depth)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: Offset(0, _depthAnimation.value),
                  blurRadius: 4,
                ),
                // Top Highlight (Lighting)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  offset: Offset(0, -_depthAnimation.value * 0.5),
                  blurRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.baseColor.withValues(alpha: 0.9),
                  widget.baseColor,
                ],
              ),
            ),
            child: Transform.translate(
              offset: Offset(0, 6.0 - _depthAnimation.value),
              child: Center(child: widget.child),
            ),
          ),
        );
      },
    );
  }
}
