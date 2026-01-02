import 'dart:ui';
import 'dart:convert';

import 'package:calorie/common/util/deviceId.dart';
import 'package:calorie/main.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart' hide FormData;
import 'package:intl/intl.dart';

import '../store/store.dart';

// const String baseUrl = 'https://calorie-backend.xyvn.workers.dev/api';
const String baseUrl = 'https://api.xyvnai.com/api';
// const String imgUrl = 'http://127.0.0.1:8787';

//  const String baseUrl = 'http://10.10.20.34:9304/api';
//  const String imgUrl = 'http://10.10.20.34/';

class DioService {
  static final DioService _instance = DioService._internal();
  factory DioService() => _instance;

  late Dio _dio;
  DioService._internal() {
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 58),
      receiveTimeout: const Duration(seconds: 58),
      sendTimeout: const Duration(seconds: 58),
      headers: {
        'app-user-locale': 'zh_CN',
        'version': 'v1.2.15',
      },
    );

    _dio = Dio(options);

    // 添加日志或拦截器
    // _dio.interceptors.add(LogInterceptor(
    // request: true,
    // responseBody: true,
    // requestHeader: true,
    // responseHeader: false,
    // error: true,
    // ));
  }

  /// 标准化的返回结构，便于逐步替换旧的 "-1" 错误判断
  Future<ApiResult<T>> requestResult<T>(
    String path,
    String method, {
    Map<String, dynamic>? query,
    dynamic body,
    Map<String, String>? headers,
    bool pass = false,
  }) async {
    try {
      // 根据当前用户语言动态设置 locale 头，默认 zh_CN
      final String localeHeader =
          (Controller.c.user['lang']?.toString().isNotEmpty ?? false)
              ? Controller.c.user['lang'].toString()
              : 'zh_CN';

      final Map<String, String> mergedHeaders = {
        'app-user-locale': localeHeader,
        if (headers != null) ...headers,
      };

      final options = Options(
        method: method,
        headers: mergedHeaders,
        contentType: body is FormData ? 'multipart/form-data' : 'application/json',
      );

      final response = await _dio.request(
        path,
        data: body,
        queryParameters: query,
        options: options,
      );

      if (pass) {
        // 透传，用于流式等特殊场景
        return ApiResult.ok(raw: response);
      }

      final data = response.data;

      if (data is Map && data['code'] != null) {
        final code = data['code'] as int;
        if (code == 200) {
          return ApiResult.ok(data: data['data'] as T?);
        }
        return ApiResult.fail(
          code: code,
          message: data['message']?.toString(),
          data: data['data'],
        );
      }

      // 未按约定返回
      return ApiResult.fail(
        code: -1,
        message: 'Unexpected response',
        data: data,
      );
    } on DioException catch (e) {
      final offline = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      return ApiResult.fail(
        code: e.response?.statusCode ?? -1,
        message: e.message ?? 'NETWORK_ERROR',
        offline: offline,
      );
    } catch (e) {
      return ApiResult.fail(
        code: -1,
        message: e.toString(),
      );
    }
  }

  Future<dynamic> request(
    String path,
    String method, {
    Map<String, dynamic>? query,
    dynamic body,
    Map<String, String>? headers,
    bool pass = false,
  }) async {
    // 统一兜底: 确保 user 已创建
    if (Controller.c.user['id'] == null) {
      print("⚠️ 用户 ID 为空，等待登录完成...");
      int retry = 0;
      while (Controller.c.user['id'] == null && retry < 3) {
        await Future.delayed(const Duration(milliseconds: 3000));
        retry++;
      }

      // 10次仍然为空 -> 主动尝试重新登录一次
      if (Controller.c.user['id'] == null) {
        print("⚠️ 用户仍为空，尝试重新调用 login()");
        try {
          final deviceId = await DeviceIdManager.getId();
          final res = await login(deviceId, initData);
          if (res != "-1") {
            Locale locale;
            if (res['lang'] == 'en_US') {
              locale = const Locale('en', 'US');
              Get.updateLocale(locale);
            } else {
              locale = const Locale('zh', 'CN');
              Get.updateLocale(locale);
            }
            Controller.c.user(res);
            Controller.c.lang(res['lang']);
            print("✅ 重新登录成功");
          } else {
            print("❌ 重新登录失败");
            return "-1";
          }
        } catch (e) {
          print("❌ 自动重新登录异常: $e");
          return "-1";
        }
      }
    }
    try {
      // 根据当前用户语言动态设置 locale 头，默认 zh_CN
      final String localeHeader =
          (Controller.c.user['lang']?.toString().isNotEmpty ?? false)
              ? Controller.c.user['lang'].toString()
              : 'zh_CN';

      final Map<String, String> mergedHeaders = {
        'app-user-locale': localeHeader,
        if (headers != null) ...headers,
      };

      final options = Options(
        method: method,
        headers: mergedHeaders,
        contentType:
            body is FormData ? 'multipart/form-data' : 'application/json',
      );

      final response = await _dio.request(
        path,
        data: body,
        queryParameters: query,
        options: options,
      );

      final data = response.data;

      if (pass) return response;

      if (data is String || data['code'] == 404) {
        return data;
      } else if (data['code'] == 200) {
        return data['data'];
      } else {
        print('request error $data');
        return "-1";
      }
    } catch (e) {
      print('请求失败: $e');
      // Get.defaultDialog(title:'OOPS'.tr,
      // titleStyle: TextStyle(fontSize: 18),
      // content:Text('NETWORK_ERROR'.tr),
      // contentPadding: EdgeInsets.all(10));

      Fluttertoast.showToast(
        msg: 'NETWORK_ERROR'.tr,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return "-1";
    }
  }
}

