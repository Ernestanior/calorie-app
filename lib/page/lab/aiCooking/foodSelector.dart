import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:calorie/network/api.dart';

class FoodIngredientSelector extends StatefulWidget {
  final List<Map<String, dynamic>> selectedIngredients;
  final Function(List<Map<String, dynamic>>) onIngredientsSelected;

  const FoodIngredientSelector({
    super.key,
    required this.selectedIngredients,
    required this.onIngredientsSelected,
  });

  @override
  State<FoodIngredientSelector> createState() => _FoodIngredientSelectorState();
}

class _FoodIngredientSelectorState extends State<FoodIngredientSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredIngredients = [];
  int _selectedCategoryIndex = 0;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  // 获取食材名称：直接使用后端返回的 name，避免因旧翻译资源导致名称错位
  String _getIngredientName(Map<String, dynamic> ingredient) {
    return ingredient['name']?.toString() ?? '';
  }

  // 类型映射：-1 表示"常用"（特殊类别，不传type参数）
  final List<Map<String, dynamic>> _categories = [
    {'id': 0, 'nameKey': 'CATEGORY_MEAT', 'icon': '🥩', 'type': 0},
    {'id': 1, 'nameKey': 'CATEGORY_SEAFOOD', 'icon': '🦀', 'type': 1},
    {'id': 2, 'nameKey': 'CATEGORY_VEGETABLE', 'icon': '🥬', 'type': 2},
    {'id': 3, 'nameKey': 'CATEGORY_MUSHROOM', 'icon': '🍄', 'type': 3},
    {'id': 4, 'nameKey': 'CATEGORY_BEAN', 'icon': '🫘', 'type': 4},
    {'id': 5, 'nameKey': 'CATEGORY_EGG', 'icon': '🥚', 'type': 5},
    {'id': 6, 'nameKey': 'CATEGORY_FRUIT', 'icon': '🍎', 'type': 6},
    {'id': 7, 'nameKey': 'CATEGORY_NUT', 'icon': '🥜', 'type': 7},
    {'id': 8, 'nameKey': 'CATEGORY_DAIRY', 'icon': '🥛', 'type': 8},
    {'id': 9, 'nameKey': 'CATEGORY_COMMON', 'icon': '⭐', 'type': 9},

  ];

  // 缓存每个类别的食材数据
  final Map<int, List<Map<String, dynamic>>> _cachedIngredients = {};
  // 每个类别的当前页码
  final Map<int, int> _categoryPages = {};
  // 每个类别是否还有更多数据
  final Map<int, bool> _categoryHasMore = {};
  // 记录哪些类别已经加载过
  final Set<int> _loadedCategories = {};

  List<Map<String, dynamic>> _selectedIngredients = [];
  final GlobalKey _selectedListKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  final Map<int, GlobalKey> _ingredientKeys = {};

  @override
  void initState() {
    super.initState();
    _selectedIngredients = List.from(widget.selectedIngredients);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    // 初始化"常用"类别数据（加载type=0的肉类数据，传0）
    _loadCategoryData(0, isInitialLoad: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _updateFilteredIngredients();
    } else {
      setState(() {
        // 在所有已缓存的食材中搜索
        final allCached = _cachedIngredients.values.expand((list) => list).toList();
        _filteredIngredients = allCached.where((ingredient) {
          final name = _getIngredientName(ingredient);
          return name.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final category = _categories[_selectedCategoryIndex];
      final categoryKey = category['id'] as int;
      
      if (_categoryHasMore[categoryKey] == true && !_isLoading) {
        _loadMoreIngredients(categoryKey);
      }
    }
  }

  // 加载指定类别的数据
  Future<void> _loadCategoryData(int categoryIndex, {bool isInitialLoad = false}) async {
    final category = _categories[categoryIndex];
    final categoryKey = category['id'] as int;
    final type = category['type'] as int?;
    
    // 如果已经加载过，直接显示缓存的数据
    if (_loadedCategories.contains(categoryKey) && !isInitialLoad) {
      _updateFilteredIngredients();
      return;
    }

    // 如果是"常用"类别，显示所有已缓存的食材
    if (categoryKey == -1) {
      _updateFilteredIngredients();
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      // "常用"传0，实际请求type=0的肉类数据
      final requestType = isInitialLoad ? 0 : type;
      
      final response = await yifanFoodIngredient(
        1,
        20,
        type: requestType,
      );

      if (response != null && response['content'] != null) {
        final List<dynamic> content = response['content'];
        final ingredients = content.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'name': item['displayName'] ?? item['name'],
            'type': item['type'],
            'imageUrl': item['imageUrl'],
          };
        }).toList();
        setState(() {
          // 初始化或追加数据
          if (_cachedIngredients[categoryKey] == null) {
            _cachedIngredients[categoryKey] = ingredients;
          } else {
            _cachedIngredients[categoryKey]!.addAll(ingredients);
          }

          final int total = (response['total'] ?? 0) as int;
          final int pageSize = (response['pageSize'] ?? 20) as int;

          _categoryPages[categoryKey] = 1;
          _categoryHasMore[categoryKey] = total > pageSize;
          _loadedCategories.add(categoryKey);

          _updateFilteredIngredients();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading category ingredients: $e');
      setState(() => _isLoading = false);
    }
  }

  // 加载更多指定类别的食材
  Future<void> _loadMoreIngredients(int categoryKey) async {
    if (_isLoading || _categoryHasMore[categoryKey] != true) return;

    final category = _categories.firstWhere((c) => c['id'] == categoryKey);
    final type = category['type'] as int?;
    final currentPage = (_categoryPages[categoryKey] ?? 1) + 1;

    try {
      setState(() => _isLoading = true);
      
      final response = await yifanFoodIngredient(
        currentPage,
        20,
        type: type,
      );

      if (response != null && response['content'] != null) {
        final List<dynamic> content = response['content'];
        final ingredients = content.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            // 使用后端返回的 displayName（多语言），未提供时回退到原始 name
            'name': item['displayName'] ?? item['name'],
            'type': item['type'],
            'imageUrl': item['imageUrl'],
          };
        }).toList();

        setState(() {
          _cachedIngredients[categoryKey]!.addAll(ingredients);

          final int total = (response['total'] ?? 0) as int;
          final int pageSize = (response['pageSize'] ?? 20) as int;

          _categoryPages[categoryKey] = currentPage;
          _categoryHasMore[categoryKey] = total > currentPage * pageSize;

          _updateFilteredIngredients();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading more ingredients: $e');
      setState(() => _isLoading = false);
    }
  }

  // 更新筛选后的食材列表
  void _updateFilteredIngredients() {
    final category = _categories[_selectedCategoryIndex];
    final categoryKey = category['id'] as int;

    setState(() {
      if (categoryKey == -1) {
        // "常用"类别：显示所有已缓存的食材（前20个）
        final allCached = _cachedIngredients.values.expand((list) => list).toList();
        _filteredIngredients = allCached.take(20).toList();
      } else {
        // 其他类别：显示对应类别的缓存数据
        _filteredIngredients = _cachedIngredients[categoryKey] ?? [];
      }
    });
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
    _loadCategoryData(index);
  }

  void _addIngredient(Map<String, dynamic> ingredient) {
    // 检查是否已存在
    final exists = _selectedIngredients.any(
      (item) => item['id'] == ingredient['id'],
    );
    
    if (exists) {
      return;
    }

    // 先添加食材到列表
    setState(() {
      _selectedIngredients.add(ingredient);
      // 立即更新父组件的食材列表
      widget.onIngredientsSelected(_selectedIngredients);
    });

    // 等待一帧后执行动画，确保列表已经更新
    final ingredientKey = _ingredientKeys[ingredient['id']];
    if (ingredientKey?.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateIngredientToSelectedList(ingredient, ingredientKey!.currentContext!);
      });
    }
  }

  void _removeIngredient(Map<String, dynamic> ingredient) {
    setState(() {
      _selectedIngredients.removeWhere((item) => item['id'] == ingredient['id']);
      // 立即更新父组件的食材列表
      widget.onIngredientsSelected(_selectedIngredients);
    });
  }

  void _animateIngredientToSelectedList(Map<String, dynamic> ingredient, BuildContext sourceContext) {
    final RenderBox? sourceBox = sourceContext.findRenderObject() as RenderBox?;
    final RenderBox? targetBox = _selectedListKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (sourceBox == null || targetBox == null) return;

    // 获取食材图片的中心位置
    final sourceSize = sourceBox.size;
    final sourcePosition = sourceBox.localToGlobal(Offset(
      sourceSize.width / 2 - 30,
      sourceSize.height / 2 - 30,
    ));
    
    // 计算目标位置（选中列表的右侧末尾，每个item宽64+间距12=76）
    final selectedCount = _selectedIngredients.length - 1; // -1因为已经在列表中了
    final targetX = targetBox.localToGlobal(Offset.zero).dx + 16 + (selectedCount * 76.0) + 32;
    final targetY = targetBox.localToGlobal(Offset.zero).dy + 40;

    // 创建动画widget
    _overlayEntry = OverlayEntry(
      builder: (context) => _FlyingIngredientWidget(
        ingredient: ingredient,
        startPosition: sourcePosition,
        targetPosition: Offset(targetX, targetY),
        onComplete: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  bool _isSelected(Map<String, dynamic> ingredient) {
    return _selectedIngredients.any((item) => item['id'] == ingredient['id']);
  }

  void _showCustomIngredientDialog() {
    final TextEditingController customController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'INGREDIENT'.tr,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: customController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'ENTER_INGREDIENT_NAME'.tr,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0A1628), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _addCustomIngredient(value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'CANCEL'.tr,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (customController.text.trim().isNotEmpty) {
                _addCustomIngredient(customController.text.trim());
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1628),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'ADD'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _addCustomIngredient(String name) {
    // 检查是否已存在相同名称的食材
    final exists = _selectedIngredients.any(
      (item) => item['name']?.toString().toLowerCase() == name.toLowerCase(),
    );
    
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('食材 "$name" 已存在'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    // 创建自定义食材，使用负数id以区分
    final customIngredient = {
      'id': -DateTime.now().millisecondsSinceEpoch, // 使用时间戳作为唯一id
      'name': name,
      'type': null,
      'imageUrl': null, // 自定义食材没有图片
      'isCustom': true, // 标记为自定义食材
    };

    setState(() {
      _selectedIngredients.add(customIngredient);
      // 立即更新父组件的食材列表
      widget.onIngredientsSelected(_selectedIngredients);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加 "$name"'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(

        decoration: const BoxDecoration(
          color:Color.fromARGB(255, 253, 252, 255),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部栏
              _buildHeader(),
              // 搜索框
              _buildSearchBar(),
              // 主要内容区域
              Expanded(
                child: Row(
                  children: [
                    // 左侧分类列表
                    _buildCategoryList(),
                    // 右侧食材列表
                    Expanded(child: _buildIngredientList()),
                  ],
                ),
              ),
              // 已选中食材列表（在自定义添加按钮上方）
              _buildSelectedIngredientsList(),
              // 底部确认按钮
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              // 返回时保存已选择的食材
              widget.onIngredientsSelected(_selectedIngredients);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 8),
          Text(
            'INGREDIENT_LIBRARY'.tr,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedIngredientsList() {
    if (_selectedIngredients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      key: _selectedListKey,
      height: 90, // 增加高度以容纳溢出的删除按钮（64 + 顶部12像素空间 + 底部8像素padding）
      padding: const EdgeInsets.only(top: 6), // 顶部留出更多空间给溢出的删除按钮
      clipBehavior: Clip.none, // 允许溢出内容显示
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 4),
        itemCount: _selectedIngredients.length,
        itemBuilder: (context, index) {
          final ingredient = _selectedIngredients[index];
          return _buildSelectedIngredientItem(ingredient);
        },
      ),
    );
  }

  Widget _buildSelectedIngredientItem(Map<String, dynamic> ingredient) {
    final imageUrl = ingredient['imageUrl'];

    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 64,
      height: 64,
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 食材图片
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.grey,
                            size: 24,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.fastfood,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
            ),
          ),
          // 删除按钮（右上角x）
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: () => _removeIngredient(ingredient),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(left:16,right:16,bottom:16,top:5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'SEARCH_INGREDIENTS'.tr,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topRight:Radius.circular(10) ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategoryIndex == index;
          
          return GestureDetector(
            onTap: () => _onCategorySelected(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color.fromARGB(255, 251, 249, 255) : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSelected ? const Color(0xFF0A1628) : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    category['icon'],
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (category['nameKey'] as String).tr,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? const Color(0xFF0A1628) : Colors.black87,
                      ),
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // if (isLoaded && categoryKey != -1)
                  //   Container(
                  //     margin: const EdgeInsets.only(left: 4),
                  //     width: 6,
                  //     height: 6,
                  //     decoration: const BoxDecoration(
                  //       color: Colors.green,
                  //       shape: BoxShape.circle,
                  //     ),
                  //   ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIngredientList() {
    if (_isLoading && _filteredIngredients.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A1628)),
        ),
      );
    }

    if (_filteredIngredients.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'NO_INGREDIENTS'.tr,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    final category = _categories[_selectedCategoryIndex];
    final categoryKey = category['id'] as int;
    final hasMore = _categoryHasMore[categoryKey] == true;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredIngredients.length + (_isLoading && hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredIngredients.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A1628)),
              ),
            ),
          );
        }

        final ingredient = _filteredIngredients[index];
        final ingredientId = ingredient['id'];
        
        // 为每个食材创建或获取GlobalKey
        if (!_ingredientKeys.containsKey(ingredientId)) {
          _ingredientKeys[ingredientId] = GlobalKey();
        }

        return _buildIngredientItem(ingredient, _ingredientKeys[ingredientId]!);
      },
    );
  }

  Widget _buildIngredientItem(Map<String, dynamic> ingredient, GlobalKey key) {
    final imageUrl = ingredient['imageUrl'] ?? '';
    final isSelected = _isSelected(ingredient);

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 食材图片
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: Icon(Icons.fastfood, color: Colors.grey[400]),
                          );
                        },
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: Icon(Icons.fastfood, color: Colors.grey[400]),
                      ),
              ),
              const SizedBox(width: 12),
              // 食材名称
              Expanded(
                child: Text(
                  _getIngredientName(ingredient),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,

                  ),
                ),
              ),
              // +按钮
              GestureDetector(
                onTap: isSelected ? null : () => _addIngredient(ingredient),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.grey[300] 
                        : const Color(0xFF0A1628),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.check : Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(colors: 
        [Colors.white,Color.fromARGB(255, 253, 252, 255)])
        
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _showCustomIngredientDialog,
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: Text(
              'CUSTOM_ADD'.tr,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1628),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}

// 飞行的食材Widget
class _FlyingIngredientWidget extends StatefulWidget {
  final Map<String, dynamic> ingredient;
  final Offset startPosition;
  final Offset targetPosition;
  final VoidCallback onComplete;

  const _FlyingIngredientWidget({
    required this.ingredient,
    required this.startPosition,
    required this.targetPosition,
    required this.onComplete,
  });

  @override
  State<_FlyingIngredientWidget> createState() => _FlyingIngredientWidgetState();
}

class _FlyingIngredientWidgetState extends State<_FlyingIngredientWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // 位置动画：从起点飞到终点
    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.targetPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    // 缩放动画：先放大再缩小
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.8), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // 透明度动画：逐渐消失
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0),
    ));

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.ingredient['imageUrl'];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx - 30,
          top: _positionAnimation.value.dy - 30,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.fastfood,
                                color: Colors.grey,
                                size: 24,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
