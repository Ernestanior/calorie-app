import 'package:calorie/common/icon/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';

class StarRatingDialog extends StatefulWidget {
  const StarRatingDialog({super.key});

  @override
  State<StarRatingDialog> createState() => _StarRatingDialogState();
}

class _StarRatingDialogState extends State<StarRatingDialog>
    with TickerProviderStateMixin {
  int _selectedStars = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openAppStore() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;

      // 使用原生评分弹窗（推荐）或跳转到 App Store
      if (await inAppReview.isAvailable()) {
        // 优先尝试使用原生评分弹窗
        await inAppReview.requestReview();
      } else {
        // 如果原生评分不可用，则跳转到 App Store
        if (await inAppReview.isAvailable()) {
          await inAppReview.openStoreListing();
        }
      }
    } catch (e) {
      print('Error opening review: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 成功打卡图标
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 255, 187, 69),
                          Color.fromARGB(255, 251, 130, 50)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 255, 178, 55)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      AliIcon.check2,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 星级评分
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStars = index + 1;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: _selectedStars > index
                                ? (Matrix4.identity()..scale(1.2))
                                : Matrix4.identity(),
                            child: Icon(
                                _selectedStars > index
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 36,
                                color: const Color(0xFFFFB800)),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // 按钮组
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE9ECEF)),
                          ),
                          child: TextButton(
                            onPressed: () => Get.back(),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'MAYBE_LATER'.tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C757D),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 255, 158, 48),
                                  Color.fromARGB(255, 243, 77, 0)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF667EEA).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ]),
                          child: TextButton(
                            onPressed:
                                _selectedStars > 0 ? _openAppStore : null,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'RATE_NOW'.tr,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
