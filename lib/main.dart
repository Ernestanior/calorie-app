import 'package:calorie/common/camera/index.dart';
import 'package:calorie/common/locale/index.dart';
import 'package:calorie/common/tabbar/floatBtn.dart';
import 'package:calorie/common/tabbar/index.dart';
import 'package:calorie/common/util/deviceId.dart';
import 'package:calorie/common/util/utils.dart';
import 'package:calorie/network/api.dart';
import 'package:calorie/page/lab/index.dart';
import 'package:calorie/page/lab/aiCooking/history.dart';
import 'package:calorie/page/aboutUs/index.dart';
import 'package:calorie/page/aboutUs/service.dart';
import 'package:calorie/page/chef/index.dart';
import 'package:calorie/page/contactUs/index.dart';
import 'package:calorie/page/premium/index.dart';
import 'package:calorie/page/recipe/detail/index.dart';
import 'package:calorie/page/recipe/index.dart';
import 'package:calorie/page/foodDetail/index.dart';
import 'package:calorie/page/home/index.dart';
import 'package:calorie/page/profile/index.dart';
import 'package:calorie/page/profileDetail/index.dart';
import 'package:calorie/page/recipe/myPlan.dart';
import 'package:calorie/page/records/index.dart';
import 'package:calorie/page/step/index.dart';
import 'package:calorie/page/survey/index.dart';
import 'package:calorie/page/scan/index.dart';
import 'package:calorie/page/scan/result/index.dart';
import 'package:calorie/page/setting/index.dart';
import 'package:calorie/page/survey/analysis.dart';
import 'package:calorie/page/survey/result/index.dart';
import 'package:calorie/page/weight/index.dart';
import 'package:calorie/page/guide/index.dart';
import 'package:calorie/store/receiptController.dart';
import 'package:calorie/store/store.dart';
import 'package:calorie/store/timeController.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'page/aboutUs/privacy.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

dynamic initData = {
  'age': 18,
  'height': 175,
  'gender': 1,
  'initWeight': 65,
  'currentWeight': 65,
  'targetWeight': 65,
  'targetStep': 8000,
  'dailyCalories': 2200,
  'dailyCarbs': 300,
  'dailyFats': 70,
  'dailyProtein': 70,
  "unitType": 0,
  'targetType': 1,
  "lang": "en_US"
};
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Get.lazyPut<ApiConnect>(() => ApiConnect());
  Get.lazyPut(() => Controller());
  Get.put(RecipeController(), permanent: true); // 改为permanent，确保不被回收
  Get.put(TimerController(), permanent: true);

  await TimerController.t.restore();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final deviceId = await DeviceIdManager.getId();
  var langCode = 'en_US';
  StreamSubscription? _netSub;

  Future onLogin() async {
    try {
      var res = await login(deviceId, initData);
      print('userCreate $res');
      // 保存用户信息到全局
      if (res != "-1") {
        Controller.c.user(res);
        // 设置初始语言
        Controller.c.lang(res['lang']);
        langCode = res?['lang'] ?? 'en_US';
        Get.updateLocale(getLocaleFromCode(langCode).value);
        // 延迟加载食谱数据，避免与其他初始化冲突
        Future.delayed(const Duration(milliseconds: 1000), () {
          try {
            RecipeController.r.safeFetchRecipes();
          } catch (e) {
            print('Initial recipe fetch error: $e');
          }
        });
      } else {
        print("❌ 用户创建失败，5 秒后重试一次...");
        Future.delayed(const Duration(seconds: 5), () async {
          var res = await login(deviceId, initData);
          // 保存用户信息到全局
          if (res != "-1") {
            Controller.c.user(res);
            // 设置初始语言
            Controller.c.lang(res['lang']);
            langCode = res?['lang'] ?? 'en_US';
            Get.updateLocale(getLocaleFromCode(langCode).value);

            // 延迟加载食谱数据，避免与其他初始化冲突
            Future.delayed(const Duration(milliseconds: 1000), () {
              try {
                RecipeController.r.safeFetchRecipes();
              } catch (e) {
                print('Initial recipe fetch error: $e');
              }
            });
          }
        });

        _netSub?.cancel();
        _netSub = Connectivity().onConnectivityChanged.listen((result) async {
          if (result != ConnectivityResult.none) {
            print("🌐 网络恢复，重新尝试创建用户...");
            await onLogin();
            _netSub?.cancel();
          }
        });
      }
    } catch (e) {
      print('error $e');
    }
  }

  unawaited(onLogin());

  final locale = getLocaleFromCode(langCode).value;
  Get.updateLocale(locale);
  // 初始化 SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  bool firstOpen = prefs.getBool('first_open') ?? true; // 默认第一次打开为 true
  // 如果是第一次打开，显示 GuidePage；否则显示 BottomNavScreen
  Widget initialPage = firstOpen ? const GuidePage() : const BottomNavScreen();

  // 可在第一次打开后保存状态
  if (firstOpen) {
    await prefs.setBool('first_open', false);
  }

  runApp(CalAiApp(initialPage: initialPage));
}

