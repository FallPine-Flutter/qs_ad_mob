import 'package:flutter_test/flutter_test.dart';
import 'package:qs_ad_mob/qs_ad_mob_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('$MethodChannelQsAdMob can be created', () {
    final platform = MethodChannelQsAdMob();
    expect(platform, isA<MethodChannelQsAdMob>());
  });
}
