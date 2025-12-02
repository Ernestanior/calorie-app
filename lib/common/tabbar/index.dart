import 'package:calorie/common/icon/index.dart';
import 'package:calorie/store/store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomTabBar extends StatefulWidget {
  @override
  _CustomTabBarState createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> _tabs = [
      {"icon": AliIcon.check, "label": "RECORD".tr},
      {"icon": AliIcon.recipe3, "label": "PLAN".tr},
      {"icon": AliIcon.chef2, "label": "CHEF".tr},
      {"icon": AliIcon.mine3, "label": "MINE".tr},
    ];
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom,
      left: 15,
      right: 20,
      child: SizedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 左边 Tabs

            Container(
              width: 280,
              height: 65,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color.fromARGB(234, 249, 245, 253),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.white, width: 2)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double tabWidth = constraints.maxWidth / _tabs.length;
                  return Stack(
                    children: [
                      // 灰色滑块背景
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: Controller.c.tabIndex.value * tabWidth,
                        top: 0,
                        bottom: 0,
                        width: tabWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(90, 205, 205, 205),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),

                      // Tabs 内容
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(_tabs.length, (index) {
                          final tab = _tabs[index];
                          final isSelected =
                              index == Controller.c.tabIndex.value;
                          return GestureDetector(
                            onTap: () {
                              Controller.c.tabIndex(index);
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.transparent),
                              width: tabWidth,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 3),
                                  Icon(
                                    tab["icon"],
                                    color: isSelected
                                        ? Colors.black
                                        : const Color.fromARGB(
                                            255, 131, 120, 176),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tab["label"],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
            // FloatBtn()
            // 右边加号按钮
            // Container(
            //   width: 60,
            //   height: 60,
            //   decoration: const BoxDecoration(
            //     color: Colors.black,
            //     shape: BoxShape.circle,
            //   ),
            //   child: const Icon(AliIcon.camera_fill, color: Colors.white, size: 29),
            // ),
          ],
        ),
      ),
    );
  }
}
