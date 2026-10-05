import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// CONTROLLER: validation rules and customer account creation.
class CustomerRegistrationController {
  static const Duration _authTimeout = Duration(seconds: 20);
  static const Duration _firestoreTimeout = Duration(seconds: 15);
  static const Duration _emailTimeout = Duration(seconds: 10);

  // ============================================================
  // Registration
  // ============================================================

  /// Returns null on success, or the error message on failure.
  Future<String?> registerCustomer({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
  }) async {
    User? createdUser;

    try {
      debugPrint('1. Starting customer registration...');

      // 1) Create the Firebase Auth account
      final UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(_authTimeout);

      createdUser = credential.user;
      if (createdUser == null) {
        return 'تعذر إنشاء الحساب. الرجاء المحاولة مرة أخرى.';
      }
      debugPrint('2. Auth account created: ${createdUser.uid}');

      // 2) Save the profile in Firestore (with a timeout so loading never hangs)
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(createdUser.uid)
          .set({
            'firstName': firstName.trim(),
            'lastName': lastName.trim(),
            'email': email.trim(),
            'phone': normalizeDigits(phone.trim()),
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(_firestoreTimeout);
      debugPrint('3. Customer data saved');

      // 3) Verification email: if it fails, registration still succeeds
      try {
        await createdUser.sendEmailVerification().timeout(_emailTimeout);
        debugPrint('4. Verification email sent');
      } catch (e) {
        debugPrint('Verification email failed (non-fatal): $e');
      }

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} / ${e.message}');
      switch (e.code) {
        case 'email-already-in-use':
          return 'هذا البريد الإلكتروني مسجل مسبقًا.';
        case 'weak-password':
        // Sent when the Firebase password policy is set to "Require".
        case 'password-does-not-meet-requirements':
          return 'كلمة المرور لا تستوفي الشروط المطلوبة.';
        case 'invalid-email':
          return 'الرجاء إدخال بريد إلكتروني صحيح.';
        case 'network-request-failed':
          return 'تعذر الاتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.';
        case 'too-many-requests':
          return 'محاولات كثيرة. حاول مرة أخرى لاحقًا.';
        default:
          return 'حدث خطأ ما. الرجاء المحاولة مرة أخرى.';
      }
    } on TimeoutException catch (_) {
      debugPrint('Registration timed out');
      await _rollbackUser(createdUser);
      return 'انتهت مهلة الاتصال بالخادم. تأكد من الإنترنت وحاول مرة أخرى.';
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error: ${e.code} / ${e.message}');
      await _rollbackUser(createdUser);
      return 'تعذر حفظ بيانات الحساب. الرجاء المحاولة مرة أخرى.';
    } catch (e) {
      debugPrint('General Registration Error: $e');
      await _rollbackUser(createdUser);
      return 'حدث خطأ ما. الرجاء المحاولة مرة أخرى.';
    }
  }

  /// Deletes the Auth account if saving its profile failed, so no half-made account is left.
  Future<void> _rollbackUser(User? user) async {
    if (user == null) return;
    try {
      await user.delete();
    } catch (e) {
      debugPrint('Rollback failed: $e');
    }
  }

  // ============================================================
  // Validation
  // ============================================================

  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال الاسم الأول';
    }
    return null;
  }

  static String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال اسم العائلة';
    }
    return null;
  }

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

  static String? validateEmail(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح';
    }
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

  // ============================================================
  // Arabic-Indic digits -> Western digits
  // ============================================================
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