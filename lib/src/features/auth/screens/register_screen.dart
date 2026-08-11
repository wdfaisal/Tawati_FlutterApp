import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/country_codes.dart';
import 'package:tawati_mobile/src/core/error_handler.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/features/surveys/models/survey_template.dart';
import 'package:tawati_mobile/src/features/surveys/widgets/dynamic_form.dart';

class ChildData {
  String firstName;
  String fatherName;
  String grandName;
  String familyName;
  String gender;
  int? age;
  String? nationalId;

  ChildData({
    this.firstName = '',
    this.fatherName = '',
    this.grandName = '',
    this.familyName = '',
    this.gender = 'male',
    this.age,
    this.nationalId,
  });

  String get fullName => '$firstName $fatherName $grandName $familyName';
}

class RegisterScreen extends ConsumerStatefulWidget {
  final bool showJoinOnly;
  const RegisterScreen({super.key, this.showJoinOnly = false});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isJoinFlow = false;

  final _picker = ImagePicker();
  String? _profileImagePath;

  CountryCode _selectedCountry = allCountryCodes.first;
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  DateTime? _selectedDate;
  String _gender = 'male';

  String _maritalStatus = 'single';
  final _spouseNameCtrl = TextEditingController();
  bool _hasChildren = false;
  int _childCount = 0;
  final List<ChildData> _children = [];

  SurveyTemplate? _surveyTemplate;

  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool get _hasMin8Chars => _passwordCtrl.text.length >= 8;
  bool get _hasLetters => _passwordCtrl.text.contains(RegExp(r'[a-zA-Z\u0621-\u064A]'));
  bool get _hasNumbers => _passwordCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _passwordsMatch => _passwordCtrl.text.isNotEmpty && _passwordCtrl.text == _confirmPasswordCtrl.text;
  bool get _passwordValid => _hasMin8Chars && _hasLetters && _hasNumbers && _passwordsMatch;

