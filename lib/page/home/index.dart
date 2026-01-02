import 'dart:io';
import 'dart:math';
import 'package:calorie/common/icon/index.dart';
import 'package:calorie/common/util/constants.dart';
import 'package:calorie/components/dialog/delete.dart';
import 'package:calorie/components/imgSwitcher/index.dart';
import 'package:calorie/components/lottieFood/index.dart';
import 'package:calorie/main.dart';
import 'package:calorie/network/api.dart';
import 'package:calorie/store/store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with SingleTickerProviderStateMixin, RouteAware {
  int currentDay = DateTime.now().weekday % 7;
  DateTime now = DateTime.now();
  DateTime currentDate = DateTime.now();
  dynamic dailyData = {'fats': 0, 'carbs': 0, 'calories': 0, 'protein': 0,'sugar': 0, 'fiber': 0};
  List record = [];
  late Worker _homeDataWorker;
  Worker? _userReadyWorker;
  Worker? _analyzingWorker;
  bool _showMonthPicker = false;
  bool _isLoadingRecords = false; // 日记录请求加载状态
  late AnimationController _animationController;
  late Animation<double> _animation;
  DateTime _displayMonth = DateTime.now(); // 月份选择器当前显示的月份
  bool _initialFetchDone = false; // 首次加载是否已完成
  final Map<int, double> _swipeOffsets = {};
  int? _activeSwipeId;
  static const double _deleteButtonWidth = 65.0;

  int? _getUserIdSafe() {
    try {
      final dynamic userState = Controller.c.user;
      final dynamic idVal = userState['id'];
      if (idVal is int && idVal > 0) return idVal;
      return null;
    } catch (_) {
      return null;
    }
  }

  // 该月内有记录的日期集合与计数
  final Set<String> _recordedDays = <String>{};
  final Map<String, int> _recordedCount = <String, int>{};

  // 统一将 DateTime 转为 yyyy-MM-dd 字符串（零补齐）
  String _toYmd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // 计算热量占比，空值或非法值时返回 0，避免空指针/除零
  double _calcCaloriePercent() {
    final num calories =
        dailyData['calories'] is num ? dailyData['calories'] as num : 0;
    final num target = Controller.c.user['dailyCalories'] is num
        ? Controller.c.user['dailyCalories'] as num
        : 0;
    if (target <= 0) return 0;
    final double ratio = calories / target;
    // clamp to 0-1 for percent indicator
    return ratio.clamp(0, 1).toDouble();
  }

  void _onRecordHorizontalDragStart(int itemId, DragStartDetails details) {
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

  void _onRecordHorizontalDragUpdate(int itemId, DragUpdateDetails details) {
    setState(() {
      final double currentOffset = _swipeOffsets[itemId] ?? 0.0;
      double newOffset = currentOffset + details.delta.dx;
      newOffset = newOffset.clamp(-_deleteButtonWidth, 0.0);
      _swipeOffsets[itemId] = newOffset;
    });
  }

  void _onRecordHorizontalDragEnd(int itemId) {
    setState(() {
      final double currentOffset = _swipeOffsets[itemId] ?? 0.0;
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

  void _closeRecordSwipe(int itemId) {
    setState(() {
      _swipeOffsets[itemId] = 0.0;
      if (_activeSwipeId == itemId) {
        _activeSwipeId = null;
      }
    });
  }

  Future<bool> _deleteRecordItem(dynamic item) async {
    final int? itemId = item?['id'] is int
        ? item['id'] as int
        : (item?['id'] is String ? int.tryParse(item['id'].toString()) : null);
    if (itemId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CANNOT_GET_ITEM_ID'.tr)),
        );
      }
      return false;
    }

    final bool? confirmed = await showDeleteConfirmDialog(context);
    if (confirmed != true) return false;

    try {
      await detectionDelete(itemId);
      if (mounted) {
        setState(() {
          record.removeWhere((element) => element['id'] == itemId);
          _swipeOffsets.remove(itemId);
          if (_activeSwipeId == itemId) {
            _activeSwipeId = null;
          }
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

  void _onRecordDeleteTap(dynamic item) {
    _deleteRecordItem(item);
  }

  // 读取用户创建日期（仅日期部分），用于限制可选范围
  DateTime? _getUserCreateDateOnly() {
    try {
      final dynamic user = Controller.c.user;
      final dynamic raw = user['createDate'];
      if (raw is String && raw.isNotEmpty) {
        // 期望格式: yyyy-MM-dd HH:mm:ss
        final String normalized = raw.replaceAll('/', '-');
        final String datePart = normalized.split(' ').first;
        final parts = datePart.split('-');
        if (parts.length >= 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final da = int.tryParse(parts[2]);
          if (y != null && m != null && da != null) {
            return DateTime(y, m, da);
          }
        }
      }
    } catch (_) {}
    return null; // 返回空表示不限制
  }

  @override
  void initState() {
    super.initState();
    // 如果用户ID已就绪，直接拉取；否则监听用户信息变化，等ID到位后再拉取一次
    final int? readyId = _getUserIdSafe();
    print('readyId $readyId');
    if (readyId != null) {
      _initialFetchDone = true;
      fetchData(now);
      _fetchMonthDetections(DateTime(currentDate.year, currentDate.month));
    } else {
      _userReadyWorker = ever<dynamic>(Controller.c.user, (dynamic u) {
        final int? uid = _getUserIdSafe();
        if (!_initialFetchDone && uid != null) {
          _initialFetchDone = true;
          fetchData(now);
          _fetchMonthDetections(DateTime(currentDate.year, currentDate.month));
        }
      });
    }

    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // 监听触发器，触发后刷新数据
    // 保存 worker 引用
    _homeDataWorker = ever(Controller.c.refreshHomeDataTrigger, (triggered) {
      if (triggered == true) {
        setState(() {
          currentDate= DateTime.now();
          currentDay=DateTime.now().weekday % 7;
        });
        fetchData(DateTime.now());
        _fetchMonthDetections(DateTime(currentDate.year, currentDate.month));
        Controller.c.refreshHomeDataTrigger.value = false;
      }
    });

    // 当分析状态从 true 切换为 false 时，立即刷新当日记录，避免短暂出现“无记录”引导卡片
    _analyzingWorker = ever<bool>(Controller.c.isAnalyzing, (bool analyzing) {
      if (!analyzing && mounted) {
        setState(() {
          _isLoadingRecords = true;
        });
        fetchData(currentDate);
      }
    });
  }

  // 拉取某个月份的记录分布
  Future<void> _fetchMonthDetections(DateTime month) async {
    // 若用户ID未就绪，直接跳过
    final int? userId = _getUserIdSafe();
    if (userId == null) return;

    final DateTime firstDay = DateTime(month.year, month.month, 1);
    final DateTime lastDay = DateTime(month.year, month.month + 1, 0);
    final String start = DateFormat('yyyy-MM-dd').format(firstDay);
    final String end = DateFormat('yyyy-MM-dd').format(lastDay);
    try {
      final List<dynamic> res = await detectionForMonth(start, end);
      _recordedDays.clear();
      _recordedCount.clear();
      for (final item in res) {
        try {
          final dynamic raw = item['date'];
          final int count = (item['detectionTimes'] ?? 0) as int;
          DateTime? d;
          if (raw is String) {
            d = DateTime.tryParse(raw);
            if (d == null) {
              // 兼容例如 yyyy-M-d 或使用斜线分隔
              final String norm = raw.replaceAll('/', '-');
              final parts = norm.split('-');
              if (parts.length >= 3) {
                final y = int.tryParse(parts[0]);
                final m = int.tryParse(parts[1]);
                final da = int.tryParse(parts[2]);
                if (y != null && m != null && da != null) {
                  d = DateTime(y, m, da);
                }
              }
            }
          } else if (raw is DateTime) {
            d = raw;
          }
          if (d != null) {
            final String key = DateFormat('yyyy-MM-dd').format(d);
            _recordedDays.add(key);
            _recordedCount[key] = count;
          }
        } catch (_) {}
      }
      if (mounted) setState(() {});
    } catch (e) {
      // 忽略该月标记失败，不影响其它功能
    }
  }

  Future<void> fetchData(DateTime date) async {
    // 若用户ID未就绪，直接返回，不请求
    final int? userId = _getUserIdSafe();
    if (userId == null) return;
    if (mounted) {
      setState(() {
        _isLoadingRecords = true;
      });
    }
    try {
      await userSummaryResult(DateFormat('yyyy-MM-dd').format(date));

      final dailyRes =
          await dailyRecordResult(userId, DateFormat('yyyy-MM-dd').format(date));
      final recordsRes = await detectionListResult(1, 18,
          date: DateFormat('yyyy-MM-dd').format(date));

      if (!mounted) return;
      if (dailyRes.ok && dailyRes.data != null) {
        setState(() {
          dailyData = dailyRes.data;
        });
      }
      if (recordsRes.ok) {
        setState(() {
          record = recordsRes.data?['content'] ?? [];
        });
      }
    } catch (e) {
      print('$e error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecords = false;
        });
      }
    }

    // final dayList = await detectionList();
  }

  @override
  void didPopNext() {
    // 从页面B返回后触发
    fetchData(currentDate); // 重新拉取数据
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 注册路由观察者
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _homeDataWorker.dispose(); // ✅ 取消监听，防止页面销毁后还触发回调
    try {
      _userReadyWorker?.dispose();
      _analyzingWorker?.dispose();
    } catch (_) {}
    _animationController.dispose(); // 释放动画控制器
    // 移除观察者
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // 判断两个日期是否为同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // 全屏背景，延伸到安全区域
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 191, 212, 255),
                  Color.fromARGB(255, 175, 195, 255),
                  Color.fromARGB(255, 191, 222, 255),
                  Color.fromARGB(255, 205, 230, 255),
                  Color.fromARGB(255, 212, 235, 255),
                  Color.fromARGB(255, 249, 238, 255),
                  Colors.white,
                  Colors.white
                ],
              ),
            ),
          ),
          // 主要内容，延伸到安全区域，但内容有额外的padding
          SingleChildScrollView(
            child: Column(
              children: [
                // 顶部安全区域的内容延伸
                Container(
                  height: MediaQuery.of(context).padding.top - 10,
                  color: Colors.transparent,
                ),
                // 实际内容区域
                Column(
                  children: [
                    _buildAppBar(),
                    _buildDateSelector(),
                    const SizedBox(height: 5),
                    _buildSummaryCard(),
                    _buildNutrientCards(),
                    _buildHistoryRecord(),
                  ],
                ),
                // 底部安全区域的内容延伸
                Container(
                  height: MediaQuery.of(context).padding.bottom,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),
          // 顶部安全区域渐变遮罩
          if (MediaQuery.of(context).padding.top > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).padding.top,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color.fromARGB(255, 171, 199, 255).withOpacity(1),
                      const Color.fromARGB(255, 171, 199, 255).withOpacity(1),
                      const Color.fromARGB(255, 171, 199, 255).withOpacity(0.9),
                      const Color.fromARGB(255, 171, 199, 255).withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          // 底部安全区域渐变遮罩
          if (MediaQuery.of(context).padding.bottom > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).padding.bottom,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white.withOpacity(1),
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.6),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          // 全屏点击区域，用于隐藏月份选择器
          if (_showMonthPicker)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showMonthPicker = false;
                    _animationController.reverse();
                  });
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          // 浮动的月份选择器（放在全屏点击区域之上）
          if (_showMonthPicker)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100, // 在日期选择器下方
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  // 阻止事件冒泡到全屏点击区域
                },
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animation.value,
                      child: Opacity(
                        opacity: _animation.value,
                        child: _buildMonthPicker(),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text(
            'Vita AI',
            style: GoogleFonts.afacad(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    List<String> days = [
      'SUNDAY'.tr,
      'MONDAY'.tr,
      'TUESDAY'.tr,
      'WEDNESDAY'.tr,
      'THURSDAY'.tr,
      'FRIDAY'.tr,
      'SATURDAY'.tr
    ];
    DateTime now = DateTime.now(); // 当前日期
    // 根据当前选择的日期计算周日期
    List<int> dates = List.generate(
        7,
        (index) => currentDate
            .subtract(Duration(days: currentDate.weekday % 7 - index))
            .day);
    List<DateTime> fullDates = List.generate(
        7,
        (index) => currentDate.subtract(
            Duration(days: currentDate.weekday % 7 - index))); // 计算完整日期

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(100, 255, 255, 255),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            width: 1, color: const Color.fromARGB(150, 255, 255, 255)),
      ),
      margin: const EdgeInsets.only(top: 6, bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.only(top: 5, bottom: 5, left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ...List.generate(7, (index) {
            bool isFutureDate = fullDates[index].isAfter(now); // 判断是否是未来日期
            bool isSelected = _isSameDay(fullDates[index], currentDate);
            final String ymd = _toYmd(fullDates[index]);
            final bool hasRecord = _recordedDays.contains(ymd);
            final DateTime? createDateOnly = _getUserCreateDateOnly();
            final DateTime? minSelectableDay = createDateOnly == null
                ? null
                : DateTime(createDateOnly.year, createDateOnly.month,
                    createDateOnly.day);
            final bool isBeforeCreate = minSelectableDay != null
                ? fullDates[index].isBefore(minSelectableDay)
                : false;

            return Expanded(
              child: GestureDetector(
                onTap: (isFutureDate || isBeforeCreate)
                    ? null
                    : () {
                        // 未来日期禁用点击
                        fetchData(fullDates[index]);
                        setState(() {
                          currentDate = fullDates[index];
                          currentDay = index;
                          // 隐藏月份选择器
                          _showMonthPicker = false;
                          _animationController.reverse();
                        });
                        // 切换周/日后刷新对应月份的分布
                        _fetchMonthDetections(
                            DateTime(currentDate.year, currentDate.month));
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected && !isFutureDate
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected && !isFutureDate
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        days[index],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: (isFutureDate || isBeforeCreate)
                              ? Colors.grey
                              : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dates[index]}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: (isFutureDate || isBeforeCreate)
                              ? Colors.grey
                              : Colors.black,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        AliIcon.check2,
                        size: 15,
                        color: (isFutureDate || isBeforeCreate)
                            ? Colors.grey[300]
                            : (hasRecord
                                ? const Color(0xFF22C55E)
                                : Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
              GestureDetector(
            onTap: () {
              setState(() {
                _showMonthPicker = !_showMonthPicker;
                if (_showMonthPicker) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _showMonthPicker ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _showMonthPicker
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.black,
                size: 18,
              ),
            ),
          ),
        
          
          // 下拉按钮
        ],
      ),
    );
  }

  Widget _buildMonthPicker() {
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth =
        DateTime(_displayMonth.year, _displayMonth.month, 1);
    DateTime lastDayOfMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0);
    int daysInMonth = lastDayOfMonth.day;

    // 计算月份第一天是星期几 (0=周日, 1=周一, ..., 6=周六)
    int firstDayWeekday = firstDayOfMonth.weekday % 7;

    // 生成该月所有日期
    List<DateTime> monthDates = List.generate(daysInMonth, (index) {
      return DateTime(_displayMonth.year, _displayMonth.month, index + 1);
    });

    // 创建完整的网格数据，包含空白占位符
    List<Widget> gridItems = [];

    // 添加空白占位符，使第一天对齐到正确的星期
    for (int i = 0; i < firstDayWeekday; i++) {
      gridItems.add(Container()); // 空白占位符
    }

    // 添加实际日期
    final DateTime? createDateOnly = _getUserCreateDateOnly();
    final DateTime? minSelectableDay = createDateOnly == null
        ? null
        : DateTime(
            createDateOnly.year, createDateOnly.month, createDateOnly.day);
    for (DateTime date in monthDates) {
      bool isFutureDate = date.isAfter(now);
      bool isSelected = _isSameDay(date, currentDate);
      bool isBeforeCreate =
          minSelectableDay != null ? date.isBefore(minSelectableDay) : false;
      final String ymd = _toYmd(date);
      final bool hasRecord = _recordedDays.contains(ymd);

      gridItems.add(
        GestureDetector(
          onTap: (isFutureDate || isBeforeCreate)
              ? null
              : () {
                  fetchData(date);
                  setState(() {
                    currentDate = date;
                    _showMonthPicker = false; // 选择后关闭月份选择器
                  });
                  _animationController.reverse();
                  // 切换日期后刷新对应月份的分布
                  _fetchMonthDetections(
                      DateTime(currentDate.year, currentDate.month));
                },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white
                        : ((isFutureDate || isBeforeCreate)
                            ? Colors.grey
                            : Colors.black),
                  ),
                ),
                const SizedBox(height: 2),
                (isFutureDate || isBeforeCreate)
                    ? const SizedBox(height: 13)
                    : Icon(
                        AliIcon.check2,
                        size: 13,
                        color: isSelected
                            ? (hasRecord ? Colors.white : Colors.grey[500])
                            : (hasRecord
                                ? const Color(0xFF22C55E)
                                : Colors.grey[300]),
                      )
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            width: 1, color: const Color.fromARGB(150, 255, 255, 255)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 月份标题和切换按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 后退按钮
              GestureDetector(
                onTap: () {
                  final DateTime? cd = _getUserCreateDateOnly();
                  final DateTime currentFirst =
                      DateTime(_displayMonth.year, _displayMonth.month, 1);
                  final bool canGoPrev = cd == null
                      ? true
                      : currentFirst.isAfter(DateTime(cd.year, cd.month, 1));
                  if (!canGoPrev) return;
                  setState(() {
                    _displayMonth =
                        DateTime(_displayMonth.year, _displayMonth.month - 1);
                  });
                  _fetchMonthDetections(_displayMonth);
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: () {
                      final DateTime? cd = _getUserCreateDateOnly();
                      final DateTime currentFirst =
                          DateTime(_displayMonth.year, _displayMonth.month, 1);
                      final bool disabled = cd != null &&
                          !currentFirst.isAfter(DateTime(cd.year, cd.month, 1));
                      return disabled ? Colors.grey[100] : Colors.grey[200];
                    }(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(AliIcon.left, size: 18, color: () {
                    final DateTime? cd = _getUserCreateDateOnly();
                    final DateTime currentFirst =
                        DateTime(_displayMonth.year, _displayMonth.month, 1);
                    final bool disabled = cd != null &&
                        !currentFirst.isAfter(DateTime(cd.year, cd.month, 1));
                    return disabled ? Colors.grey[400] : Colors.black;
                  }()),
                ),
              ),
              // 月份标题
              Text(
                DateFormat('yyyy-MM').format(_displayMonth),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              // 前进按钮（不能选择未来月份）
              GestureDetector(
                onTap: _displayMonth.year == now.year &&
                        _displayMonth.month == now.month
                    ? null
                    : () {
                        setState(() {
                          _displayMonth = DateTime(
                              _displayMonth.year, _displayMonth.month + 1);
                        });
                        _fetchMonthDetections(_displayMonth);
                      },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: (_displayMonth.year == now.year &&
                            _displayMonth.month == now.month)
                        ? Colors.grey[100]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    AliIcon.right,
                    size: 18,
                    color: (_displayMonth.year == now.year &&
                            _displayMonth.month == now.month)
                        ? Colors.grey[400]
                        : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 星期标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              'SUNDAY'.tr,
              'MONDAY'.tr,
              'TUESDAY'.tr,
              'WEDNESDAY'.tr,
              'THURSDAY'.tr,
              'FRIDAY'.tr,
              'SATURDAY'.tr
            ].map((day) {
              return Text(
                day,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              );
            }).toList(),
          ),
          // 日期网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.8,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: gridItems.length,
            itemBuilder: (context, index) {
              return gridItems[index];
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return CircularPercentIndicator(
      radius: 100.0,
      lineWidth: 15.0,
      animation: true,
      percent: _calcCaloriePercent(),
      center: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(150, 255, 255, 255),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: const Color.fromARGB(150, 255, 255, 255),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CALORIE'.tr,
                style: const TextStyle(
                    fontSize: 16, color: Color.fromARGB(255, 115, 115, 115)),
              ),
              Text('${dailyData['calories']}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  )),
              Text('/${Controller.c.user['dailyCalories']} ${'KCAL'.tr}',
                  style: const TextStyle(
                      fontSize: 14, color: Color.fromARGB(255, 141, 141, 141))),
            ],
          ),
        ),
      ),
      circularStrokeCap: CircularStrokeCap.round,
      arcType: ArcType.FULL,
      arcBackgroundColor: const Color.fromARGB(150, 255, 255, 255),
      backgroundColor: Colors.pink,
      progressBorderColor: const Color.fromARGB(150, 255, 255, 255),
      progressColor: const Color.fromARGB(255, 99, 188, 240),
    );
  }

  Widget _buildNutrientCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNutrientCard(
              Controller.c.user['dailyProtein'],
              dailyData['protein'],
              'PROTEIN'.tr,
              AliIcon.fat,
              const Color.fromARGB(255, 255, 181, 71)),
          _buildNutrientCard(
              Controller.c.user['dailyCarbs'],
              dailyData['carbs'],
              'CARBS'.tr,
              AliIcon.dinner4,
              const Color.fromARGB(255, 95, 154, 255)),
          _buildNutrientCard(
              Controller.c.user['dailyFats'],
              dailyData['fats'],
              'FAT'.tr,
              AliIcon.meat2,
              const Color.fromARGB(255, 255, 122, 122)),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(
      int total, int eat, String label, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(left: 8, right: 8, bottom: 14),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(31, 173, 173, 173),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ]),
        child: Column(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            CircularPercentIndicator(
              radius: 30.0,
              lineWidth: 5.0,
              animation: true,
              percent: min(1, eat / total),
              center: CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.2),
                radius: 24,
                child: Icon(icon, size: 24, color: iconColor),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              arcType: ArcType.FULL,
              arcBackgroundColor: const Color.fromARGB(150, 255, 255, 255),
              backgroundColor: Colors.pink,
              progressBorderColor: const Color.fromARGB(150, 255, 255, 255),
              progressColor: iconColor,
            ),
            const SizedBox(height: 5),
            Text('REMAINING'.tr,
                style: const TextStyle(
                    color: Color.fromARGB(255, 61, 61, 61), fontSize: 11)),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${max(0, total - eat)}',
                    style: const TextStyle(fontSize: 14)),
                Text(' ${'G'.tr}', style: const TextStyle(fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingTask() {
    return Obx(() {
      if (!Controller.c.isAnalyzing.value) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(255, 247, 249, 255),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Obx(() {
                      final path = Controller.c.analyzingFilePath.value;
                      if (path.isEmpty) {
                        return Container(
                          color: const Color.fromARGB(255, 228, 232, 255),
                          child: const Icon(
                            AliIcon.camera,
                            size: 38,
                            color: Color.fromARGB(255, 120, 134, 200),
                          ),
                        );
                      }
                      return Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        color: const Color.fromARGB(60, 0, 0, 0), // 👈 半透明灰色
                        colorBlendMode: BlendMode.darken,
                      );
                    }),
                  ),
                  Obx(() {
                    final progress = Controller.c.analyzingProgress.value;
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, animatedValue, child) {
                        return SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: animatedValue,
                            strokeWidth: 6,
                            backgroundColor:
                                const Color.fromARGB(255, 161, 161, 161),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color.fromARGB(255, 255, 255, 255)),
                          ),
                        );
                      },
                    );
                  }),
                  Obx(() {
                    final progress = Controller.c.analyzingProgress.value;
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, animatedValue, child) {
                        return Text(
                          "${(animatedValue * 100).toInt()}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ANALYZING_2".tr,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  const LottieFood(), // 你已有的动画组件
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHistoryRecord() {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.35, // 至少半屏高
      ),
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 15,
        bottom: 30,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Color.fromARGB(31, 204, 204, 204),
              blurRadius: 5,
              spreadRadius: 2,
              offset: Offset(0, -10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MY_RECORD'.tr,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
                textAlign: TextAlign.left,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, 'records');
                },
                child: Text(
                  '${'MORE'.tr} > ',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.left,
                ),
              )
            ],
          ),
          const SizedBox(
            height: 4,
          ),
          _buildAnalyzingTask(),
          _buildRecordList(),
        ],
      ),
    );
  }

  Widget _buildHomeRecordCard(dynamic item, dynamic meal) {
    final detectionResultData =
        item is Map ? item['detectionResultData'] : null;
    final totalData =
        detectionResultData is Map ? detectionResultData['total'] : null;
    final Map<String, dynamic> detectionData =
        totalData is Map<String, dynamic> ? totalData : {};
    final String dishName = (detectionData['dishName'] ?? '').toString().trim();
    final String calories =
        '${detectionData['calories'] ?? 0} ${'KCAL'.tr}';
    final protein = detectionData['protein'] ?? 0;
    final carbs = detectionData['carbs'] ?? 0;
    final fat = detectionData['fat'] ?? 0;
    final dynamic rawImg = item is Map ? item['sourceImg'] : null;
    final String? imageUrl = rawImg?.toString();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromARGB(255, 247, 249, 255),
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.hardEdge,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant_menu, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant_menu, color: Colors.grey),
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
                        width: 130,
                        child: Text(
                          dishName.isEmpty ? 'UNKNOWN_FOOD'.tr : dishName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(AliIcon.calorie,
                              size: 20, color: Color.fromARGB(255, 255, 133, 25)),
                          const SizedBox(width: 2),
                          Text(
                            calories,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: meal?['color'] ?? const Color.fromARGB(255, 122, 226, 114),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      meal?['label'] ?? 'DINNER'.tr,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(AliIcon.fat,
                          size: 16, color: Color.fromARGB(255, 255, 204, 109)),
                      const SizedBox(width: 2),
                      Text("$protein${'G'.tr}", style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 10),
                      const Icon(AliIcon.dinner4,
                          size: 16, color: Color.fromARGB(255, 102, 166, 255)),
                      const SizedBox(width: 2),
                      Text("$carbs${'G'.tr}", style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 10),
                      const Icon(AliIcon.meat2,
                          size: 16, color: Color.fromARGB(255, 255, 124, 124)),
                      const SizedBox(width: 2),
                      Text("$fat${'G'.tr}", style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordListItem(dynamic item) {
    final meal = mealInfoMap[item['mealType']];
    final int? itemId = item?['id'] is int
        ? item['id'] as int
        : (item?['id'] is String ? int.tryParse(item['id'].toString()) : null);
    final card = _buildHomeRecordCard(item, meal);

    void navigateToDetail() {
      Controller.c.foodDetail(item);
      Navigator.pushNamed(context, '/foodDetail');
    }

    if (itemId == null) {
      return GestureDetector(
        onTap: navigateToDetail,
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: card,
        ),
      );
    }

    final double offset = _swipeOffsets[itemId] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              child: Container(
                width: _deleteButtonWidth - 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _onRecordDeleteTap(item),
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
          GestureDetector(
            onHorizontalDragStart: (details) =>
                _onRecordHorizontalDragStart(itemId, details),
            onHorizontalDragUpdate: (details) =>
                _onRecordHorizontalDragUpdate(itemId, details),
            onHorizontalDragEnd: (_) => _onRecordHorizontalDragEnd(itemId),
            onTap: () {
              if (offset < 0) {
                _closeRecordSwipe(itemId);
              } else {
                navigateToDetail();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(offset, 0, 0),
              child: card,
            ),
          ),
        ],
      ),
    );
  }

  // 记录列表
  Widget _buildRecordList() {
    return Obx(() {
      final isAnalyzing = Controller.c.isAnalyzing.value;
      // 优先展示加载中的动画
      if (_isLoadingRecords) {
        return Container(
          margin: const EdgeInsets.only(top: 20, bottom: 40),
          alignment: Alignment.center,
          child: const LottieFood(
            size: 40,
            spacing: 12,
          ),
        );
      }

      if (record.isEmpty && !isAnalyzing) {
        // 判断选择的日期是否为今天
        bool isToday = _isSameDay(currentDate, DateTime.now());

        return Container(
          margin: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 247, 249, 255)),
                  child: Row(
                    children: [
                      const ImageSwitcher(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    AliIcon.calorie,
                                    size: 20,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      isToday
                                          ? 'UPLOAD_YOUR_FOOD'.tr
                                          : 'NO_RECORDS_PAST_DATE'.tr,
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isToday) ...[
                                const SizedBox(
                                  height: 8,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "CLICK".tr,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 4,
                                    ),
                                    Text(
                                      "+".tr,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 4,
                                    ),
                                    Text(
                                      "BUTTON".tr,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(
                height: 50,
              ),
            ],
          ),
        );
      } else {
        return Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            children: record.map(_buildRecordListItem).toList(),
          ),
        );
      }
    });
  }
}