class CalAiApp extends StatefulWidget {
  final Widget initialPage;
  const CalAiApp({super.key, required this.initialPage});

  @override
  State<CalAiApp> createState() => _CalAiAppState();
}

class _CalAiAppState extends State<CalAiApp>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext contextX) {
    return GetMaterialApp(
      translations: Messages(),
      navigatorObservers: [routeObserver],
      locale: Get.locale,
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      initialRoute: '/', //2、调用onGenerateRoute处理
      home: widget.initialPage,
      getPages: [
        // GetPage(name: "/", page: () => BottomNavScreen()),
        GetPage(name: "/home", page: () => BottomNavScreen()),
        GetPage(name: "/profile", page: () => Profile()),
        GetPage(
            name: "/profileDetail", page: () => ProfileDetail()), // 详情页（无底部导航）
        GetPage(name: "/weight", page: () => Weight()),
        GetPage(
          name: "/premium",
          page: () => Premium(),
          preventDuplicates: true,
          popGesture: false,
        ),
        GetPage(name: "/step", page: () => StepPage()),
        GetPage(name: "/guide", page: () => GuidePage()),
        GetPage(name: "/contactUs", page: () => ContactUs()),
        GetPage(name: "/aboutUs", page: () => AboutUs()),
        GetPage(name: "/privacy", page: () => Privacy()),
        GetPage(name: "/service", page: () => Service()),
        GetPage(name: "/camera", page: () => CameraScreen()),
        GetPage(name: "/records", page: () => Records()),
        GetPage(name: "/scan", page: () => ScanAnimationPage()),
        GetPage(name: "/scanResult", page: () => ScanResult()),
        GetPage(name: "/survey", page: () => MultiStepForm()),
        GetPage(name: "/surveyAnalysis", page: () => SurveyAnalysis()),
        GetPage(name: "/surveyResult", page: () => SurveyResult()),
        GetPage(name: "/recipe", page: () => RecipePage()),
        GetPage(name: "/recipeCollect", page: () => RecipeCollect()),
        GetPage(name: "/recipeDetail", page: () => RecipeDetail()),
        GetPage(name: "/foodDetail", page: () => FoodDetail()),
        GetPage(name: "/setting", page: () => Setting()),
        GetPage(name: "/aiCookingHistory", page: () => AiCookingHistoryPage()),
      ],
    );
  }
}

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  final List<Widget> _pages = [
    const Home(),
    const RecipePage(),
    // const ChefPage(),
    const LabPage(),
    const Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        // 检查RecipeController状态，如果切换到recipe页面且controller有问题，强制重新初始化
        if (Controller.c.tabIndex.value == 1 &&
            !RecipeController.r.isInitialized.value) {
          print(
              'RecipeController not initialized when switching to recipe tab, reinitializing...');
          Future.delayed(const Duration(milliseconds: 100), () {
            RecipeController.r.forceReinitialize();
          });
        }

        // 使用 IndexedStack 保持所有页面状态在内存中
        return Stack(
          children: [
            IndexedStack(
              index: Controller.c.tabIndex.value,
              children: _pages,
            ),
            CustomTabBar(),
          ],
        );
      }),
      floatingActionButton: const FloatBtn(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
