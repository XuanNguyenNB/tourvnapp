import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/core/services/onboarding_service.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';
import 'package:tour_vn/features/onboarding/domain/entities/mood.dart';
import 'package:tour_vn/features/onboarding/domain/mood_category_mapping.dart';
import 'package:tour_vn/features/recommendation/data/repositories/user_profile_repository.dart';
import 'package:tour_vn/features/recommendation/domain/entities/user_profile.dart';

/// State cho màn hình cập nhật sở thích (tách khỏi Onboarding)
class UpdatePreferencesState {
  final Set<Mood> selectedMoods;
  final Set<String> selectedDestinationIds;
  final Set<Mood> initialMoods;
  final Set<String> initialDestinationIds;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final bool savedSuccessfully;

  const UpdatePreferencesState({
    this.selectedMoods = const {},
    this.selectedDestinationIds = const {},
    this.initialMoods = const {},
    this.initialDestinationIds = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.savedSuccessfully = false,
  });

  /// Có thay đổi so với ban đầu không?
  bool get hasChanges =>
      !_setsEqual(selectedMoods, initialMoods) ||
      !_setsEqual(selectedDestinationIds, initialDestinationIds);

  /// Có chọn ít nhất 1 mục không?
  bool get hasSelection =>
      selectedMoods.isNotEmpty || selectedDestinationIds.isNotEmpty;

  /// Cho phép lưu khi có thay đổi VÀ có ít nhất 1 lựa chọn
  bool get canSave => hasChanges && hasSelection && !isSaving;

  bool _setsEqual<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);

  UpdatePreferencesState copyWith({
    Set<Mood>? selectedMoods,
    Set<String>? selectedDestinationIds,
    Set<Mood>? initialMoods,
    Set<String>? initialDestinationIds,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool? savedSuccessfully,
  }) {
    return UpdatePreferencesState(
      selectedMoods: selectedMoods ?? this.selectedMoods,
      selectedDestinationIds:
          selectedDestinationIds ?? this.selectedDestinationIds,
      initialMoods: initialMoods ?? this.initialMoods,
      initialDestinationIds:
          initialDestinationIds ?? this.initialDestinationIds,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }
}

/// Notifier quản lý state cho cập nhật sở thích
class UpdatePreferencesNotifier extends Notifier<UpdatePreferencesState> {
  @override
  UpdatePreferencesState build() {
    // Load sở thích hiện tại khi khởi tạo
    _loadCurrentPreferences();
    return const UpdatePreferencesState(isLoading: true);
  }

  /// Load sở thích hiện tại từ local storage
  void _loadCurrentPreferences() {
    try {
      final service = ref.read(onboardingServiceProvider);

      // Load moods
      final currentMoods = service.getMoodPreferencesLocally();

      // Load destinations
      final currentDestIds = service.getDestinationPreferencesLocally();
      final destSet = currentDestIds.toSet();

      state = UpdatePreferencesState(
        selectedMoods: Set.from(currentMoods),
        selectedDestinationIds: destSet,
        initialMoods: Set.from(currentMoods),
        initialDestinationIds: Set.from(destSet),
        isLoading: false,
      );
    } catch (e) {
      state = UpdatePreferencesState(
        isLoading: false,
        error: 'Không thể tải sở thích hiện tại',
      );
    }
  }

  /// Toggle mood selection
  void toggleMood(Mood mood) {
    final current = Set<Mood>.from(state.selectedMoods);
    if (current.contains(mood)) {
      current.remove(mood);
    } else {
      current.add(mood);
    }
    state = state.copyWith(selectedMoods: current);
  }

  /// Toggle destination selection
  void toggleDestination(String destId) {
    final current = Set<String>.from(state.selectedDestinationIds);
    if (current.contains(destId)) {
      current.remove(destId);
    } else {
      current.add(destId);
    }
    state = state.copyWith(selectedDestinationIds: current);
  }

  /// Lưu sở thích (local + Firestore nếu đã đăng nhập)
  Future<bool> savePreferences() async {
    if (!state.canSave) return false;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final service = ref.read(onboardingServiceProvider);
      final currentUser = ref.read(currentUserProvider);

      // 1. Lưu local
      await service.saveMoodPreferencesLocally(state.selectedMoods);
      await service.saveDestinationPreferencesLocally(
        state.selectedDestinationIds.toList(),
      );

      // 2. Lưu Firestore nếu đã đăng nhập
      if (currentUser != null && !currentUser.isAnonymous) {
        try {
          final userRepo = ref.read(userRepositoryProvider);
          final moodNames = state.selectedMoods.map((m) => m.name).toList();
          await userRepo.completeOnboarding(
            currentUser.uid,
            moodNames,
            destinationIds: state.selectedDestinationIds.toList(),
          );
        } catch (_) {
          // Non-critical: local save succeeded
        }

        // 3. Update UserProfile cho recommendation engine
        try {
          final (categoryList, tagList) =
              MoodCategoryMapping.resolve(state.selectedMoods);
          final profile = UserProfile(
            userId: currentUser.uid,
            preferredCategoryIds: categoryList,
            preferredTags: tagList,
            preferredDestinationIds: state.selectedDestinationIds.toList(),
            updatedAt: DateTime.now(),
          );
          final profileRepo = ref.read(userProfileRepositoryProvider);
          await profileRepo.saveProfile(profile);
        } catch (_) {
          // Non-critical
        }
      }

      // Update initial state để reflect saved state
      state = state.copyWith(
        isSaving: false,
        savedSuccessfully: true,
        initialMoods: Set.from(state.selectedMoods),
        initialDestinationIds: Set.from(state.selectedDestinationIds),
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Đã xảy ra lỗi. Vui lòng thử lại.',
      );
      return false;
    }
  }
}

/// Provider cho UpdatePreferencesNotifier
final updatePreferencesProvider =
    NotifierProvider<UpdatePreferencesNotifier, UpdatePreferencesState>(
      UpdatePreferencesNotifier.new,
    );
