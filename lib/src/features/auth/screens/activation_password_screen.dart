import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/error_handler.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';

class ActivationPasswordScreen extends ConsumerStatefulWidget {
  final String phone;
  const ActivationPasswordScreen({super.key, required this.phone});

  @override
  ConsumerState<ActivationPasswordScreen> createState() => _ActivationPasswordScreenState();
}

class _ActivationPasswordScreenState extends ConsumerState<ActivationPasswordScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _setPin() async {
    final pin = _pinController.text;
    if (pin.length < 4) {
      _showError('أدخل كلمة مرور من 4 أرقام على الأقل');
      return;
    }
    if (pin != _confirmPinController.text) {
      _showError('تأكيد كلمة المرور غير مطابق');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ref.read(authProvider.notifier).setPinAndLogin(
            phone: widget.phone,
            otp: '',
            pin: pin,
          );
      if (!mounted) return;
      final name = ref.read(authProvider).user?.fullNameAr ?? '';
      final needsSetup = result['needs_family_setup'] == true;
      final userId = result['user_id'];
      context.pushReplacementNamed(
        'activationSuccess',
        extra: {'name': name, 'needsSetup': needsSetup, 'userId': userId},
      );
    } catch (e) {
      if (!mounted) return;
      _showError(friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
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
          title: const Text('تعيين كلمة المرور',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.lock_outline, size: 40, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('تعيين كلمة المرور الجديدة',
                    style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'اختر كلمة مرور قوية لحماية حسابك',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 32),
              const Text('كلمة المرور', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('تأكيد كلمة المرور', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _setPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('تفعيل الحساب', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
