import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

class NutritionPieChart extends StatelessWidget {
  final int calories;
  final int carb;    // 克
  final int protein; // 克
  final int fat;     // 克

  const NutritionPieChart({
    super.key,
    required this.calories,
    required this.carb,
    required this.protein,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    int total = carb + protein + fat;
    double carbPercent = total == 0 ? 0 : (carb / total * 100);
    double proteinPercent = total == 0 ? 0 : (protein / total * 100);
    double fatPercent = total == 0 ? 0 : (fat / total * 100);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding:const EdgeInsets.symmetric(vertical: 30,horizontal: 15),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Color.fromARGB(31, 147, 147, 147), blurRadius: 10)],
      ),
      child:Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 饼图
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _buildSections(carbPercent, proteinPercent, fatPercent),
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  'CALORIC_INTAKE'.tr,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${calories.toInt()}',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'KCAL'.tr,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            )
          ],
        ),
        const SizedBox(width: 40),
        // 右侧文字
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NUTRIENT_RATIO'.tr,style:const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildNutrientRow('CARBS'.tr, carbPercent, carb, const Color.fromARGB(255, 255, 216, 100)),
            const SizedBox(height: 12),
            _buildNutrientRow('PROTEIN'.tr, proteinPercent, protein, Colors.pinkAccent),
            const SizedBox(height: 12),
            _buildNutrientRow('FATS'.tr, fatPercent, fat, Colors.lightBlueAccent),
          ],
        )
      ],
    ));
  }

  List<PieChartSectionData> _buildSections(double carbPercent, double proteinPercent, double fatPercent) {
    return [
      PieChartSectionData(
        color: const Color.fromARGB(167, 255, 100, 131),
        value: carbPercent,
        radius: 18,
        title: '',
      ),
      PieChartSectionData(
        color: const Color.fromARGB(121, 255, 204, 0),
        value: proteinPercent,
        radius: 18,
        title: '',
      ),
      PieChartSectionData(
        color: const Color.fromARGB(133, 64, 195, 255),
        value: fatPercent,
        radius: 18,
        title: '',
      ),
    ];
  }

  Widget _buildNutrientRow(String name, double percent, int gram, Color color) {
    return  Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$name ${percent.toStringAsFixed(1)}%',
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
                const SizedBox(width: 16),

        Text(
          '${gram}g',
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
   }
}
