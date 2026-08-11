import 'package:flutter_test/flutter_test.dart';
import 'package:qs_ad_mob/qs_ad_mob_platform_interface.dart';
import 'package:qs_ad_mob/qs_ad_mob_method_channel.dart';

void main() {
  final QsAdMobPlatform initialPlatform = QsAdMobPlatform.instance;

  test('$MethodChannelQsAdMob is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelQsAdMob>());
  });
}
