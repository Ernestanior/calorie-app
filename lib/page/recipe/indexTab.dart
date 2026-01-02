import 'package:flutter/material.dart';

class RecipeTabList extends StatefulWidget {
  const RecipeTabList({super.key});

  @override
  State<RecipeTabList> createState() => _RecipeTabListState();
}

class _RecipeTabListState extends State<RecipeTabList> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> tabs = ['流行', '热门', '减脂增肌'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildCard({
    required String imageUrl,
    required String title,
    required List<String> subtitle,
    required String duration,
    required String weightLoss,
    required String usedCount,
    int overlayColor = 0xB52FA933,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/recipeDetail'),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
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
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
                    top: 10,
                    left: 10,
                    child: Wrap(
                      spacing: 8,
                      children: subtitle.map<Widget>((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(111, 0, 0, 0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(tag, style: const TextStyle(fontSize: 12,color: Colors.white)),
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
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 14),
                    const SizedBox(width: 2),
                    Text(duration, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(width: 15),
                    const Icon(Icons.local_fire_department, color: Colors.white, size: 14),
                    const SizedBox(width: 2),
                    Text(weightLoss, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(width: 15),
                    const Icon(Icons.group, color: Colors.white, size: 14),
                    const SizedBox(width: 2),
                    Text(usedCount, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    ) ;
    }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('饮食计划'),
          automaticallyImplyLeading:false,
          bottom: TabBar(
            controller: _tabController,
            tabs: tabs.map((t) => Tab(text: t)).toList(),
            indicatorColor: Colors.pinkAccent,
            labelColor: Colors.pinkAccent,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: 
        // Stack(
        //   children: [
TabBarView(
          controller: _tabController,
          children: tabs.map((tab) {
            return ListView(
              children: [
                buildCard(
                  imageUrl: 'https://i.postimg.cc/ZntHyhVK/food.jpg',
                  title: '中伏 · 10天加速燃脂食谱',
                  subtitle: ['智能定制', '中伏', '清肠润燥'],
                  duration: '10天',
                  weightLoss: '减重3-5斤',
                  usedCount: '9.9万人使用过',
                  overlayColor: 0xB52FA933,
                ),
                buildCard(
                  imageUrl: 'https://i.postimg.cc/ZntHyhVK/food.jpg',
                  title: '夏断食 · 7天减肥食谱',
                  subtitle:['智能定制', '夏季', '轻断食'],
                  duration: '7天',
                  weightLoss: '减重2-4斤',
                  usedCount: '54.2万人使用过',
                  overlayColor: 0xB69B27B0
                ),
                buildCard(
                  imageUrl: 'https://i.postimg.cc/ZntHyhVK/food.jpg',
                  title: '放纵餐后3天急救',
                  subtitle: ['智能定制', '急救', '短期'],
                  duration: '3天',
                  weightLoss: '减重2-4斤',
                  usedCount: '178万人使用过',
                  overlayColor: 0xB5FF8400
                ),
                buildCard(
                  imageUrl: 'https://i.postimg.cc/ZntHyhVK/food.jpg',
                  title: '放纵餐后3天急救',
                  subtitle: ['智能定制', '急救', '短期'],
                  duration: '3天',
                  weightLoss: '减重2-4斤',
                  usedCount: '178万人使用过',
                  overlayColor: 0xB5FF8400
                ),
                buildCard(
                  imageUrl: 'https://i.postimg.cc/ZntHyhVK/food.jpg',
                  title: '放纵餐后3天急救',
                  subtitle: ['智能定制', '急救', '短期'],
                  duration: '3天',
                  weightLoss: '减重2-4斤',
                  usedCount: '178万人使用过',
                  overlayColor: 0xB5FF8400
                ),
                const SizedBox(height: 70,)
              ],
            );
          }).toList(),
        ),
      // CustomTabBar(),
      //     ],
      //   )
         ),
    );
  }
}