class ApiResult<T> {
  final bool ok;
  final int code;
  final T? data;
  final String? message;
  final bool offline;
  final dynamic raw;

  const ApiResult({
    required this.ok,
    required this.code,
    this.data,
    this.message,
    this.offline = false,
    this.raw,
  });

  factory ApiResult.ok({T? data, dynamic raw}) =>
      ApiResult(ok: true, code: 200, data: data, raw: raw);

  factory ApiResult.fail({
    required int code,
    String? message,
    bool offline = false,
    dynamic data,
  }) =>
      ApiResult(
        ok: false,
        code: code,
        message: message,
        offline: offline,
        data: data,
      );
}

// 首次进入app时获取用户信息，若无该用户则新建用户
Future login(String id, dynamic data) => DioService()
    .request('/user/create', 'put', body: {'deviceId': id, ...data});

// 标准化版本：返回 ApiResult，避免使用 "-1" 哨兵
Future<ApiResult<Map<String, dynamic>?>> loginResult(String id, dynamic data) =>
    DioService().requestResult<Map<String, dynamic>?>(
      '/user/create',
      'put',
      body: {'deviceId': id, ...data},
    );

// 修改用户
Future userModify(dynamic data) => DioService().request('/user/modify', 'put',
    body: {'id': '${Controller.c.user['id']}', ...data});

Future<ApiResult<Map<String, dynamic>?>> userModifyResult(dynamic data) =>
    DioService().requestResult<Map<String, dynamic>?>('/user/modify', 'put',
        body: {'id': '${Controller.c.user['id']}', ...data});

// 获取用户信息
Future getUserDetail() => DioService().request('/user/detail', 'get',
    query: {'id': '${Controller.c.user['id']}'});

Future<ApiResult<Map<String, dynamic>?>> getUserDetailResult() =>
    DioService().requestResult<Map<String, dynamic>?>('/user/detail', 'get',
        query: {'id': '${Controller.c.user['id']}'});

// 删除用户
Future userDelete() => DioService().request('/user/delete', 'delete',
    query: {'id': Controller.c.user['id']});

