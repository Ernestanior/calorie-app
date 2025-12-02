import 'package:calorie/common/icon/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:calorie/page/lab/aiCooking/index.dart';
import 'package:calorie/page/lab/mysteryBox/index.dart';

class ChefPage extends StatefulWidget {
  const ChefPage({super.key});

  @override
  _ChefPageState createState() => _ChefPageState();
}

class _ChefPageState extends State<ChefPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAED),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题区域
                _buildHeader(),
                const SizedBox(height: 40),
                // 卡片区域
                _buildCardGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI_CHEF'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 125, 52, 16),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCardGrid() {
    return Column(
      children: [
        // 第一张卡片 - AI智能烹饪
        _buildImageCard(
          imagePath: 'assets/cards/card2.jpeg',
          titleKey: 'SMART_COOKING',
          featureKeys: [
            'SMART_RECIPE_1',
            'SMART_RECIPE_2',
            'SMART_RECIPE_3',
          ],
          imageOnLeft: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AiCookingPage()),
            );
          },
        ),
        const SizedBox(height: 20),
        // 第二张卡片 - 美食盲盒
        _buildImageCard(
          imagePath: 'assets/cards/card1.jpeg',
          titleKey: 'MYSTERY_BOX_TITLE',
          featureKeys: [
            'MYSTERY_MEAL_1',
            'MYSTERY_MEAL_2',
            'MYSTERY_MEAL_3',
          ],
          imageOnLeft: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RandomEatPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImageCard({
    required String imagePath,
    required String titleKey,
    required List<String> featureKeys,
    required bool imageOnLeft,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Row(
            children: imageOnLeft
                ? [
                    // 图片在左边
                    _buildImageSection(imagePath),
                    _buildTextSection(titleKey, featureKeys, imageOnLeft),
                  ]
                : [
                    // 图片在右边
                    _buildTextSection(titleKey, featureKeys, imageOnLeft),
                    _buildImageSection(imagePath),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(String imagePath) {
    return Expanded(
      flex: 3,
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        height: 210,
      ),
    );
  }

  Widget _buildTextSection(
      String titleKey, List<String> featureKeys, bool imageOnLeft) {
    return Expanded(
      flex: 4,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: imageOnLeft ? Alignment.topRight : Alignment.topLeft,
            end: imageOnLeft ? Alignment.bottomLeft : Alignment.bottomRight,
            colors: [
              const Color(0xFFFFF9E8),
              const Color(0xFFFFF4D4),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 标题区域
            Text(
              titleKey.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF8B4513),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            // 功能列表
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: featureKeys.asMap().entries.map((entry) {
                  int index = entry.key;
                  String key = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '· ',
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            color: const Color.fromARGB(255, 54, 116, 0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            key.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              color: const Color.fromARGB(255, 54, 116, 0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            // 底部箭头靠右
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 255, 165, 38),
                      Color.fromARGB(255, 255, 125, 44),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C42).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
