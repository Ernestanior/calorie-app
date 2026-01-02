import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdManager {
  static const _storage = FlutterSecureStorage();
  static const _key = 'device_id';
  static const _uuid = Uuid();

  /// 获取设备唯一 ID
  static Future<String> getId() async {
    // 尝试从 Keychain/Keystore 读取
    String? deviceId = await _storage.read(key: _key);

    if (deviceId == null) {
      // 如果没有，就生成一个新的
      deviceId = _uuid.v4();
      await _storage.write(key: _key, value: deviceId);
    }

    return deviceId;
  }

  /// 清空（仅用于调试或账号注销）
  static Future<void> clearId() async {
    await _storage.delete(key: _key);
  }
}
