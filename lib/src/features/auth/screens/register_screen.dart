import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/country_codes.dart';
import 'package:tawati_mobile/src/core/error_handler.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/features/surveys/models/survey_template.dart';
import 'package:tawati_mobile/src/features/surveys/widgets/dynamic_form.dart';

class ChildData {
  String fullName;
  String gender;
  int? age;
  String? nationalId;
  String phone;
  DateTime? dateOfBirth;

  ChildData({
    this.fullName = '',
    this.gender = 'male',
    this.age,
    this.nationalId,
    this.phone = '',
    this.dateOfBirth,
  });
}

class RegisterScreen extends ConsumerStatefulWidget {
  final bool showJoinOnly;
  const RegisterScreen({super.key, this.showJoinOnly = false});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const _newFamilyDraftKey = 'registration_draft_v1';
  static const _joinFlowDraftKey = 'registration_join_draft_v1';
  static const _storage = FlutterSecureStorage();

  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isJoinFlow = false;

  final _picker = ImagePicker();
  String? _profileImagePath;

  CountryCode _selectedCountry = allCountryCodes.first;
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _familyHeadPhoneCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  DateTime? _selectedDate;
  String _gender = 'male';

  String? _nameError;
  String? _phoneError;

  String _maritalStatus = 'single';
  final _spouseNameCtrl = TextEditingController();
  final _spousePhoneCtrl = TextEditingController();
  final _spouseNationalIdCtrl = TextEditingController();
  DateTime? _spouseDateOfBirth;
  bool _hasChildren = false;
  int _childCount = 0;
  final List<ChildData> _children = [];

  SurveyTemplate? _surveyTemplate;

  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Timer? _draftDebounce;
  bool _hasDraft = false;
  bool _showResumeBanner = false;

  bool get _hasMin8Chars => _passwordCtrl.text.length >= 8;
  bool get _hasLetters => _passwordCtrl.text.contains(RegExp(r'[a-zA-Z\u0621-\u064A]'));
  bool get _hasNumbers => _passwordCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _passwordsMatch => _passwordCtrl.text.isNotEmpty && _passwordCtrl.text == _confirmPasswordCtrl.text;
  bool get _passwordValid => _hasMin8Chars && _hasLetters && _hasNumbers && _passwordsMatch;
  bool get _joinPasswordValid => _hasMin8Chars && _hasLetters && _hasNumbers;

  int get _totalSteps => _isJoinFlow ? 3 : (_surveyTemplate != null ? 6 : 5);

  List<String> get _stepLabels {
    if (_isJoinFlow) return ['بياناتك', 'ربّ أسرتك', 'مراجعة وإرسال'];
    final labels = ['بياناتك', 'حالتك العائلية', 'أبناؤك', 'حماية حسابك', 'مراجعة وإرسال'];
    if (_surveyTemplate != null) labels.insert(3, 'الاستبيان');
    return labels;
  }

  ({IconData icon, String title, String caption}) _stepHeaderFor(int index) {
    if (_isJoinFlow) {
      return switch (index) {
        0 => (
            icon: Icons.person_rounded,
            title: 'بياناتك',
            caption: 'أهلاً بك في عائلتك — أدخل بياناتك لتُعتمد بناءً عليها.',
          ),
        1 => (
            icon: Icons.family_restroom_rounded,
            title: 'ربّ أسرتك',
            caption: 'أدخل رقم جوال ربّ أسرتك المسجّل لدينا — سيُعتمد طلبك بناءً عليه.',
          ),
        _ => (
            icon: Icons.fact_check_rounded,
            title: 'مراجعة وإرسال',
            caption: 'تأكد من بياناتك ثم أرسل طلب انضمامك.',
          ),
      };
    }
    return switch (index) {
      0 => (
          icon: Icons.person_rounded,
          title: 'مَن أنت؟',
          caption: 'بياناتك تُربط رسميًا بشجرة عائلتك بعد الموافقة.',
        ),
      1 => (
          icon: Icons.family_restroom_rounded,
          title: 'حالتك العائلية',
          caption: 'اختر حالتك، وستظهر الحقول المطلوبة تلقائيًا.',
        ),
      2 => (
          icon: Icons.child_care_rounded,
          title: 'أبناؤك',
          caption: 'أضف أبناءك — كل ابن في بطاقة قابلة للطي.',
        ),
      3 => _surveyTemplate != null
          ? (
              icon: Icons.quiz_rounded,
              title: 'الاستبيان',
              caption: 'أجب على الأسئلة التالية.',
            )
          : (
              icon: Icons.lock_rounded,
              title: 'حماية حسابك',
              caption: 'اختر كلمة مرور قوية لحماية حسابك.',
            ),
      4 => _surveyTemplate != null
          ? (
              icon: Icons.lock_rounded,
              title: 'حماية حسابك',
              caption: 'اختر كلمة مرور قوية لحماية حسابك.',
            )
          : (
              icon: Icons.fact_check_rounded,
              title: 'مراجعة وإرسال',
              caption: 'تأكد من بياناتك ثم أرسل طلب انضمامك.',
            ),
      _ => (
          icon: Icons.fact_check_rounded,
          title: 'مراجعة وإرسال',
          caption: 'تأكد من بياناتك ثم أرسل طلب انضمامك.',
        ),
    };
  }

