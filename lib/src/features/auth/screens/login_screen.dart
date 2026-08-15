import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/country_codes.dart';
import 'package:tawati_mobile/src/core/error_handler.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';

const _kSubtitleColor = Color(0xFF62707B);
const _kLabelColor = Color(0xFF1A242B);
const _kPlaceholderColor = Color(0xFF9CAFB8);
const _kChipBg = Color(0xFFF1F5F8);
const _kFlagGreen = Color(0xFF006C35);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  CountryCode _selectedCountry = allCountryCodes.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final bio = ref.read(biometricServiceProvider);
    final capable = await bio.isDeviceCapable();
    final enabled = await bio.isEnabled();
    if (mounted) {
      setState(() => _biometricAvailable = capable && enabled);
    }
  }

  Future<void> _loginWithBiometric() async {
    final bio = ref.read(biometricServiceProvider);
    final authed = await bio.authenticate(reason: 'تسجيل الدخول إلى تواتي');
    if (!mounted) return;
    if (!authed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل التحقق من البصمة، حاول مرة أخرى', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final success = await ref.read(authProvider.notifier).loginWithBiometric();
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تسجيل الدخول بالبصمة، استخدم رقم الجوال وكلمة المرور', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'اختر الدولة',
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allCountryCodes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final country = allCountryCodes[index];
                      final isSelected = country.code == _selectedCountry.code;
                      return ListTile(
                        dense: true,
                        leading: Text(
                          country.dialCode,
                          style: TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          country.name,
                          style: const TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 15,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                            : null,
                        onTap: () {
                          setState(() => _selectedCountry = country);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    final raw = _phoneController.text.trim();
    final normalized = _selectedCountry.code == 'SD'
        ? normalizePhone(raw)
        : '${_selectedCountry.dialCode.replaceAll('+', '')}$raw';
    ref.read(authProvider.notifier).login(
          phone: normalized,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated) {
        final name = next.user?.fullNameAr ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('مرحباً $name', style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.goNamed('home');
      } else if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!, style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = (constraints.maxWidth - 64).clamp(0.0, 347.0).toDouble();
              final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
              final fullHeight = constraints.maxHeight + viewInsets;
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(bottom: viewInsets),
                  child: Center(
                    child: SizedBox(
                      height: fullHeight,
                      width: constraints.maxWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: contentWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                        const SizedBox(height: 48),
                        Center(
                          child: Image.asset(
                            'assets/images/splash_logo.png',
                            width: 220,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'الرجاء تسجيل الدخول لمتابعة رحلتك معنا',
                            style: TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: _kSubtitleColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'رقم الهاتف',
                                style: TextStyle(
                                  fontFamily: 'IBMPlexSansArabic',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _kLabelColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'IBMPlexSansArabic',
                                  fontSize: 15,
                                  color: _kLabelColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: '5XX XXX XXXX',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'IBMPlexSansArabic',
                                    color: _kPlaceholderColor,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => _showCountryPicker(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: _kChipBg,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 18,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: _kFlagGreen,
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                _selectedCountry.code,
                                                style: const TextStyle(
                                                  fontFamily: 'IBMPlexSansArabic',
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _selectedCountry.dialCode,
                                              style: const TextStyle(
                                                fontFamily: 'IBMPlexSansArabic',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _kLabelColor,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            const Icon(Icons.expand_more, color: _kPlaceholderColor, size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.error),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'أدخل رقم الجوال';
                                  }
                                  if (v.trim().length < 9) {
                                    return 'رقم الجوال غير صحيح';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'كلمة المرور',
                                      style: TextStyle(
                                        fontFamily: 'IBMPlexSansArabic',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _kLabelColor,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Text(
                                      'نسيت كلمة المرور؟',
                                      style: TextStyle(
                                        fontFamily: 'IBMPlexSansArabic',
                                        fontSize: 13,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () => context.pushNamed('firstLogin'),
                                  child: const Text(
                                    'أول تسجيل دخول؟ فعّل حسابك الآن',
                                    style: TextStyle(
                                      fontFamily: 'IBMPlexSansArabic',
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  fontFamily: 'IBMPlexSansArabic',
                                  fontSize: 15,
                                  color: _kLabelColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'IBMPlexSansArabic',
                                    color: _kPlaceholderColor,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  prefixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _kPlaceholderColor,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  suffixIcon: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Icon(
                                      Icons.lock_outline,
                                      color: _kPlaceholderColor,
                                      size: 20,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.error),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'أدخل كلمة المرور';
                                  }
                                  if (v.length < 6) {
                                    return 'كلمة المرور قصيرة جداً';
                                  }
                                  return null;
                                },
                              ),
                              if (authState.error != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    authState.error!,
                                    style: const TextStyle(
                                      fontFamily: 'IBMPlexSansArabic',
                                      fontSize: 13,
                                      color: AppColors.error,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: authState.isLoading ? null : _onLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    shadowColor: AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                  child: authState.isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'تسجيل الدخول',
                                          style: TextStyle(
                                            fontFamily: 'IBMPlexSansArabic',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              if (_biometricAvailable) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: _loginWithBiometric,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.fingerprint, size: 24),
                                        SizedBox(width: 8),
                                        Text(
                                          'تسجيل الدخول بالبصمة',
                                          style: TextStyle(
                                            fontFamily: 'IBMPlexSansArabic',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: AppColors.border)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'أو عبر',
                                      style: TextStyle(
                                        fontFamily: 'IBMPlexSansArabic',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _kPlaceholderColor,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider(color: AppColors.border)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SocialCard(
                                      label: 'Google',
                                      icon: const _GoogleGIcon(),
                                      onTap: () {},
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _SocialCard(
                                      label: 'Apple',
                                      icon: const _AppleIcon(),
                                      onTap: () {},
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'ليس لديك حساب؟ ',
                                    style: TextStyle(
                                      fontFamily: 'IBMPlexSansArabic',
                                      fontSize: 14,
                                      color: _kSubtitleColor,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.pushNamed('register'),
                                    child: const Text(
                                      'سجل الآن',
                                      style: TextStyle(
                                        fontFamily: 'IBMPlexSansArabic',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
            },
          ),
        ),
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const _SocialCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _kLabelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleGIcon extends StatelessWidget {
  const _GoogleGIcon();

  @override
  Widget build(BuildContext context) {
    return Text(
      'G',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        height: 1,
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0xFF4285F4),
              Color(0xFFEA4335),
              Color(0xFFFBBC05),
              Color(0xFF34A853),
            ],
          ).createShader(const Rect.fromLTWH(0, 0, 16, 16)),
      ),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(16, 16),
      painter: _ApplePainter(),
    );
  }
}

class _ApplePainter extends CustomPainter {
  const _ApplePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _kLabelColor;
    final w = size.width;
    final h = size.height;
    final body = Path()
      ..moveTo(w * 0.50, h * 0.22)
      ..quadraticBezierTo(w * 0.62, h * 0.08, w * 0.76, h * 0.16)
      ..quadraticBezierTo(w * 0.90, h * 0.28, w * 0.84, h * 0.55)
      ..quadraticBezierTo(w * 0.80, h * 0.78, w * 0.62, h * 0.92)
      ..quadraticBezierTo(w * 0.55, h * 0.98, w * 0.50, h * 0.94)
      ..quadraticBezierTo(w * 0.45, h * 0.98, w * 0.38, h * 0.92)
      ..quadraticBezierTo(w * 0.20, h * 0.78, w * 0.16, h * 0.55)
      ..quadraticBezierTo(w * 0.10, h * 0.28, w * 0.24, h * 0.16)
      ..quadraticBezierTo(w * 0.38, h * 0.08, w * 0.50, h * 0.22)
      ..close();
    canvas.drawPath(body, paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.475, 0, w * 0.05, h * 0.24), paint);
  }

  @override
  bool shouldRepaint(covariant _ApplePainter oldDelegate) => false;
}
