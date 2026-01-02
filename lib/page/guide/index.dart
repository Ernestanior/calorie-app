import 'package:calorie/components/languageSelector/index.dart';
import 'package:calorie/components/video/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:google_fonts/google_fonts.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  bool _videoEnded = false;

  // ✅ 创建一个 GlobalKey，用于调用视频组件内部的 reload 方法
  final GlobalKey<OnboardingVideoState> _videoKey =
      GlobalKey<OnboardingVideoState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SafeArea(
      child: SingleChildScrollView(
        child:   Column(
        children: [
          // ✅ 视频组件（带 key）
          
          OnboardingVideo(
            key: _videoKey,
            onVideoEnd: () {
              setState(() {
                _videoEnded = true;
              });
            },
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: _videoEnded ? 1 : 0,
                child: GestureDetector(
                  onTap: () {
                    // 安全地调用公开方法
                    setState(() {
                      _videoEnded = false;
                    });
                    _videoKey.currentState?.reloadVideo();
                  },
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      const Icon(Icons.replay_rounded, size: 22),
                      const SizedBox(
                        width: 5,
                      ),
                      Text('RELOAD_VIDEO'.tr),
                    ],
                  ),
                ),
              ),
              const LanguageSelector(),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            'AI_CALORIE_TRACKING'.tr,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: const Color.fromARGB(197, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xC5291B30),
                  minimumSize: const Size(300, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/survey');
                },
                child: Text(
                  "GET_STARTED".tr,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
                child: Text(
                  'SKIP'.tr,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),)
      ) 
     );
  }
}
