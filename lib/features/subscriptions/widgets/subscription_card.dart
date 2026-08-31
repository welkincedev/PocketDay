// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: subscription_card.dart
//
// Purpose:
// Interactive 3D flip card component representing a digital subscription membership card.
//
// Responsibilities:
// - Render card front (Logo, subscription name, amount, billing cycle, status pill, auto badge).
// - Render card back on tap flip animation (Category, payment method, start date, next due date, notes, edit & delete buttons).
// - Apply dynamic brand gradient styling based on subscription name or category.
//
// Data Flow:
// SubscriptionModel → SubscriptionCard → User Flip Gesture / Action Callbacks
//
// Important Rules:
// - Height constraint fixed at 210px to prevent unbounded flex overflow in scroll views.
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/subscription_model.dart';

/// # Developer Notes
///
/// Digital Card representation of a subscription inspired by a membership/payment card.
///
/// ## Features
/// - Smooth 3D Y-axis flip animation on tap to reveal front and back.
/// - Front displays subscription name, logo badge, amount, billing cycle, status pill, and next payment date.
/// - Back displays comprehensive details (category, payment method, start date, status) plus Edit & Delete action buttons.
/// - Fixed bounded height constraint (210px) to prevent unbounded flex layout errors.
class SubscriptionCard extends StatefulWidget {
  final SubscriptionModel subscription;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animation = Tween<double>(
      begin: 0,
      end: pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (!mounted || _controller.isAnimating) return;
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  /// Brand styling helper based on subscription name or category.
  List<Color> _getCardGradient(bool isDark) {
    final name = widget.subscription.name.toLowerCase();
    if (name.contains('netflix')) {
      return [const Color(0xFFE50914), const Color(0xFF800000)];
    } else if (name.contains('spotify')) {
      return [const Color(0xFF1DB954), const Color(0xFF0F5226)];
    } else if (name.contains('youtube')) {
      return [const Color(0xFFFF0000), const Color(0xFF8B0000)];
    } else if (name.contains('amazon') || name.contains('prime')) {
      return [const Color(0xFF00A8E8), const Color(0xFF003459)];
    } else if (name.contains('adobe')) {
      return [const Color(0xFFFF0000), const Color(0xFF4A00E0)];
    } else if (name.contains('apple') || name.contains('icloud')) {
      return isDark
          ? [const Color(0xFF333333), const Color(0xFF111111)]
          : [const Color(0xFF666666), const Color(0xFF333333)];
    } else if (name.contains('google')) {
      return [const Color(0xFF4285F4), const Color(0xFF0D47A1)];
    }

    // Default category fallback gradients
    switch (widget.subscription.category.toLowerCase()) {
      case 'entertainment':
        return isDark
            ? [const Color(0xFF6B21A8), const Color(0xFF3B0764)]
            : [const Color(0xFF9333EA), const Color(0xFF6B21A8)];
      case 'utilities':
      case 'internet':
        return isDark
            ? [const Color(0xFF0369A1), const Color(0xFF0C4A6E)]
            : [const Color(0xFF0284C7), const Color(0xFF0369A1)];
      case 'fitness':
      case 'gym':
        return isDark
            ? [const Color(0xFFC2410C), const Color(0xFF7C2D12)]
            : [const Color(0xFFEA580C), const Color(0xFFC2410C)];
      case 'software':
      case 'cloud':
        return isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [const Color(0xFF0F766E), const Color(0xFF115E59)];
      default:
        return isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [const Color(0xFF059669), const Color(0xFF10B981)];
    }
  }

  IconData _getCategoryIcon() {
    final name = widget.subscription.name.toLowerCase();
    if (name.contains('netflix') ||
        name.contains('youtube') ||
        name.contains('prime')) {
      return Icons.movie_rounded;
    } else if (name.contains('spotify') || name.contains('music')) {
      return Icons.music_note_rounded;
    } else if (name.contains('cloud') ||
        name.contains('google') ||
        name.contains('icloud')) {
      return Icons.cloud_rounded;
    } else if (name.contains('gym') || name.contains('fitness')) {
      return Icons.fitness_center_rounded;
    }
    switch (widget.subscription.category.toLowerCase()) {
      case 'entertainment':
        return Icons.movie_rounded;
      case 'utilities':
        return Icons.bolt_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'software':
        return Icons.code_rounded;
      default:
        return Icons.subscriptions_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = _getCardGradient(isDark);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value;
        final isFrontSide = angle < (pi / 2);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: _flipCard,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              height: 210,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withAlpha(50),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: isFrontSide
                  ? _buildFront(context)
                  : Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: _buildBack(context),
                    ),
            ),
          ),
        );
      },
    );
  }

  /// Front view of digital card.
  Widget _buildFront(BuildContext context) {
    final sub = widget.subscription;
    final dateStr = DateFormat('dd MMM yyyy').format(sub.nextPaymentDate);
    final isPaused = sub.status == SubscriptionStatus.paused;
    final isCancelled = sub.status == SubscriptionStatus.cancelled;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Logo Badge + Status Pill + Flip Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(60),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(_getCategoryIcon(), color: Colors.white, size: 20),
              ),

              // Status Pill + Auto-Expense Badge + Flip Indicator
              Row(
                children: [
                  if (sub.autoRecordExpense) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.autorenew_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'AUTO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sub.status.color.withAlpha(45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sub.status.color.withAlpha(120),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sub.status.color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          sub.status.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.flip_rounded,
                    size: 18,
                    color: Colors.white.withAlpha(200),
                  ),
                ],
              ),
            ],
          ),

          // Name & Amount Group
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sub.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      CurrencyFormatter.format(sub.amount),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sub.billingCycle.shortLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withAlpha(230),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Bottom Bar: Next Payment & Flip Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT PAYMENT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.white.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCancelled ? 'Cancelled' : (isPaused ? 'Paused' : dateStr),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCancelled
                          ? Colors.white.withAlpha(160)
                          : Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                'Tap to flip ↺',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withAlpha(170),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Back view of digital card.
  Widget _buildBack(BuildContext context) {
    final sub = widget.subscription;
    final startDateStr = DateFormat('dd MMM yyyy').format(sub.startDate);
    final nextDateStr = DateFormat('dd MMM yyyy').format(sub.nextPaymentDate);

    return Column(
      children: [
        // Magnetic Strip Header Bar
        Container(
          width: double.infinity,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(120),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SUBSCRIPTION DETAILS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white.withAlpha(200),
                ),
              ),
              Text(
                'Flip ↺',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withAlpha(180),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Details Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailField(
                        label: 'CATEGORY',
                        value: sub.category,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDetailField(
                        label: 'PAYMENT METHOD',
                        value: sub.paymentMethod,
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: _buildDetailField(
                        label: 'START DATE',
                        value: startDateStr,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDetailField(
                        label: 'NEXT DUE',
                        value: nextDateStr,
                      ),
                    ),
                  ],
                ),

                if (sub.notes != null && sub.notes!.isNotEmpty)
                  Text(
                    'NOTES: ${sub.notes}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withAlpha(200),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Action Buttons Row (Edit & Delete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Material(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: widget.onEdit,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.expense.withAlpha(180),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: widget.onDelete,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Colors.white.withAlpha(170),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
