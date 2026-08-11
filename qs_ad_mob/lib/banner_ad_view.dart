import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';

class BannerAdView extends StatelessWidget {
  const BannerAdView({
    super.key,
    this.backgroundColor = Colors.transparent,
    this.size = AdSize.banner,
    this.margin,
    this.padding,
    required this.bannerAd,
  });

  // MARK: - Property
  final Color backgroundColor;
  final AdSize size;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BannerAd? bannerAd;

// MARK: - Widget
  @override
  Widget build(BuildContext context) {
    if (bannerAd == null) {
      return _buildPlaceholder();
    }

    return Container(
      height: size.height.toDouble() + (padding?.vertical ?? 0.0),
      width: size.width.toDouble() + (padding?.horizontal ?? 0.0),
      margin: margin,
      padding: padding,
      color: backgroundColor,
      child: AdWidget(ad: bannerAd!),
    );
  }

  Widget _buildPlaceholder() {
    var shimmerHeight = 8.0;

    return Container(
      height: size.height.toDouble() + (padding?.vertical ?? 0.0),
      width: size.width.toDouble() + (padding?.horizontal ?? 0.0),
      color: backgroundColor,
      child: Shimmer.fromColors(
        baseColor: Colors.grey,
        highlightColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 200.0,
              height: shimmerHeight,
              color: Colors.white,
            ),
            Container(
              width: 250.0,
              height: shimmerHeight,
              color: Colors.white,
            ),
            Container(
              width: 150.0,
              height: shimmerHeight,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
