import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/features/auth/presentation/helpers/sign_in_prompt_helper.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';
import 'package:tour_vn/features/trip/data/repositories/trip_repository.dart';
import 'package:tour_vn/features/trip/data/mappers/trip_mapper.dart';

/// Result of a trip save attempt
enum TripSaveResult {
  /// Trip was saved successfully
  success,

  /// User dismissed sign-in prompt (trip not saved)
  cancelled,

  /// An error occurred during save
  error,
}

/// Notifier for pending trip state
class PendingTripNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void setTrip(Map<String, dynamic> tripData) {
    state = tripData;
  }

  void clear() {
    state = null;
  }
}

/// Provider for pending trip data (trip waiting to be saved after sign-in)
final pendingTripProvider =
    NotifierProvider<PendingTripNotifier, Map<String, dynamic>?>(
      PendingTripNotifier.new,
    );

/// Provider for TripSaveService
final tripSaveServiceProvider = Provider<TripSaveService>((ref) {
  return TripSaveService(ref);
});

/// Service to handle saving trips with auth check
///
/// Implements FR29: Sign-in prompt for trip save
class TripSaveService {
  TripSaveService(this._ref);

  final Ref _ref;

  /// Saves a trip, prompting for sign-in if user is anonymous
  Future<TripSaveResult> saveTrip({
    required BuildContext context,
    required Map<String, dynamic> tripData,
  }) async {
    final isAnonymous = _ref.read(isAnonymousProvider);

    if (!isAnonymous) {
      return _saveDirectly(context, tripData);
    }

    return _saveWithSignInPrompt(context, tripData);
  }

  Future<TripSaveResult> _saveDirectly(
    BuildContext context,
    Map<String, dynamic> tripData,
  ) async {
    try {
      await _saveTripToFirestore(tripData);
      if (context.mounted) {
        HapticFeedback.mediumImpact();
        _showSuccessMessage(context);
      }
      return TripSaveResult.success;
    } catch (e) {
      if (context.mounted) {
        _showErrorMessage(context, e.toString());
      }
      return TripSaveResult.error;
    }
  }

  Future<TripSaveResult> _saveWithSignInPrompt(
    BuildContext context,
    Map<String, dynamic> tripData,
  ) async {
    _ref.read(pendingTripProvider.notifier).setTrip(tripData);

    final completer = Completer<TripSaveResult>();

    await showSignInPrompt(
      context: context,
      onSignInSuccess: () async {
        final pendingTrip = _ref.read(pendingTripProvider);
        if (pendingTrip != null) {
          try {
            await _saveTripToFirestore(pendingTrip);
            _ref.read(pendingTripProvider.notifier).clear();
            if (context.mounted) {
              HapticFeedback.mediumImpact();
              _showSuccessMessage(context);
            }
            completer.complete(TripSaveResult.success);
          } catch (e) {
            if (context.mounted) {
              _showErrorMessage(context, e.toString());
            }
            completer.complete(TripSaveResult.error);
          }
        } else {
          completer.complete(TripSaveResult.error);
        }
      },
      onDismiss: () {
        _ref.read(pendingTripProvider.notifier).clear();
        if (context.mounted) {
          _showDismissMessage(context);
        }
        completer.complete(TripSaveResult.cancelled);
      },
    );

    return completer.future;
  }

  Future<void> _saveTripToFirestore(Map<String, dynamic> tripData) async {
    final repo = _ref.read(tripRepositoryProvider);
    final trip = TripMapper.fromFirestore(tripData);
    await repo.createTrip(trip);
  }

  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã lưu chuyến đi thành công!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showDismissMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Chuyến đi chưa được lưu'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lỗi khi lưu chuyến đi: $error'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
