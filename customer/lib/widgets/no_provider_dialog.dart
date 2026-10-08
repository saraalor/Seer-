import 'package:flutter/material.dart';

import '../controllers/matching_controller.dart';
import '../theme/app_colors.dart';

/// VIEW: shown when no nearby provider can take the request (#19).
/// Closing it keeps the customer on the order summary, so they can
/// press "confirm" again whenever they want to retry.
Future<void> showNoProviderDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: CustomerColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: CustomerColors.fieldFill,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.location_off_outlined,
              size: 32,
              color: CustomerColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد مزود خدمة متاح حاليًا',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: CustomerColors.primaryText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'لم نجد مزود خدمة متاح يقدّم هذه الخدمة '
            'في نطاق ${MatchingController.radiusKm.toInt()} كم من موقعك، '
            'ولم يتم إرسال طلبك.\n'
            'يمكنك المحاولة مرة أخرى بالضغط على "تأكيد الطلب".',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: CustomerColors.secondaryText,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: CustomerColors.accent,
            ),
            child: const Text('حسنًا'),
          ),
        ),
      ],
    ),
  );
}