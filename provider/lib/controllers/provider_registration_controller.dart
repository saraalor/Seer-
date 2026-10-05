/// CONTROLLER: validation rules for the provider's password, phone and national ID.
class ProviderRegistrationController {
  static String? validatePhone(String? value) {
    final String v = normalizeDigits(value?.trim() ?? '');
    if (v.isEmpty) return 'الرجاء إدخال رقم الجوال';
    if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
      return 'رقم الجوال يجب أن يحتوي على أرقام فقط';
    }
    if (!v.startsWith('05')) return 'رقم الجوال يجب أن يبدأ بـ 05';
    if (v.length != 10) return 'رقم الجوال يجب أن يكون 10 أرقام';
    return null;
  }

  static String? validateNationalId(String? value) {
    final String v = normalizeDigits(value?.trim() ?? '');
    if (v.isEmpty) return 'الرجاء إدخال رقم الهوية أو الإقامة';
    if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
      return 'رقم الهوية يجب أن يحتوي على أرقام فقط';
    }
    if (v.length != 10) return 'رقم الهوية يجب أن يكون 10 أرقام بالضبط';
    return null;
  }

  // Password rules. They match the Firebase password policy, so the app and
  // Firebase accept exactly the same passwords. Used by the validator and by
  // the live checklist under the password field.
  static bool hasMinLength(String p) => p.length >= 8;
  static bool hasUppercase(String p) => RegExp(r'[A-Z]').hasMatch(p);
  static bool hasLowercase(String p) => RegExp(r'[a-z]').hasMatch(p);
  static bool hasNumber(String p) => RegExp(r'[0-9]').hasMatch(p);

  /// Special characters Firebase counts as non-alphanumeric. Kept to this
  /// list so the app never accepts a character Firebase would reject.
  static const String specialCharacters = r'^$*.[]{}()?"!@#%&/\,><' "'" r':;|_~`';
  static bool hasSpecialChar(String p) =>
      p.split('').any(specialCharacters.contains);

  static String? validatePassword(String? value) {
    final String v = value ?? '';
    if (v.isEmpty) return 'الرجاء إدخال كلمة المرور';
    if (!hasMinLength(v)) return 'يجب أن تكون كلمة المرور 8 خانات على الأقل';
    if (!hasUppercase(v)) {
      return 'يجب أن تحتوي كلمة المرور على حرف إنجليزي كبير';
    }
    if (!hasLowercase(v)) {
      return 'يجب أن تحتوي كلمة المرور على حرف إنجليزي صغير';
    }
    if (!hasNumber(v)) return 'يجب أن تحتوي كلمة المرور على رقم';
    if (!hasSpecialChar(v)) {
      return 'يجب أن تحتوي كلمة المرور على رمز خاص مثل ! @ # \$';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'الرجاء تأكيد كلمة المرور';
    if (value != password) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  static String normalizeDigits(String input) {
    const String arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    final StringBuffer buffer = StringBuffer();
    for (final String ch in input.split('')) {
      final int index = arabicDigits.indexOf(ch);
      buffer.write(index == -1 ? ch : index);
    }
    return buffer.toString();
  }
}
