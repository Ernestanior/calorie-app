import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieFood extends StatefulWidget {

  final double size;
  final double spacing;

  const LottieFood({
    super.key,
    this.size = 25,
    this.spacing = 8,
  });

  @override
  State<LottieFood> createState() => _LottieFoodState();
}

class _LottieFoodState extends State<LottieFood> with TickerProviderStateMixin {
  late AnimationController _LottieController1;
  late AnimationController _LottieController2;
  late AnimationController _LottieController3;

  void startAnimations() async {
        if (!mounted) return;
    _LottieController1.repeat();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _LottieController2.repeat();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _LottieController3.repeat();
  }

  @override
  void initState() {
    super.initState();
    _LottieController1 = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _LottieController2 = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _LottieController3 = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    startAnimations();
  }

    @override
  void dispose() {
    _LottieController1.dispose();
    _LottieController2.dispose();
    _LottieController3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/image/rice.json',
          controller: _LottieController1,
          width: widget.size,
        ),
        SizedBox(width: widget.spacing),
        Lottie.asset(
          'assets/image/beef.json',
          controller: _LottieController2,
          width: widget.size,
        ),
        SizedBox(width: widget.spacing),
        Lottie.asset(
          'assets/image/egg.json',
          controller: _LottieController3,
          width: widget.size,
        ),
      ],
    );
  }
}
