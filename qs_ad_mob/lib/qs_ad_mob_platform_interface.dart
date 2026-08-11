import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'qs_ad_mob_method_channel.dart';

abstract class QsAdMobPlatform extends PlatformInterface {
  /// Constructs a QsAdMobPlatform.
  QsAdMobPlatform() : super(token: _token);

  static final Object _token = Object();

  static QsAdMobPlatform _instance = MethodChannelQsAdMob();

  /// The default instance of [QsAdMobPlatform] to use.
  ///
  /// Defaults to [MethodChannelQsAdMob].
  static QsAdMobPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [QsAdMobPlatform] when
  /// they register themselves.
  static set instance(QsAdMobPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}
