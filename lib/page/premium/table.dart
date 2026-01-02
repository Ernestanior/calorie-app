import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VipFeatures extends StatelessWidget {
  const VipFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionTitle('Features'),
          const SizedBox(height: 15),
          _buildComparisonCard([
            ['AI Calorie Tracker', '✔', '-'],
            ['AI Food Scaner', '✔', '-'],
            ['AI Nutrition Coach', '✔', '-'],
            ['AI Expert Insights', '✔', '-'],
            ['Nutrition Analysis', '✔', '-'],
            ['Daily Food Logging', '✔', '-'],
            ['Recipe Plans', '✔', '-'],
            ['My Favorites', '✔', '-'],
            ['Weight Log', '✔', '✔'],
            ['Walking steps', '✔', '✔'],
            // ['Workout Plans', '✔', '10 time/day'],
            ['Fitness Goals', '✔', '✔'],
          ]),
        ],
      ),
    );
  }

  // ——— 分区标题 ———
  Widget _buildSectionTitle(String title) {
    return Text(
      '—  $title  —',
      style: GoogleFonts.ubuntu(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF444444),
      ),
    );
  }

  // ——— 对比表卡片 ———
  Widget _buildComparisonCard(List<List<String>> rows) {
    // const headerColor = Color(0xFFFFD76A);
    const bgColor = Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 表头行
          Container(
            decoration: const BoxDecoration(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(10)),
              color: Color.fromARGB(255, 255, 248, 245),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text('Premium',
                        style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text('Pro',
                        style: GoogleFonts.ubuntu(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEEB100))),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text('Free',
                        style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // 数据行
          for (int i = 0; i < rows.length; i++)
            _buildRow(
              index: i,
              title: rows[i][0],
              vip: rows[i][1],
              free: rows[i][2],
            ),
        ],
      ),
    );
  }

  // ——— 单行内容 ———
  Widget _buildRow({
    required int index,
    required String title,
    required String vip,
    required String free,
  }) {
    final bool isEven = index % 2 == 0;
    final Color rowColor = isEven
        ? Colors.white
        : const Color.fromARGB(255, 255, 249, 246); // 💜 淡紫色背景

    return Column(
      children: [
        Container(
          color: rowColor,
          height: 52,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Text(title,
                        style:
                            GoogleFonts.ubuntu(color: const Color(0xFF444444))),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(255, 250, 231, 188),
                        Color(0xFFFEF7E3),
                        Color.fromARGB(255, 254, 233, 188),
                      ],
                    ),
                  ),
                  child: Center(child: _buildCell(vip, isVip: true)),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(child: _buildCell(free)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ——— 单元格内容渲染 ———
  Widget _buildCell(String content, {bool isVip = false}) {
    if (content == '✔') {
      return Icon(Icons.check_rounded,
          color: isVip ? const Color.fromARGB(255, 225, 135, 0) : Colors.grey,
          size: 20);
    } else if (content == '-' || content.isEmpty) {
      return Text('-', style: GoogleFonts.ubuntu(color: Colors.grey));
    } else {
      return Text(
        content,
        style: GoogleFonts.ubuntu(
          color: isVip ? const Color(0xFFEEB100) : Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      );
    }
  }
}
