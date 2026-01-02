

import 'package:calorie/common/icon/index.dart';
import 'package:calorie/store/store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:calorie/common/util/utils.dart';

final GlobalKey shareFoodKey = GlobalKey();

class ShareFoodSheet extends StatefulWidget {
  const ShareFoodSheet({super.key});
  @override
  State<ShareFoodSheet> createState() => _ShareFoodSheetState();
}

class _ShareFoodSheetState extends State<ShareFoodSheet>  {

  // 安全地获取数据
  Map<String, dynamic> _safeGetTotal() {
    try {
      final foodDetail = Controller.c.foodDetail;
      final detectionResultData = foodDetail['detectionResultData'];
      if (detectionResultData != null && detectionResultData is Map) {
        final total = detectionResultData['total'];
        if (total != null && total is Map) {
          return Map<String, dynamic>.from(total);
        }
      }
    } catch (e) {
      print('Error getting total data in ShareFoodSheet: $e');
    }
    return {};
  }

  // 安全地获取菜品名称
  String _safeGetDishName() {
    try {
      final total = _safeGetTotal();
      final dishName = total['dishName'];
      if (dishName != null && dishName.toString().isNotEmpty) {
        return dishName.toString();
      }
    } catch (e) {
      print('Error getting dish name: $e');
    }
    return 'UNKNOWN_FOOD'.tr;
  }

  // 安全地获取图片URL
  String? _safeGetImageUrl() {
    try {
      final foodDetail = Controller.c.foodDetail;
      final sourceImg = foodDetail['sourceImg'];
      if (sourceImg != null && sourceImg.toString().isNotEmpty) {
        return sourceImg.toString();
      }
    } catch (e) {
      print('Error getting image URL: $e');
    }
    return null;
  }

  // 安全地获取数字值
  num? _safeGetNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      return parsed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          color: Color.fromARGB(255, 250, 249, 255)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(children: [
        Text(
          'SHARE'.tr,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        RepaintBoundary(
            key: shareFoodKey,
            child:Container(
              decoration: const BoxDecoration(color: Color.fromARGB(255, 250, 249, 255)),
              child:   Column(
              children: [
                const SizedBox(height: 20),
                // 图片 + 标题
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _safeGetImageUrl() != null
                          ? Image.network(
                              _safeGetImageUrl()!,
                              height: 300,
                              width: 300,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // 图片加载失败时显示默认背景
                                return Container(
                                  height: 300,
                                  width: 300,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.restaurant_menu,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 300,
                                  width: 300,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 300,
                              width: 300,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.restaurant_menu,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    Positioned(
                        left: 20,
                        bottom: 10,
                        child: Container(
                          child: Column(
                            children: [
                              Text(
                                _safeGetDishName(),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        )),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/image/logo.png',
                      width: 26,
                    ),
                    const Text("Vita AI",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                // 营养信息
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 15,
                    runSpacing: 15,
                    children: [
                      _buildInfoCard(
                          "CALORIE".tr,
                          _safeGetNum(_safeGetTotal()['calories']) ?? 0,
                          'kcal',
                          AliIcon.calorie2,
                          const Color.fromARGB(255, 255, 122, 82)),
                      _buildInfoCard(
                          "CARBS".tr,
                          _safeGetNum(_safeGetTotal()['carbs']) ?? 0,
                          'g',
                          AliIcon.dinner4,
                          Colors.blueAccent),
                      _buildInfoCard(
                          "PROTEIN".tr,
                          _safeGetNum(_safeGetTotal()['protein']) ?? 0,
                          'g',
                          AliIcon.fat,
                          Colors.orangeAccent),
                      _buildInfoCard(
                          "FATS".tr,
                          _safeGetNum(_safeGetTotal()['fat']) ?? 0,
                          'g',
                          AliIcon.meat2,
                          Colors.redAccent),
                      _buildInfoCard(
                          "SUGAR".tr,
                          _safeGetNum(_safeGetTotal()['sugar']) ?? 0,
                          'g',
                          AliIcon.sugar2,
                          const Color.fromARGB(255, 4, 247, 255)),
                      _buildInfoCard(
                          "FIBER".tr,
                          _safeGetNum(_safeGetTotal()['fiber']) ?? 0,
                          'g',
                          AliIcon.fiber,
                          const Color.fromARGB(255, 64, 255, 83)),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
              ],
            )),
           
            ) ,
             
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: ()=>SharePng(shareFoodKey,type:'ins'),
                      child:Column(
                      children: [
                        Image.asset(
                          'assets/image/ins.png',
                          width: 50,
                        ),
                        const Text("Instagram", style: TextStyle(fontSize: 12)),
                      ],
                    ) ,
                    )
                    ,
                    GestureDetector(
                      onTap: ()=>SharePng(shareFoodKey,type:'facebook'),
                      child:Column(
                      children: [
                        Image.asset(
                          'assets/image/facebook.png',
                          width: 47,
                        ),
                        const SizedBox(height: 3,),
                        const Text("Facebook", style: TextStyle(fontSize: 12)),
                      ],
                    ) ,
                    ),
                    _buildShareButton(
                        Image.asset(
                          'assets/image/wechat.png',
                          width: 31,
                        ),
                        "WECHAT".tr,onPress:()=>SharePng(shareFoodKey,type:'wx'),
                        color: const Color.fromARGB(255, 9, 194, 15)
                          ),
                    _buildShareButton(
                        Image.asset(
                          'assets/image/share.png',
                          width: 30,
                        ),
                        "OTHER".tr,onPress:()=>SharePng(shareFoodKey)
                          ),
                  ],
                ),
              
      ]),
    );
  }

  Widget _buildInfoCard(String title, Object? value, String unit, IconData icon,
      Color iconColor) {
    // 安全地处理 value，确保显示有效值
    final displayValue = value != null ? value.toString() : '0';
    
    return Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(31, 155, 155, 155),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ]),
        child: Row(
          children: [
            const SizedBox(
              width: 10,
            ),
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(
              width: 15,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color.fromARGB(176, 0, 0, 0))),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: "$displayValue ",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                          text: unit,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Color.fromARGB(255, 120, 120, 120)))
                    ],
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  Widget _buildShareButton(Widget icon, String text, {Color? color, void Function()? onPress}) {
    return GestureDetector(
      onTap: onPress,
      child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(31, 122, 122, 122),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ],
            color: color ?? Colors.white,
          ),
          child: icon,
        ),
        const SizedBox(height: 3),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    ),
    ) ;
  }
}
