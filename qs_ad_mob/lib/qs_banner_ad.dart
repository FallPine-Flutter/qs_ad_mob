import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qs_ad_mob/qs_ad_mob.dart';
import 'package:qs_log/qs_log.dart';

enum BannerAdPosition { top, bottom }

class QsBannerAd {
  /// Funcs
  /// 配置banner广告
  static void configureBannerAd({
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
        _adUnitId = "ca-app-pub-3940256099942544/2014213617";
      } else if (Platform.isIOS) {
        _adUnitId = "ca-app-pub-3940256099942544/8388050270";
      }
    }
  }

  void loadAd({
    required BannerAdPosition position,
    required AdSize adSize,
    required OnPaidEventCallback onPaidEvent,
  }) async {
    if (_isLoadingAd) {
      return;
    }
    // 检查是否同意广告
    if (!(await QsAdMob.canRequestAds())) {
      Future.delayed(const Duration(seconds: 5), () {
        loadAd(position: position, adSize: adSize, onPaidEvent: onPaidEvent);
      });
      return;
    }
    _isLoadingAd = true;

    AdRequest adRequest = AdRequest(extras: {"collapsible": position.name});

    unawaited(
      BannerAd(
        adUnitId: _adUnitId,
        request: adRequest,
        size: adSize,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            QsLog.info('Ad was loaded.');
            _isLoadingAd = false;
            bannerAd = ad as BannerAd;
            _bannerAdController.add(bannerAd!);
          },
          onAdFailedToLoad: (ad, err) {
            _isLoadingAd = false;
            QsLog.error('Ad failed to load with error: $err');
            ad.dispose();
          },
          onPaidEvent: (ad, valueMicros, precision, currencyCode) {
            QsLog.info(
              'banner广告收益事件: valueMicros=$valueMicros, precision=$precision, currencyCode=$currencyCode',
            );
            onPaidEvent(ad, valueMicros, precision, currencyCode);
          },
        ),
      ).load(),
    );
  }

  /// 开屏广告单元ID
  static String _adUnitId = "";
  final StreamController<BannerAd> _bannerAdController =
      StreamController<BannerAd>.broadcast();

  /// Banner 广告成功加载通知流
  Stream<BannerAd> get bannerAdStream => _bannerAdController.stream;

  BannerAd? bannerAd;
  bool _isLoadingAd = false;

  /// 单例
  static QsBannerAd? _instance;
  QsBannerAd._internal();
  static QsBannerAd getInstance() {
    _instance ??= QsBannerAd._internal();
    return _instance!;
  }
}
