# qs_ad_mob

基于 [`google_mobile_ads`](https://pub.dev/packages/google_mobile_ads) 的 AdMob 广告封装插件，提供统一的初始化、UMP 隐私授权与广告展示接口。

当前支持：

- 开屏广告（App Open Ad）
- 插屏广告（Interstitial Ad）
- 激励广告（Rewarded Ad）
- 自适应 Banner 广告及加载占位视图
- UMP 隐私授权和隐私选项入口
- 非 Release 环境的 Google 官方测试广告位、测试设备与收益回调

## 安装

在宿主项目的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  qs_ad_mob: ^1.0.1
```

使用本地插件时：

```yaml
dependencies:
  qs_ad_mob:
    path: ../qs_ad_mob
```

然后执行：

```bash
flutter pub get
```

## 平台配置

请先在 AdMob 后台创建应用及广告单元，并准备 Android 和 iOS 各自的 App ID、开屏、插屏、Banner、激励广告单元 ID。

### Android

在宿主 App 的 `android/app/src/main/AndroidManifest.xml` 的 `application` 节点中添加 AdMob App ID：

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy" />
```

### iOS

在宿主 App 的 `ios/Runner/Info.plist` 中添加：

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

如果应用需要请求 IDFA，请按业务需求添加 `NSUserTrackingUsageDescription`，并自行安排 ATT 授权请求时机。

## 初始化与广告位配置

在 `runApp` 前调用一次 `QsAdMob.configureAd`。所有广告位参数均为必填；插件会在 Release 环境使用这里的正式广告位，在 Debug/Profile 环境自动使用 Google 官方测试广告位。

```dart
import 'package:flutter/material.dart';
import 'package:qs_ad_mob/qs_ad_mob.dart';

void main() {
  QsAdMob.configureAd(
    testDeviceIds: const ['你的测试设备 ID'],
    androidOpenAppAdUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
    iosOpenAppAdUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
    androidInterstitialAdUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
    iosOpenInterstitialUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
    androidBannerAdUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
    iosBannerUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
    androidRewardedAdUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
    iosRewardedAdUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
  );

  runApp(const MyApp());
}
```

`testDeviceIds` 仅在非 Release 环境用于 Google Mobile Ads 的测试设备配置与 UMP 调试配置。

首次使用广告接口时，插件会先请求 UMP 隐私授权信息；在需要时会展示授权表单，并在可请求广告后初始化 Mobile Ads SDK。

## 开屏广告

调用后若广告尚未准备好，插件会先加载，加载成功后继续展示。若页面已离开，可取消这次等待展示。

```dart
QsAdMob.showAppOpenAd(
  onReady: () {
    // Mobile Ads SDK 已就绪。
  },
  onShowing: () {
    // 开屏广告开始展示。
  },
  onAdDismiss: () {
    // 广告已关闭。
  },
  onError: () {
    // 广告加载或展示失败。
  },
  onCanceled: () {
    // 等待展示已取消。
  },
  onPaidEvent: (ad, valueMicros, precision, currencyCode) {
    // 上报广告收益。
  },
);

// 页面离开后，不再等待广告加载完成。
QsAdMob.cancelToShowAppOpenAd();
```

开屏广告关闭或展示失败后，插件会自动预加载下一条；已缓存广告的有效期为 4 小时。

## 插屏广告

建议在业务节点前提前加载。展示关闭后会自动加载下一条；若展示时尚未准备好，插件会触发加载并调用 `onError`。

```dart
// 例如在页面进入后预加载。
QsAdMob.loadInterstitialAd();

QsAdMob.showInterstitialAd(
  onShowing: () {},
  onAdDismiss: () {},
  onError: () {},
  onAdClicked: () {},
  onPaidEvent: (ad, valueMicros, precision, currencyCode) {
    // 上报广告收益。
  },
);
```

## 激励广告

可提前加载，也可以直接展示。直接展示时若广告未准备好，插件会先加载，成功后自动展示。

```dart
// 可选：提前加载。
QsAdMob.loadRewardedAd();

QsAdMob.showRewardedAd(
  onShowing: () {},
  onAdDismiss: () {},
  onError: () {},
  onAdClicked: () {},
  onPaidEvent: (ad, valueMicros, precision, currencyCode) {
    // 上报广告收益。
  },
  onUserEarnedReward: () {
    // 仅在用户实际获得奖励时发放业务奖励。
  },
);
```

激励广告关闭或展示失败后，插件会自动加载下一条。

## Banner 广告

Banner 使用宽度自适应尺寸。需要额外导入 `BannerAdPosition` 枚举和 `QsBannerAdView`：

```dart
import 'package:qs_ad_mob/qs_ad_mob.dart';
import 'package:qs_ad_mob/qs_banner_ad.dart';
import 'package:qs_ad_mob/qs_banner_ad_view.dart';
```

加载广告，并监听成功加载后的 `BannerAd`：

```dart
QsAdMob.loadBannerAd(
  position: BannerAdPosition.bottom,
  adWidth: MediaQuery.sizeOf(context).width,
  onPaidEvent: (ad, valueMicros, precision, currencyCode) {
    // 上报广告收益。
  },
);
```

`bannerAdStream` 是广播流；在需要展示 Banner 的页面中订阅它。`QsBannerAdView` 在广告尚未到达时会显示骨架占位。

```dart
StreamBuilder(
  stream: QsAdMob.bannerAdStream,
  builder: (context, snapshot) {
    return QsBannerAdView(
      bannerAd: snapshot.data,
    );
  },
)
```

`BannerAdPosition.top` 和 `BannerAdPosition.bottom` 会分别作为可折叠 Banner 的 `collapsible` 请求参数传入；实际是否返回可折叠广告由 AdMob 决定。

## 隐私授权

插件在广告 SDK 初始化前自动处理 UMP 授权。应用若需要提供“隐私选项”入口，可调用：

```dart
await QsAdMob.requestPrivacyOptions();
```

判断当前是否已允许请求广告：

```dart
final canRequestAds = await QsAdMob.canRequestAds();
```

开发调试时可重置同意状态，以重新验证授权流程：

```dart
await QsAdMob.resetConsentInfo();
```

`resetConsentInfo` 仅在非 Release 环境生效。

## 注意事项

- 发布前请确认 Android、iOS 的 AdMob App ID 与所有正式广告单元 ID 已替换完成。
- 不要在正式环境点击自己的广告；调试时请使用测试设备或测试广告位。
- 全屏广告应结合页面生命周期和业务流程控制展示频率与时机。
- `onPaidEvent` 的 `valueMicros`、`precision`、`currencyCode` 为广告 SDK 返回的数据，建议按你的数据上报规范原样处理。
- iOS 真机调试前请完成 CocoaPods 安装与更新。

## License

MIT
