# qs_ad_mob

谷歌 AdMob 广告封装插件，基于 `google_mobile_ads`，目前支持：

- 开屏广告 App Open Ad
- 插屏广告 Interstitial Ad
- UMP 隐私授权流程
- 测试设备配置
- 广告收益事件回调 `onPaidEvent`

## 安装

在项目的 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  qs_ad_mob: ^1.0.0
```

如果是本地依赖：

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

接入前需要先在 AdMob 后台创建应用和广告单元，并分别准备：

- Android App ID
- iOS App ID
- Android 开屏广告单元 ID
- iOS 开屏广告单元 ID
- Android 插屏广告单元 ID
- iOS 插屏广告单元 ID

### Android

在宿主 App 的 `android/app/src/main/AndroidManifest.xml` 中，给 `application` 添加 AdMob App ID：

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy" />
    </application>
</manifest>
```

### iOS

在宿主 App 的 `ios/Runner/Info.plist` 中添加 AdMob App ID：

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

如应用需要请求 IDFA，请在宿主 App 中按业务需要补充 `NSUserTrackingUsageDescription`，并自行处理 ATT 授权时机。

## 初始化广告配置

建议在 App 启动阶段先调用一次 `configureAd`，用于配置正式广告位和测试设备 ID。

```dart
import 'package:qs_ad_mob/qs_ad_mob.dart';

void main() {
  QsAdMob.configureAd(
    testDeviceIds: [
      '你的测试设备ID',
    ],
    androidOpenAppAdUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
    iosOpenAppAdUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
    androidInterstitialAdUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
    iosOpenInterstitialUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
  );

  runApp(const MyApp());
}
```

说明：

- Debug/Profile 环境会自动使用 Google 官方测试广告位。
- Release 环境会使用 `configureAd` 传入的正式广告位。
- `testDeviceIds` 只在非 Release 环境用于测试设备和 UMP 调试配置。

## 开屏广告

调用 `showAppOpenAd` 会自动触发隐私授权检查和 Mobile Ads SDK 初始化。广告未加载完成时，会先加载广告，加载成功后继续展示。

```dart
QsAdMob.showAppOpenAd(
  onReady: () {
    // SDK 已准备好
  },
  onShowing: () {
    // 开屏广告开始展示
  },
  onAdDismiss: () {
    // 开屏广告关闭
  },
  onError: () {
    // 开屏广告加载或展示失败
  },
  onCanceled: () {
    // 已取消本次等待展示
  },
  onPaidEvent: (ad, valueMicros, precision, currencyCode) {
    // 广告收益事件
  },
);
```

如果页面已经离开，或不再需要等待开屏广告展示，可以取消本次等待：

```dart
QsAdMob.cancelToShowAppOpenAd();
```

## 插屏广告

建议在合适的时机提前加载插屏广告：

```dart
QsAdMob.loadInterstitialAd();
```

在业务节点展示插屏广告：

```dart
QsAdMob.showInterstitialAd(
  onShowing: () {
    // 插屏广告开始展示
  },
  onAdDismiss: () {
    // 插屏广告关闭
  },
  onError: () {
    // 插屏广告未准备好、加载失败或展示失败
  },
  onAdClicked: () {
    // 插屏广告被点击
  },
  onPaidEvent: (ad, valueMicros, precision, currencyCode) {
    // 广告收益事件
  },
);
```

说明：

- 插屏广告展示关闭后，插件会自动加载下一条广告。
- 如果展示时广告未准备好，插件会触发一次加载并回调 `onError`。

## 隐私授权

插件内部会在初始化广告前请求 UMP 隐私授权信息，并在需要时展示授权表单。

如果应用内需要提供“隐私选项”入口，可以调用：

```dart
await QsAdMob.requestPrivacyOptions();
```

判断当前是否可以请求广告：

```dart
final canRequestAds = await QsAdMob.canRequestAds();
```

开发调试时可以重置用户隐私同意状态：

```dart
await QsAdMob.resetConsentInfo();
```

`resetConsentInfo` 只会在非 Release 环境生效。

## 完整示例

```dart
import 'package:flutter/material.dart';
import 'package:qs_ad_mob/qs_ad_mob.dart';

void main() {
  QsAdMob.configureAd(
    testDeviceIds: const [],
    androidOpenAppAdUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
    iosOpenAppAdUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
    androidInterstitialAdUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
    iosOpenInterstitialUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('QsAdMob Demo')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  QsAdMob.showAppOpenAd(
                    onReady: () {},
                    onShowing: () {},
                    onAdDismiss: () {},
                    onError: () {},
                    onCanceled: () {},
                    onPaidEvent: (ad, valueMicros, precision, currencyCode) {},
                  );
                },
                child: const Text('Show App Open Ad'),
              ),
              ElevatedButton(
                onPressed: () {
                  QsAdMob.showInterstitialAd(
                    onShowing: () {},
                    onAdDismiss: () {},
                    onError: () {},
                    onAdClicked: () {},
                    onPaidEvent: (ad, valueMicros, precision, currencyCode) {},
                  );
                },
                child: const Text('Show Interstitial Ad'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 注意事项

- 发布前请确认已替换为自己的 AdMob App ID 和广告单元 ID。
- 不要在正式环境点击自己的广告，调试阶段请使用测试设备或测试广告位。
- 开屏广告和插屏广告都是全屏广告，请结合页面生命周期和业务流程控制展示时机。
- iOS 真机调试前建议先完成 CocoaPods 安装和更新。

## License

MIT
