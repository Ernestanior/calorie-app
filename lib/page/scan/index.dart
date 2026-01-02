import 'dart:io';
import 'package:calorie/store/store.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ScanAnimationPage extends StatefulWidget {
  const ScanAnimationPage({super.key});

  @override
  _ScanAnimationPageState createState() => _ScanAnimationPageState();
}

class _ScanAnimationPageState extends State<ScanAnimationPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late AnimationController _LottieController1;
  late AnimationController _LottieController2;
  late AnimationController _LottieController3;

  @override
  void initState() {
    super.initState();
    _LottieController1 = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _LottieController2 = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _LottieController3 = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    startAnimations();
    // uploadImg();
  }

  // Future<void> uploadImg() async {
  //     if (Controller.c.image['path'] is String) {
  //       File imageFile = File(Controller.c.image['path']!);
  //       // 创建FormData
  //       dio.FormData formData = dio.FormData.fromMap({
  //         "file": await dio.MultipartFile.fromFile(
  //           imageFile.path,
  //           filename: "upload.jpg", 
  //         ),
  //       });
  //       dynamic url = await fileUpload(formData);
  //       if (url==null) {
  //         return;
  //       }
  //       dynamic res = await detectionCreate({'userId':Controller.c.user['id'],'mealType':Controller.c.image['mealType'],'sourceImg': imgUrl+url});
  //       Controller.c.scanResult(res);
  //       if (!mounted) return; // ✅ 防止已被 pop 时仍访问 context
  //        Navigator.pushReplacementNamed(context, '/scanResult');
  //     }
  // }

   void startAnimations() async {
    _LottieController1.repeat();
    await Future.delayed(const Duration(milliseconds: 400));
    _LottieController2.repeat();
    await Future.delayed(const Duration(milliseconds: 400));
    _LottieController3.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height * 0.8;

    return Scaffold(
      backgroundColor: Colors.white,
      body: 
      SingleChildScrollView(  
      child:Column(
        children: [
        Stack(
          children: [
          Container(
            decoration: const BoxDecoration(color: Color.fromARGB(255, 241, 241, 241)),
            height: screenHeight,
            child: Image.file(File(Controller.c.image['path']!),width: screenWidth,
                fit: BoxFit.contain,),
          ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight-100,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: CoolScanPainter(_animation.value, screenHeight),
                  );
                },
              ),
            ),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, -15), // 向上移动 50 像素
          child: Container(
            width: double.infinity,
            padding:const EdgeInsets.only(top: 0,bottom: 20, left: 20, right: 20, ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft:Radius.circular(20),topRight:Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color:Color.fromARGB(31, 204, 204, 204),
                  blurRadius: 5,
                  spreadRadius: 2,
                  offset: Offset(0, -10)
                ),
              ],
            ),
            ),
          ), 
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,),
            child: 
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset('assets/image/rice.json', controller: _LottieController1, width: 50),
                    const SizedBox(width: 20,),
                    Lottie.asset('assets/image/beef.json', controller: _LottieController2, width: 50),
                    const SizedBox(width: 20,),
                    Lottie.asset('assets/image/egg.json', controller: _LottieController3, width: 50),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20,),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: LinearProgressIndicator(minHeight: 12,borderRadius:BorderRadius.circular(6)),
          )

        ],
      )
           
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _LottieController1.dispose();
    _LottieController2.dispose();
    _LottieController3.dispose();
    super.dispose();
  }
}

class CoolScanPainter extends CustomPainter {
  final double position;
  final double maxHeight;
  CoolScanPainter(this.position, this.maxHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blue.withAlpha((0.0 * 255).round()),
          Colors.cyan.withAlpha((0.1 * 255).round()),
          Colors.blue.withAlpha((0.0 * 255).round())
        ],
        stops: const [0.0,0.5,1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, size.height * position, size.width, 15));

    final blurPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    final glowRect = Rect.fromLTWH(0, size.height * position, size.width, 30);
    canvas.drawRect(glowRect, blurPaint);
    canvas.drawRect(glowRect, paint);

    final Paint linePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(0, size.height * position + 15),
        Offset(size.width, size.height * position + 15),
        linePaint);

    // 平滑的尾迹渐变效果
    for (int i = 0; i < 10; i++) {
      double trailOpacity = (1 - i / 10) * 0.5;
      final Paint trailPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.0),
            Colors.cyan.withOpacity(trailOpacity),
            Colors.blue.withOpacity(0.0)
          ],
          stops: const [0.2, 0.5, 0.8],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, size.height * (position - (i * 0.01)), size.width, 30));

      final Rect trailRect = Rect.fromLTWH(0, size.height * (position - (i * 0.01)), size.width, 30);
      canvas.drawRect(trailRect, trailPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
