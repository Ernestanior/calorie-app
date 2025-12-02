import 'dart:math' as math;
import 'package:calorie/page/lab/aiCooking/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../../common/icon/index.dart';
import '../../../network/api.dart';
import '../../../store/store.dart';
import '../../../components/dialog/nutrition.dart';

class RecipeDetailPage extends StatefulWidget {
  final List<String> ingredients;
  final int cuisineId;
  final String cuisineName;
  final String customPrompt;
  final List<Map<String, dynamic>> selectedIngredients;
  final Map<String, dynamic>? initialRecipe; // 可选的初始数据，如果提供则不需要请求API
  
  const RecipeDetailPage({
    super.key,
    required this.ingredients,
    required this.cuisineId,
    required this.cuisineName,
    required this.customPrompt,
    required this.selectedIngredients,
    this.initialRecipe,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _recipe;
  String? _error;
  bool _isLoadingImage = false;
  String? _recipeImageUrl;
  
  late AnimationController _progressController;
  late AnimationController _loadingTextController;
  late AnimationController _hourglassController;
  late AnimationController _floatingController;
  double _progress = 0.0;
  String _loadingText = 'AI_COOKING_CRAFTING'.tr;
  int _loadingTextIndex = 0;
  late final List<String> _loadingTexts;
  
  // 保存监听器引用以便正确移除
  VoidCallback? _progressListener;
  void Function(AnimationStatus)? _loadingTextStatusListener;

  @override
  void initState() {
    super.initState();
    _loadingTexts = [
      'AI_COOKING_CRAFTING'.tr,
      'AI_COOKING_PLATING'.tr,
      'AI_COOKING_CAREFULLY_CRAFTING'.tr,
    ];
    _loadingText = _loadingTexts.first;

    _progressController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _loadingTextStatusListener = (status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _loadingTextIndex = (_loadingTextIndex + 1) % _loadingTexts.length;
          _loadingText = _loadingTexts[_loadingTextIndex];
        });
        if (mounted) {
          _loadingTextController.forward(from: 0);
        }
      }
    };
    
