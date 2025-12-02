import 'dart:ui';
import 'package:calorie/common/icon/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:calorie/page/lab/aiCooking/foodSelector.dart';
import 'package:calorie/network/api.dart';
import 'package:calorie/page/lab/aiCooking/result.dart';

  // 菜系中文名 -> 多语言 Key 映射（后端固定中文名）
 const Map<String, String> cuisineZhNameToKey = {
    '苏菜': 'CUISINE_SU',
    '鲁菜': 'CUISINE_LU',
    '川菜': 'CUISINE_CHUAN',
    '粤菜': 'CUISINE_YUE',
    '浙菜': 'CUISINE_ZHE',
    '湘菜': 'CUISINE_XIANG',
    '闽菜': 'CUISINE_MIN',
    '徽菜': 'CUISINE_HUI',
    '日式料理': 'CUISINE_JAPANESE',
    '韩式料理': 'CUISINE_KOREAN',
    '意式料理': 'CUISINE_ITALIAN',
    '法式料理': 'CUISINE_FRENCH',
    '泰式料理': 'CUISINE_THAI',
    '墨西哥料理': 'CUISINE_MEXICAN',
    '印度料理': 'CUISINE_INDIAN',
  };

class AiCookingPage extends StatefulWidget {
  const AiCookingPage({super.key});

  @override
  State<AiCookingPage> createState() => _AiCookingPageState();
}

