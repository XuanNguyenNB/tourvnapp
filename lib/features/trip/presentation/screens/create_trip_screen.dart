import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/active_trip_provider.dart';
import '../providers/trip_creation_provider.dart';
import '../widgets/day_count_selector.dart';
import '../widgets/destination_selection_grid.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _tripNameController = TextEditingController();

  @override
  void dispose() {
    _tripNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripCreationProvider);

    // Update text controller if it is out of sync with state tripName
    if (state.tripName != _tripNameController.text) {
      // Need to maintain cursor position
      final selection = _tripNameController.selection;
      _tripNameController.text = state.tripName;
      if (selection.isValid && selection.end <= state.tripName.length) {
        _tripNameController.selection = selection;
      } else {
        _tripNameController.selection = TextSelection.collapsed(
          offset: state.tripName.length,
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: Text(
          'Tạo chuyến đi mới',
          style: AppTypography.headingMD.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('📍 BƯỚC 1: Bạn muốn đi đâu?'),
              const SizedBox(height: 12),
              const DestinationSelectionGrid(),
              const SizedBox(height: 28),

              _SectionTitle('⏱️ BƯỚC 2: Đi mấy ngày?'),
              const SizedBox(height: 12),
              const DayCountSelector(),
              const SizedBox(height: 28),

              _SectionTitle('📝 BƯỚC 3: Tên chuyến đi (tuỳ chọn)'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _tripNameController,
                  maxLength: 50,
                  style: AppTypography.bodyMD,
                  decoration: InputDecoration(
                    hintText: 'VD: Khám phá Ninh Bình',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    ref.read(tripCreationProvider.notifier).setTripName(val);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, ref, state),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    TripCreationState state,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.paddingOf(context).bottom + 80,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: GradientButton(
        onPressed: state.isValid && !state.isCreating
            ? () => _handleCreateTrip(context, ref)
            : null,
        text: '🎒 Tạo chuyến đi',
        isLoading: state.isCreating,
        width: double.infinity,
      ),
    );
  }

  Future<void> _handleCreateTrip(BuildContext context, WidgetRef ref) async {
    final isAnonymous = ref.read(isAnonymousProvider);
    final user = ref.read(currentUserProvider);

    if (user == null || isAnonymous) {
      // Show auth prompt for anonymous users
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để tạo chuyến đi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pushNamed(AppRoutes.login);
      return;
    }

    final notifier = ref.read(tripCreationProvider.notifier);
    final newTrip = await notifier.createTrip();

    if (!context.mounted) return;

    if (newTrip != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo chuyến đi! Thêm hoạt động nhé 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Set active trip to enable Contextual Add Button in Destination Hub
      ref.read(activeTripProvider.notifier).setActiveTrip(newTrip);

      context.pushNamed(
        AppRoutes.destination,
        pathParameters: {'id': newTrip.destinationId},
      );
    } else {
      final error = ref.read(tripCreationProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể tạo chuyến đi: ${error ?? 'Lỗi không xác định'}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: AppTypography.bodyMD.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