  int get _totalSteps {
    int count = 5;
    if (_surveyTemplate != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _isJoinFlow = widget.showJoinOnly;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final extra = GoRouterState.of(context).extra;
      if (extra is Map && extra['join'] == true) {
        setState(() => _isJoinFlow = true);
      }
      if (!_isJoinFlow) _loadSurvey();
    });
  }

  Future<void> _loadSurvey() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/surveys/registration');
      if (mounted) {
        setState(() {
          _surveyTemplate = SurveyTemplate.fromJson(res.data['data']);
        });
      }
    } catch (e) {
      debugPrint('_loadSurvey: failed to load registration survey: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _nationalIdCtrl.dispose();
    _spouseNameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  bool _validateCurrentStep() {
    final hasSurvey = _surveyTemplate != null;
    // Personal data (always index 0)
    if (_currentStep == 0) {
      if (_fullNameCtrl.text.trim().isEmpty || _fullNameCtrl.text.trim().split(' ').length < 4) {
        _showError('أدخل الاسم الرباعي كاملاً (الاسم - الأب - الجد - العائلة)');
        return false;
      }
      if (_phoneCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().length < 6) {
        _showError('أدخل رقم جوال صحيح');
        return false;
      }
      return true;
    }
    // Marital status (always index 1)
    if (_currentStep == 1) {
      if (_maritalStatus == 'married' || _maritalStatus == 'widowed') {
        if (_spouseNameCtrl.text.trim().isEmpty || _spouseNameCtrl.text.trim().split(' ').length < 4) {
          _showError('أدخل اسم الزوج/الزوجة رباعياً');
          return false;
        }
      }
      return true;
    }
    // Password step (index 3 without survey, index 4 with survey)
    final passwordIdx = hasSurvey ? 4 : 3;
    if (_currentStep == passwordIdx) {
      if (!_passwordValid) {
        _showError('تأكد من استيفاء جميع شروط كلمة المرور');
        return false;
      }
      return true;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _submitNewFamily() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final fullName = _fullNameCtrl.text.trim();
      final spouseName = (_maritalStatus == 'married' || _maritalStatus == 'widowed')
          ? _spouseNameCtrl.text.trim()
          : null;

      await api.post('/registration-requests', data: {
        'type': 'new_family',
        'fullNameAr': fullName,
        'phone': normalizePhone(_phoneCtrl.text),
        'nationalId': _nationalIdCtrl.text.trim().isEmpty ? null : _nationalIdCtrl.text.trim(),
        'age': _selectedDate != null ? DateTime.now().year - _selectedDate!.year : null,
        'maritalStatus': _maritalStatus,
        'spouseName': spouseName,
        'gender': _gender,
        'password': _passwordCtrl.text,
        'hasChildren': _hasChildren,
        'childCount': _childCount,
        'children': _children.map((c) => {
          'fullName': c.fullName,
          'gender': c.gender,
          'age': c.age,
          'nationalId': c.nationalId?.trim().isEmpty == true ? null : c.nationalId?.trim(),
        }).toList(),
        'surveyAnswers': _surveyAnswers,
      });
      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(friendlyError(e), style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _surveyAnswers;

  Future<void> _submitJoinFamily() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final fullName = _fullNameCtrl.text.trim();
      await api.post('/registration-requests', data: {
        'type': 'join_family',
        'familyHeadPhone': normalizePhone(_phoneCtrl.text),
        'fullNameAr': fullName,
        'phone': normalizePhone(_phoneCtrl.text),
        'password': _passwordCtrl.text,
      });
      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(friendlyError(e), style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'تم إرسال طلبك بنجاح، سيتم مراجعته من قبل المشرف',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () => context.goNamed('login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('تسجيل الدخول', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            _isJoinFlow ? 'انضمام لعائلة' : 'طلب انضمام',
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () {
              if (_currentStep > 0 && !_isJoinFlow) {
                _prev();
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: _isJoinFlow ? _buildJoinFamilyForm() : _buildOnboardingFlow(),
      ),
    );
  }

  // ─── ONBOARDING FLOW ────────────────────────────────────────────────

  Widget _buildOnboardingFlow() {
    return Column(
      children: [
        _buildStepIndicator(),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentStep = i),
            children: _buildSteps(),
          ),
        ),
        _buildBottomNav(),
      ],
    );
  }

  List<Widget> _buildSteps() {
    final steps = <Widget>[
      _buildPersonalInfoStep(),
      _buildMaritalStatusStep(),
      _buildChildrenStep(),
      _buildPasswordStep(),
      _buildReviewStep(),
    ];
    if (_surveyTemplate != null) {
      steps.insert(3, _buildSurveyStep());
    }
    return steps;
  }

  List<String> get _stepLabels {
    final labels = ['البيانات الشخصية', 'الحالة الاجتماعية', 'الأبناء', 'كلمة المرور', 'المراجعة'];
    if (_surveyTemplate != null) {
      labels.insert(3, 'الاستبيان');
    }
    return labels;
  }

  Widget _buildStepIndicator() {
    final labels = _stepLabels;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      color: Colors.white,
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone || isActive ? AppColors.primary : AppColors.border,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? AppColors.primary : (isActive ? Colors.white : AppColors.surface),
                        border: Border.all(
                          color: isDone ? AppColors.primary : (isActive ? AppColors.primary : AppColors.border),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontFamily: 'IBMPlexSansArabic',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? AppColors.primary : AppColors.textHint,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 9,
                        color: isActive ? AppColors.primary : AppColors.textHint,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textHint, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.textHint, size: 20) : null,
      prefix: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    );
  }

  // ─── STEP 0: PERSONAL INFO ──────────────────────────────────────────

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileImagePicker(),
          const SizedBox(height: 24),
          _buildLabel('الاسم الرباعي *'),
          const SizedBox(height: 4),
          TextFormField(
            controller: _fullNameCtrl,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
            decoration: _inputDecoration(hint: 'الاسم - الأب - الجد - العائلة'),
          ),
          const SizedBox(height: 20),
          _buildLabel('رقم الجوال *'),
          const SizedBox(height: 6),
          _buildPhoneField(),
          const SizedBox(height: 16),
          _buildLabel('رقم الهوية'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nationalIdCtrl,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
            decoration: _inputDecoration(hint: 'رقم الهوية (اختياري)', icon: Icons.badge_outlined),
          ),
          const SizedBox(height: 16),
          _buildLabel('العمر'),
          const SizedBox(height: 6),
          _buildAgePicker(),
          const SizedBox(height: 16),
          _buildLabel('النوع'),
          const SizedBox(height: 6),
          _buildGenderSelector(),
        ],
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return GestureDetector(
      onTap: () async {
        final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
        if (file != null) setState(() => _profileImagePath = file.path);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              image: _profileImagePath != null
                  ? DecorationImage(image: FileImage(File(_profileImagePath!)), fit: BoxFit.cover)
                  : null,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: _profileImagePath == null
                ? const Icon(Icons.camera_alt, color: AppColors.primary, size: 22)
                : null,
          ),
          const SizedBox(width: 12),
          const Text('ارفع الصوره الشخصيه', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Row(
      children: [
        _buildCountryCodeSelector(),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
            decoration: _inputDecoration(hint: '912345678'),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryCodeSelector() {
    return GestureDetector(
      onTap: () => _showCountryPicker(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCountry.dialCode,
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.85, minChildSize: 0.4, expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('اختر الدولة', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: allCountryCodes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = allCountryCodes[i];
                  final selected = c.code == _selectedCountry.code;
                  return ListTile(
                    dense: true,
                    leading: Text(c.dialCode, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    title: Text(c.name, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: AppColors.textPrimary)),
                    trailing: Text(c.dialCode, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary)),
                    selected: selected,
                    onTap: () {
                      setState(() => _selectedCountry = c);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgePicker() {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime(now.year - 25, 1, 1),
          firstDate: DateTime(now.year - 120, 1, 1),
          lastDate: now,
          helpText: 'اختر تاريخ الميلاد',
          cancelText: 'إلغاء',
          confirmText: 'تأكيد',
          fieldLabelText: 'التاريخ',
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.textHint, size: 20),
            const SizedBox(width: 12),
            Text(
              _selectedDate != null
                  ? '${_selectedDate!.year}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')} (${DateTime.now().year - _selectedDate!.year} سنة)'
                  : 'اختر تاريخ الميلاد',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 15,
                color: _selectedDate != null ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: ['ذكر', 'أنثى'].asMap().entries.map((e) {
          final val = e.value == 'ذكر' ? 'male' : 'female';
          final selected = _gender == val;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _gender = val),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── STEP 1: MARITAL STATUS ─────────────────────────────────────────

  Widget _buildMaritalStatusStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('الحالة الاجتماعية'),
          const SizedBox(height: 8),
          _buildMaritalOption('single', 'أعزب'),
          _buildMaritalOption('married', 'متزوج'),
          _buildMaritalOption('divorced', 'مطلق'),
          _buildMaritalOption('widowed', 'أرمل'),
          if (_maritalStatus == 'married' || _maritalStatus == 'widowed') ...[
            const SizedBox(height: 24),
            Text(
              _maritalStatus == 'married' ? 'اسم الزوجة (رباعي) *' : 'اسم الزوج (رباعي) *',
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _spouseNameCtrl,
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
              decoration: _inputDecoration(hint: 'الاسم - الأب - الجد - العائلة'),
            ),
          ],
          const SizedBox(height: 24),
          _buildLabel('هل لديك أبناء؟'),
          const SizedBox(height: 8),
          _buildYesNoToggle(),
          if (_hasChildren) ...[
            const SizedBox(height: 16),
            _buildLabel('عدد الأبناء'),
            const SizedBox(height: 8),
            _buildChildCountSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildMaritalOption(String value, String label) {
    final selected = _maritalStatus == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => _maritalStatus = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppColors.primary : AppColors.textHint, size: 22),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYesNoToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _hasChildren = true; _childCount = 1; _updateChildCount(1); }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _hasChildren ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('نعم', textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.bold,
                    color: _hasChildren ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _hasChildren = false; _childCount = 0; _children.clear(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_hasChildren ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('لا', textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.bold,
                    color: !_hasChildren ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCountSelector() {
    return Row(
      children: [
        IconButton(
          onPressed: _childCount > 1 ? () => setState(() { _childCount--; _updateChildCount(_childCount); }) : null,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: _childCount > 1 ? AppColors.primary : AppColors.border),
            child: const Icon(Icons.remove, color: Colors.white, size: 20),
          ),
        ),
        Container(
          width: 60, alignment: Alignment.center,
          child: Text('$_childCount', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 28,
              fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ),
        IconButton(
          onPressed: () => setState(() { _childCount++; _updateChildCount(_childCount); }),
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Text('أبناء', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  void _updateChildCount(int count) {
    setState(() {
      while (_children.length < count) {
        _children.add(ChildData());
      }
      if (count < _children.length) {
        _children.removeRange(count, _children.length);
      }
    });
  }

  // ─── STEP 2: CHILDREN ───────────────────────────────────────────────

  Widget _buildChildrenStep() {
    if (!_hasChildren || _children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_care_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('لا يوجد أبناء لإضافتهم', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('يمكنك تخطي هذه الخطوة', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textHint)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: List.generate(_children.length, (i) => _buildChildCard(i)),
    );
  }

  Widget _buildChildCard(int index) {
    final child = _children[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                child: Text('الابن ${index + 1}', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLabel('الاسم الرباعي للابن'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: child.firstName,
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
                  decoration: _inputDecoration(hint: 'الاسم'),
                  onChanged: (v) => child.firstName = v,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: child.fatherName,
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
                  decoration: _inputDecoration(hint: 'الأب'),
                  onChanged: (v) => child.fatherName = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: child.grandName,
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
                  decoration: _inputDecoration(hint: 'الجد'),
                  onChanged: (v) => child.grandName = v,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: child.familyName,
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
                  decoration: _inputDecoration(hint: 'العائلة'),
                  onChanged: (v) => child.familyName = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('النوع'),
                    const SizedBox(height: 6),
                    _buildChildGenderSelector(index),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('العمر'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: child.age != null ? DateTime(now.year - child.age!) : DateTime(now.year - 10, 1, 1),
                          firstDate: DateTime(now.year - 100, 1, 1),
                          lastDate: now,
                          helpText: 'اختر تاريخ الميلاد',
                          cancelText: 'إلغاء', confirmText: 'تأكيد',
                        );
                        if (picked != null) {
                          setState(() => child.age = now.year - picked.year);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.textHint, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              child.age != null ? '${child.age} سنة' : 'اختر',
                              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: child.age != null ? AppColors.textPrimary : AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChildGenderSelector(int index) {
    final child = _children[index];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => child.gender = 'male'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: child.gender == 'male' ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                child: Text('ذكر', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13,
                    fontWeight: FontWeight.bold, color: child.gender == 'male' ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => child.gender = 'female'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: child.gender == 'female' ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                child: Text('أنثى', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13,
                    fontWeight: FontWeight.bold, color: child.gender == 'female' ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 3: SURVEY ─────────────────────────────────────────────────

  Widget _buildSurveyStep() {
    if (_surveyTemplate == null) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('الاستبيان', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('أجب على الأسئلة التالية', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          DynamicForm(
            template: _surveyTemplate!,
            onSubmit: (answers) {
              _surveyAnswers = answers;
            },
          ),
        ],
      ),
    );
  }

  // ─── STEP 4: PASSWORD ───────────────────────────────────────────────

  Widget _buildPasswordStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('كلمة المرور', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('اختر كلمة مرور قوية لحماية حسابك', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ستستخدم كلمة المرور هذه مع رقم جوالك لتسجيل الدخول لاحقاً',
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel('كلمة المرور *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
            decoration: _inputDecoration(
              hint: 'أدخل كلمة المرور',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textHint, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLabel('تأكيد كلمة المرور *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordCtrl,
            obscureText: _obscureConfirm,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
            decoration: _inputDecoration(
              hint: 'أعد إدخال كلمة المرور',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textHint, size: 20),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('يجب أن تحتوي كلمة المرور على:', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                _buildCheckItem('8 أحرف على الأقل', _hasMin8Chars),
                _buildCheckItem('حروف (أحرف عربية أو إنجليزية)', _hasLetters),
                _buildCheckItem('أرقام (0-9)', _hasNumbers),
                _buildCheckItem('تأكيد كلمة المرور مطابق', _passwordsMatch),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool condition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(condition ? Icons.check_circle : Icons.circle_outlined,
              size: 20, color: condition ? AppColors.success : AppColors.textHint),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13,
              color: condition ? AppColors.success : AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ─── STEP 5: REVIEW ─────────────────────────────────────────────────

  Widget _buildReviewStep() {
    final fullName = _fullNameCtrl.text.trim();
    final spouseName = (_maritalStatus == 'married' || _maritalStatus == 'widowed')
        ? _spouseNameCtrl.text.trim()
        : null;
    final ageStr = _selectedDate != null ? '${DateTime.now().year - _selectedDate!.year} سنة' : '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('مراجعة الطلب', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('تأكد من صحة بياناتك قبل الإرسال', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _buildReviewSection('البيانات الشخصية', [
            if (_profileImagePath != null) _buildReviewRow('الصورة', 'تم الاختيار'),
            _buildReviewRow('الاسم', fullName),
            _buildReviewRow('الجوال', '${_selectedCountry.dialCode} ${_phoneCtrl.text.trim()}'),
            if (_nationalIdCtrl.text.trim().isNotEmpty) _buildReviewRow('الهوية', _nationalIdCtrl.text.trim()),
            _buildReviewRow('العمر', ageStr),
            _buildReviewRow('النوع', _gender == 'male' ? 'ذكر' : 'أنثى'),
          ]),
          const SizedBox(height: 12),
          _buildReviewSection('الحالة الاجتماعية', [
            _buildReviewRow('الحالة', _maritalStatusLabel()),
            if (spouseName != null) _buildReviewRow('اسم الزوج/الزوجة', spouseName),
            _buildReviewRow('أبناء', _hasChildren ? 'نعم ($_childCount)' : 'لا'),
          ]),
          if (_hasChildren && _children.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildReviewSection('الأبناء ($_childCount)', _children.map((c) {
              final ageStr2 = c.age != null ? '${c.age} سنة' : '—';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                      child: Text('${_children.indexOf(c) + 1}', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c.fullName, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textPrimary))),
                    Text('${c.gender == 'male' ? 'ذكر' : 'أنثى'} · $ageStr2', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              );
            }).toList()),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _maritalStatusLabel() {
    switch (_maritalStatus) {
      case 'married': return 'متزوج';
      case 'single': return 'أعزب';
      case 'divorced': return 'مطلق';
      case 'widowed': return 'أرمل';
      default: return '—';
    }
  }

  Widget _buildReviewSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border.withOpacity(0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  // ─── BOTTOM NAV ─────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final isLast = _currentStep == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2)),
      ]),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _prev,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('السابق', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15)),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (isLast ? _submitNewFamily : _next),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(
                        isLast ? 'إرسال الطلب' : 'التالي',
                        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── JOIN FAMILY FORM ──────────────────────────────────────────────

  Widget _buildJoinFamilyForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.family_restroom, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('انضم إلى عائلة موجودة برقم جوال رب الأسرة', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('رقم جوال رب الأسرة'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
              decoration: _inputDecoration(hint: '912345678', icon: Icons.phone_outlined),
            ),
            const Divider(height: 32, color: AppColors.border),
            _buildLabel('الاسم الرباعي'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _fullNameCtrl,
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
              decoration: _inputDecoration(hint: 'الاسم - الأب - الجد - العائلة'),
            ),
            const SizedBox(height: 20),
            _buildLabel('رقم الجوال'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
              decoration: _inputDecoration(hint: '912345678', icon: Icons.phone_outlined),
            ),
            const SizedBox(height: 20),
            _buildLabel('كلمة المرور'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
              decoration: _inputDecoration(
                hint: '8 أحرف على الأقل + حروف + أرقام',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textHint, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitJoinFamily,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('إرسال الطلب', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
