import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/country_codes.dart';
import 'package:tawati_mobile/src/core/error_handler.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';

class FirstLoginScreen extends ConsumerStatefulWidget {
  const FirstLoginScreen({super.key});

  @override
  ConsumerState<FirstLoginScreen> createState() => _FirstLoginScreenState();
}

class _FirstLoginScreenState extends ConsumerState<FirstLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  CountryCode _selectedCountry = allCountryCodes.first;
  bool _otpSent = false;
  bool _pinSet = false;
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _obscureConfirm = true;
  bool _canResend = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  String get _normalizedPhone {
    final raw = _phoneController.text.trim();
    return _selectedCountry.code == 'SD'
        ? normalizePhone(raw)
        : '${_selectedCountry.dialCode.replaceAll('+', '')}$raw';
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).sendOtp(phone: _normalizedPhone);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(friendlyError(e));
    }
  }

  Future<void> _setPin() async {
    final pin = _pinController.text;
    if (pin.length < 4) {
      _showError('أدخل PIN من 4 أرقام على الأقل');
      return;
    }
    if (pin != _confirmPinController.text) {
      _showError('تأكيد PIN غير مطابق');
      return;
    }
    if (_otpController.text.length != 6) {
      _showError('أدخل رمز التحقق المكوّن من 6 أرقام');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authProvider.notifier).setPinAndLogin(
            phone: _normalizedPhone,
            otp: _otpController.text,
            pin: pin,
          );
      if (!mounted) return;
      final needsSetup = result['needs_family_setup'] == true;
      final userId = result['user_id'];
      setState(() => _isLoading = false);
      if (needsSetup && userId != null) {
        context.goNamed('familySetup', extra: {'userId': userId});
      } else {
        context.goNamed('home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(friendlyError(e));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'أول تسجيل دخول',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline, size: 40, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'تفعيل حسابك',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'أدخل رقم جوالك لاستلام رمز التحقق، ثم اختر رمز PIN للدخول',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 32),

                const Text('رقم الجوال', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_otpSent,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
                  decoration: InputDecoration(
                    hintText: '912345678',
                    hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surface,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.phone_in_talk_outlined, color: AppColors.textHint, size: 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل رقم الجوال';
                    if (v.trim().length < 9) return 'رقم الجوال غير صحيح';
                    return null;
                  },
                ),
                if (!_otpSent) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('إرسال رمز التحقق', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],

                if (_otpSent) ...[
                  const SizedBox(height: 24),
                  const Text('رمز التحقق', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, letterSpacing: 6),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                      hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.surface,
                      prefixIcon: const Icon(Icons.sms_outlined, color: AppColors.textHint, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'لم يصلك الرمز؟ ',
                        style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: _canResend ? _sendOtp : null,
                        child: Text(
                          _canResend ? 'إعادة الإرسال' : 'إعادة الإرسال بعد $_secondsRemaining ثانية',
                          style: TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _canResend ? AppColors.primary : AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('اختر رمز PIN', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pinController,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, letterSpacing: 6),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.surface,
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textHint, size: 20),
                        onPressed: () => setState(() => _obscurePin = !_obscurePin),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('تأكيد رمز PIN', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPinController,
                    obscureText: _obscureConfirm,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, letterSpacing: 6),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.surface,
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textHint, size: 20),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _setPin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('تفعيل الحساب', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
