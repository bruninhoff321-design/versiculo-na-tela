import 'package:flutter/services.dart';

class LockWallpaperService {
  static const _channel =
      MethodChannel('com.versiculonatela.app/widget_scheduler');

  Future<bool> isEnabled() async =>
      await _channel.invokeMethod<bool>('lockWallpaperEnabled') ?? false;

  Future<void> setEnabled(bool enabled) =>
      _channel.invokeMethod<void>('setLockWallpaperEnabled', {
        'enabled': enabled,
      });

  Future<void> refresh() => _channel.invokeMethod<void>('refreshLockWallpaper');
}
