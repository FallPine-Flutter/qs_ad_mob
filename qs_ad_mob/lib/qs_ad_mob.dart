import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qs_ad_mob/qs_app_open_ad.dart';
import 'package:qs_ad_mob/qs_interstitial_ad.dart';
import 'package:qs_log/qs_log.dart';

class QsAdMob {
  /// Funcs
  /// 配置广告
  static void configureAd({
    required List<String> testDeviceIds,
    required String androidOpenAppAdUnitId,
    required String iosOpenAppAdUnitId,
    required String androidInterstitialAdUnitId,
    required String iosOpenInterstitialUnitId,
  }) {
    _testDeviceIds = testDeviceIds;
    QsAppOpenAd.configureAppOpenAd(
      androidAdUnitId: androidOpenAppAdUnitId,
      iosAdUnitId: iosOpenAppAdUnitId,
    );
    QsInterstitialAd.configureInterstitialAd(
      androidAdUnitId: androidInterstitialAdUnitId,
      iosAdUnitId: iosOpenInterstitialUnitId,
    );
  }

  /// 初始化
  static void _initialize({required VoidCallback onReady}) {
    if (_initialized) {
      onReady();
      return;
    }
    if (!kReleaseMode) {
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
    }

    // 配置测试参数
    ConsentDebugSettings debugSettings = ConsentDebugSettings(
      // 配置测试设备ID
      testIdentifiers: _testDeviceIds,
      // 配置调试地理位置（模拟欧洲经济区 (EEA)）
      debugGeography: DebugGeography.debugGeographyEea,
    );
    ConsentRequestParameters params = ConsentRequestParameters(
      consentDebugSettings: kReleaseMode ? null : debugSettings,
    );
    // 应用启动时，判断用户是否需要隐私隐私选项
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        // 显示隐私选项表单(如果需要的话，会自动弹出)
        ConsentForm.loadAndShowConsentFormIfRequired((loadAndShowError) {
          if (loadAndShowError != null) {
            QsLog.error(
              "${loadAndShowError.errorCode}: ${loadAndShowError.message}",
            );
          }

          // 初始化Mobile Ads SDK
          _initializeMobileAdsSDK(onReady: onReady);
        });
      },
      (FormError error) {
        QsLog.error("${error.errorCode}: ${error.message}");
        // 初始化Mobile Ads SDK
        _initializeMobileAdsSDK(onReady: onReady);
      },
    );
  }

  /// 初始化Mobile Ads SDK
  static Future<void> _initializeMobileAdsSDK({
    required VoidCallback onReady,
  }) async {
    if (await canRequestAds()) {
      var status = await MobileAds.instance.initialize();
      status.adapterStatuses.forEach((key, value) {
        if (value.state == AdapterInitializationState.ready) {
          _initialized = true;
          onReady();
        }
      });
    }
  }

  /// 请求隐私选项（提供用户后续修改隐私选项的入口）
  static Future<void> requestPrivacyOptions() async {
    // 检查是否需要隐私选项入口
    if (await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required) {
      // 显示隐私选项表单
      ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) {
          QsLog.error("${formError.errorCode}: ${formError.message}");
        }
      });
    }
  }

  /// 是否可以请求广告
  static Future<bool> canRequestAds() async {
    return await ConsentInformation.instance.canRequestAds();
  }

  /// 显示开屏广告
  static void showAppOpenAd({
    required VoidCallback onReady,
    required VoidCallback onShowing,
    required VoidCallback onAdDismiss,
    required VoidCallback onError,
    required VoidCallback onCanceled,
    required OnPaidEventCallback onPaidEvent,
  }) {
    // 初始化广告SDK
    _initialize(
      onReady: () {
        onReady();
        QsAppOpenAd.getInstance().showAd(
          onShowing: onShowing,
          onAdDismiss: onAdDismiss,
          onError: onError,
          onCanceled: onCanceled,
          onPaidEvent: onPaidEvent,
        );
      },
    );
  }

  /// 取消开屏广告展示
  static void cancelToShowAppOpenAd() {
    QsAppOpenAd.getInstance().cancelToShowAd();
  }

  /// 加载插页广告
  static void loadInterstitialAd() {
    _initialize(
      onReady: () {
        QsInterstitialAd.getInstance().loadAd();
      },
    );
  }

  /// 显示插页广告
  static void showInterstitialAd({
    required VoidCallback onShowing,
    required VoidCallback onAdDismiss,
    required VoidCallback onError,
    required VoidCallback onAdClicked,
    required OnPaidEventCallback onPaidEvent,
  }) {
    _initialize(
      onReady: () {
        QsInterstitialAd.getInstance().showAd(
          onShowing: onShowing,
          onAdDismiss: onAdDismiss,
          onError: onError,
          onAdClicked: onAdClicked,
          onPaidEvent: onPaidEvent,
        );
      },
    );
  }

  /// 重置用户隐私同意情况
  static Future<void> resetConsentInfo() async {
    if (!kReleaseMode) {
      ConsentInformation.instance.reset();
    }
  }

  /// Propertys
  static List<String> _testDeviceIds = [];

  /// 是否已经初始化
  static bool _initialized = false;
}
