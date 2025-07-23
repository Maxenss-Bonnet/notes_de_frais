import 'package:flutter/material.dart';

class AnimatedIconButton extends StatefulWidget {
  final IconData? icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color color;
  final double size;
  final Widget? child;

  const AnimatedIconButton({
    super.key,
    this.icon,
    required this.onPressed,
    this.tooltip,
    this.color = Colors.white,
    this.size = 24.0,
    this.child,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: Tooltip(
        message: widget.tooltip ?? '',
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child ??
              Icon(
                widget.icon,
                color: widget.color,
                size: widget.size,
              ),
        ),
      ),
    );
  }
}