import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:calorie/components/dialog/delete.dart';
import '../../../common/icon/index.dart';
import '../../../network/api.dart';
import 'detail.dart';
import 'package:intl/intl.dart';

class MysteryBoxHistoryPage extends StatefulWidget {
  const MysteryBoxHistoryPage({super.key});

  @override
  State<MysteryBoxHistoryPage> createState() => _MysteryBoxHistoryPageState();
}

class _MysteryBoxHistoryPageState extends State<MysteryBoxHistoryPage> {
  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  
  // 跟踪每个 item 的滑动偏移量，key 为 item 的 id
  final Map<int, double> _swipeOffsets = {};
  int? _activeSwipeId;
  
  // 删除按钮的宽度
  static const double _deleteButtonWidth = 65.0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool loadMore = false}) async {
    if (!mounted) return;

    if (loadMore) {
      if (_isLoadingMore || !_hasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _historyList = [];
        _hasMore = true;
      });
    }

    try {
      final response = await yifanRecipeResponsePage(_currentPage, _pageSize, 2);
      
      if (response != null && response['content'] != null) {
        final List<dynamic> content = response['content'];
        final newItems = content.map<Map<String, dynamic>>((item) => item as Map<String, dynamic>).toList();
        
        if (mounted) {
          setState(() {
            if (loadMore) {
              _historyList.addAll(newItems);
            } else {
              _historyList = newItems;
            }
            _hasMore = newItems.length >= _pageSize;
            _currentPage = loadMore ? _currentPage + 1 : 2;
            _isLoading = false;
            _isLoadingMore = false;
            _error = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
            _hasMore = false;
          });
        }
      }
    } catch (e) {
      print('Error loading history: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _loadMore() {
    if (!_isLoadingMore && _hasMore) {
      _loadHistory(loadMore: true);
    }
  }

  void _onRefresh() {
    _loadHistory(loadMore: false);
  }

  Future<bool> _deleteItem(Map<String, dynamic> item) async {
    final int? itemId = item['id'] is int ? item['id'] as int : null;
    if (itemId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CANNOT_GET_ITEM_ID'.tr)),
        );
      }
      return false;
    }

    // 显示确认对话框
    final bool? confirmed = await showDeleteConfirmDialog(context);

    if (confirmed != true) return false;

    try {
      await yifanRecipeResponseDelete(itemId);
      
      if (mounted) {
        setState(() {
          _historyList.removeWhere((element) => element['id'] == itemId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DELETE_SUCCESS'.tr),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return true;
    } catch (e) {
      print('Error deleting item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'DELETE_FAILED'.tr}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  void _closeAllSwipes() {
    setState(() {
      _swipeOffsets.clear();
      _activeSwipeId = null;
    });
  }

  String _mealTypeToString(int? mealType) {
    switch (mealType) {
      case 1:
        return 'breakfast';
      case 2:
        return 'lunch';
      case 3:
        return 'dinner';
      default:
        return 'lunch';
    }
  }

  String _mealTypeToDisplayName(int? mealType) {
    switch (mealType) {
      case 1:
        return 'MYSTERY_BOX_MEAL_BREAKFAST'.tr;
      case 2:
        return 'MYSTERY_BOX_MEAL_LUNCH'.tr;
      case 3:
        return 'MYSTERY_BOX_MEAL_DINNER'.tr;
      default:
        return 'MYSTERY_BOX_MEAL_LUNCH'.tr;
    }
  }

  void _onItemTap(Map<String, dynamic> item) {
    // 先收起所有已展开的 item
    _closeAllSwipes();
    final Map<String, dynamic>? responseDto = item['responseDto'] as Map<String, dynamic>?;
    if (responseDto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('MYSTERY_BOX_DETAIL_ERROR'.tr)),
      );
      return;
    }

    final String? imageUrl = responseDto['imageUrl']?.toString();
    final int? mealType = item['mealType'] is int ? item['mealType'] as int : null;
    final String? prompt = item['prompt']?.toString();
    final List<String> dishes = item['ingredientList'] != null
        ? List<String>.from(item['ingredientList'] as List)
        : [];

    
    // 获取营养分析数据
    final Map<String, dynamic>? nutritionAnalysis = responseDto['nutritionAnalysis'] as Map<String, dynamic>?;
    
    // 构建营养数据（与 yifanRandomMealNutrition 返回的格式一致）
    Map<String, dynamic>? initialNutrition;
    if (nutritionAnalysis != null) {
      initialNutrition = {
        'locale': responseDto['locale']?.toString() ?? 'en_US',
        'nutritionAnalysis': nutritionAnalysis,
      };
    }

    // 获取 mealName，如果没有则使用默认值
    String mealName = item['meal_name']?.toString() ?? '';
    if (mealName.isEmpty) {
      mealName = _mealTypeToDisplayName(mealType);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MysteryMealDetailPage(
          imageUrl: imageUrl ?? '',
          dishes: dishes,
          mealType: _mealTypeToString(mealType),
          prompt: prompt,
          mealName: mealName,
          initialNutrition: initialNutrition,
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'JUST_NOW'.tr;
          }
          return '${difference.inMinutes} ${'MINUTES_AGO'.tr}';
        }
        return '${difference.inHours} ${'HOURS_AGO'.tr}';
      } else if (difference.inDays == 1) {
        return 'YESTERDAY'.tr;
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ${'DAYS_AGO'.tr}';
      } else {
        return DateFormat('yyyy-MM-dd').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(AliIcon.back, color: Colors.black87, size: 30),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 24,
        ),
        Text(
          'MYSTERY_BOX_HISTORY'.tr,
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

  void _onHorizontalDragStart(int itemId, DragStartDetails details) {
    setState(() {
      _activeSwipeId = itemId;
      final keys = List<int>.from(_swipeOffsets.keys);
      for (final key in keys) {
        if (key != itemId && (_swipeOffsets[key] ?? 0) != 0) {
          _swipeOffsets[key] = 0.0;
        }
      }
    });
  }

  void _onHorizontalDragUpdate(int itemId, DragUpdateDetails details) {
    setState(() {
      final double currentOffset = _swipeOffsets[itemId] ?? 0.0;
      double newOffset = currentOffset + details.delta.dx;
      
      // 限制滑动范围：向左滑动最多到 -_deleteButtonWidth，向右滑动最多到 0
      newOffset = newOffset.clamp(-_deleteButtonWidth, 0.0);
      _swipeOffsets[itemId] = newOffset;
    });
  }

  void _onHorizontalDragEnd(int itemId) {
    setState(() {
      final double currentOffset = _swipeOffsets[itemId] ?? 0.0;
      
      // 如果滑动超过一半，自动展开；否则自动收起
      if (currentOffset < -_deleteButtonWidth / 2) {
        _swipeOffsets[itemId] = -_deleteButtonWidth;
        _activeSwipeId = itemId;
      } else {
        _swipeOffsets[itemId] = 0.0;
        if (_activeSwipeId == itemId) {
          _activeSwipeId = null;
        }
      }
    });
  }

  void _closeSwipe(int itemId) {
    setState(() {
      _swipeOffsets[itemId] = 0.0;
      if (_activeSwipeId == itemId) {
        _activeSwipeId = null;
      }
    });
  }

  void _onDeleteButtonTap(Map<String, dynamic> item) {
    _deleteItem(item).then((success) {
      if (success) {
        final int? itemId = item['id'] is int ? item['id'] as int : null;
        if (itemId != null) {
          _swipeOffsets.remove(itemId);
          if (_activeSwipeId == itemId) {
            _activeSwipeId = null;
          }
        }
      }
    });
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final Map<String, dynamic>? responseDto = item['responseDto'] as Map<String, dynamic>?;
    final String? imageUrl = responseDto?['imageUrl']?.toString();
    final int? mealType = item['mealType'] is int ? item['mealType'] as int : null;
    final String mealName = item['meal_name'] ?? "";
    final String mealTypeName = _mealTypeToDisplayName(mealType);
    final String createDate = _formatDate(item['createDate']?.toString());
    final int? itemId = item['id'] is int ? item['id'] as int : null;
    
    // 获取营养分析数据用于显示
    final Map<String, dynamic>? nutritionAnalysis = responseDto?['nutritionAnalysis'] as Map<String, dynamic>?;
    final Map<String, dynamic>? nutrition = nutritionAnalysis?['nutrition'] as Map<String, dynamic>?;
    final double? calories = nutrition?['calories'] is num ? (nutrition!['calories'] as num).toDouble() : null;
    
    if (itemId == null) {
      return const SizedBox.shrink();
    }
    
    final double offset = _swipeOffsets[itemId] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 120,
      child: Stack(
        children: [
          // 删除按钮背景（在 item 后面）
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              child: Container(
                width: _deleteButtonWidth - 5,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 240, 240),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _onDeleteButtonTap(item),
                  child: const Center(
                    child: Icon(
                      Icons.delete_outline,
                      color: Color.fromARGB(255, 255, 22, 22),
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 可滑动的内容项
          GestureDetector(
            onHorizontalDragStart: (details) =>
                _onHorizontalDragStart(itemId, details),
            onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(itemId, details),
            onHorizontalDragEnd: (_) => _onHorizontalDragEnd(itemId),
            onTap: () {
              // 如果当前是展开状态，点击收起；否则跳转详情
              if (offset < 0) {
                _closeSwipe(itemId);
              } else {
                _onItemTap(item);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(offset, 0, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 图片
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Image.network(
                          imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: const Color(0xFFF7F7FA),
                              child: const Icon(Icons.image_not_supported, color: Colors.black38),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF7F7FA),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        child: const Icon(Icons.restaurant_menu, color: Colors.black38, size: 40),
                      ),
                    
                    // 内容
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 标题（餐类型）
                            Text(
                              mealName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            
                            // 标签
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 173, 255, 194).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.restaurant_menu, size: 12, color: Color.fromARGB(255, 120, 208, 125)),
                                      const SizedBox(width: 4),
                                      Text(
                                        mealTypeName,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color.fromARGB(255, 120, 208, 125),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (calories != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.local_fire_department, size: 12, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${calories.toStringAsFixed(calories % 1 == 0 ? 0 : 0)} kcal',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            
                            // 创建时间
                            Text(
                              createDate,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
              Color.fromARGB(255, 234, 255, 230),
              Color.fromARGB(255, 249, 255, 249),
              Color.fromARGB(255, 243, 255, 241),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: _buildHeader(),
              ),
              
              // Content
              Expanded(
                child: _isLoading && _historyList.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 120, 208, 125)),
                        ),
                      )
                    : _error != null && _historyList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  'LOAD_FAILED'.tr,
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
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _onRefresh,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 120, 208, 125),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('RETRY'.tr),
                                ),
                              ],
                            ),
                          )
                        : _historyList.isEmpty
                            ? Center(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 150),
                                    Image.asset(
                                      'assets/image/rice.png',
                                      height: 100,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'NO_HISTORY_RECORDS'.tr,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color.fromARGB(255, 154, 148, 141),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'HISTORY_EMPTY_MESSAGE'.tr,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color.fromARGB(255, 154, 148, 141),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width: 150,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(255, 34, 32, 30),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'EXPLORE_RECIPES'.tr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  _onRefresh();
                                },
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    // 滚动时收起所有已展开的 item
                                    if (notification is ScrollUpdateNotification) {
                                      _closeAllSwipes();
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  itemCount: _historyList.length + (_hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _historyList.length) {
                                      // 加载更多指示器
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        _loadMore();
                                      });
                                      return const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    }
                                    return _buildHistoryItem(_historyList[index]);
                                  },
                                ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

