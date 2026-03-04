import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/example_provider.dart';

/// Example screen demonstrating Riverpod ConsumerWidget pattern
///
/// This screen showcases:
/// - ConsumerWidget for reactive UI
/// - ref.watch() for observing provider state
/// - AsyncValue.when() for handling loading/error/data states
/// - ref.read().notifier for calling provider actions
/// - Riverpod best practices per architecture.md
class ExampleScreen extends ConsumerWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider - UI rebuilds when state changes
    // Pattern: ref.watch(provider) in build method
    final itemsAsync = ref.watch(exampleItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod Example'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: itemsAsync.when(
        // DATA STATE: Provider has successfully loaded data
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No items yet',
                    style: AppTypography.headingMD.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tap the + button to add your first item',
                    style: AppTypography.bodySM.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: Checkbox(
                    value: item.isCompleted,
                    onChanged: (value) {
                      // Call provider action via notifier
                      // Pattern: ref.read(provider.notifier).method()
                      ref
                          .read(exampleItemsProvider.notifier)
                          .toggleItem(item.id);
                    },
                    activeColor: AppColors.primary,
                  ),
                  title: Text(
                    item.name,
                    style: AppTypography.headingMD.copyWith(
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    item.description,
                    style: AppTypography.bodySM.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      ref
                          .read(exampleItemsProvider.notifier)
                          .deleteItem(item.id);
                    },
                    color: AppColors.error,
                  ),
                ),
              );
            },
          );
        },

        // LOADING STATE: Provider is fetching data (build() in progress)
        loading: () => const Center(child: CircularProgressIndicator()),

        // ERROR STATE: Provider encountered an error during fetch
        error: (error, stackTrace) {
          // Cast to AppException for user-friendly Vietnamese message
          final appError = error as AppException;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Có lỗi xảy ra',
                    style: AppTypography.headingMD.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    appError.message, // User-friendly Vietnamese message
                    style: AppTypography.bodySM.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Invalidate provider to trigger rebuild()
                      // This will call build() again to retry
                      ref.invalidate(exampleItemsProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Show dialog to add new item
  ///
  /// Demonstrates calling provider actions from dialogs
  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Item', style: AppTypography.headingMD),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter item name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final description = descriptionController.text.trim();

              if (name.isNotEmpty) {
                // Call provider action
                ref
                    .read(exampleItemsProvider.notifier)
                    .addItem(
                      name,
                      description.isEmpty ? 'No description' : description,
                    );
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
