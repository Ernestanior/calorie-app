// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlanButton extends StatefulWidget {
  final dynamic onSubmit;
  const PlanButton({
    super.key,
    required this.onSubmit,
  });

  @override
  _PlanButtonState createState() => _PlanButtonState();
}

class _PlanButtonState extends State<PlanButton> {
  String buttonText = 'MAKING_PLAN'.tr;
  bool isLoading = true;
  int dotCount = 1;
  Timer? _dotTimer;
  Timer? _endTimer;

  @override
  void initState() {
    super.initState();
    // 每500毫秒改变一个点
    _dotTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      setState(() {
        dotCount = (dotCount % 3) + 1;
        buttonText = 'CREATING_PLAN'.tr + '.' * dotCount;
      });
    });

    // 5秒后切换按钮状态
    _endTimer = Timer(const Duration(seconds: 5), () {
      _dotTimer?.cancel();
      setState(() {
        isLoading = false;
        buttonText = 'CHECK_YOUR_PLAN'.tr;
      });
    });
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    _endTimer?.cancel();
    super.dispose();
  }

  void _onPressed() {
    if (!isLoading) {
      widget.onSubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      margin: const EdgeInsets.symmetric(vertical: 15),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed: isLoading ? null : _onPressed,
        child: Text(buttonText, style: const TextStyle(color: Colors.white, fontSize: 16,fontWeight: FontWeight.bold)),
      ),
    );
  }
}