class _AiCookingPageState extends State<AiCookingPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _selectedIngredients = [];
  List<int> _selectedCuisines = []; // 改为 int 类型，因为 API 返回的 id 是数字
  bool _isGenerating = false;
  late String _generatingText;
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _commonIngredients = []; // 常用食材列表
  bool _isLoadingCommonIngredients = false;
  List<Map<String, dynamic>> _cuisines = []; // 从 API 获取的菜系列表
  bool _isLoadingCuisines = false;
  String _customPrompt = '';
  bool _isPromptExpanded = false;



  String _getCuisineDisplayName(Map<String, dynamic> cuisine) {
    final String raw = (cuisine['name'] ?? '').toString();
    final String? key = cuisineZhNameToKey[raw];
    if (key != null) return key.tr;
    return raw;
  }

  late AnimationController _fadeController;
  late AnimationController _generatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _generatingAnimation;

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
    // 如果没有id或翻译不存在，使用原始name
    return ingredient['name'] ?? '';
  }


  @override
  void initState() {
    super.initState();
    _generatingText = 'AI_COOKING_GENERATING_STATUS'.tr;
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _generatingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _generatingAnimation = CurvedAnimation(
      parent: _generatingController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    _loadCommonIngredients();
    _loadCuisines();
  }

  // 加载常用食材
  Future<void> _loadCommonIngredients() async {
    setState(() {
      _isLoadingCommonIngredients = true;
    });

    try {
      final response = await yifanFoodIngredient(1, 20, type: 9);
      
      if (response != null && response['content'] != null) {
        final List<dynamic> content = response['content'];
        final ingredients = content.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'name': item['name'],
            'type': item['type'],
            'imageUrl': item['imageUrl'],
          };
        }).toList();
        
        setState(() {
          _commonIngredients = ingredients;
          _isLoadingCommonIngredients = false;
        });
      } else {
        setState(() {
          _isLoadingCommonIngredients = false;
        });
      }
    } catch (e) {
      print('Error loading common ingredients: $e');
      setState(() {
        _isLoadingCommonIngredients = false;
      });
    }
  }

  // 加载菜系数据
  Future<void> _loadCuisines() async {
    setState(() {
      _isLoadingCuisines = true;
    });

    try {
      final response = await yifanFoodCuisine();      
      if (response != null) {
        final List<dynamic> content = response['content'];
        final cuisines = content.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'name': item['name'],
            'description': item['description'],
            'imageUrl': item['imageUrl'],
            'specialty': item['specialty'],
            'prompt': item['prompt'],
          };
        }).toList();

        setState(() {
          _cuisines = cuisines;
          _isLoadingCuisines = false;
        });
      } else {
        setState(() {
          _isLoadingCuisines = false;
        });
      }
    } catch (e) {
      print('Error loading cuisines: $e');
      setState(() {
        _isLoadingCuisines = false;
      });
    }
  }

  // 添加食材到选中列表
  void _addIngredientToSelected(Map<String, dynamic> ingredient) {
    // 检查是否已存在
    final exists = _selectedIngredients.any(
      (item) => item['id'] == ingredient['id'],
    );
    
    if (!exists) {
      setState(() {
        _selectedIngredients.add(ingredient);
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _generatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 255, 232, 219),
              const Color.fromARGB(255, 255, 255, 255),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 主内容
            FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
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
                        // 标题栏
                        _buildHeader(),
                        const SizedBox(height: 18),
                        
                        // Step 1: 添加食材
                        _buildStepCard(
                          stepNumber: 1,
                          title: 'AI_COOKING_STEP_ADD'.tr,
                          child: _buildIngredientSection(),
                          trailing: _buildIngredientLibraryButton(),
                        ),
                        const SizedBox(height: 20),
                        
                        // Step 2: 选择菜系
                        _buildStepCard(
                          stepNumber: 2,
                          title: 'AI_COOKING_STEP_SELECT_CUISINE'.tr,
                          child: _buildCuisineSection(),
                        ),
                        const SizedBox(height: 20),
                        
                        // Step 3: 自定义提示 & 生成
                        _buildGenerateSection(),
                        
                        // 结果展示
                        if (_recipes.isNotEmpty) _buildResults(),
                        Container(
                          height: MediaQuery.of(context).padding.bottom ,
                          color: Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // AI生成遮罩层
            if (_isGenerating) _buildGeneratingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
        Text(
          'SMART_COOKING'.tr,
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const Spacer(),
        GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/aiCookingHistory');
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 255, 181, 124),
                    Color.fromARGB(255, 255, 115, 14),
                    Color.fromARGB(255, 255, 181, 124),

                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 255, 201, 39)
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

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEAEAF0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildIngredientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),

        // 快捷食材列表
        _buildQuickIngredientsList(),
        
        const SizedBox(height: 16),
        
        // 已选食材标签
        if (_selectedIngredients.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedIngredients.map((ingredient) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF6B35),
                      Color(0xFFFF8E53),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 显示食材图片，如果是自定义食材则显示默认图标
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white.withOpacity(0.3),
                      ),
                      child: ingredient['imageUrl'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                '$imgUrl${ingredient['imageUrl']}',
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.fastfood,
                                    size: 12,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.fastfood,
                              size: 12,
                              color: Colors.white,
                            ),
                    ),
                    Text(
                      _getIngredientName(ingredient),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIngredients.remove(ingredient);
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildIngredientLibraryButton() {
    return GestureDetector(
      onTap: () => _showIngredientSelector(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF6B35),
              Color(0xFFFF8E53),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.kitchen_outlined,
              size: 15,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              'INGREDIENT_LIBRARY'.tr,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建快捷食材列表
  Widget _buildQuickIngredientsList() {
    if (_isLoadingCommonIngredients) {
      return SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFFFF6B35),
            ),
          ),
        ),
      );
    }

    if (_commonIngredients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMMON_INGREDIENTS'.tr,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _commonIngredients.length,
            itemBuilder: (context, index) {
              final ingredient = _commonIngredients[index];
              final isSelected = _selectedIngredients.any(
                (item) => item['id'] == ingredient['id'],
              );
              
              return GestureDetector(
                onTap: () => _addIngredientToSelected(ingredient),
                child: Container(
                  width: 80,
                  margin: EdgeInsets.only(
                    right: index == _commonIngredients.length - 1 ? 0 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF6B35).withOpacity(0.1)
                        : const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF6B35)
                          : const Color.fromARGB(255, 220, 220, 220),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 食材图片
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFEAEAF0),
                        ),
                        child: ingredient['imageUrl'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '$imgUrl${ingredient['imageUrl']}',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.fastfood,
                                      size: 24,
                                      color: Colors.black54,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.fastfood,
                                size: 24,
                                color: Colors.black54,
                              ),
                      ),
                      const SizedBox(height: 6),
                      // 食材名称
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          _getIngredientName(ingredient),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCuisineSection() {
    if (_isLoadingCuisines) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
          ),
        ),
      );
    }

    if (_cuisines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'AI_COOKING_NO_CUISINE'.tr,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _cuisines.map((cuisine) {
          final cuisineId = cuisine['id'] as int;
          final isSelected = _selectedCuisines.contains(cuisineId);
          return GestureDetector(
            onTap: () {
              setState(() {
                // 仅允许选择一个菜系；再次点击已选项可取消选择
                if (isSelected) {
                  _selectedCuisines = [];
                } else {
                  _selectedCuisines = [cuisineId];
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFFF6B35),
                          Color(0xFFFF8E53),
                        ],
                      )
                    : null,
                color: isSelected ? null : const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : const Color(0xFFEAEAF0),
                  width: 1.5,
                ),
              ),
              child: Text(
                _getCuisineDisplayName(cuisine),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenerateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'AI_COOKING_PROMPT_TITLE'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPromptExpanded = !_isPromptExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE0E3EB),
                    ),
                  ),
                  child: Icon(
                    _isPromptExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: _isPromptExpanded,
          maintainAnimation: true,
          maintainSize: true,
          maintainState: true,
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color.fromARGB(255, 250, 241, 234), width: 1),
            ),
            child: TextField(
              onChanged: (v) => _customPrompt = v,
              style: GoogleFonts.inter(color: Colors.black87),
              maxLines: 3,
              maxLength: 100,
              textInputAction: TextInputAction.done,
              onEditingComplete: () => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: 'AI_COOKING_PROMPT_HINT'.tr,
                hintStyle:
                    GoogleFonts.inter(color: Colors.black38, fontSize: 13),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: GestureDetector(
            // 始终可点击，内部做校验给出弹窗提示
            onTap: _generateRecipes,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.4),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                          spreadRadius: 1,
                        ),
                      ]
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AI_COOKING_GENERATE_BUTTON'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI_COOKING_RESULTS_TITLE'.tr,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        ..._recipes.map((recipe) => _buildRecipeCard(recipe)).toList(),
      ],
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe['name'] ?? 'AI_COOKING_DEFAULT_RECIPE_NAME'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                if (recipe['ingredients'] != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (recipe['ingredients'] as List)
                        .map((ingredient) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getIngredientName(ingredient),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratingOverlay() {
    return AnimatedBuilder(
      animation: _generatingAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 加载动画
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        const Color(0xFF6C63FF).withOpacity(0.3),
                        const Color(0xFF42E8E0).withOpacity(0.3),
                        const Color(0xFF6C63FF).withOpacity(0.3),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      transform: GradientRotation(_generatingAnimation.value * 2 * 3.14159),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _generatingText,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // 粒子效果
                SizedBox(
                  width: 200,
                  height: 4,
                  child: CustomPaint(
                    painter: ParticleFlowPainter(_generatingAnimation.value),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showIngredientSelector() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodIngredientSelector(
          selectedIngredients: _selectedIngredients,
          onIngredientsSelected: (ingredients) {
            setState(() {
              _selectedIngredients = ingredients;
            });
          },
        ),
      ),
    );
  }

  Future<void> _generateRecipes() async {
    // 校验：必须选择食材
    if (_selectedIngredients.isEmpty) {
      await _showRequirementDialog(
        title: 'AI_COOKING_DIALOG_INGREDIENTS_TITLE'.tr,
        message: 'AI_COOKING_DIALOG_INGREDIENTS_MESSAGE'.tr,
      );
      return;
    }
    // 校验：必须选择菜系（单选）
    if (_selectedCuisines.isEmpty) {
      await _showRequirementDialog(
        title: 'AI_COOKING_DIALOG_CUISINE_TITLE'.tr,
        message: 'AI_COOKING_DIALOG_CUISINE_MESSAGE'.tr,
      );
      return;
    }

    // 组织参数
    final ingredients = _selectedIngredients.map((i) => _getIngredientName(i)).toList();
    final cuisineId = _selectedCuisines.first;
    final selectedCuisine = _cuisines.firstWhere((c) => c['id'] == cuisineId);
    
    // 立即跳转到RecipeDetailPage，传递参数用于显示loading状态
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeDetailPage(
            ingredients: ingredients,
            cuisineId: cuisineId,
            cuisineName: _getCuisineDisplayName(selectedCuisine),
            customPrompt: _customPrompt,
            selectedIngredients: _selectedIngredients,
          ),
        ),
      );
    }
  }

  Future<void> _showRequirementDialog({
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B35).withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            'AI_COOKING_DIALOG_ACTION'.tr,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -28,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 粒子流动画
class ParticleFlowPainter extends CustomPainter {
  final double animationValue;

  ParticleFlowPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF6C63FF);

    final particleCount = 5;
    final particleWidth = size.width / particleCount;

    for (int i = 0; i < particleCount; i++) {
      final x = (particleWidth * i) + (animationValue * particleWidth * 2);
      final normalizedX = x % (size.width + particleWidth);
      final opacity = 1.0 - (normalizedX / size.width).abs();
      
      paint.color = const Color(0xFF6C63FF).withOpacity(opacity.clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(normalizedX, size.height / 2),
        2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
