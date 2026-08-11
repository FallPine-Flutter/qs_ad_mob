import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qs_ad_mob/qs_ad_mob.dart';
import 'package:qs_log/qs_log.dart';

class QsInterstitialAd {
  /// Funcs
  /// 配置插页广告
  static void configureInterstitialAd({
    required String androidAdUnitId,
    required String iosAdUnitId,
  }) {
    // 是否是生产环境
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        _adUnitId = androidAdUnitId;
      } else if (Platform.isIOS) {
        _adUnitId = iosAdUnitId;
      }
    } else {
      if (Platform.isAndroid) {
        _adUnitId = "ca-app-pub-3940256099942544/1033173712";
      } else if (Platform.isIOS) {
        _adUnitId = "ca-app-pub-3940256099942544/4411468910";
      }
    }
  }

  /// 加载广告
  Future<void> loadAd() async {
    if (_isLoadingAd || _interstitialAd != null) {
      return;
    }

    _isLoadingAd = true;

    // 检查是否同意广告
    if (!(await QsAdMob.canRequestAds())) {
      _isLoadingAd = false;
      return;
    }

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          QsLog.info('插页广告加载成功');
          _isLoadingAd = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          QsLog.error("插页广告加载失败: $error");

          _isLoadingAd = false;
        },
      ),
    );
  }

  /// 展示广告
  void showAd({
    required VoidCallback onShowing,
    required VoidCallback onAdDismiss,
    required VoidCallback onError,
    required VoidCallback onAdClicked,
    required OnPaidEventCallback onPaidEvent,
  }) {
    if (!_isAdAvailable) {
      QsLog.info('插页广告未准备好，开始加载广告');
      // 加载广告
      loadAd();
      onError();
      return;
    }
    if (_isShowingAd) {
      QsLog.info('插页广告正在展示中，忽略重复展示请求');
      onError();
      return;
    }

    // 设置广告收益事件回调
    _interstitialAd?.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
      QsLog.info(
        '插页广告收益事件: valueMicros=$valueMicros, precision=$precision, currencyCode=$currencyCode',
      );
      onPaidEvent(ad, valueMicros, precision, currencyCode);
    };

    // 设置广告回调并展示广告
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        onShowing();
        QsLog.info('$ad 插页广告开始全屏展示');
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        QsLog.error('$ad 插页广告全屏展示失败: $err');
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        loadAd();
        onError();
      },
      onAdDismissedFullScreenContent: (ad) {
        QsLog.info('$ad 插页广告全屏展示关闭');
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        loadAd();
        onAdDismiss();
      },
      onAdImpression: (ad) {
        // Called when an impression occurs on the ad.
        QsLog.info('Ad recorded an impression.');
      },
      onAdClicked: (ad) {
        onAdClicked();
      },
    );
    _interstitialAd?.show();
  }

  /// 是否有广告可展示
  bool get _isAdAvailable {
    return _interstitialAd != null;
  }

  /// 开屏广告单元ID
  static String _adUnitId = "";
  InterstitialAd? _interstitialAd;
  bool _isLoadingAd = false;
  bool _isShowingAd = false;

  /// 单例
  static QsInterstitialAd? _instance;
  QsInterstitialAd._internal();
  static QsInterstitialAd getInstance() {
    _instance ??= QsInterstitialAd._internal();
    return _instance!;
  }
}