// 用户每日数据统计
Future userSummary(String date) => DioService().request('/user-daily-summary/fetch-one', 'put',
    body: {'userId': Controller.c.user['id'], 'date': date});

Future<ApiResult<Map<String, dynamic>?>> userSummaryResult(String date) =>
    DioService().requestResult<Map<String, dynamic>?>(
      '/user-daily-summary/fetch-one',
      'put',
      body: {'userId': Controller.c.user['id'], 'date': date},
    );

// 饮食建议：直接从当前用户数据中读取，无需额外请求
Future<List<dynamic>> getUserDietaryAdvice() async {
  final raw = Controller.c.user['dietaryAdviceList'] ??
      Controller.c.user['dietaryAdvice'];

  if (raw == null) return [];

  if (raw is List) return raw;

  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
      if (decoded is String) return [decoded];
      return [];
    } catch (_) {
      return [raw];
    }
  }

  return [];
}

// 目前弃用！ 图片base64
Future imgRender(dynamic data) =>
    DioService().request('/render/start', 'post', body: data);

// deepseek思考过程
Future deepseekReason(Map data) => DioService()
    .request('/deepseek/create-reasoner', 'put', body: data, pass: true);

// deepseek答案
Future deepseekResult(Map data) => DioService()
    .request('/deepseek/create-chat', 'put', body: data, pass: true);

// openAi思考过程
Future openAiReason(Map data) => DioService()
    .request('/openAI/create-reasoner', 'put', body: data, pass: true);

// openAi答案
Future openAiResult(Map data) =>
    DioService().request('/openAI/create-chat', 'put', body: data, pass: true);

// openAi完整内容
Future openAiPlainChat(Map data) =>
    DioService().request('/openAI/plainchat', 'put', body: data, pass: true);

Future<ApiResult<dynamic>> openAiPlainChatResult(Map data) =>
    DioService().requestResult('/openAI/plainchat', 'put', body: data, pass: true);

// 每天的卡路里，碳水，脂肪，蛋白质记录
Future dailyRecord(int userId, String date) =>
    DioService().request('/detection/count-by-date', 'post', body: {
      'userId': userId,
      'startDateTime': '$date 00:00:00',
      'endDateTime': '$date 23:59:59'
    });

Future<ApiResult<Map<String, dynamic>?>> dailyRecordResult(int userId, String date) =>
    DioService().requestResult<Map<String, dynamic>?>(
      '/detection/count-by-date',
      'post',
      body: {
        'userId': userId,
        'startDateTime': '$date 00:00:00',
        'endDateTime': '$date 23:59:59'
      },
    );

// 图片上传获取uri
Future fileUpload(FormData data) =>
    DioService().request('/file/upload', 'put', body: data);

// 扫描食物
Future detectionCreate(dynamic data) =>
    DioService().request('/detection/create', 'put', body: data);

Future<ApiResult<Map<String, dynamic>?>> detectionCreateResult(dynamic data) =>
    DioService().requestResult<Map<String, dynamic>?>('/detection/create', 'put', body: data);

// 文本描述创建食物记录
Future detectionCreateWithText(dynamic data) =>
    DioService().request('/detection/create-with-text', 'put', body: data);

Future<ApiResult<Map<String, dynamic>?>> detectionCreateWithTextResult(dynamic data) =>
    DioService().requestResult<Map<String, dynamic>?>('/detection/create-with-text', 'put', body: data);

// 一个月内的打卡记录
Future detectionForMonth(String startDate, String endDate) => DioService()
        .request('/detection/count-detection-times-by-date', 'post', body: {
      'userId': Controller.c.user['id'],
      'startDateTime': '$startDate 00:00:00',
      'endDateTime': '$endDate 23:59:59',
    });

