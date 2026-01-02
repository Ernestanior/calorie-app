import 'dart:async';
import 'package:flutter/material.dart';

class ImageSwitcher extends StatefulWidget {
  const ImageSwitcher({super.key});

  @override
  _ImageSwitcherState createState() => _ImageSwitcherState();
}

class _ImageSwitcherState extends State<ImageSwitcher> {
  final List<String> _images = [
    'assets/food/f1.jpeg',
    'assets/food/f2.jpeg',
    'assets/food/f3.jpg',
    'assets/food/f4.jpg',
    'assets/food/f5.jpg',
    'assets/food/f6.jpg',
    'assets/food/f7.jpg',
    'assets/food/f8.jpg',
    'assets/food/f9.jpg',
    'assets/food/f10.jpg',
  ];
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // 每 3 秒切换一次图片
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _images.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedSwitcher(
        duration: const Duration(seconds: 1), // 淡入淡出动画时长
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Image.asset(
          _images[_currentIndex],
          key: ValueKey<String>(_images[_currentIndex]), // 必须加 key 才能触发切换
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
