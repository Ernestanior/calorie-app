import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class ActivatingDialog extends StatefulWidget {
  const ActivatingDialog({
    super.key,
  });

  @override
  State<ActivatingDialog> createState() => _ActivatingDialogState();
}

class _ActivatingDialogState extends State<ActivatingDialog>
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 255, 243, 226),
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white
            ],
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 16),
          Image.asset(
            'assets/image/activate.png',
            width: 90,
          ),
          const SizedBox(height: 16),
          Text(
            'SUBSCRIPTION_SUCCESSFUL'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ACTIVATING_YOUR_MEMBERSHIP'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.brown[700],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            child: Center(
              child: Container(
                width: 200,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: const Color.fromARGB(255, 201, 161, 109),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/image/rice_2.json',
                      controller: _LottieController1,
                      width: 25,
                    ),
                    const SizedBox(width: 20),
                    Lottie.asset(
                      'assets/image/beef_2.json',
                      controller: _LottieController2,
                      width: 25,
                    ),
                    const SizedBox(width: 20),
                    Lottie.asset(
                      'assets/image/egg_2.json',
                      controller: _LottieController3,
                      width: 25,
                    ),
                  ],
                ),
              ),
            ),
          )
        ]),
      ),
    );
  }
}

// Usage example
void showActivatingDialog() {
  Get.dialog(
    const ActivatingDialog(),
    barrierDismissible: true,
  );
}
