import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProviderSuccessScreen extends StatelessWidget {
  const ProviderSuccessScreen({super.key, this.verificationEmailSent = true});

  final bool verificationEmailSent;

  static const Color navy = Color(0xFF0F1B4C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 24),
              const Text(
                'شكرًا لتسجيلك معنا!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 12),
              // Step 1: the provider must verify their email first.
              Text(
                verificationEmailSent
                    ? 'أرسلنا رابط تفعيل إلى بريدك الإلكتروني. افتح الرابط لتفعيل حسابك.'
                    : 'تعذر إرسال رابط التفعيل الآن. سجّل الدخول وستظهر لك خيارات إعادة الإرسال.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              // Step 2: only verified accounts reach the admin for review.
              const Text(
                'بعد التفعيل، يصل طلبك للإدارة للمراجعة، ويمكنك تسجيل الدخول بعد اعتماده.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'العودة إلى تسجيل الدخول',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}