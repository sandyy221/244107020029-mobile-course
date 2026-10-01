import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prefs.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());

final darkModeProvider =
    AsyncNotifierProvider(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier {
  @override
  Future build() {
    return ref.read(prefsRepositoryProvider).getDarkMode();
  }

  Future toggle() async {
    final current = state.value ?? false;
    final next = !current;
    
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}