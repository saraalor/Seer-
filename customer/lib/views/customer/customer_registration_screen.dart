import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../controllers/customer_registration_controller.dart';

// ============================================================
// Saudi Phone Input Formatter
// ============================================================
// - Accepts Arabic-Indic digits and converts them to Western digits
// - Digits only
// - First digit 0, second digit 5
// - At most 10 digits (extra pasted text is cut off)
class SaudiPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text =
        CustomerRegistrationController.normalizeDigits(newValue.text);

    if (text.isEmpty) return const TextEditingValue();

    if (!RegExp(r'^[0-9]+$').hasMatch(text)) return oldValue;
    if (text[0] != '0') return oldValue;
    if (text.length >= 2 && text[1] != '5') return oldValue;

    if (text.length > 10) text = text.substring(0, 10);

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  State<CustomerRegistrationScreen> createState() =>
      _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState
    extends State<CustomerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerRegistrationController _controller =
      CustomerRegistrationController();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final String? error = await _controller.registerCustomer(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      showAppMessage(context, error);
      return;
    }

    showAppMessage(
      context,
      'تم إنشاء الحساب! الرجاء التحقق من بريدك الإلكتروني.',
      isError: false,
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ---------- UI helpers ----------

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CustomerColors.primaryText,
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: CustomerColors.secondaryText),
      prefixIcon: Icon(icon, color: CustomerColors.secondaryText),
      suffixIcon: suffix,
      filled: true,
      fillColor: CustomerColors.fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: _border(CustomerColors.cardBorder),
      enabledBorder: _border(CustomerColors.cardBorder),
      focusedBorder: _border(CustomerColors.accent, 1.6),
      errorBorder: _border(AppStatusColors.error),
      focusedErrorBorder: _border(AppStatusColors.error, 1.6),
    );
  }

  Widget _eyeToggle(bool obscured, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: CustomerColors.secondaryText,
      ),
    );
  }

  // ---------- Live password requirements ----------

  Widget _passwordRequirement(String text, bool valid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: valid ? Colors.green : CustomerColors.secondaryText,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: valid ? Colors.green : CustomerColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordRequirements() {
    final String p = _passwordController.text;
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 4, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _passwordRequirement(
            '8 خانات على الأقل',
            CustomerRegistrationController.hasMinLength(p),
          ),
          _passwordRequirement(
            'حرف إنجليزي كبير (A-Z)',
            CustomerRegistrationController.hasUppercase(p),
          ),
          _passwordRequirement(
            'حرف إنجليزي صغير (a-z)',
            CustomerRegistrationController.hasLowercase(p),
          ),
          _passwordRequirement(
            'رقم واحد على الأقل',
            CustomerRegistrationController.hasNumber(p),
          ),
          _passwordRequirement(
            'رمز خاص مثل ! @ # \$',
            CustomerRegistrationController.hasSpecialChar(p),
          ),
        ],
      ),
    );
  }

  // ---------- Live phone requirements ----------

  Widget _phoneRequirements() {
    final String p = CustomerRegistrationController.normalizeDigits(
      _phoneController.text,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 4, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _passwordRequirement('يبدأ بـ 05', p.startsWith('05')),
          _passwordRequirement('10 أرقام بالضبط', p.length == 10),
        ],
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerColors.background,
      appBar: AppBar(
        backgroundColor: CustomerColors.background,
        foregroundColor: CustomerColors.darkPanel,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          // Each field is checked as soon as the user edits it, so a red
          // error disappears the moment the value becomes valid.
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/icon/icon.jpg',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'سير',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: CustomerColors.primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'إنشاء حساب جديد',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: CustomerColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أنشئ حسابك لطلب المساعدة لمركبتك بسهولة.',
                  style: TextStyle(
                    fontSize: 14,
                    color: CustomerColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 32),

                // First + last name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _fieldLabel('الاسم الأول'),
                          TextFormField(
                            controller: _firstNameController,
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDecoration(
                              hint: '',
                              icon: Icons.person_outline,
                            ),
                            validator:
                                CustomerRegistrationController.validateFirstName,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _fieldLabel('اسم العائلة'),
                          TextFormField(
                            controller: _lastNameController,
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDecoration(
                              hint: '',
                              icon: Icons.person_outline,
                            ),
                            validator:
                                CustomerRegistrationController.validateLastName,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Phone
                _fieldLabel('رقم الجوال'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [SaudiPhoneInputFormatter()],
                  maxLength: 10,
                  onChanged: (_) => setState(() {}),
                  decoration: _fieldDecoration(
                    hint: '05XXXXXXXX',
                    icon: Icons.phone_outlined,
                  ).copyWith(counterText: ''),
                  validator: CustomerRegistrationController.validatePhone,
                ),
                _phoneRequirements(),
                const SizedBox(height: 20),

                // Email
                _fieldLabel('البريد الإلكتروني'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    hint: 'example@email.com',
                    icon: Icons.email_outlined,
                  ),
                  validator: CustomerRegistrationController.validateEmail,
                ),
                const SizedBox(height: 20),

                // Password
                _fieldLabel('كلمة المرور'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: _fieldDecoration(
                    hint: '',
                    icon: Icons.lock_outline,
                    suffix: _eyeToggle(
                      _obscurePassword,
                      () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: CustomerRegistrationController.validatePassword,
                ),
                _passwordRequirements(),
                const SizedBox(height: 20),

                // Confirm password
                _fieldLabel('تأكيد كلمة المرور'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.done,
                  decoration: _fieldDecoration(
                    hint: 'أعد كتابة كلمة المرور',
                    icon: Icons.lock_outline,
                    suffix: _eyeToggle(
                      _obscureConfirm,
                      () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (value) =>
                      CustomerRegistrationController.validateConfirmPassword(
                        value,
                        _passwordController.text,
                      ),
                ),
                const SizedBox(height: 32),

                // Submit
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomerColors.darkPanel,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'إنشاء حساب',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Back to login
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: CustomerColors.primaryText,
                      ),
                      children: [
                        const TextSpan(text: 'لديك حساب؟ '),
                        TextSpan(
                          text: 'سجّل الدخول',
                          style: const TextStyle(
                            color: CustomerColors.accent,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: CustomerColors.accent,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}