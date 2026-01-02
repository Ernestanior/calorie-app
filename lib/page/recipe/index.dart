import 'package:cached_network_image/cached_network_image.dart';
import 'package:calorie/common/icon/index.dart';
import 'package:calorie/common/util/constants.dart';
import 'package:calorie/store/receiptController.dart';
import 'package:calorie/store/store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'detail/index.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    // 确保每次进入页面都尝试加载数据
    _loadRecipes();
  }

  void _loadRecipes() {
    print('RecipePage _loadRecipes called');

    // 检查RecipeController是否正常初始化
    if (!RecipeController.r.isInitialized.value) {
      print('RecipeController not initialized, forcing reinitialize');
      RecipeController.r.forceReinitialize();
      return;
    }

    // 如果数据为空或出错，重新加载
    if (RecipeController.r.recipeSets.isEmpty ||
        RecipeController.r.hasError.value) {
      print('Recipe data empty or error, fetching recipes');
      RecipeController.r.safeFetchRecipes();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('RecipePage didChangeDependencies called');
    // 页面重新获得焦点时重新加载数据
    _loadRecipes();
  }

  @override
  void didUpdateWidget(RecipePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('RecipePage didUpdateWidget called');
    _loadRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        // 全屏背景，延伸到安全区域
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 236, 255, 237),
                Color.fromARGB(255, 233, 255, 244),
                Color.fromARGB(255, 225, 245, 255),
                Color.fromARGB(255, 255, 241, 225),
                Color.fromARGB(255, 255, 225, 225),
              ],
            ),
          ),
        ),
        // 主要内容，延伸到安全区域
        Column(
          children: [
            // 顶部安全区域的内容延伸
            Container(
              height: MediaQuery.of(context).padding.top,
              color: Colors.transparent,
            ),
            // 实际内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    _buildAppBar(context),
                    const SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: Obx(() {
                        // 显示加载状态
                        if (RecipeController.r.isLoading.value) {
                          return Column(
                            children: [
                              const SizedBox(height: 100),
                              const CircularProgressIndicator(),
                              const SizedBox(height: 20),
                              Text(
                                'LOADING_RECIPES'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 115, 115, 115),
                                ),
                              ),
                            ],
                          );
                        }

                        // 显示错误状态
                        if (RecipeController.r.hasError.value) {
                          return Column(
                            children: [
                              const SizedBox(height: 100),
                              Image.asset('assets/image/rice.png', height: 100),
                              const SizedBox(height: 20),
                              Text(
                                'OOPS'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 115, 115, 115),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'NETWORK_ERROR'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 115, 115, 115),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  RecipeController.r.refreshRecipes();
                                },
                                child: Text('RETRY'.tr),
                              ),
                            ],
                          );
                        }

                        // 显示空数据状态
                        if (RecipeController.r.recipeSets.isEmpty) {
                          return Column(
                            children: [
                              const SizedBox(height: 100),
                              Image.asset('assets/image/rice.png', height: 100),
                              const SizedBox(height: 20),
                              Text(
                                'NO_RECIPES'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 115, 115, 115),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  RecipeController.r.refreshRecipes();
                                },
                                child: Text('REFRESH'.tr),
                              ),
                            ],
                          );
                        }

                        // 显示食谱列表
                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 60),
                          itemCount: RecipeController.r.recipeSets.length,
                          itemBuilder: (context, index) {
                            final item = RecipeController.r.recipeSets[index];
                            return buildCard(
                              context: context,
                              imageUrl: item['previewPhoto'],
                              id: item['id'],
                              name: item['name'],
                              nameEn: item['nameEn'],
                              labelList:
                                  (item['label'] as List?)?.cast<dynamic>() ?? const [],
                              labelEnList:
                                  (item['labelEn'] as List?)?.cast<dynamic>() ?? const [],
                              type: item['type'],
                              day: item['day'],
                              weight: item['weight'],
                              hot: item['hot'],
                              overlayColor: int.parse(item['color']),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            // 顶部安全区域的内容延伸
            Container(
              height: MediaQuery.of(context).padding.bottom,
              color: Colors.transparent,
            ),
          ],
        ),
        // 底部安全区域渐变遮罩
        if (MediaQuery.of(context).padding.bottom > 0)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).padding.bottom,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color.fromARGB(255, 255, 225, 225).withOpacity(1),
                    const Color.fromARGB(255, 255, 225, 225).withOpacity(0.8),
                    const Color.fromARGB(255, 255, 225, 225).withOpacity(0.6),
                    const Color.fromARGB(255, 255, 225, 225).withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.25, 0.5, 1.0],
                ),
              ),
            ),
          ),
      ],
    ));
  }
}

Widget buildCard({
  required BuildContext context,
  required int id,
  required String imageUrl,
  required String name,
  required String nameEn,
  required int type,
  required int weight,
  required double hot,
  required int day,
  required List<dynamic> labelList,
  required List<dynamic> labelEnList,
  int overlayColor = 0xB52FA933,
}) {
  List weightType = [
    '',
    'LOSS'.tr,
    'GAIN'.tr,
  ];
  List displayLabel =
      Controller.c.lang.value == 'zh_CN' ? labelList : labelEnList;
  String displayName = Controller.c.lang.value == 'zh_CN' ? name : nameEn;
  String displayType = '${weightType[type]} ${weightList[weight]} ${'KG'.tr}';
  String displayDay = '$day ${'DAY'.tr}';
  String displayHot = '$hot ${'HOT_UNIT'.tr}';
  return GestureDetector(
    onTap: () => Get.to(() => const RecipeDetail(), arguments: {
      'id': id,
      'name': displayName,
      'imageUrl': imageUrl,
      'label': displayLabel,
      'weight': weightList[weight],
      'type': weightType[type],
      'day': day,
      'hot': hot
    }),
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // image: DecorationImage(
        //   image: NetworkImage(imageUrl),
        //   fit: BoxFit.cover,
        // ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: const Color.fromARGB(255, 255, 220, 204), // 蓝色背景
                highlightColor: Colors.white, // 扫光白色
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: const Color.fromARGB(255, 255, 204, 232), // 固定蓝白背景
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromARGB(0, 0, 0, 0),
                    Color(overlayColor),
                    Color(overlayColor),
                    Color(overlayColor),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Obx(() => (Controller.c.user['recipeSetIdList'] ?? []).contains(id)
              ? const Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(
                    AliIcon.collectFill,
                    color: Color.fromARGB(255, 255, 214, 7),
                  ))
              : const SizedBox.shrink()),
          Positioned(
            top: 10,
            left: 10,
            child: Wrap(
              spacing: 8,
              children: displayLabel
                  .map<Widget>((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(151, 0, 0, 0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$tag',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white)),
                      ))
                  .toList(),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 14),
                    const SizedBox(width: 2),
                    Text(displayDay,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(width: 15),
                    const Icon(Icons.local_fire_department,
                        color: Colors.white, size: 15),
                    const SizedBox(width: 2),
                    Text(displayType,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(width: 15),
                    const Icon(Icons.group, color: Colors.white, size: 15),
                    const SizedBox(width: 2),
                    Text(displayHot,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildAppBar(context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLAN'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
      Row(
        children: [
         
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/recipeCollect');
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                                      Color.fromARGB(255, 173, 255, 194),
                  Color.fromARGB(255, 120, 208, 125),
                  Color.fromARGB(255, 173, 255, 194),

                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 255, 201, 39)
                        .withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                AliIcon.collectFill,
                color: Colors.white,
                size: 20,
              ),
            ),
          )
        ],
      )
    ],
  );
}
