import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qs_ad_mob/qs_ad_mob.dart';
import 'package:qs_log/qs_log.dart';

class QsRewardedAd {
  /// Funcs
  /// 配置激励广告
  static void configureRewardedAd({
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
        _adUnitId = "ca-app-pub-3940256099942544/5224354917";
      } else if (Platform.isIOS) {
        _adUnitId = "ca-app-pub-3940256099942544/1712485313";
      }
    }
  }

  /// 加载广告
  Future<void> loadAd({required VoidCallback onAdLoaded}) async {
    if (_isLoadingAd || _rewardedAd != null) {
      QsLog.info('激励广告正在加载中，忽略重复加载请求');
      return;
    }

    _isLoadingAd = true;

    // 检查是否同意广告
    if (!(await QsAdMob.canRequestAds())) {
      QsLog.error('激励广告未同意广告，无法加载广告');
      _isLoadingAd = false;
      return;
    }

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          // Called when an ad is successfully received.
          QsLog.info('$ad 激励广告加载成功');
          // Keep a reference to the ad so you can show it later.
          _rewardedAd = ad;
          _isLoadingAd = false;
          onAdLoaded();
        },
        onAdFailedToLoad: (LoadAdError error) {
          // Called when an ad request failed.
          QsLog.error('激励广告加载失败: $error');
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
    required VoidCallback onUserEarnedReward,
  }) {
    if (!_isAdAvailable) {
      QsLog.info('激励广告未准备好，开始加载广告');
      // 加载广告
      loadAd(
        onAdLoaded: () {
          showAd(
            onShowing: onShowing,
            onAdDismiss: onAdDismiss,
            onError: onError,
            onAdClicked: onAdClicked,
            onPaidEvent: onPaidEvent,
            onUserEarnedReward: onUserEarnedReward,
          );
        },
      );
      return;
    }
    if (_isShowingAd) {
      QsLog.info('激励广告正在展示中，忽略重复展示请求');
      onError();
      return;
    }

    // 设置广告收益事件回调
    _rewardedAd?.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
      QsLog.info(
        '激励广告收益事件: valueMicros=$valueMicros, precision=$precision, currencyCode=$currencyCode',
      );
      onPaidEvent(ad, valueMicros, precision, currencyCode);
    };

    // 设置广告回调并展示广告
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        onShowing();
        QsLog.info('$ad 激励广告开始全屏展示');
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        QsLog.error('$ad 激励广告全屏展示失败: $err');
        _isShowingAd = false;
        ad.dispose();
        _rewardedAd = null;
        loadAd(onAdLoaded: () {});
        onError();
      },
      onAdDismissedFullScreenContent: (ad) {
        QsLog.info('$ad 激励广告全屏展示关闭');
        _isShowingAd = false;
        ad.dispose();
        _rewardedAd = null;
        loadAd(onAdLoaded: () {});
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

    _rewardedAd?.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
        QsLog.info('$ad 激励广告用户获得奖励: ${rewardItem.amount}');
        onUserEarnedReward();
      },
    );
  }

  /// 是否有广告可展示
  bool get _isAdAvailable {
    return _rewardedAd != null;
  }

  /// 开屏广告单元ID
  static String _adUnitId = "";
  RewardedAd? _rewardedAd;
  bool _isLoadingAd = false;
  bool _isShowingAd = false;

  /// 单例
  static QsRewardedAd? _instance;
  QsRewardedAd._internal();
  static QsRewardedAd getInstance() {
    _instance ??= QsRewardedAd._internal();
    return _instance!;
  }
}
