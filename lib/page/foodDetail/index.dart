import 'dart:math';

import 'package:calorie/common/icon/index.dart';
import 'package:calorie/common/util/constants.dart';
import 'package:calorie/common/util/utils.dart';
import 'package:calorie/components/actionSheets/shareFood.dart';
import 'package:calorie/components/dialog/nutrition.dart';
// import 'package:calorie/components/buttonX/index.dart';
import 'package:calorie/network/api.dart';
import 'package:calorie/store/store.dart';
import 'package:calorie/components/dialog/delete.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:sliding_up_panel/sliding_up_panel.dart';

class FoodDetail extends StatefulWidget {
  const FoodDetail({super.key});

  @override
  State<FoodDetail> createState() => _FoodDetailState();
}

class _FoodDetailState extends State<FoodDetail> {
  // final PanelController _panelController = PanelController();
  int _selectedMeal = 1; // 默认值
  String _dishName = 'UNKNOWN_FOOD'.tr; // 默认值

  double? _imageHeight;
  double? _imageWidth;
  String? _imageUrl; // 存储图片URL，可能为null

  // 安全地获取数据
  void _initializeData() {
    try {
      final foodDetail = Controller.c.foodDetail;
      
      // 安全地获取 mealType
      final mealType = foodDetail['mealType'];
      _selectedMeal = (mealType is int) ? mealType : (mealType != null ? int.tryParse(mealType.toString()) ?? 1 : 1);
      
      // 安全地获取 dishName
      final detectionResultData = foodDetail['detectionResultData'];
      if (detectionResultData != null && detectionResultData is Map) {
        final total = detectionResultData['total'];
        if (total != null && total is Map) {
          final dishNameRaw = total['dishName'];
          if (dishNameRaw != null && dishNameRaw.toString().isNotEmpty) {
            _dishName = dishNameRaw.toString();
          }
        }
      }
      
      // 安全地获取图片URL
      final sourceImg = foodDetail['sourceImg'];
      if (sourceImg != null && sourceImg.toString().isNotEmpty) {
        _imageUrl = sourceImg.toString();
        _loadImageSize();
      }
    } catch (e) {
      print('Error initializing food detail data: $e');
      // 使用默认值继续
    }
  }

