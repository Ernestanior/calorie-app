import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:calorie/common/util/constants.dart';
import 'package:calorie/main.dart';
import 'package:calorie/network/api.dart';
import 'package:calorie/store/store.dart';
import 'package:calorie/components/lottieFood/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import 'detail/index.dart';

class RecipeCollect extends StatefulWidget {
  const RecipeCollect({super.key});

  @override
  State<RecipeCollect> createState() => _RecipeCollectState();
}

class _RecipeCollectState extends State<RecipeCollect>
    with SingleTickerProviderStateMixin, RouteAware {
  List recipeSets = [];
   bool _isLoading = true; 
  @override
  void initState() {
    fetchRecipes();
    super.initState();
  }

  @override
  void didPopNext() {
    // 从页面B返回后触发
    fetchRecipes(); // 重新拉取数据
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 注册路由观察者
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

    @override
  void dispose() {
    // 移除观察者
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void fetchRecipes() async {
        setState(() {
      _isLoading = true; // 请求开始前置为 true
    });
    try {
      final res = await recipeSetCollects();
      setState(() {
        recipeSets = res['content'];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
              setState(() {
        _isLoading = false;
      });
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'MY_PLAN'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: Container(
            decoration:
                const BoxDecoration(color: Color.fromARGB(255, 249, 248, 255)),
            child: _isLoading
            ? const Center(
                child: LottieFood(
                  size: 60,
                  spacing: 15,
                ),
              )
            :recipeSets.isEmpty
                ? buildEmptyState(context)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ...recipeSets.map(
                        (item) => buildCard(
                            context: context,
                            imageUrl: item['previewPhoto'],
                            id: item['id'],
                            name: item['name'],
                            nameEn: item['nameEn'],
                            // 适配新后端：label / labelEn 为 JSON 字符串，这里统一解析为 List
                            labelList: parseLabel(item['label']),
                            labelEnList: parseLabel(item['labelEn']),
                            type: item['type'],
                            day: item['day'],
                            weight: item['weight'],
                            hot: item['hot'],
                            overlayColor: int.parse(item['color'])),
                      ),
                      Container(
                        height: 50,
                      )
                    ],
                  )));
  }
}

/// 将后端返回的 label / labelEn 字段安全转换为 List
/// 支持三种情况：
/// - null => []
/// - 已经是 List => 原样返回
/// - String（JSON 数组）=> 尝试 jsonDecode 成 List
List<dynamic> parseLabel(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) return raw;
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    } catch (_) {
      // ignore parse error, fallback to empty list
    }
  }
  return [];
}

  Widget buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 150),
          Image.asset('assets/image/rice.png',height: 100,),

          const SizedBox(height: 20),
          Text(
            'NO_FAVORITE_PLAN'.tr,
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 154, 148, 141),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: (){
              Controller.c.tabIndex(1);
              Navigator.pop(context);},
            child: Container(
              width: 150,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 34, 32, 30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'EXPLORE_RECIPES'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
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
            borderRadius: const BorderRadius.all(Radius.circular(14)),
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
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
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
