import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../buttonX/index.dart';

class CameraAuthSheet extends StatelessWidget {
  const CameraAuthSheet({super.key});

  static const textStyle =
      TextStyle(fontSize: 15, height: 2, fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Colors.white),
      height: 270,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'AUTHORIZE_CAMERA'.tr,
            style: const TextStyle(
                color: Color.fromARGB(255, 149, 149, 149),
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            'AUTHORIZE_CAMERA_TIP_1'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'AUTHORIZE_CAMERA_TIP_2'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'AUTHORIZE_CAMERA_TIP_3'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          buildCompleteButton(context, 'GO_SETTING'.tr, () {
            openAppSettings();
          })
        ],
      ),
    );
  }
}
