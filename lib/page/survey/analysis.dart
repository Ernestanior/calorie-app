import 'dart:async';
import 'dart:convert';
import 'package:calorie/components/buttonX/planButton.dart';
import 'package:calorie/network/api.dart';
import 'package:calorie/store/user.dart';
import 'package:calorie/store/receiptController.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class SurveyAnalysis extends StatefulWidget {
  const SurveyAnalysis({super.key});

  @override
  State<SurveyAnalysis> createState() => _SurveyAnalysisState();
}

class _SurveyAnalysisState extends State<SurveyAnalysis>
    with TickerProviderStateMixin {
  // --- Lottie ---
  late AnimationController _LottieController1;
  late AnimationController _LottieController2;
  late AnimationController _LottieController3;

  // --- 状态管理 ---
  CancelToken cancelToken = CancelToken();
  bool isDisposed = false;
  bool isTyping = false;
  bool buttonState = false;

  double progress = 0.0;
  bool isFastForward = false;

  // --- 打字相关 ---
  String fullText = "";
  String displayedText = "";
  String queueText = "";
  int currentIndex = 0;
  Timer? timer;
  Timer? _scrollThrottleTimer;
  final ScrollController _scrollController = ScrollController();

  // --- 初始化 ---
  @override
  void initState() {
    super.initState();
    _initLottie();
    startAnimations();
    _startSlowProgress();

    final Map<String, dynamic> data = Get.arguments ?? {};
    _fetchOpenAi(data);
    reportGenerate(data);
  }

  void _initLottie() {
    _LottieController1 =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _LottieController2 =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _LottieController3 =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  void startAnimations() async {
    _LottieController1.repeat();
    await Future.delayed(const Duration(milliseconds: 400));
    _LottieController2.repeat();
    await Future.delayed(const Duration(milliseconds: 400));
    _LottieController3.repeat();
  }

  @override
  void dispose() {
    isDisposed = true;
    timer?.cancel();
    _scrollThrottleTimer?.cancel();
    cancelToken.cancel();
    _LottieController1.dispose();
    _LottieController2.dispose();
    _LottieController3.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- SSE 请求 ---
  Future<void> _fetchOpenAi(data) async {
    final dio = Dio();
    try {
      final response = await dio.request(
        '$baseUrl/openAI/create-reasoner',
        data: jsonEncode(data),
        options: Options(
          method: 'PUT',
          headers: {"Content-Type": "application/json"},
          responseType: ResponseType.stream,
        ),
        cancelToken: cancelToken,
      );

      final stream = utf8.decoder.bind(response.data.stream);
      stream.listen((event) {
        if (event.contains("[DONE]")) {
          cancelToken.cancel();
          return;
        }
        event = event.replaceAll('\n', '').replaceAll('data:', '');
        if (event.isNotEmpty) addNewText(event);
      }, onDone: () {
        addNewText('\n\n${"PERSONALIZED_PLAN_IS_READY".tr}');
        _jumpTo100();
      }, onError: (error) {
        if (!CancelToken.isCancel(error)) {
          print("SSE 出错: $error");
        }
      });
    } catch (e) {
      print('请求失败: $e');
    }
  }

  // --- 报告生成延迟，显示按钮 ---
  Future<void> reportGenerate(data) async {
    await openAiResult(data);
    Timer(const Duration(seconds: 8), () {
      if (!isDisposed) setState(() => buttonState = true);
    });
  }

  // --- 打字逻辑 ---
  void startTyping() {
    if (isTyping || isDisposed) return;
    isTyping = true;

    timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (currentIndex < fullText.length) {
        if (!isDisposed) {
          setState(() {
            displayedText += fullText[currentIndex];
            currentIndex++;
          });
          _throttledScrollToBottom();
        }
      } else {
        timer.cancel();
        isTyping = false;
        currentIndex = 0;

        if (queueText.isNotEmpty) {
          fullText = queueText;
          queueText = "";
          startTyping();
        } else {
          setState(() {}); // 更新 UI，让遮罩淡出
        }
      }
    });
  }

  void addNewText(String content) {
    if (isTyping) {
      queueText += content;
    } else {
      fullText = content;
      startTyping();
    }
  }

  // --- 节流滚动，保证旧机型流畅 ---
  void _throttledScrollToBottom() {
    if (_scrollThrottleTimer?.isActive ?? false) return;
    _scrollThrottleTimer = Timer(const Duration(milliseconds: 80), () async {
      if (!_scrollController.hasClients || isDisposed) return;
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // --- 进度控制 ---
  void _startSlowProgress() async {
    while (progress < 0.8 && !isFastForward && !isDisposed) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!isDisposed) {
        setState(() {
          progress += 0.04;
          if (progress > 0.8) progress = 0.8;
        });
      }
    }
  }

  void _jumpTo100()async {
    if (isDisposed) return;
    setState(() {
      isFastForward = true;
    });
    while (progress < 1 && !isFastForward && !isDisposed) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!isDisposed) {
        setState(() {
          progress += 0.1;
        });
      }
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                _buildLottieRow(),
                const SizedBox(height: 20),
                _buildProgressBar(),
                const SizedBox(height: 30),
                _buildTypingBox(),
                const SizedBox(height: 10),
                if (buttonState) _buildPlanButton(context),
              ],
            ),
          ],
        ),
      ),
    )));
  }

  Widget _buildLottieRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset('assets/image/rice.json',
            controller: _LottieController1, width: 50),
        const SizedBox(width: 20),
        Lottie.asset('assets/image/beef.json',
            controller: _LottieController2, width: 50),
        const SizedBox(width: 20),
        Lottie.asset('assets/image/egg.json',
            controller: _LottieController3, width: 50),
      ],
    );
  }

  Widget _buildProgressBar() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: progress),
      duration: Duration(milliseconds: progress == 1.0 ? 600 : 60000),
      builder: (context, double value, _) {
        return SizedBox(
          width: 300,
          child: LinearProgressIndicator(
            value: value,
            minHeight: 12,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: Colors.grey[300],
            color: const Color.fromARGB(255, 162, 208, 255),
          ),
        );
      },
    );
  }

  Widget _buildTypingBox() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.symmetric(horizontal: 15),
          height: 530,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 221, 221, 221)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: isTyping
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DEEP_ANALYSIS".tr,
                  style: const TextStyle(
                      fontSize: 14, height: 1.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                AnimatedOpacity(
                  opacity: isTyping ? 0.95 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: GptMarkdown(
                    _formatReasonMarkdown(displayedText),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color.fromARGB(255, 103, 103, 103),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ✅ 打字中半透明遮罩
        if (isTyping)
          IgnorePointer(
            ignoring: false,
            child: AnimatedOpacity(
              opacity: 0.5,
              duration: const Duration(milliseconds: 400),
              child: Container(
                height: 530,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlanButton(BuildContext context) {
    return PlanButton(onSubmit: () async {
      cancelToken.cancel();
      _jumpTo100();

      // 强制重新初始化RecipeController，防止内存问题
      try {
        RecipeController.r.forceReinitialize();
      } catch (e) {
        print('RecipeController reinitialize error: $e');
      }

      // 延迟执行用户信息更新，避免与其他操作冲突
      Future.delayed(const Duration(milliseconds: 200), () async {
        await UserInfo().getUserInfo();
      });

      Navigator.pushNamed(context, '/surveyResult');
    });
  }

  String _formatReasonMarkdown(String raw) {
    var text = raw;

    text = text.replaceAll('#### ', '\n\n#### ');
    text = text.replaceAll('### ', '\n\n### ');
    text = text.replaceAll('## ', '\n\n## ');

    // Remove leading Markdown heading markers (e.g. #, ##, ###) to avoid
    // rendering them as large heading fonts in GptMarkdown
    text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

    text = text.replaceAll('\\times', '×');
    text = text.replaceAll('\\text{ kcal}', 'kcal');
    text = text.replaceAll('\\text{', '');
    text = text.replaceAll('}', '');
    text = text.replaceAll('\\[', '');
    text = text.replaceAll('\\]', '');

    return text.trim();
  }
}
