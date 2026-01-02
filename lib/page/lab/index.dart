import 'package:calorie/common/icon/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:calorie/page/lab/aiCooking/index.dart';
import 'package:calorie/page/lab/mysteryBox/index.dart';
import 'dart:math' as math;

class LabPage extends StatefulWidget {
  const LabPage({super.key});

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    // 淡入动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 背景动画控制器（用于数据流效果）
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF7F7FA),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 背景装饰层 - 数据流和光点
            _buildBackgroundDecorations(),

            // 主内容
            FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: MediaQuery.of(context).padding.top + 30,
                        color: Colors.transparent,
                      ),

                      // 标题区域
                      _buildHeader(),
                      const SizedBox(height: 30),
                      // 功能卡片区域
                      _buildFeatureCards(),
                      Container(
                        height: MediaQuery.of(context).padding.bottom + 70,
                        color: Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundPainter(_backgroundAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主标题
        Text(
          'AI_CHEF'.tr,
          style: GoogleFonts.inter(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        // 副标题
        Text(
          'AI_CHEF_DESC'.tr,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        // 装饰性插画元素（用简单的图形代表）
        _buildIllustrationElements(),
      ],
    );
  }

  Widget _buildIllustrationElements() {
    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          // 漂浮的食材图标 - 每个都有不同的浮动速度和缩放频率
          Positioned(
            left: 0,
            top: 20,
            child: _buildFloatingIcon(
              'assets/food/set/5.png',
              40,
              floatSpeed: 1.2,
              floatAmplitude: 1.0,
              scaleSpeed: 1.5,
              initialDelay: 0.0,
            ),
          ),
          Positioned(
            right: 40,
            top: 0,
            child: _buildFloatingIcon(
              'assets/food/set/2.png',
              35,
              floatSpeed: 0.8,
              floatAmplitude: 1.3,
              scaleSpeed: 1.2,
              initialDelay: 0.3,
            ),
          ),
          Positioned(
            left: 150,
            bottom: 50,
            child: _buildFloatingIcon(
              'assets/food/set/3.png',
              30,
              floatSpeed: 1.5,
              floatAmplitude: 0.8,
              scaleSpeed: 0.9,
              initialDelay: 0.6,
            ),
          ),
          Positioned(
            left: 80,
            bottom: 0,
            child: _buildFloatingIcon(
              'assets/food/set/1.png',
              35,
              floatSpeed: 0.9,
              floatAmplitude: 1.1,
              scaleSpeed: 1.3,
              initialDelay: 0.2,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 25,
            child: _buildFloatingIcon(
              'assets/food/set/6.png',
              45,
              floatSpeed: 1.1,
              floatAmplitude: 1.2,
              scaleSpeed: 1.0,
              initialDelay: 0.4,
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildFloatingIcon(
    String icon,
    double size, {
    double floatSpeed = 1.0,
    double floatAmplitude = 1.0,
    double scaleSpeed = 1.0,
    double initialDelay = 0.0,
  }) {
    return _FloatingIcon(
      icon: icon,
      size: size,
      floatSpeed: floatSpeed,
      floatAmplitude: floatAmplitude,
      scaleSpeed: scaleSpeed,
      initialDelay: initialDelay,
    );
  }

  Widget _buildFeatureCards() {
    return Column(
      children: [
        // 功能1: AI智能烹饪
        _buildFeatureCard(
          title: 'SMART_COOKING'.tr,
          description: 'SMART_RECIPE_1'.tr,
          icon: const Icon(
            AliIcon.food1,
            color: Color.fromARGB(255, 207, 88, 3),
            size: 40,
          ),
          gradientColors: [
            const Color(0xFFFF6B35), // 暖橙
            const Color(0xFFFF8E53), // 浅橙
          ],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AiCookingPage()),
            );
          },
        ),
        const SizedBox(height: 20),

        // 功能2: 美食盲盒
        _buildFeatureCard(
          title: 'MYSTERY_BOX_TITLE'.tr,
          description: 'MYSTERY_MEAL_1'.tr,
          icon:  const Icon(
            AliIcon.food2,
            color: Color.fromARGB(255, 27, 164, 0),
            size: 40,
          ),
          gradientColors: [
            const Color.fromARGB(255, 34, 205, 0), // 金色
            const Color.fromARGB(255, 113, 254, 57), // 浅金色
          ],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RandomEatPage()),
            );
          },
        ),
        const SizedBox(height: 20),

        // 功能3: 每周AI健康报告
        // _buildFeatureCard(
        //   title: 'WEEKLY_INSIGHTS'.tr,
        //   description: 'WEEKLY_INSIGHTS_DESC'.tr,
        //   icon:  Icon(
        //     AliIcon.analyse1,
        //     color: const Color.fromARGB(255, 0, 135, 153),
        //     size: 34,
        //   ), 
        //   gradientColors: [
        //     const Color(0xFF00BCD4), // 青绿
        //     const Color(0xFF4DD0E1), // 浅青绿
        //   ],
        //   onTap: () {
        //     // 第三个功能待实现
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       SnackBar(
        //         content: Text('FEATURE_COMING_SOON'.tr),
        //         backgroundColor: Colors.black87,
        //       ),
        //     );
        //   },
        // ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required Icon icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: _FeatureCard(
        title: title,
        description: description,
        icon: icon,
        gradientColors: gradientColors,
        onTap: onTap,
        isComingSoon: isComingSoon,
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String title;
  final String description;
  final Icon icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool isComingSoon;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    this.isComingSoon = false,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _hoverController.reverse();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Future.delayed(const Duration(milliseconds: 100), widget.onTap);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _hoverController.reverse();
      },
      child: MouseRegion(
        onEnter: (_) => _hoverController.forward(),
        onExit: (_) {
          _hoverController.reverse();
          setState(() => _isPressed = false);
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? 0.98 : _scaleAnimation.value,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.gradientColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradientColors[0].withOpacity(0.4),
                      blurRadius: _isPressed ? 15 : 25,
                      offset: Offset(0, _isPressed ? 5 : 10),
                      spreadRadius: _isPressed ? 0 : 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFEAEAF0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 图标区域
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEAEAF0),
                                width: 2,
                              ),
                            ),
                            child: widget.icon,
                          ),
                          const SizedBox(width: 20),
                          // 文字区域
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    if (widget.isComingSoon)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.85),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'COMING_SOON'.tr,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.description,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// 背景装饰画布 - 数据流和光点
class BackgroundPainter extends CustomPainter {
  final double animationValue;

  BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 绘制网格线
    paint.color = const Color(0xFF00BCD4).withOpacity(0.06);
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // 绘制数据流线条
    paint.color = const Color(0xFF00BCD4).withOpacity(0.12);
    paint.strokeWidth = 2;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final y = (size.height / 5) * i + (animationValue * 100) % 100;
      path.reset();
      path.moveTo(0, y);
      path.quadraticBezierTo(
        size.width / 2,
        y + 50,
        size.width,
        y - 50,
      );
      canvas.drawPath(path, paint);
    }

    // 绘制光点
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFFFA726).withOpacity(0.15);
    for (int i = 0; i < 15; i++) {
      final x = (size.width / 15) * i +
          (animationValue * 50 * (i % 3 == 0 ? 1 : -1)) % 50;
      final y = (size.height / 3) * (i % 3) +
          (animationValue * 30 * (i % 2 == 0 ? 1 : -1)) % 30;
      canvas.drawCircle(
        Offset(x, y),
        3 + (animationValue * 2) % 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 数据流画布
class DataFlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF00BCD4).withOpacity(0.15);

    // 绘制装饰性的数据流曲线
    final path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(
      size.width / 2,
      size.height / 4,
      size.width,
      size.height / 2,
    );
    canvas.drawPath(path, paint);

    path.reset();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 0.9,
      size.width,
      size.height * 0.7,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 浮动图标组件 - 带有循环上下浮动和缩放动画
class _FloatingIcon extends StatefulWidget {
  final String icon;
  final double size;
  final double floatSpeed; // 浮动速度倍数
  final double floatAmplitude; // 浮动幅度倍数
  final double scaleSpeed; // 缩放速度倍数
  final double initialDelay; // 初始延迟（秒）

  const _FloatingIcon({
    required this.icon,
    required this.size,
    this.floatSpeed = 1.0,
    this.floatAmplitude = 1.0,
    this.scaleSpeed = 1.0,
    this.initialDelay = 0.0,
  });

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _scaleController;
  late Animation<double> _floatAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // 浮动动画控制器 - 循环动画，速度由 floatSpeed 控制
    final baseFloatDuration = 5000 + (widget.size * 100).toInt();
    final floatDuration = Duration(
      milliseconds: (baseFloatDuration / widget.floatSpeed).round(),
    );
    _floatController = AnimationController(
      duration: floatDuration,
      vsync: this,
    );

    // 缩放动画控制器 - 循环动画，速度由 scaleSpeed 控制
    final baseScaleDuration = 1500 + (widget.size * 15).toInt();
    final scaleDuration = Duration(
      milliseconds: (baseScaleDuration / widget.scaleSpeed).round(),
    );
    _scaleController = AnimationController(
      duration: scaleDuration,
      vsync: this,
    );

    // 上下浮动动画 - 使用正弦波实现平滑循环
    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    // 缩放动画 - 在 0.9 到 1.1 之间循环
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );

    // 延迟后开始动画
    if (widget.initialDelay > 0) {
      Future.delayed(Duration(milliseconds: (widget.initialDelay * 1000).round()), () {
        if (mounted) {
          _floatController.repeat(reverse: true);
          _scaleController.repeat(reverse: true);
        }
      });
    } else {
      _floatController.repeat(reverse: true);
      _scaleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _scaleController]),
      builder: (context, child) {
        // 使用正弦波实现平滑的上下浮动
        // _floatAnimation.value 从 0 到 1，通过 sin 转换为 -1 到 1 的循环
        final floatValue = (_floatAnimation.value * 2 - 1) * math.pi;
        const baseFloatOffset = 12.0; // 基础浮动范围 ±12 像素
        final floatOffset = math.sin(floatValue) * baseFloatOffset * widget.floatAmplitude;
        
        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA726).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                widget.icon,
                width: widget.size,
                height: widget.size,
              ),
            ),
          ),
        );
      },
    );
  }
}
