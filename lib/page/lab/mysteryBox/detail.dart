import 'dart:math' as math;

import 'package:calorie/page/lab/aiCooking/result.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../components/lottieFood/index.dart';
import '../../../network/api.dart';

class MysteryMealDetailPage extends StatefulWidget {
  final String imageUrl;
  final List<String> dishes;
  final String mealType;
  final String? prompt;
  final String mealName;
  final Map<String, dynamic>? initialNutrition; // 可选的初始营养数据（从历史记录传入）

  const MysteryMealDetailPage({
    super.key,
    required this.imageUrl,
    required this.dishes,
    required this.mealType,
    required this.mealName,
    this.prompt,
    this.initialNutrition,
  });

  @override
  State<MysteryMealDetailPage> createState() => _MysteryMealDetailPageState();
}

class _MysteryMealDetailPageState extends State<MysteryMealDetailPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _nutrition;

  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // 如果提供了初始营养数据，直接使用；否则调用 API
    if (widget.initialNutrition != null) {
      setState(() {
        _nutrition = widget.initialNutrition;
        _isLoading = false;
      });
    } else {
      _fetchNutrition();
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _fetchNutrition() async {
    if (widget.dishes.isEmpty) {
      setState(() {
        _error = 'MYSTERY_BOX_DETAIL_NO_DISH'.tr;
        _isLoading = false;
      });
      return;
    }
    try {
      final resp = await yifanRandomMealNutrition(widget.dishes);
      if (!mounted) return;
      if (resp == "-1" || resp == null) {
        throw Exception('Fetch nutrition failed');
      }

      try {
        await yifanRandomMealSave(
          widget.mealName,
          widget.imageUrl,
          widget.prompt ?? '',
          widget.dishes,
          resp,
        );
      } catch (e) {
        debugPrint('Failed to save random meal: $e');
      }

      setState(() {
        _nutrition = resp as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'MYSTERY_BOX_DETAIL_ERROR'.tr;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 255, 251),
      appBar: AppBar(
        title: widget.mealName.isNotEmpty
            ? Text(
                widget.mealName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              )
            : Text(
                'MYSTERY_BOX_DETAIL_TITLE'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
        backgroundColor: const Color.fromARGB(255, 247, 255, 246),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 200,
                child: const LottieFood(size: 56, spacing: 16),
              ),
              const SizedBox(height: 20),
              Text(
                'MYSTERY_BOX_DETAIL_LOADING'.tr,
                style: GoogleFonts.notoSansSc(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: GoogleFonts.notoSansSc(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _fetchNutrition,
              child: Text('MYSTERY_BOX_DETAIL_REFRESH'.tr),
            ),
          ],
        ),
      );
    }

    final nutrition = _nutrition ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          const SizedBox(height: 20),
          _buildDishList(),
          const SizedBox(height: 20),
          _buildNutritionSummary(nutrition),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final resolved = _resolveImageUrl(widget.imageUrl);
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (_, child) {
        final offset = math.sin(_floatingController.value * math.pi) * 8;
        return Transform.translate(
          offset: Offset(0, -offset),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: resolved.isNotEmpty
            ? Image.network(
                resolved,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image_outlined,
                      size: 40, color: Colors.black38),
                ),
              )
            : Container(
                height: 220,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported_rounded,
                    size: 40, color: Colors.black38),
              ),
      ),
    );
  }

  Widget _buildDishList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/icons/hotpot.png',
              width: 20,
              height: 20,
            ),
            SizedBox(
              width: 6,
            ),
            Text(
              'MYSTERY_BOX_DETAIL_DISHES'.tr,
              style: GoogleFonts.notoSansSc(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.dishes
              .map((dish) => Chip(
                    side: BorderSide(
                        color: const Color.fromARGB(255, 210, 235, 206)),
                    label: Text(dish),
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPrompt() {
    if ((widget.prompt ?? '').isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.short_text_rounded, color: Color(0xFFEE8C3D)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MYSTERY_BOX_YOUR_PROMPT'.tr,
                  style: GoogleFonts.notoSansSc(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.prompt!,
                  style: GoogleFonts.notoSansSc(color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary(Map<String, dynamic> data) {
    final Map<String, dynamic>? nutritionAnalysis =
        data['nutritionAnalysis'] as Map<String, dynamic>?;
    if (nutritionAnalysis == null) {
      return const SizedBox.shrink();
    }

    final Map<String, dynamic>? nutrition =
        nutritionAnalysis['nutrition'] as Map<String, dynamic>?;
    final double? healthScore = _asDouble(nutritionAnalysis['healthScore']);
    final String? servingSize =
        (nutritionAnalysis['servingSize'] as String?)?.trim();
    final List<String> dietaryTags = (nutritionAnalysis['dietaryTags'] as List?)
            ?.map((e) => e.toString())
            .where((text) => text.trim().isNotEmpty)
            .toList() ??
        const [];
    final List<String> balanceAdvice =
        (nutritionAnalysis['balanceAdvice'] as List?)
                ?.map((e) => e.toString())
                .where((text) => text.trim().isNotEmpty)
                .toList() ??
            const [];

    final bool hasGridContent =
        (nutrition != null && nutrition.isNotEmpty) || healthScore != null;
    final bool hasContent = hasGridContent ||
        dietaryTags.isNotEmpty ||
        balanceAdvice.isNotEmpty ||
        (servingSize != null && servingSize.isNotEmpty);

    if (!hasContent) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/icons/record2.png',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'MYSTERY_BOX_DETAIL_NUTRITION'.tr,
              style: GoogleFonts.notoSansSc(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7EAF4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasGridContent) ...[
                _buildNutritionGrid(nutrition, healthScore),
                const SizedBox(height: 16),
              ],
              if (dietaryTags.isNotEmpty) ...[
                Text(
                  'DIETARY_TAGS'.tr,
                  style: GoogleFonts.notoSansSc(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      dietaryTags.map((tag) => _buildTagChip(tag)).toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (balanceAdvice.isNotEmpty) ...[
                Text(
                  'BALANCE_ADVICE'.tr,
                  style: GoogleFonts.notoSansSc(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...balanceAdvice.map(_buildAdviceTile),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionGrid(
      Map<String, dynamic>? nutrition, double? healthScore) {
    final metrics = [
      _NutritionMetric('CALORIE'.tr, _asDouble(nutrition?['calories']), 'kcal'),
      _NutritionMetric('PROTEIN'.tr, _asDouble(nutrition?['protein']), 'g'),
      _NutritionMetric('CARBS'.tr, _asDouble(nutrition?['carbs']), 'g'),
      _NutritionMetric('FAT'.tr, _asDouble(nutrition?['fat']), 'g'),
      _NutritionMetric('DIETARY_FIBER'.tr, _asDouble(nutrition?['fiber']), 'g'),
      _NutritionMetric('SODIUM'.tr, _asDouble(nutrition?['sodium']), 'mg'),
      _NutritionMetric('SUGAR'.tr, _asDouble(nutrition?['sugar']), 'g'),
    ].where((metric) => metric.value != null).toList();

    if (healthScore != null) {
      metrics.add(
        _NutritionMetric(
          'HEALTH_SCORE'.tr,
          healthScore,
          '/10',
        ),
      );
    }

    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Widget> rows = [];
    for (int i = 0; i < metrics.length; i += 2) {
      final left = metrics[i];
      final right = i + 1 < metrics.length ? metrics[i + 1] : null;
      rows.add(Row(
        children: [
          Expanded(child: _buildNutritionMetricCard(left)),
          const SizedBox(width: 12),
          Expanded(
            child: right != null
                ? _buildNutritionMetricCard(right)
                : const SizedBox.shrink(),
          ),
        ],
      ));
      if (i + 2 < metrics.length) {
        rows.add(const SizedBox(height: 12));
      }
    }

    return Column(children: rows);
  }

  Widget _buildNutritionMetricCard(_NutritionMetric metric) {
    final Color accentColor = getNutritionIconColor(metric.label);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: GoogleFonts.notoSansSc(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMetricValue(metric.value!),
                style: GoogleFonts.notoSansSc(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  metric.unit,
                  style: GoogleFonts.notoSansSc(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                getNutritionIcon(metric.label),
                size: 20,
                color: accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 77, 255, 53).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 173, 235, 160).withOpacity(0.3),
        ),
      ),
      child: Text(
        tag,
        style: GoogleFonts.notoSansSc(
          fontSize: 12,
          color: const Color.fromARGB(255, 7, 46, 1),
        ),
      ),
    );
  }

  Widget _buildAdviceTile(String advice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(color: Colors.black54, fontSize: 13)),
          Expanded(
            child: Text(
              advice,
              style: GoogleFonts.notoSansSc(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _formatMetricValue(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  List<_KeyValue> _expandMap(Map<String, dynamic> source,
      [String prefix = '']) {
    final List<_KeyValue> result = [];
    source.forEach((key, value) {
      final displayKey = prefix.isEmpty ? key : '$prefix · $key';
      if (value is Map<String, dynamic>) {
        result.addAll(_expandMap(value, displayKey));
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          final item = value[i];
          if (item is Map<String, dynamic>) {
            result.addAll(_expandMap(item, '$displayKey [$i]'));
          } else {
            result.add(_KeyValue('$displayKey [$i]', item.toString()));
          }
        }
      } else if (value != null) {
        result.add(_KeyValue(displayKey, value.toString()));
      }
    });
    return result;
  }

  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '$imgUrl$url';
  }
}

class _NutritionMetric {
  final String label;
  final double? value;
  final String unit;
  _NutritionMetric(this.label, this.value, this.unit);
}

class _KeyValue {
  final String key;
  final String value;
  _KeyValue(this.key, this.value);
}
