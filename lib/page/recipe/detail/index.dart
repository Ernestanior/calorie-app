import 'package:cached_network_image/cached_network_image.dart';
import 'package:calorie/common/icon/index.dart';
import 'package:calorie/common/util/constants.dart';
import 'package:calorie/common/util/utils.dart';
import 'package:calorie/network/api.dart';
import 'package:calorie/page/recipe/detail/nutrition_chart.dart';
import 'package:calorie/store/store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class RecipeDetail extends StatefulWidget {
  const RecipeDetail({super.key});

  @override
  _RecipeDetailState createState() => _RecipeDetailState();
}

class _RecipeDetailState extends State<RecipeDetail> {
  int selectedDay = 1;
  double _titleOpacity = 0.0;
  final recipeSet = Get.arguments;
  Map recipes = initRecipes;
  Map recipeCovers = initRecipeSets;

  // 从新接口 /recipe/plan 加载的完整计划数据
  Map<String, dynamic>? _plan;

  int totalCalories = 0;
  int totalCarbs = 0;
  int totalFat = 0;
  int totalProtein = 0;
  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final data = await recipePlan(recipeSet['id']);
      if (!mounted) return;
      if (data != null && data != "-1") {
        _plan = Map<String, dynamic>.from(data as Map);
        _applyDay(1);
      }
    } catch (e) {
      print('$e error');
    }
  }

  void _applyDay(int day) {
    if (_plan == null) return;
    final days = (_plan!['days'] as List?) ?? [];

    Map<String, dynamic>? dayEntry;
    for (final d in days) {
      if (d is Map && d['day'] == day) {
        dayEntry = Map<String, dynamic>.from(d);
        break;
      }
    }

    if (dayEntry == null) {
      setState(() {
        selectedDay = day;
        recipes = {};
        recipeCovers = {};
        totalCalories = 0;
        totalCarbs = 0;
        totalFat = 0;
        totalProtein = 0;
      });
      return;
    }

    final meals = (dayEntry['meals'] as List?) ?? [];

    final Map<int, List<Map<String, dynamic>>> newRecipes = {};
    final Map<int, List<Map<String, dynamic>>> newCovers = {};

    int calories = 0;
    int carbs = 0;
    int fat = 0;
    int protein = 0;

    for (final m in meals) {
      if (m is! Map) continue;
      final mealType = (m['mealType'] ?? 0) as int;
      if (mealType == 0) continue;

      final coverPhoto = m['coverPhoto'];
      if (coverPhoto != null && coverPhoto is String && coverPhoto.isNotEmpty) {
        newCovers[mealType] = [
          {
            'previewPhoto': coverPhoto,
          }
        ];
      }

      final items = (m['items'] as List?) ?? [];
      final List<Map<String, dynamic>> mealItems = [];

      for (final it in items) {
        if (it is! Map) continue;
        final quantity = (it['quantity'] ?? 1) as int;
        final fn = (it['foodNutrition'] is Map)
            ? Map<String, dynamic>.from(it['foodNutrition'] as Map)
            : <String, dynamic>{};

        final calsPerUnit = (fn['caloriesPerUnit'] ?? 0) as int;
        final carbsPerUnit = (fn['carbsPerUnit'] ?? 0) as int;
        final fatPerUnit = (fn['fatPerUnit'] ?? 0) as int;
        final proteinPerUnit = (fn['proteinPerUnit'] ?? 0) as int;

        calories += calsPerUnit * quantity;
        carbs += carbsPerUnit * quantity;
        fat += fatPerUnit * quantity;
        protein += proteinPerUnit * quantity;

        mealItems.add({
          'foodName': fn['name'],
          'foodNameEn': fn['nameEn'],
          'foodUnit': fn['unit'],
          'foodImageUrl': fn['imageUrl'] ?? '',
          'foodCaloriesPerUnit': calsPerUnit,
          'foodCarbsPerUnit': carbsPerUnit,
          'foodFatPerUnit': fatPerUnit,
          'foodProteinPerUnit': proteinPerUnit,
          'quantity': quantity,
        });
      }

      if (mealItems.isNotEmpty) {
        newRecipes[mealType] = mealItems;
      }
    }

    setState(() {
      selectedDay = day;
      recipes = newRecipes;
      recipeCovers = newCovers;
      totalCalories = calories;
      totalCarbs = carbs;
      totalFat = fat;
      totalProtein = protein;
    });
  }

  // double calculateOpacity(double shrinkOffset, double expandedHeight) {
  //   double opacity = shrinkOffset / (expandedHeight - kToolbarHeight);
  //   return opacity.clamp(0.0, 1.0);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 顶部 AppBar
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                expandedHeight: 200,
                backgroundColor: Colors.white,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final double statusBarHeight =
                        MediaQuery.of(context).padding.top;
                    final double expanded = 200 + statusBarHeight;
                    final double collapsed = kToolbarHeight + statusBarHeight;

                    double percent = ((constraints.maxHeight - collapsed) /
                            (expanded - collapsed))
                        .clamp(0.0, 1.0);
                    _titleOpacity = 1 - percent;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          recipeSet['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/food/f1.jpeg', // 你准备好的本地默认图
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                        Container(
                          color: Color.lerp(const Color.fromARGB(148, 0, 0, 0),
                              Colors.white, _titleOpacity),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Opacity(
                            opacity: 1 - _titleOpacity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(recipeSet['name'],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 15),
                                _buildPlanInfo(),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          left: 20,
                          right: 20,
                          child: Row(
                            children: [
                              _buildButton(
                                  AliIcon.left, () => Navigator.pop(context)),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Opacity(
                                    opacity: _titleOpacity,
                                    child: Text(
                                      recipeSet['name'],
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                              Obx(
                                () => (Controller.c.user['recipeSetIdList'] ??
                                            [])
                                        .contains(recipeSet['id'])
                                    ? _buildButton(AliIcon.collectFill,
                                        () async {
                                        //     Fluttertoast.showToast(
                                        // msg: 'UNFAVORITED'.tr,
                                        // toastLength: Toast.LENGTH_SHORT,
                                        // gravity: ToastGravity.CENTER,
                                        // timeInSecForIosWeb: 2,
                                        // backgroundColor: const Color.fromARGB(255, 127, 127, 127),
                                        // textColor: const Color.fromARGB(255, 255, 255, 255),
                                        // fontSize: 16.0);

                                        dynamic res = await userModify({
                                          'recipeSetIdList': Controller
                                              .c.user['recipeSetIdList']
                                              .where(
                                                  (x) => x != recipeSet['id'])
                                              .toList()
                                        });
                                        Controller.c.user(res);
                                      },
                                        iconColor: const Color.fromARGB(
                                            255, 255, 196, 0))
                                    : const SizedBox(
                                        width: 48,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // 吸顶 Day Selector
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverHeaderDelegate(
                  minHeight: 56,
                  maxHeight: 56,
                  child: Container(
                    color: Colors.white,
                    alignment: Alignment.centerLeft,
                    child: _buildDaySelector(),
                  ),
                ),
              ),
            ];
          },
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.symmetric(vertical: 15),
                children: [
                  if (recipes[1] != null) ...[
                    _buildMealCard(1),
                    const SizedBox(height: 15),
                  ],
                  if (recipes[2] != null) ...[
                    _buildMealCard(2),
                    const SizedBox(height: 15),
                  ],
                  if (recipes[3] != null) ...[
                    _buildMealCard(3),
                  ],
                  const SizedBox(height: 20),
                  NutritionPieChart(
                    calories: totalCalories,
                    carb: totalCarbs,
                    protein: totalProtein,
                    fat: totalFat,
                  ),
                  const SizedBox(height: 70),
                ],
              ),
              Obx(
                () => !(Controller.c.user['recipeSetIdList'] ?? [])
                        .contains(recipeSet['id'])
                    ? Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: _buildSetPlanButton(
                            Controller.c.user['recipeSetIdList'] ?? []),
                      )
                    : const SizedBox.shrink(),
              )
            ],
          )),
    );
  }

  Widget _buildButton(IconData icon, GestureTapCallback onTap,
      {Color backgroundColor = Colors.white, Color iconColor = Colors.black}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: backgroundColor,
        child: Icon(icon, color: iconColor, size: 26),
      ),
    );
  }

  Widget _buildPlanInfo() {
    List<Map<String, String>> infos = [
      {
        'title': 'PLAN_DURATION'.tr,
        'value': '${recipeSet['day']}',
        'unit': 'DAY'.tr
      },
      {
        'title': '${recipeSet['type']}',
        'value': recipeSet['weight'],
        'unit': 'KG'.tr
      },
      {
        'title': 'USERS'.tr,
        'value': '${recipeSet['hot']}',
        'unit': 'HOT_UNIT'.tr
      },
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(infos.length * 2 - 1, (i) {
        if (i.isEven) {
          int infoIndex = i ~/ 2;
          var info = infos[infoIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(info['title']!,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text.rich(
                TextSpan(
                  text: info['value'],
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  children: [
                    TextSpan(
                        text: info['unit']!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.normal))
                  ],
                ),
              ),
            ],
          );
        } else {
          return Container(
            height: 40,
            width: 0.5,
            color: Colors.white70,
            margin: const EdgeInsets.symmetric(horizontal: 15),
          );
        }
      }),
    );
  }

  Widget _buildDaySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: List.generate(recipeSet['day'], (index) {
          int day = index + 1;
          bool isSelected = selectedDay == day;
          return GestureDetector(
            onTap: () {
              _applyDay(day);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('DAY_NUM'.trArgs(['$day']),
                  style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMealCard(int mealType) {
    // 计算该餐总热量
    int mealCalories = recipes[mealType].fold(
        0,
        (sum, item) =>
            sum + (item['foodCaloriesPerUnit'] * item['quantity'] ?? 0) as int);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 249, 249, 255),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: CachedNetworkImage(
              imageUrl:
                  recipeCovers[mealType]?[0]?['previewPhoto'] ?? '',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: const Color(0xFFCCE0FF), // 蓝色背景
                highlightColor: Colors.white, // 扫光白色
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: const Color(0xFFCCE0FF), // 固定蓝白背景
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 180,
                width: double.infinity,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(AliIcon.calorie2,
                        color: Color.fromARGB(208, 255, 103, 43), size: 18),
                    const SizedBox(width: 3),
                    Text('$mealCalories ${'KCAL'.tr}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: mealInfoMap[mealType]?['color'],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(mealInfoMap[mealType]?['label'],
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 循环渲染每一道菜
                Column(
                  children: recipes[mealType].map<Widget>((food) {
                    return _buildFoodItem(
                      Controller.c.lang.value == 'zh_CN'
                          ? food['foodName']
                          : food['foodNameEn'],
                      food['quantity'],
                      translateUnit(food['foodUnit'], Controller.c.lang.value),
                      food['foodImageUrl'],
                      food['foodCaloriesPerUnit'] ?? 0,
                    );
                  }).toList(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(
      String name, int quantity, String unit, String img, int kcal) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                child: CachedNetworkImage(
                  imageUrl:  img,
                  height: 70,
                  width: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: const Color(0xFFCCE0FF), // 蓝色背景
                    highlightColor: Colors.white, // 扫光白色
                    child: Container(
                      height: 70,
                      width: 70,
                      color: const Color(0xFFCCE0FF), // 固定蓝白背景
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 70,
                    width: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 180,
                    child: Text(name, style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(height: 5),
                  Text('$quantity $unit',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 95, 80, 112))),
                ],
              ),
            ],
          ),
          Row(
            children: [
              const Icon(AliIcon.calorie2,
                  color: Color.fromARGB(250, 255, 143, 16), size: 14),
              const SizedBox(width: 3),
              Text('${quantity * kcal}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetPlanButton(List collectList) {
    return GestureDetector(
      onTap: () async {
        dynamic res = await userModify({
          'recipeSetIdList': [...collectList, recipeSet['id']]
        });
        Controller.c.user(res);
      },
      child: Container(
        width: double.infinity,
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: const Color.fromARGB(154, 0, 0, 0),
            borderRadius: BorderRadius.circular(25)),
        alignment: Alignment.center,
        child: Text('SET_AS_MY_PLAN'.tr,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// Delegate for SliverPersistentHeader
class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}

Map initRecipes = {
  1: [
    {
      "id": 727,
      "recipeSetId": 47,
      "foodNutritionId": 6239,
      "foodName": "绿茶",
      "foodNameEn": "Green Tea",
      "foodHeat": 1,
      "foodImageUrl": "",
      "foodUnit": "杯",
      "foodFatPerUnit": 0,
      "foodProteinPerUnit": 0,
      "foodCarbsPerUnit": 0,
      "foodCaloriesPerUnit": 1,
      "foodFatPer100gram": 0,
      "foodProteinPer100gram": 0,
      "foodCarbsPer100gram": 0,
      "foodCaloriesPer100gram": 1,
      "day": 4,
      "mealType": 1,
      "quantity": 1,
      "type": 1
    },
    {
      "id": 728,
      "recipeSetId": 47,
      "foodNutritionId": 6240,
      "foodName": "酸奶（无糖）",
      "foodNameEn": "Yogurt(no sugar)",
      "foodHeat": 2,
      "foodImageUrl": "",
      "foodUnit": "杯",
      "foodFatPerUnit": 0,
      "foodProteinPerUnit": 6,
      "foodCarbsPerUnit": 4,
      "foodCaloriesPerUnit": 60,
      "foodFatPer100gram": 0,
      "foodProteinPer100gram": 6,
      "foodCarbsPer100gram": 4,
      "foodCaloriesPer100gram": 59,
      "day": 4,
      "mealType": 1,
      "quantity": 1,
      "type": 1
    }
  ],
  2: [
    {
      "id": 729,
      "recipeSetId": 47,
      "foodNutritionId": 6224,
      "foodName": "烤三文鱼",
      "foodNameEn": "Grilled Salmon",
      "foodHeat": 3,
      "foodImageUrl": "",
      "foodUnit": "块",
      "foodFatPerUnit": 18,
      "foodProteinPerUnit": 25,
      "foodCarbsPerUnit": 0,
      "foodCaloriesPerUnit": 280,
      "foodFatPer100gram": 13,
      "foodProteinPer100gram": 20,
      "foodCarbsPer100gram": 0,
      "foodCaloriesPer100gram": 208,
      "day": 4,
      "mealType": 2,
      "quantity": 1,
      "type": 1
    },
    {
      "id": 730,
      "recipeSetId": 47,
      "foodNutritionId": 6245,
      "foodName": "炒芦笋",
      "foodNameEn": "Stir-fried Asparagus",
      "foodHeat": 2,
      "foodImageUrl": "",
      "foodUnit": "碗",
      "foodFatPerUnit": 2,
      "foodProteinPerUnit": 4,
      "foodCarbsPerUnit": 7,
      "foodCaloriesPerUnit": 80,
      "foodFatPer100gram": 1,
      "foodProteinPer100gram": 2,
      "foodCarbsPer100gram": 4,
      "foodCaloriesPer100gram": 45,
      "day": 4,
      "mealType": 2,
      "quantity": 1,
      "type": 1
    }
  ],
  3: [
    {
      "id": 731,
      "recipeSetId": 47,
      "foodNutritionId": 6075,
      "foodName": "清蒸鸡胸肉",
      "foodNameEn": "Steamed Chicken Breast",
      "foodHeat": 2,
      "foodImageUrl": "",
      "foodUnit": "块",
      "foodFatPerUnit": 3,
      "foodProteinPerUnit": 31,
      "foodCarbsPerUnit": 0,
      "foodCaloriesPerUnit": 165,
      "foodFatPer100gram": 3,
      "foodProteinPer100gram": 31,
      "foodCarbsPer100gram": 0,
      "foodCaloriesPer100gram": 165,
      "day": 4,
      "mealType": 3,
      "quantity": 1,
      "type": 1
    },
    {
      "id": 732,
      "recipeSetId": 47,
      "foodNutritionId": 6233,
      "foodName": "凉拌西红柿",
      "foodNameEn": "Chilled Tomato Salad",
      "foodHeat": 1,
      "foodImageUrl": "",
      "foodUnit": "碗",
      "foodFatPerUnit": 0,
      "foodProteinPerUnit": 1,
      "foodCarbsPerUnit": 6,
      "foodCaloriesPerUnit": 30,
      "foodFatPer100gram": 0,
      "foodProteinPer100gram": 0,
      "foodCarbsPer100gram": 3,
      "foodCaloriesPer100gram": 18,
      "day": 4,
      "mealType": 3,
      "quantity": 1,
      "type": 1
    }
  ]
};

Map initRecipeSets = {
  1: [
    {
      "id": 1961,
      "recipeSetId": 48,
      "day": 1,
      "mealType": 1,
      "quantity": 1,
      "type": 2,
      "previewPhoto": ""
    }
  ],
  2: [
    {
      "id": 1962,
      "recipeSetId": 48,
      "day": 1,
      "mealType": 2,
      "quantity": 1,
      "type": 2,
      "previewPhoto": ""
    }
  ],
  3: [
    {
      "id": 1963,
      "recipeSetId": 48,
      "day": 1,
      "mealType": 3,
      "quantity": 1,
      "type": 2,
      "previewPhoto": ""
    }
  ]
};
