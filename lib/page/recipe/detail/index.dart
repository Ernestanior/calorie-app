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
import 'mealData.dart';

class RecipeDetail extends StatefulWidget {
  @override
  _RecipeDetailState createState() => _RecipeDetailState();
}

class _RecipeDetailState extends State<RecipeDetail> {
  int selectedDay = 1;
  double _titleOpacity = 0.0;
  final recipeSet = Get.arguments;
  Map recipes = initRecipes;
  Map recipeCovers = initRecipeSets;

  int totalCalories = 0;
  int totalCarbs = 0;
  int totalFat = 0;
  int totalProtein = 0;
  @override
  void initState() {
    super.initState();
    fetchData(recipeSet['id'], 1);
  }

  Future<void> fetchData(int id, int day) async {
    try {
      final recipe = await recipePage(id, day);
      // print(MealDataHelper.groupMealsByType(recipe['content']));
      // print(MealDataHelper.groupMealsByType(recipeCover['content']));
      final type1List =
          recipe['content'].where((item) => item['type'] == 1).toList();
      final type2List =
          recipe['content'].where((item) => item['type'] == 2).toList();

      //计算总卡路里，蛋白质，碳水，脂肪
      setState(() {
        totalCalories = type1List.fold(
            0,
            (sum, item) => sum +
                (item['foodCaloriesPerUnit'] * item['quantity'] ?? 0) as int);
        totalCarbs = type1List.fold(
            0,
            (sum, item) => sum +
                (item['foodCarbsPerUnit'] * item['quantity'] ?? 0) as int);
        totalFat = type1List.fold(
            0,
            (sum, item) =>
                sum + (item['foodFatPerUnit'] * item['quantity'] ?? 0) as int);
        totalProtein = type1List.fold(
            0,
            (sum, item) => sum +
                (item['foodProteinPerUnit'] * item['quantity'] ?? 0) as int);
      });

      if (!mounted) return;
      if (recipe.isNotEmpty) {
        setState(() {
          recipes = MealDataHelper.groupMealsByType(type1List);
          recipeCovers = MealDataHelper.groupMealsByType(type2List);
        });
      }
    } catch (e) {
      print('$e error');
    }
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
              fetchData(recipeSet['id'], day);
              setState(() => selectedDay = day);
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
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: CachedNetworkImage(
              imageUrl:
                  imgUrl + (recipeCovers[mealType]?[0]?['previewPhoto'] ?? ''),
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
                  imageUrl: imgUrl + img,
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
                  Container(
                    width: 180,
                    child: Text(name, style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(height: 5),
                  Text('${quantity} ${unit}',
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
