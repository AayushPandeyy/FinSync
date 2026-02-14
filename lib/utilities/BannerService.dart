import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerService {
  InterstitialAd? _interstitialAd;

  void showInterstitialAd() {
    InterstitialAd.load(
      // adUnitId: 'ca-app-pub-3940256099942544/1033173712', // test Ad Unit ID
      adUnitId: 'ca-app-pub-3804780729029008/1042521213',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
          _interstitialAd!.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }
}
