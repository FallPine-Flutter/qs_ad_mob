import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qs_ad_mob/qs_ad_mob.dart';
import 'package:qs_log/qs_log.dart';

class QsAppOpenAd {
  /// Funcs
  /// 配置开屏广告
  static void configureAppOpenAd({
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
        _adUnitId = "ca-app-pub-3940256099942544/9257395921";
      } else if (Platform.isIOS) {
        _adUnitId = "ca-app-pub-3940256099942544/5575463023";
      }
    }
  }

  /// 加载广告
  Future<void> _loadAd() async {
    if (_isLoadingAd) {
      return;
    }

    _isLoadingAd = true;

    // 检查是否同意广告
    if (!(await QsAdMob.canRequestAds())) {
      _isLoadingAd = false;
      _isPendingShowAd = false;
      _pendingShowAdCallbacks?.onError();
      _pendingShowAdCallbacks = null;
      return;
    }

    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          QsLog.info('开屏广告加载成功');

          _isLoadingAd = false;
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          if (_isPendingShowAd) {
            final callbacks = _pendingShowAdCallbacks;
            if (callbacks != null) {
              showAd(
                onShowing: callbacks.onShowing,
                onAdDismiss: callbacks.onAdDismiss,
                onError: callbacks.onError,
                onCanceled: callbacks.onCanceled,
                onPaidEvent: callbacks.onPaidEvent,
              );
            }
          }
        },
        onAdFailedToLoad: (error) {
          QsLog.error("开屏广告加载失败: $error");

          _isLoadingAd = false;
          _isPendingShowAd = false;
          _pendingShowAdCallbacks?.onError();
          _pendingShowAdCallbacks = null;
        },
      ),
    );
  }

  /// 展示广告
  void showAd({
    required VoidCallback onShowing,
    required VoidCallback onAdDismiss,
    required VoidCallback onError,
    required VoidCallback onCanceled,
    required OnPaidEventCallback onPaidEvent,
  }) {
    if (!_isAdAvailable) {
      QsLog.info('开屏广告未准备好，开始加载广告');
      _isPendingShowAd = true;
      _pendingShowAdCallbacks = _AppOpenAdCallbacks(
        onShowing: onShowing,
        onAdDismiss: onAdDismiss,
        onError: onError,
        onCanceled: onCanceled,
        onPaidEvent: onPaidEvent,
      );
      _loadAd();
      return;
    }
    if (_isShowingAd) {
      QsLog.info('开屏广告正在展示中，忽略重复展示请求');
      onError();
      return;
    }

    /// 考虑广告有效期，超过有效期则重新加载广告
    if (DateTime.now().subtract(_maxCacheDuration).isAfter(_appOpenLoadTime!)) {
      QsLog.error('开屏广告缓存已过期，重新加载广告');
      _appOpenAd!.dispose();
      _appOpenAd = null;
      _isPendingShowAd = true;
      _pendingShowAdCallbacks = _AppOpenAdCallbacks(
        onShowing: onShowing,
        onAdDismiss: onAdDismiss,
        onError: onError,
        onCanceled: onCanceled,
        onPaidEvent: onPaidEvent,
      );
      _loadAd();
      return;
    }

    // 设置广告收益事件回调
    _appOpenAd?.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
      QsLog.info(
        '开屏广告收益事件: valueMicros=$valueMicros, precision=$precision, currencyCode=$currencyCode',
      );
      onPaidEvent(ad, valueMicros, precision, currencyCode);
    };

    // 设置全屏广告回调并展示广告
    _isPendingShowAd = false;
    _pendingShowAdCallbacks = null;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        onShowing();
        QsLog.info('$ad 开屏广告开始全屏展示');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        QsLog.error('$ad 开屏广告全屏展示失败: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        onError();
        _loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        QsLog.info('$ad 开屏广告全屏展示关闭');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        onAdDismiss();
        _loadAd();
      },
    );
    _appOpenAd!.show();
  }

  /// 取消广告展示
  void cancelToShowAd() {
    if (_isPendingShowAd) {
      _pendingShowAdCallbacks?.onCanceled();
      _pendingShowAdCallbacks = null;
    }
    _isPendingShowAd = false;
  }

  /// 是否有广告可展示
  bool get _isAdAvailable {
    return _appOpenAd != null;
  }

  /// 开屏广告单元ID
  static String _adUnitId = "";
  AppOpenAd? _appOpenAd;
  bool _isLoadingAd = false;
  bool _isShowingAd = false;

  // 广告有效期4小时
  final Duration _maxCacheDuration = Duration(hours: 4);
  // 保存广告加载时间
  DateTime? _appOpenLoadTime;
  // 是否有等待加载完成后展示的请求
  bool _isPendingShowAd = false;
  _AppOpenAdCallbacks? _pendingShowAdCallbacks;

  /// 单例
  static QsAppOpenAd? _instance;
  QsAppOpenAd._internal();
  static QsAppOpenAd getInstance() {
    _instance ??= QsAppOpenAd._internal();
    return _instance!;
  }
}

class _AppOpenAdCallbacks {
  const _AppOpenAdCallbacks({
    required this.onShowing,
    required this.onAdDismiss,
    required this.onError,
    required this.onCanceled,
    required this.onPaidEvent,
  });

  final VoidCallback onShowing;
  final VoidCallback onAdDismiss;
  final VoidCallback onError;
  final VoidCallback onCanceled;
  final OnPaidEventCallback onPaidEvent;
}