  @override
  void initState() {
    super.initState();
    _isJoinFlow = widget.showJoinOnly;
    _fullNameCtrl.addListener(_scheduleDraftSave);
    _phoneCtrl.addListener(_scheduleDraftSave);
    _familyHeadPhoneCtrl.addListener(_scheduleDraftSave);
    _nationalIdCtrl.addListener(_scheduleDraftSave);
    _spouseNameCtrl.addListener(_scheduleDraftSave);
    _passwordCtrl.addListener(_scheduleDraftSave);
    _confirmPasswordCtrl.addListener(_scheduleDraftSave);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final extra = GoRouterState.of(context).extra;
      if (extra is Map && extra['join'] == true) {
        setState(() => _isJoinFlow = true);
      }
      _restoreDraft();
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

  String get _draftKey => _isJoinFlow ? _joinFlowDraftKey : _newFamilyDraftKey;

  Map<String, dynamic> _draftData() => {
        'fullName': _fullNameCtrl.text,
        'phone': _phoneCtrl.text,
        'familyHeadPhone': _familyHeadPhoneCtrl.text,
        'nationalId': _nationalIdCtrl.text,
        'gender': _gender,
        'birth': _selectedDate?.toIso8601String(),
        'maritalStatus': _maritalStatus,
        'spouseName': _spouseNameCtrl.text,
        'hasChildren': _hasChildren,
        'childCount': _childCount,
        'children': _children
            .map((c) => {
                  'fullName': c.fullName,
                  'gender': c.gender,
                  'age': c.age,
                  'nationalId': c.nationalId,
                })
            .toList(),
        'password': _passwordCtrl.text,
        'confirmPassword': _confirmPasswordCtrl.text,
        'countryCode': _selectedCountry.code,
        'profileImagePath': _profileImagePath,
      };

  void _scheduleDraftSave() {
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_saveDraft());
    });
  }

  Future<void> _saveDraft() async {
    try {
      await _storage.write(key: _draftKey, value: jsonEncode(_draftData()));
    } catch (e) {
      debugPrint('_saveDraft failed: $e');
    }
  }

  Future<void> _restoreDraft() async {
    try {
      final raw = await _storage.read(key: _draftKey);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _fullNameCtrl.text = data['fullName'] as String? ?? '';
        _phoneCtrl.text = data['phone'] as String? ?? '';
        _familyHeadPhoneCtrl.text = data['familyHeadPhone'] as String? ?? '';
        _nationalIdCtrl.text = data['nationalId'] as String? ?? '';
        _gender = data['gender'] as String? ?? 'male';
        _maritalStatus = data['maritalStatus'] as String? ?? 'single';
        _spouseNameCtrl.text = data['spouseName'] as String? ?? '';
        _hasChildren = data['hasChildren'] as bool? ?? false;
        _childCount = data['childCount'] as int? ?? 0;
        _passwordCtrl.text = data['password'] as String? ?? '';
        _confirmPasswordCtrl.text = data['confirmPassword'] as String? ?? '';
        _profileImagePath = data['profileImagePath'] as String?;
        final code = data['countryCode'] as String?;
        if (code != null) {
          _selectedCountry = allCountryCodes.firstWhere(
            (c) => c.code == code,
            orElse: () => allCountryCodes.first,
          );
        }
        final birth = data['birth'] as String?;
        if (birth != null) _selectedDate = DateTime.tryParse(birth);
        _children.clear();
        for (final item in (data['children'] as List? ?? const [])) {
          final m = item as Map<String, dynamic>;
          _children.add(ChildData(
            fullName: m['fullName'] as String? ?? '',
            gender: m['gender'] as String? ?? 'male',
            age: m['age'] as int?,
            nationalId: m['nationalId'] as String?,
          ));
        }
        _hasDraft = true;
        _showResumeBanner = true;
      });
    } catch (e) {
      debugPrint('_restoreDraft failed: $e');
    }
  }

  Future<void> _clearDraft() async {
    _draftDebounce?.cancel();
    await _storage.delete(key: _draftKey);
  }

  void _resetDraft() {
    setState(() {
      _hasDraft = false;
      _showResumeBanner = false;
      _fullNameCtrl.clear();
      _phoneCtrl.clear();
      _familyHeadPhoneCtrl.clear();
      _nationalIdCtrl.clear();
      _spouseNameCtrl.clear();
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();
      _gender = 'male';
      _maritalStatus = 'single';
      _hasChildren = false;
      _childCount = 0;
      _children.clear();
      _selectedDate = null;
      _profileImagePath = null;
    });
    unawaited(_clearDraft());
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    unawaited(_saveDraft());
    _pageController.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _familyHeadPhoneCtrl.dispose();
    _nationalIdCtrl.dispose();
    _spouseNameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _totalSteps - 1) {
      _scheduleDraftSave();
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _scheduleDraftSave();
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      final nameWords = _fullNameCtrl.text.trim().split(' ').where((w) => w.isNotEmpty).length;
      final phoneOk = _phoneCtrl.text.trim().length >= 6;
      final nameOk = nameWords >= 4;
      setState(() {
        _nameError = nameOk ? null : 'أدخل الاسم الرباعي كاملاً (الاسم - الأب - الجد - العائلة)';
        _phoneError = phoneOk ? null : 'أدخل رقم جوال صحيح';
      });
      if (!nameOk || !phoneOk) return false;
      if (_isJoinFlow && !_joinPasswordValid) {
        _showError('تأكد من استيفاء جميع شروط كلمة المرور');
        return false;
      }
      return true;
    }
    if (_isJoinFlow) {
      if (_currentStep == 1) {
        if (_familyHeadPhoneCtrl.text.trim().length < 6) {
          _showError('أدخل رقم جوال رب الأسرة صحيح');
          return false;
        }
      }
      return true;
    }
    if (_currentStep == 1) {
      if (_maritalStatus == 'married' || _maritalStatus == 'widowed') {
        if (_spouseNameCtrl.text.trim().split(' ').where((w) => w.isNotEmpty).length < 4) {
          _showError('أدخل اسم الزوج/الزوجة رباعياً');
          return false;
        }
      }
      return true;
    }
    final passwordIdx = _surveyTemplate != null ? 4 : 3;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

      final res = await api.post('/registration-requests', data: {
        'type': 'new_family',
        'fullNameAr': fullName,
        'phone': normalizePhone(_phoneCtrl.text),
        'nationalId': _nationalIdCtrl.text.trim().isEmpty ? null : _nationalIdCtrl.text.trim(),
        'dateOfBirth': _selectedDate?.toIso8601String(),
        'age': _selectedDate != null ? DateTime.now().year - _selectedDate!.year : null,
        'maritalStatus': _maritalStatus,
        'spouseName': spouseName,
        'gender': _gender,
        'password': _passwordCtrl.text,
        'hasChildren': _hasChildren,
        'childCount': _childCount,
        'children': _children.map((c) => {
          'fullName': c.fullName.trim(),
          'phone': normalizePhone(c.phone),
          'gender': c.gender,
          'age': c.age,
          'nationalId': c.nationalId?.trim().isEmpty == true ? null : c.nationalId?.trim(),
          'dateOfBirth': c.dateOfBirth?.toIso8601String(),
          'maritalStatus': 'single',
        }).toList(),
        'surveyAnswers': _surveyAnswers,
      });
      await _clearDraft();
      if (mounted) _openPendingReview(res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(friendlyError(e), style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      final res = await api.post('/registration-requests', data: {
        'type': 'join_family',
        'familyHeadPhone': normalizePhone(_familyHeadPhoneCtrl.text),
        'fullNameAr': fullName,
        'phone': normalizePhone(_phoneCtrl.text),
        'password': _passwordCtrl.text,
      });
      await _clearDraft();
      if (mounted) _openPendingReview(res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(friendlyError(e), style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openPendingReview(dynamic response) {
    final data = response?.data;
    final record = data is Map ? data['data'] : null;
    final id = record is Map ? record['_id']?.toString() ?? '' : '';
    String requestId;
    if (id.isNotEmpty) {
      requestId = '#TWT-${id.length > 5 ? id.substring(id.length - 5) : id}'.toUpperCase();
    } else {
      requestId = '#TWT-${(_phoneCtrl.text.hashCode.abs() % 10000).toString().padLeft(4, '0')}';
    }
    context.pushNamed('pendingReview', extra: {'requestId': requestId});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(
            _isJoinFlow ? 'انضمام لعائلة' : 'طلب انضمام',
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () {
              if (_currentStep > 0) {
                _prev();
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: _buildFlow(),
      ),
    );
  }

  // ─── FLOW SHELL ─────────────────────────────────────────────────────

  Widget _buildFlow() {
    return Column(
      children: [
        _buildProgressBar(),
        _buildResumeBanner(),
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

  Widget _buildProgressBar() {
    final label = _stepLabels[_currentStep];
    final progress = (_currentStep + 1) / _totalSteps;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الخطوة ${_currentStep + 1} من $_totalSteps · $label',
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 4, color: AppColors.border),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, _) => FractionallySizedBox(
                    widthFactor: value,
                    child: Container(height: 4, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeBanner() {
    if (!_hasDraft || !_showResumeBanner) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'وجدنا طلبًا سابقًا غير مكتمل — تم استئناف بياناتك',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: _resetDraft,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSteps() {
    if (_isJoinFlow) {
      return [
        _buildJoinPersonalStep(),
        _buildJoinFamilyHeadStep(),
        _buildJoinReviewStep(),
      ];
    }
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

  Widget _buildStepHeader(int index) {
    final h = _stepHeaderFor(index);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
          child: Icon(h.icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          h.title,
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          h.caption,
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    Widget? prefix,
    Widget? suffix,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textHint, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.textHint, size: 20) : null,
      prefix: prefix,
      suffixIcon: suffix,
      errorText: errorText,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 2)),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    );
  }

  // ─── STEP 0 (NEW): PERSONAL INFO ───────────────────────────────────

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(0),
          _buildProfileImagePicker(),
          const SizedBox(height: 24),
          _buildLabel('الاسم الرباعي *'),
          const SizedBox(height: 4),
          TextFormField(
            controller: _fullNameCtrl,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
            decoration: _inputDecoration(hint: 'الاسم - الأب - الجد - العائلة', errorText: _nameError),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
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
          _buildLabel('تاريخ الميلاد'),
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
        if (file != null) {
          setState(() => _profileImagePath = file.path);
          _scheduleDraftSave();
        }
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
          const Text('ارفع الصورة الشخصية', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            decoration: _inputDecoration(hint: '912345678', errorText: _phoneError),
            onChanged: (_) {
              if (_phoneError != null) setState(() => _phoneError = null);
            },
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
          borderRadius: BorderRadius.circular(14),
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
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = allCountryCodes[i];
                  final selected = c.code == _selectedCountry.code;
                  return ListTile(
                    dense: true,
                    leading: Text(c.dialCode, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    title: Text(c.name, style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: AppColors.textPrimary)),
                    trailing: selected ? const Icon(Icons.check, color: AppColors.primary, size: 20) : null,
                    selected: selected,
                    onTap: () {
                      setState(() => _selectedCountry = c);
                      _scheduleDraftSave();
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
        if (picked != null) {
          setState(() => _selectedDate = picked);
          _scheduleDraftSave();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
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
              onTap: () {
                setState(() => _gender = val);
                _scheduleDraftSave();
              },
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

  // ─── STEP 1 (NEW): MARITAL STATUS ──────────────────────────────────

  Widget _buildMaritalStatusStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(1),
          _buildMaritalOption('single', 'أعزب'),
          _buildMaritalOption('married', 'متزوج'),
          _buildMaritalOption('divorced', 'مطلق'),
          _buildMaritalOption('widowed', 'أرمل'),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: (_maritalStatus == 'married' || _maritalStatus == 'widowed')
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 16),
                      _buildLabel('رقم جوال الزوجة *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _spousePhoneCtrl,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
                        decoration: _inputDecoration(hint: '9XXXXXXXX'),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('رقم هوية الزوجة (اختياري)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _spouseNationalIdCtrl,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
                        decoration: _inputDecoration(hint: 'رقم الهوية'),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('تاريخ ميلاد الزوجة (اختياري)'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _spouseDateOfBirth ?? DateTime(1990),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                            locale: const Locale('ar'),
                          );
                          if (picked != null) setState(() => _spouseDateOfBirth = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textHint),
                              const SizedBox(width: 12),
                              Text(
                                _spouseDateOfBirth != null
                                    ? '${_spouseDateOfBirth!.day}/${_spouseDateOfBirth!.month}/${_spouseDateOfBirth!.year}'
                                    : 'اختر التاريخ',
                                style: TextStyle(
                                  fontFamily: 'IBMPlexSansArabic',
                                  fontSize: 15,
                                  color: _spouseDateOfBirth != null ? AppColors.textPrimary : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 24),
          _buildLabel('هل لديك أبناء؟'),
          const SizedBox(height: 8),
          _buildYesNoToggle(),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _hasChildren
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildLabel('عدد الأبناء'),
                      const SizedBox(height: 8),
                      _buildChildCountSelector(),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildMaritalOption(String value, String label) {
    final selected = _maritalStatus == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          setState(() => _maritalStatus = value);
          _scheduleDraftSave();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
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
              onTap: () {
                setState(() { _hasChildren = true; _childCount = 1; _updateChildCount(1); });
                _scheduleDraftSave();
              },
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
              onTap: () {
                setState(() { _hasChildren = false; _childCount = 0; _children.clear(); });
                _scheduleDraftSave();
              },
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
          onPressed: _childCount > 1 ? () {
            setState(() { _childCount--; _updateChildCount(_childCount); });
            _scheduleDraftSave();
          } : null,
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
          onPressed: () {
            setState(() { _childCount++; _updateChildCount(_childCount); });
            _scheduleDraftSave();
          },
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

  // ─── STEP 2 (NEW): CHILDREN ────────────────────────────────────────

  Widget _buildChildrenStep() {
    if (!_hasChildren || _children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(2),
            const SizedBox(height: 40),
            const Center(
              child: Icon(Icons.child_care_outlined, size: 64, color: AppColors.textHint),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('لا يوجد أبناء بعد', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('يمكنك إضافتهم لاحقاً', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textHint)),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        _buildStepHeader(2),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() { _childCount++; _updateChildCount(_childCount); });
              _scheduleDraftSave();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة ابن', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
        const SizedBox(height: 4),
        ...List.generate(_children.length, (i) => _CollapsibleChildCard(
          child: _children[i],
          index: i,
          onFieldChanged: _scheduleDraftSave,
          onRemove: () {
            setState(() { _children.removeAt(i); _childCount = _children.length; });
            _scheduleDraftSave();
          },
        )),
      ],
    );
  }

  // ─── STEP 3 (NEW): SURVEY ──────────────────────────────────────────

  Widget _buildSurveyStep() {
    if (_surveyTemplate == null) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(3),
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

  // ─── PASSWORD STEP ─────────────────────────────────────────────────

  Widget _buildPasswordStep() {
    final idx = _surveyTemplate != null ? 4 : 3;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(idx),
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

  // ─── REVIEW STEP ───────────────────────────────────────────────────

  Widget _buildReviewStep() {
    final idx = _surveyTemplate != null ? 5 : 4;
    final fullName = _fullNameCtrl.text.trim();
    final spouseName = (_maritalStatus == 'married' || _maritalStatus == 'widowed')
        ? _spouseNameCtrl.text.trim()
        : null;
    final ageStr = _selectedDate != null ? '${DateTime.now().year - _selectedDate!.year} سنة' : '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(idx),
          _buildWhatsNextBox(),
          const SizedBox(height: 20),
          _buildReviewSection('البيانات الشخصية', [
            if (_profileImagePath != null) _buildReviewRow('الصورة', 'تم الاختيار'),
            _buildReviewRow('الاسم', fullName),
            _buildReviewRow('الجوال', '${_selectedCountry.dialCode} ${_phoneCtrl.text.trim()}'),
            if (_nationalIdCtrl.text.trim().isNotEmpty) _buildReviewRow('الهوية', _nationalIdCtrl.text.trim()),
            if (_selectedDate != null) _buildReviewRow('تاريخ الميلاد', '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
            _buildReviewRow('النوع', _gender == 'male' ? 'ذكر' : 'أنثى'),
          ]),
          const SizedBox(height: 12),
          _buildReviewSection('الحالة الاجتماعية', [
            _buildReviewRow('الحالة', _maritalStatusLabel()),
            if (spouseName != null) _buildReviewRow('اسم الزوج/الزوجة', spouseName),
            if (spouseName != null && _spousePhoneCtrl.text.trim().isNotEmpty)
              _buildReviewRow('جوال الزوج/الزوجة', _spousePhoneCtrl.text.trim()),
            if (spouseName != null && _spouseNationalIdCtrl.text.trim().isNotEmpty)
              _buildReviewRow('هوية الزوج/الزوجة', _spouseNationalIdCtrl.text.trim()),
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
                    Expanded(child: Text(c.fullName.isEmpty ? 'الابن ${_children.indexOf(c) + 1}' : c.fullName, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textPrimary))),
                    Text('${c.gender == 'male' ? 'ذكر' : 'أنثى'} · $ageStr2', style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              );
            }).toList()),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWhatsNextBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 12),
              Text('ماذا يحدث بعد الإرسال؟',
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'سيُراجع المشرف طلبك خلال 24–48 ساعة تقريبًا، ثم يُنشأ حسابك لك ولعائلتك. ستصل إليك رسالة عند القبول.',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary, height: 1.7),
          ),
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
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
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
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  // ─── BOTTOM NAV ────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final isLast = _currentStep == _totalSteps - 1;
    final label = isLast ? (_isJoinFlow ? 'إرسال الطلب' : 'إرسال طلب الانضمام') : 'التالي';
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, -4)),
      ]),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (isLast ? (_isJoinFlow ? _submitJoinFamily : _submitNewFamily) : _next),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(label, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            if (_currentStep > 0) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: _isLoading ? null : _prev,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  textStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w500),
                ),
                child: const Text('السابق'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── JOIN FAMILY STEPS ─────────────────────────────────────────────

  Widget _buildJoinPersonalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(0),
          _buildLabel('الاسم الرباعي *'),
          const SizedBox(height: 4),
          TextFormField(
            controller: _fullNameCtrl,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
            decoration: _inputDecoration(hint: 'الاسم - الأب - الجد - العائلة', errorText: _nameError),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: 20),
          _buildLabel('رقم الجوال *'),
          const SizedBox(height: 6),
          _buildPhoneField(),
          const SizedBox(height: 20),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinFamilyHeadStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(1),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.family_restroom, color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'أدخل رقم جوال ربّ أسرتك المسجّل لدينا — سيُعتمد طلبك بناءً عليه.',
                    style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel('رقم جوال رب الأسرة *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _familyHeadPhoneCtrl,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16),
            decoration: _inputDecoration(hint: '912345678', icon: Icons.phone_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(2),
          _buildWhatsNextBox(),
          const SizedBox(height: 20),
          _buildReviewSection('بياناتك', [
            _buildReviewRow('الاسم', _fullNameCtrl.text.trim()),
            _buildReviewRow('رقم جوالك', '${_selectedCountry.dialCode} ${_phoneCtrl.text.trim()}'),
            _buildReviewRow('رقم جوال رب الأسرة', '${_selectedCountry.dialCode} ${_familyHeadPhoneCtrl.text.trim()}'),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── COLLAPSIBLE CHILD CARD ───────────────────────────────────────────

class _CollapsibleChildCard extends StatefulWidget {
  final ChildData child;
  final int index;
  final VoidCallback onFieldChanged;
  final VoidCallback onRemove;

  const _CollapsibleChildCard({
    required this.child,
    required this.index,
    required this.onFieldChanged,
    required this.onRemove,
  });

  @override
  State<_CollapsibleChildCard> createState() => _CollapsibleChildCardState();
}

class _CollapsibleChildCardState extends State<_CollapsibleChildCard> {
  bool _expanded = true;

  String get _summary {
    final parts = <String>[
      widget.child.gender == 'male' ? 'ذكر' : 'أنثى',
      if (widget.child.age != null) '${widget.child.age} سنوات',
    ];
    return parts.isEmpty ? 'لم تُحدد بياناته بعد' : parts.join(' · ');
  }

  Future<void> _pickAge() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.child.age != null ? DateTime(now.year - widget.child.age!) : DateTime(now.year - 10, 1, 1),
      firstDate: DateTime(now.year - 100, 1, 1),
      lastDate: now,
      helpText: 'اختر تاريخ الميلاد',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked != null) {
      setState(() => widget.child.age = now.year - picked.year);
      widget.onFieldChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${widget.index + 1}',
                          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الابن ${widget.index + 1}',
                            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        if (!_expanded) ...[
                          const SizedBox(height: 2),
                          Text(_summary,
                              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'حذف',
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textHint,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('الاسم الرباعي للابن'),
                        const SizedBox(height: 6),
                        TextFormField(
                          initialValue: child.fullName,
                          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15),
                          decoration: _fieldDecoration('الاسم - الأب - الجد - العائلة'),
                          onChanged: (v) {
                            child.fullName = v;
                            widget.onFieldChanged();
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('النوع'),
                                  const SizedBox(height: 6),
                                  _genderSelector(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('العمر'),
                                  const SizedBox(height: 6),
                                  _ageField(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _label('رقم الهوية (اختياري)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          initialValue: child.nationalId,
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15),
                          decoration: _fieldDecoration('رقم الهوية'),
                          onChanged: (v) {
                            child.nationalId = v;
                            widget.onFieldChanged();
                          },
                        ),
                        const SizedBox(height: 12),
                        _label('رقم جوال الابن *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          initialValue: child.phone,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15),
                          decoration: _fieldDecoration('9XXXXXXXX'),
                          onChanged: (v) {
                            child.phone = v;
                            widget.onFieldChanged();
                          },
                        ),
                        const SizedBox(height: 12),
                        _label('تاريخ الميلاد (اختياري)'),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: child.dateOfBirth ?? DateTime(2005),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                              locale: const Locale('ar'),
                            );
                            if (picked != null) {
                              setState(() => child.dateOfBirth = picked);
                              widget.onFieldChanged();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textHint),
                                const SizedBox(width: 8),
                                Text(
                                  child.dateOfBirth != null
                                      ? '${child.dateOfBirth!.day}/${child.dateOfBirth!.month}/${child.dateOfBirth!.year}'
                                      : 'اختر التاريخ',
                                  style: TextStyle(
                                    fontFamily: 'IBMPlexSansArabic',
                                    fontSize: 14,
                                    color: child.dateOfBirth != null ? AppColors.textPrimary : AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textHint, fontSize: 13),
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  Widget _genderSelector() {
    final child = widget.child;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => child.gender = 'male');
                widget.onFieldChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: child.gender == 'male' ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                child: Text('ذكر', textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13,
                        fontWeight: FontWeight.bold, color: child.gender == 'male' ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => child.gender = 'female');
                widget.onFieldChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: child.gender == 'female' ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                child: Text('أنثى', textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13,
                        fontWeight: FontWeight.bold, color: child.gender == 'female' ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ageField() {
    final child = widget.child;
    return GestureDetector(
      onTap: _pickAge,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.textHint, size: 16),
            const SizedBox(width: 8),
            Text(
              child.age != null ? '${child.age} سنة' : 'اختر',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: child.age != null ? AppColors.textPrimary : AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
