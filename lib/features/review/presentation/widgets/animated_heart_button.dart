import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/review_like_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/helpers/sign_in_prompt_helper.dart';

/// Animated heart button for liking reviews.
///
/// Features (Story 3.9):
/// - Scale animation on tap (1.0 → 1.3 → 1.0)
/// - Color transition (gray outline → red filled)
/// - Optimistic updates with rollback on error
/// - Haptic feedback on like/unlike
/// - Auth check with sign-in prompt for anonymous users
/// - Debouncing to prevent rapid taps
class AnimatedHeartButton extends ConsumerStatefulWidget {
  final String reviewId;
  final int initialLikeCount;
  final bool initiallyLiked;
  final bool showCount;
  final double iconSize;

  const AnimatedHeartButton({
    super.key,
    required this.reviewId,
    required this.initialLikeCount,
    this.initiallyLiked = false,
    this.showCount = true,
    this.iconSize = 24,
  });

  @override
  ConsumerState<AnimatedHeartButton> createState() =>
      _AnimatedHeartButtonState();
}

class _AnimatedHeartButtonState extends ConsumerState<AnimatedHeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;
  bool _isLiked = false;
  int _likeCount = 0;

  // Debounce handling
  DateTime? _lastTapTime;
  static const _debounceDelay = Duration(milliseconds: 300);

  // Colors
  static const _likedColor = Color(0xFFEF4444);
  static const _unlikedColor = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initiallyLiked;
    _likeCount = widget.initialLikeCount;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Scale animation: 1.0 → 1.3 → 1.0
    _scaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
      ],
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(AnimatedHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update state if widget props change (e.g., from provider refresh)
    if (oldWidget.initiallyLiked != widget.initiallyLiked) {
      _isLiked = widget.initiallyLiked;
    }
    if (oldWidget.initialLikeCount != widget.initialLikeCount) {
      _likeCount = widget.initialLikeCount;
    }
  }

  /// Handle tap with debouncing and auth check
  Future<void> _handleTap() async {
    // Debounce check
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < _debounceDelay) {
      return;
    }
    _lastTapTime = now;

    if (_isProcessing) return;

    // Check auth state
    final user = ref.read(currentUserProvider);
    if (user == null || user.isAnonymous) {
      _showSignInPrompt();
      return;
    }

    await _performLikeAction();
  }

  /// Perform the like/unlike action with optimistic update
  Future<void> _performLikeAction() async {
    _isProcessing = true;

    // Store previous state for rollback
    final wasLiked = _isLiked;
    final previousCount = _likeCount;

    // Optimistic update
    setState(() {
      _isLiked = !wasLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    // Play animation
    _controller.forward(from: 0);

    // Haptic feedback
    HapticFeedback.lightImpact();

    try {
      final notifier = ref.read(
        reviewLikeNotifierProvider(
          ReviewLikeParams(
            reviewId: widget.reviewId,
            initialLikeCount: widget.initialLikeCount,
            initiallyLiked: widget.initiallyLiked,
          ),
        ).notifier,
      );
      await notifier.toggleLike();
    } catch (e) {
      // Rollback on error
      setState(() {
        _isLiked = wasLiked;
        _likeCount = previousCount;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể thực hiện thao tác. Vui lòng thử lại.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Show sign-in prompt for anonymous users
  void _showSignInPrompt() {
    showSignInPrompt(
      context: context,
      onSignInSuccess: () {
        // After sign-in, perform the like action
        _performLikeAction();
      },
      onDismiss: () {
        // User dismissed without signing in
      },
    );
  }

  /// Format count for display (e.g., 1234 → "1.2k")
  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(_isLiked),
                size: widget.iconSize,
                color: _isLiked ? _likedColor : _unlikedColor,
              ),
            ),
            if (widget.showCount) ...[
              const SizedBox(width: 6),
              Text(
                _formatCount(_likeCount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isLiked ? _likedColor : _unlikedColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