Future<ApiResult<Map<String, dynamic>?>> detectionForMonthResult(String startDate, String endDate) =>
    DioService().requestResult<Map<String, dynamic>?>(
      '/detection/count-detection-times-by-date',
      'post',
      body: {
        'userId': Controller.c.user['id'],
        'startDateTime': '$startDate 00:00:00',
        'endDateTime': '$endDate 23:59:59',
      },
    );

// 扫描食物记录
Future detectionList(int page, int pageSize, {String? date}) {
  if (date == null) {
    return DioService().request('/detection/page', 'post', body: {
      'userId': Controller.c.user['id'],
      'searchPage': {
        'page': page,
        'pageSize': pageSize,
        'desc': 1,
        'sort': 'createDate'
      },
    });
  } else {
    return DioService().request('/detection/page', 'post', body: {
      'userId': Controller.c.user['id'],
      'searchPage': {
        'page': page,
        'pageSize': pageSize,
        'desc': 1,
        'sort': 'createDate'
      },
      'startDateTime': '$date 00:00:00',
      'endDateTime': '$date 23:59:59'
    });
  }
}

Future<ApiResult<Map<String, dynamic>?>> detectionListResult(int page, int pageSize, {String? date}) {
  if (date == null) {
    return DioService().requestResult<Map<String, dynamic>?>('/detection/page', 'post', body: {
      'userId': Controller.c.user['id'],
      'searchPage': {
        'page': page,
        'pageSize': pageSize,
        'desc': 1,
        'sort': 'createDate'
      },
    });
  } else {
    return DioService().requestResult<Map<String, dynamic>?>(
      '/detection/page',
      'post',
      body: {
        'userId': Controller.c.user['id'],
        'searchPage': {
          'page': page,
          'pageSize': pageSize,
          'desc': 1,
          'sort': 'createDate'
        },
        'startDateTime': '$date 00:00:00',
        'endDateTime': '$date 23:59:59'
      },
    );
  }
}

// 修改某个食物记录的名称
Future detectionModify(int id, dynamic data) =>
    DioService().request('/detection/modify', 'put',
        body: {'userId': '${Controller.c.user['id']}', 'id': id, ...data});

// 目前弃用！ 修改某个食物记录的早中晚餐
Future detectionModify1(int id, String dishName, int mealType) =>
    DioService().request('/detection/modify', 'put', body: {
      'userId': '${Controller.c.user['id']}',
      'id': id,
      'dishName': dishName,
      'mealType': mealType
    });

// 删除某个记录
Future detectionDelete(int id) => DioService().request('/detection/delete', 'delete',
    query: {'id': id});

// 体重记录
Future weightPage(String date) =>
    DioService().request('/weightRecord/page', 'post', body: {
      'date': date,
      'userId': Controller.c.user['id'],
      'searchPage': {'page': 1, 'pageSize': 999, 'desc': 0, 'sort': 'id'}
    });

// 删除体重
Future weightDelete(int id) =>
    DioService().request('/weightRecord/delete', 'delete', body: {'id': id});

// 修改体重
Future weightModify(dynamic data) =>
    DioService().request('/weightRecord/modify', 'put', body: data);

// 新增体重记录
Future weightCreate(double weight) =>
    DioService().request('/weightRecord/create', 'put', body: {
      'userId': Controller.c.user['id'],
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'weight': weight
    });

// 计划集合
Future recipeSetPage() =>
    DioService().request('/recipeSet/page', 'post', body: {
      'visible': 1,
      'searchPage': {'page': 1, 'pageSize': 999, 'desc': 0, 'sort': 'id'}
    });

Future<ApiResult<Map<String, dynamic>?>> recipeSetPageResult() =>
    DioService().requestResult<Map<String, dynamic>?>('/recipeSet/page', 'post', body: {
      'visible': 1,
      'searchPage': {'page': 1, 'pageSize': 999, 'desc': 0, 'sort': 'id'}
    });

// 用户收藏食谱的集合
Future recipeSetCollects() =>
    DioService().request('/user/page/recipeSet', 'post', body: {
      'id': Controller.c.user['id'],
      'searchPage': {'page': 1, 'pageSize': 999, 'desc': 0, 'sort': 'id'}
    });

