import 'package:shared_preferences/shared_preferences.dart';

/// App-enforced trial window for one-time (non-subscription) apps. Subscriptions
/// use the store intro offer instead and do NOT touch this class.
///
/// Duration defaults to {{trial_days}} days (from the manifest) but is read from
/// Remote Config key `trial_days` when present, so you can tune or kill the trial
/// after launch without shipping a release.
class TrialWindow {
  static const _startKey = 'surge_trial_start';
  final int days;
  const TrialWindow(this.days);

  Future<bool> isActive() async {
    final prefs = await SharedPreferences.getInstance();
    final startMs = prefs.getInt(_startKey);
    if (startMs == null) {
      await prefs.setInt(_startKey, DateTime.now().millisecondsSinceEpoch);
      return true;
    }
    final start = DateTime.fromMillisecondsSinceEpoch(startMs);
    return DateTime.now().difference(start).inDays < days;
  }
}
