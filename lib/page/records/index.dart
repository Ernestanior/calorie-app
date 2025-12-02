import 'dart:collection';
import 'package:calorie/common/icon/index.dart';
import 'package:calorie/common/util/constants.dart';
import 'package:calorie/main.dart';
import 'package:calorie/network/api.dart';
import 'package:calorie/store/store.dart';
import 'package:calorie/components/dialog/delete.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Records extends StatefulWidget {
  const Records({super.key});

  @override
  State<Records> createState() => _RecordsState();
}

class _RecordsState extends State<Records>
    with SingleTickerProviderStateMixin, RouteAware {
  List<dynamic> allRecords = [];
  bool isLoading = false;
  bool isLastPage = false;
  int page = 1;
  final int pageSize = 8;
  final ScrollController _scrollController = ScrollController();

  final Map<String, List<dynamic>> groupedRecords = LinkedHashMap();
  final Map<String, bool> sectionExpanded = {
    'TODAY': true,
    'LAST_7_DAYS': true,
    'THIS_MONTH': true,
    'EARLIER': true,
  };
  
  // 跟踪每个 item 的滑动偏移量，key 为 item 的 id
  final Map<int, double> _swipeOffsets = {};
  
  // 当前展示删除按钮的 item
  int? _activeSwipeId;
  
  // 删除按钮的宽度
  static const double _deleteButtonWidth = 65.0;

  @override
  void initState() {
    super.initState();
    fetchData();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isLoading &&
        !isLastPage) {
      page++;
      fetchData();
    }
  }

  @override
  void didPopNext() {
    // 从页面B返回后触发
    fetchData(isRefresh: true); // 重新拉取数据
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 注册路由观察者
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  Future<void> fetchData({bool isRefresh = false}) async {
    if (isLoading) return;
    isLoading = true;

    if (isRefresh) {
      page = 1;
      allRecords.clear();
      groupedRecords.clear();
      isLastPage = false;
    }

    try {
      final res = await detectionList(page, pageSize);
      print(res);
      if (res == "-1") {
        isLoading = false;
        if (mounted) setState(() {});
        return;
      }
      
      // 安全地获取分页信息
      final int totalPage = res?['totalPages'] ?? 0;
      final int currentPage = res?['number'] ?? 0;
      final List<dynamic> fetched = res?['content'] ?? [];

      if (totalPage <= currentPage + 1) isLastPage = true;

      allRecords.addAll(fetched);
      groupRecords();
    } catch (e) {
      print('Error fetching data: $e');
      // 即使出错也继续，避免灰屏
    } finally {
      isLoading = false;
      if (mounted) setState(() {});
    }
  }

  void groupRecords() {
    groupedRecords.clear();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d7 = today.subtract(const Duration(days: 7));

    for (var item in allRecords) {
      try {
        final createDateStr = item['createDate'];
        if (createDateStr == null || createDateStr.toString().isEmpty) {
          continue; // 跳过无效的日期数据
        }
        final createDate = DateTime.parse(createDateStr.toString());
        String key;
        if (createDate.isAfter(today)) {
          key = 'TODAY';
        } else if (createDate.isAfter(d7)) {
          key = 'LAST_7_DAYS';
        } else if (createDate.year == now.year && createDate.month == now.month) {
          key = 'THIS_MONTH';
        } else {
          key = 'EARLIER';
        }
        groupedRecords.putIfAbsent(key, () => []).add(item);
      } catch (e) {
        print('Error grouping record: $e');
        // 跳过有问题的记录，继续处理其他记录
        continue;
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);

    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MEAL_RECORDS'.tr,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: const BackButton(),
      ),
      body: RefreshIndicator(
        onRefresh: () => fetchData(isRefresh: true),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // 滚动时收起所有已展开的 item
            if (notification is ScrollUpdateNotification) {
              _closeAllSwipes();
            }
            return false;
          },
          child: ListView(
            controller: _scrollController,
            children: [
              for (String key in [
                'TODAY',
                'LAST_7_DAYS',
                'THIS_MONTH',
                'EARLIER'
              ])
                if (groupedRecords[key]?.isNotEmpty ?? false)
                  buildSection(key, groupedRecords[key]!),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (isLastPage && allRecords.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("No more records")),
                ),
              if (allRecords.isEmpty && !isLoading) _buildEmpty(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSection(String key, List<dynamic> items) {
    final title = key.tr;
    final expanded = sectionExpanded[key] ?? true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          onTap: () => setState(() {
            sectionExpanded[key] = !expanded;
          }),
        ),
        if (expanded) ...items.map((item) => buildRecordCard(item)).toList(),
      ],
    );
  }

  Widget buildRecordCard(dynamic item) {
    // 安全地获取数据，使用默认值
    final mealType = item?['mealType'];
    final meal = mealType != null ? mealInfoMap[mealType] : null;
    
    // 安全地获取 detectionResultData
    final detectionResultData = item?['detectionResultData'];
    final total = detectionResultData?['total'] ?? {};
    
    // 安全地获取 dishName
    final dishNameRaw = total?['dishName'];
    final dishName = (dishNameRaw != null && dishNameRaw.toString().isNotEmpty)
        ? dishNameRaw.toString()
        : 'UNKNOWN_FOOD'.tr;
    
    // 安全地获取营养数据，使用默认值 0
    final calories = _safeGetNum(total?['calories']) ?? 0;
    final fat = _safeGetNum(total?['fat']) ?? 0;
    final protein = _safeGetNum(total?['protein']) ?? 0;
    final carbs = _safeGetNum(total?['carbs']) ?? 0;
    
    // 安全地获取图片 URL
    final sourceImg = item?['sourceImg'];
    final imageUrl = (sourceImg != null && sourceImg.toString().isNotEmpty)
        ? sourceImg.toString()
        : null;

    // 获取 item id
    final int? itemId = item?['id'];
    if (itemId == null) {
      // 如果没有 id，返回普通卡片（不支持删除）
      return _buildCardContent(item, meal, dishName, calories, fat, protein, carbs, imageUrl);
    }

    final double offset = _swipeOffsets[itemId] ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      height: 110,
      child: Stack(
        children: [
          // 删除按钮背景（在 item 后面）
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              child: Container(
                width: _deleteButtonWidth-5,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
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
                try {
                  Controller.c.foodDetail(item);
                  Navigator.pushNamed(context, '/foodDetail');
                } catch (e) {
                  print('Error navigating to food detail: $e');
                }
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(offset, 0, 0),
              child: _buildCardContent(item, meal, dishName, calories, fat, protein, carbs, imageUrl),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(dynamic item, dynamic meal, String dishName, 
      num calories, num fat, num protein, num carbs, String? imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 237, 242, 255),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[200],
            ),
            clipBehavior: Clip.hardEdge,
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // 图片加载失败时显示默认图标
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.restaurant_menu,
                          size: 40,
                          color: Colors.grey,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(dishName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        Row(children: [
                          const Icon(AliIcon.calorie,
                              size: 18, color: Colors.orange),
                          Text("$calories ${'KCAL'.tr}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ]),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: meal?['color'] ?? Colors.blueAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(meal?['label'] ?? 'DINNER'.tr,
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(AliIcon.fat, size: 16, color: Colors.amber),
                      Text(" $protein${'G'.tr}",
                          style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 10),
                      const Icon(AliIcon.dinner4,
                          size: 16, color: Colors.lightBlue),
                      Text(" $carbs${'G'.tr}",
                          style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 10),
                      const Icon(AliIcon.meat2,
                          size: 16, color: Colors.redAccent),
                      Text(" $fat${'G'.tr}",
                          style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // 辅助方法：安全地获取数字值
  num? _safeGetNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      return parsed;
    }
    return null;
  }

  // 滑动处理方法
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

  void _closeAllSwipes() {
    setState(() {
      _swipeOffsets.clear();
      _activeSwipeId = null;
    });
  }

  // 删除记录
  Future<bool> _deleteItem(dynamic item) async {
    final int? itemId = item?['id'];
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
      await detectionDelete(itemId);
      
      if (mounted) {
        // 从列表中移除该项
        allRecords.removeWhere((element) => element['id'] == itemId);
        // 重新分组
        groupRecords();
        // 移除滑动状态
        _swipeOffsets.remove(itemId);
        
        setState(() {});
        
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

  void _onDeleteButtonTap(dynamic item) {
    _deleteItem(item).then((success) {
      if (success) {
        final int? itemId = item?['id'];
        if (itemId != null) {
          _swipeOffsets.remove(itemId);
          if (_activeSwipeId == itemId) {
            _activeSwipeId = null;
          }
        }
      }
    });
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: 300,
      child: Center(
          child: Column(children: [
        const SizedBox(height: 100),
        Image.asset('assets/image/rice.png', height: 100),
        const SizedBox(height: 20),
        Text(
          'NO_RECORDS'.tr,
          style: const TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 115, 115, 115),
          ),
        ),
        const SizedBox(height: 10),
      ])),
    );
  }
}
