import 'dart:async';
import 'dart:convert';
import 'package:calorie/components/buttonX/planButton.dart';
import 'package:calorie/network/api.dart';
import 'package:calorie/store/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class SurveyAnalysis extends StatefulWidget {
  const SurveyAnalysis({super.key});
  @override
  State<SurveyAnalysis> createState() => _SurveyAnalysisState();
}

class _SurveyAnalysisState extends State<SurveyAnalysis>
    with TickerProviderStateMixin {
  late AnimationController _LottieController1;
  late AnimationController _LottieController2;
  late AnimationController _LottieController3;

  CancelToken cancelToken = CancelToken();
  double progress = 0.0;
  bool isFastForward = false;
  bool isDisposed = false;

  String fullText = "";
  String displayedText = "";
  String queueText = "";
  int currentIndex = 0;
  bool isTyping = false;
  Timer? timer;
  bool buttonState = false;
  String buttonTitle = 'CREATING_PLAN'.tr;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _LottieController1 =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _LottieController2 =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _LottieController3 =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    startAnimations();
    _startSlowProgress();
    startTyping();

    final Map<String, dynamic> data = Get.arguments ?? {};
    // _fetchOpenAi(data);
    _fetchOpenAi(data);
    reportGenerate(data);
  }

  @override
  void dispose() {
    isDisposed = true;
    timer?.cancel();
    cancelToken.cancel(); // ✅ 取消请求
    _LottieController1.dispose();
    _LottieController2.dispose();
    _LottieController3.dispose();
    super.dispose();
  }
  // Future<void> _fetchDeepseek(data) async {
  //   final dio = Dio();
  //   try {
  //     final response = await dio.request(
  //       '${baseUrl}/deepseek/create-reasoner',
  //       data: jsonEncode(data),
  //       options: Options(
  //         method: 'PUT',
  //         headers: {"Content-Type": "application/json"},
  //         responseType: ResponseType.stream,
  //       ),
  //       cancelToken: cancelToken,
  //     );

  //     final stream = utf8.decoder.bind(response.data.stream);
  //     stream.listen((event) {
  //       if (event.contains("[DONE]")) {
  //         return;
  //       }
  //         event = event
  //             .replaceAll('data:','')
  //             .replaceAll('\n','')
  //             .replaceAll(RegExp(r'(\* |\*\*\*\*|\*\*\*|\*\*|\*|####|###|##)'), '\n') // 把 **、####、###、## 替换成换行
  //             .replaceAll(RegExp(r'[ ]{2,}'), ' ')  //把多个连续空格压缩成一个空格（更整齐）
  //             .replaceAll(RegExp(r'\n{2,}'), '\n') //去掉多余的连续换行
  //             .replaceAll(RegExp(r'^\n+'), '');  //去掉多余的连续换行
  //         if (event.isNotEmpty) {
  //           print('event $event');
  //           try {
  //             addNewText(event);
  //           } catch (e) {
  //             // print('解析失败: line $line');
  //             print('失败事件2: event $event');
  //           }
  //         }
  //     }, onDone: () {
  //       print('dddddddd');
  //       addNewText('\n' + "PERSONALIZED_PLAN_IS_READY".tr);
  //       _jumpTo100();
  //     }, onError: (error) {
  //       if (CancelToken.isCancel(error)) {
  //         print('请求已取消');
  //       } else {
  //         print("SSE 出错: $error");
  //       }
  //     });
  //   } catch (e) {
  //     print('请求失败: $e');
  //   }
  // }

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
            event = event
              .replaceAll('\n','')
              .replaceAll('data:','');
          if (event.isNotEmpty) {
            print('event $event');
            try {
              addNewText(event);
            } catch (e) {
              print('失败事件2: event $event');
            }
          }
      }, onDone: () {
        addNewText('\n\n${"PERSONALIZED_PLAN_IS_READY".tr}');
        _jumpTo100();
      }, onError: (error) {
        if (CancelToken.isCancel(error)) {
          print('请求已取消');
        } else {
          print("SSE 出错: $error");
        }
      });
    } catch (e) {
      print('请求失败: $e');
    }
  }

  Future<void> reportGenerate(data) async {
    await openAiResult(data);
    Timer(const Duration(seconds: 3), () {
      if (!isDisposed) {
        setState(() {
          buttonState = true;
        });
      }
    });
  }

  void startTyping() {
    if (isTyping) return;
    isTyping = true;
    timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (currentIndex < fullText.length) {
        if (!isDisposed) {
          setState(() {
            displayedText += fullText[currentIndex];
            currentIndex++;
          });
          _autoScrollToBottom();
        }
      } else {
        timer.cancel();
        isTyping = false;
        currentIndex = 0;
        if (!isDisposed) {
          setState(() {}); // ✅ 通知 UI 更新，遮罩消失、恢复滚动
        }
        if (queueText.isNotEmpty) {
          fullText = queueText;
          queueText = "";
          startTyping();
        }
      }
    });
  }

  void addNewText(String content) {
    if (isTyping) {
      queueText += content;
    } else {
      // displayedText += "\n";
      fullText = content;
      startTyping();
    }
  }

  void _autoScrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void startAnimations() async {
    _LottieController1.repeat();
    await Future.delayed(const Duration(milliseconds: 400));
    _LottieController2.repeat();
    await Future.delayed(const Duration(milliseconds: 400));
    _LottieController3.repeat();
  }

  void _startSlowProgress() async {
    while (progress < 0.8 && !isFastForward) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (isDisposed) return;
      setState(() {
        progress += 0.02;
        if (progress > 0.8) progress = 0.8;
      });
    }
  }

  void _jumpTo100() {
    if (isDisposed) return;
    setState(() {
      isFastForward = true;
      progress = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    print(isTyping);
    return Scaffold(
      body: SafeArea(child:    Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
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
                  ),
                  const SizedBox(height: 20),
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration:
                        Duration(milliseconds: progress == 1.0 ? 500 : 60000),
                    builder: (context, double value, child) {
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
                  ),
                  const SizedBox(height: 30),
                  Stack(children: [
                    Container(
                    padding: const EdgeInsets.all(10),
                    height: 540,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color.fromARGB(255, 221, 221, 221)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                              physics: isTyping
            ? const NeverScrollableScrollPhysics() // 打字时禁止滚动
            : const BouncingScrollPhysics(), // 打完可以滑动
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DEEP_ANALYSIS".tr,
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            displayedText,
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Color.fromARGB(255, 103, 103, 103)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
// ✅ 半透明遮罩，阻止触摸操作
    if (isTyping)
      IgnorePointer(
        ignoring: false,
        child: Container(
          height: 540,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
                  ],),
                  if (buttonState)
                    PlanButton(onSubmit: () async {
                      cancelToken.cancel(); // ✅ 再次确保请求取消
                      _jumpTo100();
                      await UserInfo().getUserInfo();
                      Navigator.pushNamed(context, '/surveyResult');
                    })
                ],
              ),
            ),
          ],
        ),
      ),
    
      )
    );
  }
}