// 整套计划（所有天数与三餐）
Future recipePlan(int id) =>
    DioService().request('/recipe/plan', 'get', query: {
      'recipeSetId': id,
    });

// 苹果订阅验证
Future appleJwsVerify(String receipt, String productId, String platform) =>
    DioService().request('/apple/jws/verify', 'post', pass: true, body: {
      'receipt': receipt,
      'productId': productId,
      'platform': platform,
      'userId': Controller.c.user['id']
    });

// 新增反馈
Future feedback(String content, String imageUrl) =>
    DioService().request('/feedback/create', 'put', body: {
      "id": Controller.c.user['id'],
      'content': content,
      'imageUrl': imageUrl
    });

/* 一饭封神接口 */
// 食材列表
Future yifanFoodIngredient(int page, int pageSize, {int? type}) =>
    DioService().request('/yifan/recipe/foodIngredient/page', 'post', body: {
      "searchPage": {
        "page": page,
        "pageSize": pageSize,
        "desc": 0,
        "sort": "id"
      },
      if (type != null) "type": type,
    });
// 菜系列表
Future yifanFoodCuisine() =>
    DioService().request('/yifan/recipe/foodCuisine/page', 'post', body: {
      "searchPage": {"page": 1, "pageSize": 999, "desc": 0, "sort": "id"},
    });
// 生成菜品记录列表
Future yifanRecipeResponsePage(
  int page,
  int pageSize,
  int type
) =>
    DioService().request('/yifan/recipe/response/page', 'post', body: {
      "searchPage": {
        "page": page,
        "pageSize": pageSize,
        "desc": 1,
        "sort": "id"
      },
      "type":type,
      "userId": Controller.c.user['id'],
    });
// 删除某个生成菜品记录
Future yifanRecipeResponseDelete(
  int id,
) =>
    DioService().request('/yifan/recipe/response/delete', 'delete', query: {
      "id": id,
    });
// 生成做菜步骤
Future yifanRecipeGenerate(List<String> ingredients, int cuisineId,
        String customPrompt, String locale) =>
    DioService().request('/yifan/recipe/generate', 'post', body: {
      "ingredients": ingredients,
      "cuisine": {
        "id": cuisineId,
      },
      "customPrompt": customPrompt,
      "locale": locale,
      "userId": Controller.c.user['id']
    });
// 生成菜品图片
Future yifanImageGenerate(int id) =>
    DioService().request('/yifan/image/generate', 'post', body: {
      "recipeGenerateId": id,
    });
// 生成营养分析
Future yifanNutritionAnalyze() =>
    DioService().request('/yifan/nutrition/analyze', 'post', body: {});

// 盲盒 - 获取菜品
Future yifanRandomMeal(int mealType, {String? prompt}) =>
    DioService().request('/yifan/random/meal', 'post', body: {
      'locale': Controller.c.user['lang'],
      'mealType': mealType,
      if (prompt != null && prompt.trim().isNotEmpty) 'prompt': prompt,
    });

  // 盲盒 - 获取菜品营养信息
Future yifanRandomMealNutrition(List<String> dishnames) =>
    DioService().request('/yifan/random/meal/nutrition-analysis', 'post', body: {
      'locale': Controller.c.user['lang'],
      'dishNames': dishnames,
    });

// 盲盒 - 保存盲盒到数据库
Future yifanRandomMealSave(String mealName,String imageUrl,String prompt,List<String> dishes, dynamic recipeResponse) =>
    DioService().request('/yifan/random/meal/save','put', body: {
      'locale': Controller.c.user['lang'],
      "userId": Controller.c.user['id'],
      "mealName":mealName,
      'imageUrl':imageUrl,
      'prompt':prompt,
      'dishNames':dishes,
      'recipeResponse': recipeResponse,
    });