  void _loadImageSize() {
    if (_imageUrl == null || _imageUrl!.isEmpty) return;
    
    try {
      final img = Image.network(_imageUrl!).image;
      img.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          if (mounted) {
            setState(() {
              _imageWidth = info.image.width.toDouble();
              _imageHeight = info.image.height.toDouble();
            });
          }
        }, onError: (exception, stackTrace) {
          print('Error loading image size: $exception');
          // 图片加载失败时使用默认尺寸
          if (mounted) {
            setState(() {
              _imageWidth = null;
              _imageHeight = null;
            });
          }
        }),
      );
    } catch (e) {
      print('Error creating image: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    // 页面绘制完成后调用打开面板
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _panelController.open(); // 展开到最大高度
    // });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // 计算背景图显示高度
    double displayHeight;
    if (_imageWidth != null && _imageHeight != null) {
      final aspectRatio = _imageWidth! / _imageHeight!;
      if (aspectRatio < 1) {
        // 竖图：宽度撑满，高度自适应
        displayHeight = screenWidth / aspectRatio;
      } else {
        // 横图：固定高度 400
        displayHeight = 400;
      }
    } else {
      displayHeight = screenHeight * 0.6; // 默认占 60%
    }
    Widget buildMealHeader() {
      final meal = mealInfoMap[_selectedMeal];
      return Row(
        children: [
          SizedBox(
            width: 250,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text:
                        _dishName.isEmpty ? 'Unknow Food' : _dishName, // 你的多行文本
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle, // 图标对齐到文字中间或底部
                    child: GestureDetector(
                      onTap: () => _showEditDishNameModal(context),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4), // 图标和文字之间加点间距
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: Color.fromARGB(255, 81, 81, 81),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showEditMealTypeModal(context),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      meal?['color'] ?? const Color.fromARGB(255, 255, 159, 14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Text(meal?['label'] ?? 'DINNER'.tr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(
                      width: 5,
                    ),
                    const Icon(Icons.edit,
                        size: 12, color: Color.fromARGB(255, 255, 255, 255))
                  ],
                )),
          ),
        ],
      );
    }

    Widget buildPanelContent(ScrollController controller) {
      return Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              )),
          padding: const EdgeInsets.only(top: 10),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildMealHeader(),
                const SizedBox(
                  height: 5,
                ),
                Text(
                    _safeGetDate(Controller.c.foodDetail['createDate']),
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),

                const SizedBox(height: 20),
                _buildNutritionStats(),
                const SizedBox(height: 30),
                _buildIngredients(),
                const SizedBox(height: 30),
                _buildNutrition(_safeGetMicronutrients()),
                const SizedBox(height: 15),
                // buildCompleteButton(context,'SAVE'.tr,()async {
                //   final res = await detectionModify(Controller.c.foodDetail['id'],{'dishName':_dishName,'mealType':_selectedMeal});
                //   Get.back();
                // }),
                // const SizedBox(height: 15),
              ],
            ),
          ));
    }

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              // 安全地显示图片，如果URL无效或加载失败则显示默认背景
              _imageUrl != null && _imageUrl!.isNotEmpty
                  ? Image.network(
                      _imageUrl!,
                      width: double.infinity,
                      height: displayHeight,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) {
                        // 图片加载失败时显示默认背景
                        return Container(
                          width: double.infinity,
                          height: displayHeight,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 80,
                            color: Colors.grey,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: displayHeight,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    )
                  : Container(
                      width: double.infinity,
                      height: displayHeight,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
              Positioned(
                top: 68,
                left: 20,
                child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child:  Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                      color: const Color.fromARGB(148, 82, 82, 82),
                      borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        AliIcon.left,
                        color: Colors.white,
                        size: 23,
                      ),
                    )),
              ),
              Positioned(
                top: 68,
                right: 20,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => Get.bottomSheet(const ShareFoodSheet(),
                          isScrollControlled: true),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(147, 63, 63, 63),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          AliIcon.share,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _showDeleteConfirmDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(147, 63, 63, 63),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // SlidingUpPanel(
              //   controller: _panelController, // 加上 controller
              //   borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              //   minHeight: 230, // 初始展开高度可调整
              //   maxHeight: screenHeight * 0.8,
              //   panelBuilder: (ScrollController sc) => _buildPanelContent(sc),
              //   body: const SizedBox(), // 可忽略
              // ),
              // 计算面板初始/最小高度，确保符合约束
              Builder(builder: (context) {
                final rawMin = double.parse(
                  (((screenHeight - displayHeight) / screenHeight).toStringAsFixed(2)),
                );
                final minChildSize = max(rawMin, 0.1);
                const maxChildSize = 0.85;
                final initialChildSize = min(maxChildSize, max(0.53, minChildSize));

                return DraggableScrollableSheet(
                  initialChildSize: initialChildSize,
                  minChildSize: min(minChildSize, initialChildSize),
                  maxChildSize: maxChildSize,
                  builder: (context, controller) {
                    return buildPanelContent(controller);
                  },
                );
              })
            ],
          ),
        ));
  }

  Widget _buildNutritionStats() {
    // 安全地获取营养数据
    final total = _safeGetTotal();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _stat(
                context,
                "CALORIE".tr,
                _safeGetNum(total['calories']) ?? 0,
                Icons.local_fire_department,
                const Color.fromARGB(255, 255, 91, 21),
                'KCAL'.tr,
                'calorie'),
            _stat(
                context,
                "CARBS".tr,
                _safeGetNum(total['carbs']) ?? 0,
                AliIcon.dinner4,
                Colors.blueAccent,
                'G_UNIT'.tr,
                'carbs'),
            _stat(
                context,
                "FATS".tr,
                _safeGetNum(total['fat']) ?? 0,
                AliIcon.meat2,
                Colors.redAccent,
                'G_UNIT'.tr,
                'fat'),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _stat(
                context,
                "PROTEIN".tr,
                _safeGetNum(total['protein']) ?? 0,
                AliIcon.fat,
                Colors.orangeAccent,
                'G_UNIT'.tr,
                'protein'),
            _stat(
                context,
                "SUGAR".tr,
                _safeGetNum(total['sugar']) ?? 0,
                AliIcon.sugar2,
                const Color.fromARGB(255, 64, 242, 255),
                'G_UNIT'.tr,
                'sugars'),
            _stat(
                context,
                "FIBER".tr,
                _safeGetNum(total['fiber']) ?? 0,
                AliIcon.fiber,
                const Color.fromARGB(255, 64, 255, 83),
                'G_UNIT'.tr,
                'dietaryFiber'),
          ],
        ),
      ],
    );
  }

  static Widget _stat(
      BuildContext context,
      String name, 
      dynamic value, 
      IconData icon, 
      Color iconColor, 
      String unit,
      String? nutritionKey) {
    return GestureDetector(
      onTap: () {
        if (nutritionKey != null) {
          showNutritionInfoDialog(context, nutritionKey);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        width: 110,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(31, 89, 89, 89),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ]),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: const Color.fromARGB(255, 250, 246, 246),
              radius: 24,
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    value != null ? value.toString() : '0',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(' $unit',
                    style: const TextStyle(
                        fontSize: 12, color: Color.fromARGB(255, 90, 90, 90))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIngredients() {
    // 安全地获取配料列表
    final ingredients = _safeGetIngredients();

    if (ingredients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("FOOD_KCAL".tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 16,
          runSpacing: 12,
          children: ingredients.map((item) {
            final name = item is Map 
                ? (item['name']?.toString() ?? 'unknown')
                : 'unknown';
            final calories = item is Map 
                ? (_safeGetNum(item['calories']) ?? 0)
                : 0;
            
            return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(31, 89, 89, 89),
                        blurRadius: 5,
                        spreadRadius: 1,
                      )
                    ]),
                child: Column(
                  children: [
                    Text(name.isEmpty ? 'unknown' : name),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      "$calories",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNutrition(Map<String, dynamic> nutritionData) {
    // 只保留 value 不为 0 且 key 存在于 nutritionLabelMap 的项
    List filteredItems = nutritionData.entries.where((e) {
      final key = e.key;
      final value = e.value;
      return value != 0 && nutritionLabelMap().containsKey(key);
    }).toList();
    return filteredItems.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("NUTRITIONAL_VALUE".tr,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              GridView.count(
                shrinkWrap: true, // 重要！让 GridView 适应内容高度（不滚动）
                physics: const NeverScrollableScrollPhysics(), // 禁止内部滚动，避免和外层冲突
                padding: const EdgeInsets.only(top: 22),
                crossAxisCount: 3, // 每行 3 个
                crossAxisSpacing: 16, // 横向间距
                mainAxisSpacing: 12, // 纵向间距
                childAspectRatio: 1.2 / 0.8, // 控制宽高比 1:1（方形），你可以改成 1.2 / 0.8 等
                children: filteredItems.map((item) {
                  String key = item.key;
                  dynamic value = item.value;
                  String displayValue = value % 1 == 0
                      ? value.toInt().toString()
                      : value.toString();

                  String label = nutritionLabelMap()[key]!["label"]!;
                  String unit = nutritionLabelMap()[key]!["unit"]!;

                  return GestureDetector(
                      onTap: () => showNutritionInfoDialog(context, key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 17),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(31, 89, 89, 89),
                              blurRadius: 5,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(label, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 5),
                            Text("$displayValue $unit",
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ));
                }).toList(),
              )
            ],
          );
  }

  void _showEditMealTypeModal(BuildContext context) {
    // final TextEditingController controller = TextEditingController(
    //   text: _dishName,
    // );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true, // 不滚动，内容多少就显示多少
              physics: const NeverScrollableScrollPhysics(), // 禁止滚动
              childAspectRatio:
                  (MediaQuery.of(context).size.width / 2 - 24) / 50, // 控制每项宽高比
              children: mealOptions().map((meal) {
                return GestureDetector(
                    onTap: () async {
                      setState(() {
                        _selectedMeal = meal['value'];
                      });
                      Navigator.pop(context);
                      final id = Controller.c.foodDetail['id'];
                      if (id != null) {
                        try {
                          await detectionModify(id, {'mealType': _selectedMeal});
                        } catch (e) {
                          print('Error modifying meal type: $e');
                        }
                      }
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                            color: meal['value'] == _selectedMeal
                                ? meal['color']
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: meal['color'])),
                        child: Row(
                          children: [
                            Icon(meal['icon'],
                                color: meal['value'] == _selectedMeal
                                    ? Colors.white
                                    : meal['color']),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              meal['label'],
                              style: TextStyle(
                                  color: meal['value'] == _selectedMeal
                                      ? Colors.white
                                      : meal['color'],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        )));
              }).toList(),
            ));
      },
    );
  }

  void _showEditDishNameModal(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: _dishName,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                maxLength: 45,
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (value) async {
                  final newName = value.trim();
                  if (newName.isNotEmpty) {
                    setState(() {
                      _dishName = newName;
                    });
                  }

                  Navigator.pop(context); // 关闭 bottom sheet
                  final id = Controller.c.foodDetail['id'];
                  if (id != null) {
                    try {
                      await detectionModify(id, {'dishName': newName});
                    } catch (e) {
                      print('Error modifying dish name: $e');
                    }
                  }
                },
                decoration: const InputDecoration(
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 154, 154, 154))),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // 辅助方法：安全地获取 total 数据
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
      print('Error getting total data: $e');
    }
    return {};
  }

  // 辅助方法：安全地获取 micronutrients
  Map<String, dynamic> _safeGetMicronutrients() {
    try {
      final total = _safeGetTotal();
      final micronutrients = total['micronutrients'];
      if (micronutrients != null && micronutrients is Map) {
        return Map<String, dynamic>.from(micronutrients);
      }
    } catch (e) {
      print('Error getting micronutrients: $e');
    }
    return {};
  }

  // 辅助方法：安全地获取 ingredients
  List<dynamic> _safeGetIngredients() {
    try {
      final foodDetail = Controller.c.foodDetail;
      final detectionResultData = foodDetail['detectionResultData'];
      if (detectionResultData != null && detectionResultData is Map) {
        final ingredients = detectionResultData['ingredients'];
        if (ingredients != null && ingredients is List) {
          return List.from(ingredients);
        }
      }
    } catch (e) {
      print('Error getting ingredients: $e');
    }
    return [];
  }

  // 辅助方法：安全地获取数字值
  num? _safeGetNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      return parsed;
    }
    return null;
  }

  // 辅助方法：安全地获取日期字符串
  String _safeGetDate(dynamic dateValue) {
    try {
      if (dateValue != null) {
        return formatDate(dateValue);
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    return '';
  }

  // 显示删除确认弹窗
  void _showDeleteConfirmDialog(BuildContext context) async {
    final foodDetail = Controller.c.foodDetail;
    final dynamic idValue = foodDetail['id'];
    final int? id = idValue is int ? idValue : (idValue is String ? int.tryParse(idValue) : null);
    
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CANNOT_GET_ITEM_ID'.tr)),
      );
      return;
    }

    final bool? confirmed = await showDeleteConfirmDialog(context);

    if (confirmed != true) return;

    try {
      await detectionDelete(id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DELETE_SUCCESS'.tr),
            duration: const Duration(seconds: 2),
          ),
        );
        // 删除成功后返回上一页
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error deleting food detail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'DELETE_FAILED'.tr}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
