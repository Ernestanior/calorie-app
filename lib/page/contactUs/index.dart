// import 'dart:html';
import 'dart:io';
import 'package:calorie/components/buttonX/index.dart';
import 'package:dio/dio.dart' as dio;

import 'package:calorie/page/contactUs/gmail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../network/api.dart';

class ContactUs extends StatefulWidget {
  const ContactUs({super.key});
  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
  bool _isPicking = false;
  File? _image;
  String content = '';
  String imgPath = '';
  String errorMsg = '';
  Future<void> _pickImage() async {
    if (_isPicking) return;
    _isPicking = true;
    print('开始选择图片...');

    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker
          .pickImage(
        source: ImageSource.gallery,
      )
          .timeout(
        const Duration(seconds: 15), // ✅ 设置超时时间
        onTimeout: () {
          print('选图超时，可能是 GIF 卡住了');
          return null; // 返回 null，当作用户取消
        },
      );

      if (image == null) {
        print('用户取消选择');
        return;
      }

      // 判断文件扩展名
      final String extension = image.path.split('.').last.toLowerCase();
      if (extension == 'gif') {
        print('禁止选择 GIF 图片');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GIF 格式暂不支持，请选择 JPG/PNG 图片')),
          );
        }
        return;
      }

      print('选中图片: ${image.path}');
      final file = File(image.path);
      setState(() {
        _image = file;
      });
      dio.FormData formData = dio.FormData.fromMap({
        "file":
            await dio.MultipartFile.fromFile(file.path, filename: "upload.jpg"),
      });

      final url = await fileUpload(formData);
      if (url == null) {
        return;
      }
      setState(() {
        imgPath = url;
      });
    } catch (e) {
      print('选择图片出错: $e');
    } finally {
      _isPicking = false;
      print('done');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true, // 让页面在键盘弹出时自动调整
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'CONTACT_US'.tr,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: GestureDetector(
            behavior: HitTestBehavior.translucent, // 点透明区域也能响应
            onTap: () {
              FocusScope.of(context).unfocus(); // 收起键盘
            },
            child: SingleChildScrollView(
                child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    'BUSINESS_COOPERATION'.tr,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  MailButton(),
                  SizedBox(
                    height: 50,
                  ),
                  Text(
                    'FEEDBACK'.tr,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(12),
                    child: TextField(
                      maxLines: null, // 多行
                      minLines: 5, // 默认显示行数
                      style: TextStyle(fontSize: 14),
                      onChanged: (value) async {
                        final feedback = value.trim();
                        print(feedback);
                        if (feedback.isNotEmpty) {
                          setState(() {
                            content = feedback;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelStyle: TextStyle(
                          fontSize: 12,
                        ),
                        hintText: "DESC_YOUR_QUESTION".tr,
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                        border: InputBorder.none, // 去掉边框
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    'PHOTO_UPLOAD_OPTIONAL'.tr,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                      onTap: _pickImage,
                      child: _image == null
                          ? Container(
                              padding: EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 244, 243, 250),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(
                                Icons.add,
                                size: 30,
                                color: Colors.grey,
                              ),
                            )
                          : ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              child: Image.file(_image!,
                                  height: 100, width: 100, fit: BoxFit.fill),
                            )),
                  SizedBox(
                    height: 30,
                  ),
                  buildCompleteButton(context, 'SUBMIT_FEEDBACK'.tr, () async {
                    print(content);
                    print(imgPath);
                    if (content.length < 10) {
                      setState(() {
                        errorMsg = 'FEEDBACK_MIN_LENGTH'.tr;
                      });
                    } else if (content.isNotEmpty && imgPath.isNotEmpty) {
                      await feedback(content, imgPath);
                      Get.back();
                      setState(() {
                        errorMsg = '';
                      });
                    } else {
                      setState(() {
                        errorMsg = "PLEASE_FILL_IN_COMPLETELY".tr;
                      });
                    }
                  }),
                  errorMsg == ""
                      ? SizedBox.shrink()
                      : Text(errorMsg,
                          style: TextStyle(
                            color: Colors.red,
                          ))
                ],
              ),
            ))));
  }
}
