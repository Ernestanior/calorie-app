import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/icon/index.dart';
import '../../../network/api.dart';
import 'detail.dart';
import 'history.dart';

class RandomEatPage extends StatefulWidget {
  const RandomEatPage({super.key});

  @override
  State<RandomEatPage> createState() => _RandomEatPageState();
}

class _RandomEatPageState extends State<RandomEatPage>
    with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();

  final List<Map<String, dynamic>> _mealTypes = [
    {
      'id': 'breakfast',
      'label': 'MYSTERY_BOX_MEAL_BREAKFAST',
      'color': const Color.fromARGB(255, 208, 255, 194),
    },
    {
      'id': 'lunch',
      'label': 'MYSTERY_BOX_MEAL_LUNCH',
      'color': const Color(0xFFFFF0C2),
    },
    {
      'id': 'dinner',
      'label': 'MYSTERY_BOX_MEAL_DINNER',
      'color': const Color(0xFFDDE8FF),
    },
  ];

  final List<String> _promptTags = [
    'MYSTERY_BOX_TAG_PLANT_BASED',
    'MYSTERY_BOX_TAG_LOW_FAT',
    'MYSTERY_BOX_TAG_HIGH_PROTEIN',
    'MYSTERY_BOX_TAG_LOW_CARB',
    'MYSTERY_BOX_TAG_MEDITERRANEAN',
    'MYSTERY_BOX_TAG_FASTING',
    'MYSTERY_BOX_TAG_MUSCLE_GAIN',
    'MYSTERY_BOX_TAG_DIABETES',
    'MYSTERY_BOX_TAG_DAIRY_FREE',
    'MYSTERY_BOX_TAG_HIGH_FIBER',
  ];

  final List<String> _carouselCards = [
    'assets/food/carousel/q1.jpg',
    'assets/food/carousel/q2.jpg',
    'assets/food/carousel/q3.jpg',
    'assets/food/carousel/q4.jpg',
    'assets/food/carousel/q5.jpg',
    'assets/food/carousel/q6.jpg',
    'assets/food/carousel/q7.jpg',
    'assets/food/carousel/q8.jpg',
    'assets/food/carousel/q9.jpg',
    'assets/food/carousel/q10.jpg',
    'assets/food/carousel/q11.jpg',
    'assets/food/carousel/q12.jpg',
    'assets/food/carousel/q13.jpg',
    'assets/food/carousel/q14.jpg',
    'assets/food/carousel/q15.jpg',
    'assets/food/carousel/q16.jpg',
    'assets/food/carousel/q17.jpg',
    'assets/food/carousel/q18.jpg',
    'assets/food/carousel/q19.jpg',
    'assets/food/carousel/q20.jpg',
    'assets/food/carousel/q21.jpg',
    'assets/food/carousel/q22.jpg',
    'assets/food/carousel/q23.jpg',
    'assets/food/carousel/q24.jpg',
    'assets/food/carousel/q25.jpg',
    'assets/food/carousel/q26.jpg',
    'assets/food/carousel/q27.jpg',
    'assets/food/carousel/q28.jpg',
    'assets/food/carousel/q29.jpg',
  ];

  late AnimationController _buttonPulseController;
  late Animation<double> _buttonPulseAnimation;
  late AnimationController _carouselController;
  late AnimationController _boxPulseController;
  late Animation<double> _boxPulseAnimation;
  late AnimationController _questionMarkController;
  late Animation<double> _questionMarkOpacity;
  DateTime? _carouselStartTime;

  String _selectedMeal = 'breakfast';
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedMeal;
  String? _errorMessage;
  bool _showRevealOverlay = false;

  @override
  void initState() {
    super.initState();
    _buttonPulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _buttonPulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _buttonPulseController,
        curve: Curves.easeInOut,
      ),
    );
    _carouselController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _boxPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _boxPulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _boxPulseController,
        curve: Curves.easeInOut,
      ),
    );
    _questionMarkController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _questionMarkOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _questionMarkController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _buttonPulseController.dispose();
    _carouselController.dispose();
    _boxPulseController.dispose();
    _questionMarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 255, 241),
      body: Container(
        decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              Color.fromARGB(255, 234, 255, 230),
              Color.fromARGB(255, 249, 255, 249),
              Color.fromARGB(255, 243, 255, 241),
                ],
              ),
            ),
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  _buildNavigationBar(theme),
                  const SizedBox(height: 14),
                  _buildMealSelector(),
                      const SizedBox(height: 20),
                  _buildPromptInput(),
                  const SizedBox(height: 20),
                  _buildGenerateButton(),
                  const SizedBox(height: 24),
                  _buildResultArea(),
                    ],
                  ),
                ),
                ),
            ),
      ),
    );
  }

  Widget _buildNavigationBar(ThemeData theme) {
    return Row(
      children: [
      IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 8),
        Text(
          'MYSTERY_BOX_TITLE'.tr,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MysteryBoxHistoryPage(),
              ),
            );
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
                  color: const Color.fromARGB(255, 120, 208, 125)
                      .withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              AliIcon.history,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildMealSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MYSTERY_BOX_MEAL_TYPE'.tr,
          style: GoogleFonts.notoSansSc(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          spacing: 15,
          children: _mealTypes.map((meal) {
            final bool isSelected = meal['id'] == _selectedMeal;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
                color: isSelected
                    ? Colors.black
                    : (meal['color'] as Color).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.transparent,
                  width: 1.5,
                ),
        boxShadow: [
          BoxShadow(
                    color: (meal['color'] as Color).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
          ),
        ],
      ),
              child: InkWell(
            onTap: () {
              setState(() {
                    _selectedMeal = meal['id'] as String;
              });
            },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (meal['label'] as String).tr,
                          style: GoogleFonts.notoSansSc(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPromptInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MYSTERY_BOX_PROMPT_TITLE'.tr,
          style: GoogleFonts.notoSansSc(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
          Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEBEBF5)),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TextField(
            controller: _promptController,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.done,
            onEditingComplete: () => FocusScope.of(context).unfocus(),
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            style: GoogleFonts.notoSansSc(fontSize: 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'MYSTERY_BOX_PROMPT_HINT'.tr,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _promptTags
                  .map((tagKey) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _buildPromptTag(tagKey),
                      ))
                  .toList(),
            ),
            ),
          ),
        ],
    );
  }

  Widget _buildPromptTag(String tagKey) {
    return GestureDetector(
      onTap: () => _appendPrompt(tagKey.tr),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF4FF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          '#${tagKey.tr}',
          style: GoogleFonts.notoSansSc(
            fontSize: 13,
            color: const Color(0xFF3B4A6B),
          ),
        ),
      ),
    );
  }

  void _appendPrompt(String tag) {
    final current = _promptController.text.trim();
    final newText = current.isEmpty ? tag : '$current，$tag';
        setState(() {
      _promptController.text = newText;
      _promptController.selection = TextSelection.fromPosition(
        TextPosition(offset: _promptController.text.length),
      );
    });
  }

  void _startLoadingAnimations() {
    _buttonPulseController.repeat(reverse: true);
    _carouselStartTime = DateTime.now();
    _carouselController.repeat();
  }

  void _stopLoadingAnimations() {
    if (_buttonPulseController.isAnimating) {
      _buttonPulseController.stop();
      _buttonPulseController.reset();
    }
    if (_carouselController.isAnimating) {
      _carouselController.stop();
      _carouselController.reset();
    }
    _carouselStartTime = null;
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _requestMealPlan,
      style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor:
              _isGenerating ? const Color.fromARGB(255, 117, 166, 134) : Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _buttonPulseAnimation,
              child: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              _isGenerating
                  ? 'MYSTERY_BOX_GENERATING'.tr
                  : 'MYSTERY_BOX_BUTTON'.tr,
              style: GoogleFonts.notoSansSc(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    if (_isGenerating) {
      return _buildLoadingCarousel();
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    if (_generatedMeal == null) {
      return _buildEmptyState();
    }
    return _buildMealCard(_generatedMeal!);
  }

  Widget _buildLoadingCarousel() {
    const double cardWidth = 150;
    const double cardSpacing = 12;
    final double singleSpan =
        (cardWidth + cardSpacing) * _carouselCards.length;
    final double totalWidth = singleSpan * 2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFDCE2F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.06),
            blurRadius: 25,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MYSTERY_BOX_OPENING_TITLE'.tr,
            style: GoogleFonts.notoSansSc(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ClipRect(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: AnimatedBuilder(
                    animation: _carouselController,
                    builder: (context, child) {
                      final repeatedCards = [
                        ..._carouselCards,
                        ..._carouselCards,
                      ];
                      final elapsedSeconds = _carouselStartTime == null
                          ? 0.0
                          : DateTime.now()
                                  .difference(_carouselStartTime!)
                                  .inMilliseconds /
                              1000.0;
                      const double speed = 600; // px per second
                      final distance = elapsedSeconds * speed;
                      double translation = -(distance % singleSpan);
                      // ensure range [-singleSpan, 0)
                      if (translation <= -singleSpan) {
                        translation += singleSpan;
                      }

                      return Transform.translate(
                        offset: Offset(translation, 0),
                        child: SizedBox(
                          width: totalWidth,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: repeatedCards
                                .map(
                                  (card) => _buildCarouselCard(
                                    cardWidth,
                                    cardSpacing,
                                    card,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  ),  
                  IgnorePointer(
                    child: Container(
                      width: cardWidth -10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.4),
                          width: 2,
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.5),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.help_outline,
                              size: 36, color: Colors.deepPurple[400]),
                          const SizedBox(height: 6),
                          Text(
                            'MYSTERY_BOX_OPENING_LOCKED'.tr,
                            style: GoogleFonts.notoSansSc(
                              fontSize: 12,
                              color: Colors.deepPurple[400],
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(
      double width, double spacing, String imagePath) {
    return SizedBox(
      height: 130,
      width: width,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing / 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black38,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE6E8EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          // 盲盒主体
          GestureDetector(
            onTap: _requestMealPlan,
            child:  AnimatedBuilder(
            animation: _boxPulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _boxPulseAnimation.value,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFE5B4),
                        Color(0xFFFFD89B),
                        Color(0xFFFFC97D),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: 10,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 盒子纹理
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      // 问号
                      AnimatedBuilder(
                        animation: _questionMarkOpacity,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _questionMarkOpacity.value,
                            child: Text(
                              '?',
                              style: GoogleFonts.notoSansSc(
                                fontSize: 80,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.orange.withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // 装饰星星
                      ...List.generate(2, (index) {
                        const radius = 70.0;
                        final x = radius * (index.isEven ? 1 : -1) * 0.6;
                        final y = radius * (index % 3 == 0 ? 1 : -1) * 0.4;
                        return Positioned(
                          left: 60 + x,
                          top: 60 + y,
                          child: AnimatedBuilder(
                            animation: _questionMarkController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _questionMarkController.value * 2 * 3.14159,
                                child: Opacity(
                                  opacity: 0.6 - (index * 0.1),
                                  child: Icon(
                                    Icons.star,
                                    size: 16 - (index % 3) * 3,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
          
          ),
         
          const SizedBox(height: 32),
          Text(
            'MYSTERY_BOX_EMPTY_SUBTITLE'.tr,
            style: GoogleFonts.notoSansSc(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
        color: const Color(0xFFFFECE8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFC2B9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFED5A4F)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                  'GENERATE_FAILED'.tr,
                  style: GoogleFonts.notoSansSc(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                    const SizedBox(height: 4),
                    Text(
                  _errorMessage ?? 'MYSTERY_BOX_ERROR_MESSAGE'.tr,
                  style: GoogleFonts.notoSansSc(color: Colors.black54),
                ),
                ],
              ),
            ),
          TextButton(
            onPressed: _isGenerating ? null : _requestMealPlan,
            child: Text('MYSTERY_BOX_RETRY'.tr),
            ),
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final String imageUrl = _resolveImageUrl(meal['imageUrl']?.toString());
    final List<String> dishes =
        List<String>.from(meal['dishes'] as List? ?? const <String>[]);
    final String? prompt = meal['prompt']?.toString();
    final String mealName = meal['mealName']?.toString() ??'';

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE7EAF4)),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withOpacity(0.08),
                blurRadius: 35,
                offset: const Offset(0, 30),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(10), 
                ),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image_outlined,
                              size: 40, color: Colors.black38),
                        ),
                      )
                    : Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported_rounded,
                            size: 40, color: Colors.black38),
                      ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric( vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mealName,
                                style: GoogleFonts.notoSansSc(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (dishes.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        children: dishes
                            .map((dish) => Chip(
                                  label: Text(dish,style: const TextStyle(fontSize: 13),),
                                  backgroundColor: const Color(0xFFF8F9FD),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: dishes.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  _generatedMeal = null;
                                  _showRevealOverlay = false;
                                });
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MysteryMealDetailPage(
                                      imageUrl: imageUrl,
                                      dishes: dishes,
                                      mealType: meal['mealType'] as String? ??
                                          _selectedMeal,
                                      prompt: prompt,
                                      mealName: mealName,
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          'MYSTERY_BOX_VIEW_DETAIL'.tr,
                          style: GoogleFonts.notoSansSc(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_showRevealOverlay)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _showRevealOverlay ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.help_outline,
                            size: 40, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MYSTERY_BOX_OPENING_LOCKED'.tr,
                      style: GoogleFonts.notoSansSc(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _requestMealPlan() async {
    if (_isGenerating) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedMeal = null;
      _showRevealOverlay = false;
    });
    _startLoadingAnimations();

    final prompt = _promptController.text.trim();
    try {
      final rawResp =
          await yifanRandomMeal(_mealTypeToCode(_selectedMeal), prompt: prompt);
      final resp = rawResp is ApiResult ? rawResp : null;
      final data = resp != null
          ? (resp.ok ? resp.data : null)
          : (rawResp is Map<String, dynamic> ? rawResp : null);
      if (!mounted) return;

      if (data == null) {
        throw Exception('Random meal request failed');
      }

      print('data: $data');

      print('dishes: ${data['dishNames']}');

      setState(() {
        _generatedMeal = {
          'imageUrl': data['imageUrl']?.toString(),
          'dishes': data['dishNames'],
          'prompt': prompt,
          'mealType': _selectedMeal,
          'mealName': data['mealName']?.toString(),
        };
        _showRevealOverlay = true;
        _isGenerating = false;
      });
      _stopLoadingAnimations();
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _showRevealOverlay = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'MYSTERY_BOX_BACKEND_ERROR'.tr;
          _generatedMeal = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
      _stopLoadingAnimations();
    }
  }

  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return url;
  }

  int _mealTypeToCode(String mealId) {
    switch (mealId) {
      case 'breakfast':
        return 1;
      case 'lunch':
        return 2;
      case 'dinner':
        return 3;
      default:
        return 2;
    }
  }
}
