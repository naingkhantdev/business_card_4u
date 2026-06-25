import 'package:flutter/material.dart';

class LoadingView extends StatefulWidget {
  const LoadingView({
    super.key,
    this.size = 120,
    this.showBackground = false,
  });

  final double size;
  final bool showBackground;

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loader = FadeTransition(
      opacity: _opacity,
      child: Image.asset(
        'assets/images/ABW.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );

    if (!widget.showBackground) {
      return loader;
    }

    return Container(
      color: Colors.black.withOpacity(0.15),
      alignment: Alignment.center,
      child: loader,
    );
  }
}
