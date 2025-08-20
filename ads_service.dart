
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  Future<void> init() async {
    await MobileAds.instance.initialize();
  }

  Future<bool> showRewardedAd() async {
    final c = Completer<bool>();
    await RewardedAd.load(
      adUnitId: RewardedAd.testAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!c.isCompleted) c.complete(false);
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              if (!c.isCompleted) c.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            if (!c.isCompleted) c.complete(true);
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (!c.isCompleted) c.complete(false);
        },
      ),
    );
    return c.future;
  }
}
