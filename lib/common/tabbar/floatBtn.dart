import 'package:calorie/common/icon/index.dart';
import 'package:calorie/components/actionSheets/cameraAuth.dart';
import 'package:calorie/store/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:permission_handler/permission_handler.dart';

class FloatBtn extends StatefulWidget {
  const FloatBtn({super.key});

  @override
  State<FloatBtn> createState() => _FloatBtnState();
}

class _FloatBtnState extends State<FloatBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 1.0,
      upperBound: 1.2,
    )..repeat(reverse: true);

    _animation =
        Tween<double>(begin: 1.0, end: 1.2).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // void onCamera () async{
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? photo =
  //       await picker.pickImage(source: ImageSource.camera);
  //   if (photo == null) {
  //     return;
  //   }
  //   final file = File(photo.path);
  //   List<int> imageBytes = await file.readAsBytes();
  //   String base64Image = base64Encode(imageBytes);
  // }

  // void onLibrary () async{
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? image =
  //       await picker.pickImage(source: ImageSource.gallery);
  //   if (image == null) {
  //     return;
  //   }
  //   final file = File(image.path);
  //   List<int> imageBytes = await file.readAsBytes();
  //   // Convert image to base64
  //   String base64Image = base64Encode(imageBytes);
  //   var formData = FormData({'file': base64Image});
  //   dynamic imgUrl = await imgRender({'imgBase64':base64Image});

  // }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
        scale: _animation,
        child: Obx(() => FloatingActionButton(
              shape: const CircleBorder(),
              onPressed: () async {
                // Get.dialog(
                //   const StarRatingDialog(),
                //   barrierDismissible: false,
                //   useSafeArea: true,
                // );
                var status = await Permission.camera.request();
                print('status $status');
                if (status.isDenied) {
                  // 首次拒绝，可以再请求一次
                  status = await Permission.camera.request();
                }
                if (status.isGranted) {
                  if (!Controller.c.isAnalyzing.value &&
                      Controller.c.user['id'] != 0) {
                    Navigator.pushNamed(context, '/camera');
                  }
                }
                if (status.isPermanentlyDenied) {
                  // 用户点了 "不再询问" 或 iOS 已经拒绝
                  Get.bottomSheet(const CameraAuthSheet());
                }
              },
              backgroundColor: (!Controller.c.isAnalyzing.value &&
                      Controller.c.user['id'] != 0)
                  ? const Color.fromARGB(255, 0, 0, 0)
                  : Colors.grey,
              // splashColor:const Color.fromARGB(255, 0, 0, 0),
              child: const Icon(AliIcon.camera2,
                  size: 35, color: Color.fromARGB(255, 255, 255, 255)),
            )));
  }
}
