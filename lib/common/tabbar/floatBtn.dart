import 'dart:io';

import 'package:calorie/common/icon/index.dart';
import 'package:calorie/components/actionSheets/cameraAuth.dart';
import 'package:calorie/components/actionSheets/weight.dart';
import 'package:calorie/network/api.dart';
import 'package:calorie/store/store.dart';
import 'package:calorie/common/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class FloatBtn extends StatefulWidget {
  const FloatBtn({super.key});

  @override
  State<FloatBtn> createState() => _FloatBtnState();
}

class _FloatBtnState extends State<FloatBtn> {
  final GlobalKey _fabKey = GlobalKey();
  OverlayEntry? _menuEntry;
  bool _isMenuOpen = false;
  bool _isProcessingAction = false;
  bool _isPicking = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _menuEntry?.remove();
    _menuEntry = null;
    _isMenuOpen = false;
  }

  Future<void> _toggleMenu() async {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (_isMenuOpen) return;
    _menuEntry = _buildOverlayEntry();
    Overlay.of(context, rootOverlay: true).insert(_menuEntry!);
    setState(() {
      _isMenuOpen = true;
    });
  }

  void _closeMenu() {
    if (!_isMenuOpen) return;
    _removeOverlay();
    setState(() {
      _isMenuOpen = false;
    });
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(builder: (context) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildMenuItems(),
          ),
        ],
      );
    });
  }

  Widget _buildMenuItems() {
    final actions = _menuActions();
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final config = actions[index];
          return _QuickActionCard(
            icon: config.icon,
            label: config.label,
            enabled: config.enabled,
            onTap: config.onTap != null
                ? () async {
                    await config.onTap!();
                  }
                : null,
          );
        },
      ),
    );
  }

  List<_FabActionConfig> _menuActions() {
    return [
      _FabActionConfig(
        icon: AliIcon.camera,
        label: 'FAB_CAMERA'.tr,
        onTap: () => _handleMenuAction(_handleCameraTap),
        enabled: true,
      ),
      _FabActionConfig(
        icon: Icons.photo_library_outlined,
        label: 'FAB_GALLERY'.tr,
        onTap: () => _handleMenuAction(_handleGalleryTap),
        enabled: true,
      ),
      _FabActionConfig(
        icon: Icons.edit_note_outlined,
        label: 'FAB_MANUAL'.tr,
        onTap: () => _handleMenuAction(_showManualEntrySheet),
        enabled: true,
      ),
      _FabActionConfig(
        icon: AliIcon.weightScale,
        label: 'RECORD_WEIGHT'.tr,
        onTap: () => _handleMenuAction(_handleWeightTap),
        enabled: true,
      ),
    ];
  }

  Future<void> _handleMenuAction(Future<void> Function() action) async {
    _closeMenu();
    if (_isProcessingAction) return;
    _isProcessingAction = true;
    try {
      await action();
    } finally {
      _isProcessingAction = false;
    }
  }

  Future<void> _handleCameraTap() async {
    var status = await Permission.camera.request();
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    if (status.isGranted) {
      if (!Controller.c.isAnalyzing.value &&
          Controller.c.user['id'] != 0 &&
          mounted) {
        Navigator.pushNamed(context, '/camera');
      }
      return;
    }
    if (status.isPermanentlyDenied) {
      Get.bottomSheet(const CameraAuthSheet());
    }
  }

  Future<void> _handleGalleryTap() async {
    if (!mounted || _isPicking) return;
    _isPicking = true;
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );

      if (image == null) {
        return;
      }

      final extension = image.path.split('.').last.toLowerCase();
      if (extension == 'gif') {
        Fluttertoast.showToast(msg: 'GIF_NOT_SUPPORTED'.tr);
        return;
      }

      final file = File(image.path);
      Controller.c.image({
        'mealType': 1, // 默认餐别
        'path': file.path,
      });
      Controller.c.startAnalyzing();
      Controller.c.tabIndex(0);
    } on PlatformException catch (e) {
      debugPrint('PlatformException picking image: $e');
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      _isPicking = false;
    }
  }

  Future<void> _handleWeightTap() async {
    if (!mounted) return;
    await Get.bottomSheet(
      WeightSheet(
        weight: Controller.c.user['currentWeight'].toDouble(),
        onChange: () {},
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _showManualEntrySheet() async {
    await Get.bottomSheet(
      _ManualEntrySheet(onSubmit: _submitManualEntry),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<bool> _submitManualEntry(String content, int mealType) async {
    if (content.trim().isEmpty) return false;

    // 与拍照/相册逻辑保持一致：在首页展示统一的“分析中”任务
    if (Controller.c.isAnalyzing.value) return false;

    Controller.c.isAnalyzing.value = true;
    // 手动录入没有本地图片，这里放一个占位路径，仅用于触发 _buildAnalyzingTask 显示
    Controller.c.analyzingFilePath.value = '';
    Controller.c.analyzingProgress.value = 0.0;

    // 控制模拟进度是否继续
    bool isRealRequestFinished = false;

    // 启动模拟进度（与 startAnalyzing 类似，每 0.5s 增加一段）
    Future<void> simulateProgress() async {
      for (int i = 1; i <= 4; i++) {
        if (isRealRequestFinished || !Controller.c.isAnalyzing.value) return;
        await Future.delayed(const Duration(milliseconds: 500));
        if (isRealRequestFinished || !Controller.c.isAnalyzing.value) return;
        Controller.c.analyzingProgress.value = i * 0.2;
      }
    }

    simulateProgress();

    // 在后台执行真正的请求
    () async {
      try {
        final res = await detectionCreateWithTextResult({
          'userId': Controller.c.user['id'],
          'mealType': mealType,
          'mealText': content.trim(),
        });

        if (!res.ok) {
          Fluttertoast.showToast(msg: 'FAB_MANUAL_ERROR'.tr);
          return;
        }

        isRealRequestFinished = true;
        Controller.c.analyzingProgress.value = 1;

        Fluttertoast.showToast(msg: 'FAB_MANUAL_SUCCESS'.tr);
        // 触发首页数据刷新
        Controller.c.refreshHomeDataTrigger.value = true;
      } catch (e) {
        isRealRequestFinished = true;
        Fluttertoast.showToast(msg: 'FAB_MANUAL_ERROR'.tr);
      } finally {
        Controller.c.isAnalyzing.value = false;
        Controller.c.analyzingFilePath.value = '';
        Controller.c.analyzingProgress.value = 0.0;
      }
    }();

    // 立即关闭弹窗
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDisabled = Controller.c.isAnalyzing.value ||
          Controller.c.user['id'] == 0;
      if (isDisabled && _isMenuOpen) {
        _closeMenu();
      }
      return FloatingActionButton(
        key: _fabKey,
        shape: const CircleBorder(),
        onPressed: isDisabled ? null : _toggleMenu,
        backgroundColor:
            isDisabled ? Colors.grey : const Color.fromARGB(255, 0, 0, 0),
        child: const Icon(
          Icons.add,
          size: 34,
          color: Colors.white,
        ),
      );
    });
  }
}

class _FabActionConfig {
  final IconData icon;
  final String label;
  final Future<void> Function()? onTap;
  final bool enabled;

  const _FabActionConfig({
    required this.icon,
    required this.label,
    this.onTap,
    required this.enabled,
  });
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 140,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(30, 0, 0, 0),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: enabled
                ? const Color.fromARGB(255, 0, 0, 0)
                : Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  enabled ? const Color(0xFF111111) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );

    if (!enabled) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _ManualEntrySheet extends StatefulWidget {
  final Future<bool> Function(String, int) onSubmit;

  const _ManualEntrySheet({required this.onSubmit});

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  int _selectedMealType = 1; // Add this line

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    final success = await widget.onSubmit(text, _selectedMealType);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canSubmit = _controller.text.trim().isNotEmpty && !_isSubmitting;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'FAB_MANUAL_TITLE'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'FAB_MANUAL_DESC'.tr,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: mealOptions().map((meal) {
                    final int value = meal['value'] as int;
                    final bool selected = value == _selectedMealType;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        showCheckmark: false,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              meal['icon'] as IconData,
                              size: 16,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF111111),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              meal['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF111111),
                              ),
                            ),
                          ],
                        ),
                        selected: selected,
                        selectedColor: meal['color'] as Color?,
                        backgroundColor: Colors.grey.shade200,
                        onSelected: (_) {
                          setState(() {
                            _selectedMealType = value;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                minLines: 4,
                maxLines: 6,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'FAB_MANUAL_PLACEHOLDER'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSubmit
                        ? const Color(0xFF111111)
                        : Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: canSubmit ? _submit : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'FAB_MANUAL_SUBMIT'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
