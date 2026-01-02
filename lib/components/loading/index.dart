import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoading extends StatefulWidget {
  final double size;
  final double spacing;

  const LottieLoading({
    super.key,
    this.size = 30,
    this.spacing = 25,
  });

  @override
  State<LottieLoading> createState() => _LottieLoadingState();
}

class _LottieLoadingState extends State<LottieLoading>
    with TickerProviderStateMixin {
  late AnimationController _LottieController1;
  late AnimationController _LottieController2;
  late AnimationController _LottieController3;

  void startAnimations() async {
    if (!mounted) return;
    _LottieController1.repeat();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _LottieController2.repeat();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _LottieController3.repeat();
  }

  @override
  void initState() {
    super.initState();
    _LottieController1 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _LottieController2 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _LottieController3 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
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
    return AbsorbPointer(
        absorbing: true,
        child: Container(
            color: Colors.black.withOpacity(0.1),
            child: Center(
              child: Container(
                width: 200,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black.withOpacity(0.4),
                ),
                padding: const EdgeInsets.all(25),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Lottie.asset(
                        'assets/image/rice_2.json',
                        controller: _LottieController1,
                        width: widget.size,
                      ),
                      SizedBox(width: widget.spacing),
                      Lottie.asset(
                        'assets/image/beef_2.json',
                        controller: _LottieController2,
                        width: widget.size,
                      ),
                      SizedBox(width: widget.spacing),
                      Lottie.asset(
                        'assets/image/egg_2.json',
                        controller: _LottieController3,
                        width: widget.size,
                      ),
                    ],
                  ),
                ),
              ),
            )));
  }
}