    _loadingTextController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )
      ..addStatusListener(_loadingTextStatusListener!)
      ..forward();
    
    // 沙漏旋转动画
    _hourglassController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // 图片浮动动画
    _floatingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressListener = () {
      if (mounted) {
        setState(() {
          // 进度条最多到99%，直到结果返回
          _progress = (_progressController.value * 0.99).clamp(0.0, 0.99);
        });
      }
    };
    _progressController.addListener(_progressListener!);
    
    // 如果传入了初始数据，直接使用，否则请求API
    if (widget.initialRecipe != null) {
      setState(() {
        _recipe = widget.initialRecipe;
        _isLoading = false;
        _progress = 1.0;
      });
      
      // 从初始数据中获取图片URL
      final String? imageUrl = widget.initialRecipe?['imageUrl']?.toString();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        setState(() {
          _recipeImageUrl = imageUrl;
          _isLoadingImage = false;
        });
      } else {
        // 如果没有图片URL，尝试请求图片
        final recipeGenerateId = widget.initialRecipe?['recipeGenerateId'];
        if (recipeGenerateId is int) {
          _loadRecipeImage(recipeGenerateId);
        } else {
          setState(() {
            _isLoadingImage = false;
          });
        }
      }
      
      // 停止所有动画
      if (mounted) {
        _progressController.stop();
        _loadingTextController.stop();
        _hourglassController.stop();
        _floatingController.stop();
      }
    } else {
      _loadRecipe();
    }
  }

  Future<void> _loadRecipe() async {
    if (!mounted) return;
    _progressController.forward();
    final locale = Controller.c.user['lang'];
    
    try {
      final resp = await yifanRecipeGenerate(
        widget.ingredients,
        widget.cuisineId,
        widget.customPrompt,
        locale ?? 'en_US'
      );
      
      // print('yifanRecipeGenerate resp: $resp');
      
      
      if (mounted) {
        setState(() {
          _recipe = resp;
          _isLoading = false;
          _progress = 1.0; // 结果返回后设置为100%
        });
        
        // 获取recipe的id，然后请求图片
        if (resp != null && resp['recipeGenerateId'] != null) {
          final recipeGenerateId = resp['recipeGenerateId'];
          if (recipeGenerateId is int) {
            await _loadRecipeImage(recipeGenerateId);
          }
        }
      }
    } catch (e) {
      print('Error generating recipe: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    } finally {
      // 检查mounted状态，避免在dispose后调用stop()
      if (mounted) {
        _progressController.stop();
        _loadingTextController.stop();
        _hourglassController.stop();
        _floatingController.stop();
      }
    }
  }

  Future<void> _loadRecipeImage(int recipeId) async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingImage = true;
      _recipeImageUrl = null;
    });
    
    try {
      final resp = await yifanImageGenerate(recipeId);
      // 解析返回的图片URL
      String? imageUrl;
      if (resp is Map) {
        // 尝试多种可能的字段名
        imageUrl = resp['url']?.toString();
                   
      }
      
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
          _recipeImageUrl = imageUrl;
        });
      }
    } catch (e) {
      print('Error loading recipe image: $e');
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
          _recipeImageUrl = null;
        });
      }
    }
  }

  @override
  void dispose() {
    // 先停止所有动画控制器
    try {
      _progressController.stop();
      _loadingTextController.stop();
      _hourglassController.stop();
      _floatingController.stop();
    } catch (e) {
      // 忽略已dispose的错误
    }
    
    // 移除监听器
    if (_progressListener != null) {
      _progressController.removeListener(_progressListener!);
    }
    if (_loadingTextStatusListener != null) {
      _loadingTextController.removeStatusListener(_loadingTextStatusListener!);
    }
    
    // 然后dispose
    _progressController.dispose();
    _loadingTextController.dispose();
    _hourglassController.dispose();
    _floatingController.dispose();
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
              Color.fromARGB(255, 255, 232, 219),
              Color.fromARGB(255, 255, 255, 255),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingView()
              : _error != null
                  ? _buildErrorView()
                  : _buildRecipeView(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
            children: [
        // Header
               _buildHeader(context),
        
        // Loading content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                const SizedBox(height: 20),
                
                // Top section with cuisine info
                _buildTopSection(isLoading: true),
                const SizedBox(height: 24),
                
                // Ingredients section
                _buildLoadingIngredients(),
                const SizedBox(height: 30),
                
                // Loading animation section
                _buildLoadingAnimation(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 获取食材翻译后的名称
  String _getIngredientName(Map<String, dynamic> ingredient) {
    // 如果有id，使用翻译key
    if (ingredient['id'] != null) {
      final id = ingredient['id'];
      final translationKey = 'ingre_$id';
      final translatedName = translationKey.tr;
      // 如果翻译key存在（翻译后的值不等于key本身），则使用翻译
      if (translatedName != translationKey) {
        return translatedName;
      }
    }
    // 如果没有id或翻译不存在，使用原始name或displayName
    return ingredient['displayName'] ?? ingredient['name'] ?? '';
  }

  Widget _buildLoadingIngredients() {
    final items = widget.selectedIngredients
        .map((ingredient) => _getIngredientName(ingredient))
        .where((name) => name.isNotEmpty)
        .toList();

    return _buildChipSection(
      iconPath: 'assets/icons/vegetable.png',
      title: 'AI_COOKING_USING_INGREDIENTS'.tr,
      items: items,
    );
  }

  Widget _buildFloatingImages() {
    final List<String> imagePaths = [
      'assets/food/set/1.png',
      'assets/food/set/5.png',
      'assets/food/set/6.png',
    ];
    
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: imagePaths.asMap().entries.map((entry) {
          final index = entry.key;
          final imagePath = entry.value;
          // 为每张图片添加不同的延迟，让它们错开浮动
          final delay = index * 0.3;
          
          return AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              // 计算当前图片的动画值（带延迟）
              final animationValue = ((_floatingController.value + delay) % 1.0);
              // 使用正弦波创建平滑的上下浮动效果
              final offset = (math.sin(animationValue * 2 * math.pi) * 15); // 上下浮动15像素
              
              return Transform.translate(
                offset: Offset(0, offset),
                child: Container(
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 12,
                    right: index == imagePaths.length - 1 ? 0 : 12,
                  ),
                  child: Image.asset(
                    imagePath,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    // 如果还在loading状态，进度最大显示99%
    final double displayProgress = _isLoading 
        ? _progress.clamp(0.0, 0.99)  // loading时最大99%
        : _progress;  // 结果返回后可以显示100%
    final int progressPercent = (displayProgress * 100).clamp(0, 100).toInt();
    final bool isComplete = !_isLoading && progressPercent >= 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8D6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6B35).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // 浮动图片动画
          _buildFloatingImages(),
          const SizedBox(height: 20),
          
          // Loading text
          Text(
            widget.cuisineName,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _loadingText,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: displayProgress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFFF6B35).withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isComplete
                    ? 'AI_COOKING_COMPLETE'.tr
                    : '$progressPercent%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Loading dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection({required bool isLoading}) {
    if (!isLoading && _recipe == null) {
      return const SizedBox.shrink();
    }

    final recipeData = _recipe ?? const <String, dynamic>{};
    final String title = isLoading
        ? widget.cuisineName
        : (recipeData['name']?.toString().isNotEmpty ?? false)
            ? recipeData['name'].toString()
            : 'AI_COOKING_DEFAULT_RECIPE_NAME'.tr;

    final String cuisineRaw = isLoading
        ? widget.cuisineName
        : (recipeData['cuisine']?.toString().isNotEmpty ?? false)
            ? recipeData['cuisine'].toString()
            : widget.cuisineName;

    // 将菜系中文名转换为翻译后的名称
    final String cuisine = _getCuisineDisplayName(cuisineRaw);

    final List<Widget> chips = <Widget>[
      _buildMetaChip(Icons.restaurant, cuisine),
    ];

    if (isLoading) {
      chips
        ..add(_buildMetaChip(Icons.access_time, 'AI_COOKING_ESTIMATED_TIME'.tr))
        ..add(_buildMetaChip(Icons.auto_awesome, 'AI_COOKING_CAREFULLY_CRAFTING'.tr));
    } else {
      final int? cookingTime = recipeData['cookingTime'] is int
          ? recipeData['cookingTime'] as int
          : null;
      final String difficultyRaw = (recipeData['difficulty'] ?? '').toString();
      final String difficulty = _difficultyText(difficultyRaw);

      if (cookingTime != null) {
        chips.add(_buildMetaChip(Icons.timer, '$cookingTime ${'MIN'.tr}'));
      }
      if (difficulty.isNotEmpty) {
        chips.add(_buildMetaChip(Icons.leaderboard, difficulty));
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
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
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Text(
                    //   statusText,
                    //   style: GoogleFonts.inter(
                    //     fontSize: 14,
                    //     color: Colors.white70,
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // 沙漏动画图标
              if (isLoading)
                AnimatedBuilder(
                  animation: _hourglassController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _hourglassController.value * 2 * 3.14159,
                      child: Text('⏳',style: TextStyle(fontSize: 25),),
                    );
                  },
                )
              else
                SizedBox.shrink()
            ],
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: chips,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text,
      {Color? backgroundColor, Color? iconColor, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor ?? Colors.white70,
          ),
          const SizedBox(width: 6),
                  Text(
            text,
                    style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientChip(String text) {
                      return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
        color: const Color(0xFFFFD54F),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildChipSection({
    required String iconPath,
    required String title,
    required List<String> items,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              iconPath,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: items.map(_buildIngredientChip).toList(),
        ),
      ],
    );
  }

  Widget _buildRecipeImageSection() {
    // 如果没有图片且不在loading状态，不显示
    if (!_isLoadingImage && _recipeImageUrl == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        Row(
          children: [
            Image.asset('assets/icons/hotpot.png',width: 20,height: 20,),
            const SizedBox(width: 8),
            Text(
              'RECIPE_IMAGE'.tr,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAEAF0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _isLoadingImage
                ? _buildImageLoading()
                : _recipeImageUrl != null
                    ? _buildRecipeImage(_recipeImageUrl!)
                    : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageLoading() {
    return Container(
      height: 200,
      color: const Color.fromARGB(255, 255, 246, 234),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFloatingImages(),
          const SizedBox(height: 16),
          Text(
            'AI_COOKING_GENERATING_IMAGE'.tr,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeImage(String imageUrl) {
    return Image.network(
      imageUrl.startsWith('http') ? imageUrl : '$imgUrl$imageUrl',
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          height: 300,
          color: const Color(0xFFF7F7FA),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFFF6B35),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          color: const Color(0xFFF7F7FA),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.black38,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'IMAGE_LOAD_FAILED'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepsSection(List steps) {
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/icons/tableware.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
                  Text(
              'AI_COOKING_PREPARATION_STEPS'.tr,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                color: Colors.black87,
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 12),
                  Column(
                    children: steps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value as Map<String, dynamic>? ?? {};
                      final int stepNo = step['step'] is int ? step['step'] : index + 1;
                      final String desc = (step['description'] ?? '').toString();
                      final int? time = step['time'] is int ? step['time'] as int : null;
                      final String temp = (step['temperature'] ?? '').toString();
                      return _buildStepTile(stepNo, desc, time, temp);
                    }).toList(),
                  ),
      ],
    );
  }

  Widget _buildTipsSection(List tips) {
    if (tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            
            Text('📝',style: TextStyle(
                      fontSize: 16,)),
        const SizedBox(width: 3),

                  Text(
                    'TIPS'.tr,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                color: Colors.black87,
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: tips.map((t) {
                      final text = t.toString();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEAEAF0), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '$text',
                          style: GoogleFonts.inter(color: Colors.black87,fontSize: 13),
                        ),
                      );
                    }).toList(),
                  ),
                ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: _buildHeader(context),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'GENERATE_FAILED'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'UNKNOWN_ERROR'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      ],
    );
  }

  Widget _buildRecipeView() {
    if (_recipe == null) {
      return const SizedBox.shrink();
    }
    
    final List ingredients = (_recipe!['ingredients'] as List?) ?? const [];
    final List steps = (_recipe!['steps'] as List?) ?? const [];
    final List tips = (_recipe!['tips'] as List?) ?? const [];
    final Map<String, dynamic>? nutritionAnalysis = _recipe!['nutritionAnalysis'] as Map<String, dynamic>?;
    final List<String> ingredientTexts = ingredients
        .map((ing) {
          // 如果 ingredients 是对象列表，尝试翻译
          if (ing is Map<String, dynamic>) {
            return _getIngredientName(ing);
          }
          // 如果是字符串，直接返回
          return ing.toString();
        })
        .where((text) => text.trim().isNotEmpty)
        .toList();
    final bool hasIngredients = ingredientTexts.isNotEmpty;
    final bool hasSteps = steps.isNotEmpty;
    final bool hasTips = tips.isNotEmpty;

    return Column(
      children: [
        // Header with back button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: _buildHeader(context),
        ),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopSection(isLoading: false),

                if (hasIngredients) ...[
                  const SizedBox(height: 24),
                  _buildChipSection(
                    iconPath: 'assets/icons/vegetable.png',
                    title: 'AI_COOKING_USING_INGREDIENTS'.tr,
                    items: ingredientTexts,
                  ),
                ],

                _buildRecipeImageSection(),

                // 料理渲染图
                if (hasSteps) ...[
                  const SizedBox(height: 24),
                  _buildStepsSection(steps),
                ],

                

                if (nutritionAnalysis != null) ...[
                  const SizedBox(height: 12),
                  _buildNutritionAnalysisSection(nutritionAnalysis),
                ],

                if (hasTips) ...[
                  const SizedBox(height: 20),
                  _buildTipsSection(tips),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(AliIcon.back, color: Colors.black87, size: 30),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 24,
        ),
        Text(
          'RECIPE_DETAIL'.tr,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildStepTile(int stepNo, String desc, int? time, String temp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAF0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$stepNo',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: GoogleFonts.inter(color: Colors.black87,fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (time != null) ...[
                      const Icon(Icons.timer, size: 15, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text('$time ${'MINUTES'.tr}', style: GoogleFonts.inter(color: Colors.black54,fontSize: 11)),
                      const SizedBox(width: 12),
                    ],
                    if (temp.isNotEmpty) ...[
                      const Icon(Icons.local_fire_department, size: 15, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(temp, style: GoogleFonts.inter(color: Colors.black54,fontSize: 11)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _difficultyText(String raw) {
    switch (raw.toLowerCase()) {
      case 'easy':
        return 'DIFFICULTY_EASY'.tr;
      case 'medium':
        return 'DIFFICULTY_MEDIUM'.tr;
      case 'hard':
        return 'DIFFICULTY_HARD'.tr;
      default:
        return raw;
    }
  }

  // 获取菜系翻译后的名称
  String _getCuisineDisplayName(String raw) {
    final String? key = cuisineZhNameToKey[raw];
    if (key != null) return key.tr;
    return raw;
  }

  Widget _buildNutritionAnalysisSection(Map<String, dynamic> nutritionAnalysis) {
    final Map<String, dynamic>? nutrition = nutritionAnalysis['nutrition'] as Map<String, dynamic>?;
    final List balanceAdvice = nutritionAnalysis['balanceAdvice'] as List? ?? const [];
    final List dietaryTags = nutritionAnalysis['dietaryTags'] as List? ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Row(
          children: [
            Image.asset(
              'assets/icons/record2.png',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'NUTRITION_ANALYSIS'.tr,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // 营养分析卡片
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAEAF0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 营养成分网格
              if (nutrition != null) ...[
                _buildNutritionGrid(nutrition),
                const SizedBox(height: 16),
              ],
              
              
              
              // 饮食标签
              if (dietaryTags.isNotEmpty) ...[
                Text(
                  'DIETARY_TAGS'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: dietaryTags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF6B35),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // 平衡建议
              if (balanceAdvice.isNotEmpty) ...[
                Text(
                  'BALANCE_ADVICE'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...balanceAdvice.map((advice) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.black54, fontSize: 13)),
                        Expanded(
                          child: Text(
                            advice.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionGrid(Map<String, dynamic> nutrition) {
    final double? calories = nutrition['calories'] is num ? (nutrition['calories'] as num).toDouble() : null;
    final double? protein = nutrition['protein'] is num ? (nutrition['protein'] as num).toDouble() : null;
    final double? carbs = nutrition['carbs'] is num ? (nutrition['carbs'] as num).toDouble() : null;
    final double? fat = nutrition['fat'] is num ? (nutrition['fat'] as num).toDouble() : null;
    final double? fiber = nutrition['fiber'] is num ? (nutrition['fiber'] as num).toDouble() : null;
    final double? sodium = nutrition['sodium'] is num ? (nutrition['sodium'] as num).toDouble() : null;
    final double? sugar = nutrition['sugar'] is num ? (nutrition['sugar'] as num).toDouble() : null;

    return Column(
      children: [
        // 主要营养成分
        Row(
          children: [
            Expanded(
              child: _buildNutritionItem('CALORIE'.tr, calories, 'kcal'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNutritionItem('PROTEIN'.tr, protein, 'g'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNutritionItem('CARBS'.tr, carbs, 'g'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNutritionItem('FAT'.tr, fat, 'g'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNutritionItem('DIETARY_FIBER'.tr, fiber, 'g'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNutritionItem('SODIUM'.tr, sodium, 'mg'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNutritionItem('SUGAR'.tr, sugar, 'g'),
            ),
            Expanded(
              child: SizedBox.shrink(),
            )
          ],
        ),
        
      ],
    );
  }

  Widget _buildNutritionItem(String label, double? value, String unit, {bool isSecondary = false}) {
    if (value == null) {
      return const SizedBox.shrink();
    }
    
    // 获取图标和颜色
    final iconData = getNutritionIcon(label);
    final iconColor = getNutritionIconColor(label);
    // 获取营养信息的key
    final nutritionKey = getNutritionKey(label);
    
    return GestureDetector(
      onTap: () {
        if (nutritionKey != null) {
          showNutritionInfoDialog(context, nutritionKey);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSecondary 
              ? const Color(0xFFF7F7FA) 
              : const Color(0xFFFFF8F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  iconData,
                  size: 18,
                  color: iconColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }




}

  // 根据营养成分标签获取nutritionLabelMap中的key
  String? getNutritionKey(String label) {
    // 使用翻译键进行比较
    if (label == 'CALORIE'.tr || label.contains('Calorie') || label.contains('卡路里')) {
      return 'calorie';
    } else if (label == 'CARBS'.tr || label.contains('Carb') || label.contains('碳水')) {
      return 'carbs';
    } else if (label == 'FAT'.tr || label.contains('Fat') || label.contains('脂肪')) {
      return 'fat';
    } else if (label == 'PROTEIN'.tr || label.contains('Protein') || label.contains('蛋白质')) {
      return 'protein';
    } else if (label == 'SUGAR'.tr || label.contains('Sugar') || label.contains('糖')) {
      return 'sugars';
    } else if (label == 'FIBER'.tr || label == 'DIETARY_FIBER'.tr || label.contains('Fiber') || label.contains('膳食纤维')) {
      return 'dietaryFiber';
    } else if (label == 'SODIUM'.tr || label.contains('Sodium') || label.contains('钠')) {
      return 'sodium';
    }
    return null;
  }

  // 根据营养成分标签获取对应的图标
  IconData getNutritionIcon(String label) {
    // 使用翻译键进行比较
    if (label == 'CALORIE'.tr || label.contains('Calorie') || label.contains('卡路里')) {
      return Icons.local_fire_department;
    } else if (label == 'CARBS'.tr || label.contains('Carb') || label.contains('碳水')) {
      return AliIcon.dinner4;
    } else if (label == 'FAT'.tr || label.contains('Fat') || label.contains('脂肪')) {
      return AliIcon.meat2;
    } else if (label == 'PROTEIN'.tr || label.contains('Protein') || label.contains('蛋白质')) {
      return AliIcon.fat;
    } else if (label == 'SUGAR'.tr || label.contains('Sugar') || label.contains('糖')) {
      return AliIcon.sugar2;
    } else if (label == 'FIBER'.tr || label.contains('Fiber') || label.contains('膳食纤维')) {
      return AliIcon.fiber;
    } else if (label == 'SODIUM'.tr || label.contains('Sodium') || label.contains('钠')) {
      return Icons.water_drop;
    }
    return Icons.restaurant;
  }

  // 根据营养成分标签获取对应的图标颜色
  Color getNutritionIconColor(String label) {
    if (label == 'CALORIE'.tr || label.contains('Calorie') || label.contains('卡路里')) {
      return const Color.fromARGB(255, 255, 91, 21);
    } else if (label == 'CARBS'.tr || label.contains('Carb') || label.contains('碳水')) {
      return Colors.blueAccent;
    } else if (label == 'FAT'.tr || label.contains('Fat') || label.contains('脂肪')) {
      return Colors.redAccent;
    } else if (label == 'PROTEIN'.tr || label.contains('Protein') || label.contains('蛋白质')) {
      return Colors.orangeAccent;
    } else if (label == 'SUGAR'.tr || label.contains('Sugar') || label.contains('糖')) {
      return const Color.fromARGB(255, 64, 242, 255);
    } else if (label == 'FIBER'.tr || label.contains('Fiber') || label.contains('膳食纤维')) {
      return const Color.fromARGB(255, 8, 158, 23);
    } else if (label == 'SODIUM'.tr || label.contains('Sodium') || label.contains('钠')) {
      return Colors.blueGrey;
    }
    return const Color.fromARGB(136, 30, 220, 65);
  }