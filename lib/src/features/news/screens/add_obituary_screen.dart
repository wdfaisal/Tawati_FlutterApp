import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';

const _kNameColor = Color(0xFF1A242B);
const _kSecondary = Color(0xFF62707B);
const _kMuted = Color(0xFF9CAFB8);
const _kSoftBg = Color(0xFFF1F5F8);
const _kRed = Color(0xFFEF4444);

class AddObituaryScreen extends ConsumerStatefulWidget {
  const AddObituaryScreen({super.key});

  @override
  ConsumerState<AddObituaryScreen> createState() => _AddObituaryScreenState();
}

class _AddObituaryScreenState extends ConsumerState<AddObituaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _burialPlaceCtrl = TextEditingController();
  final _menPlaceCtrl = TextEditingController();
  final _womenPlaceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  TimeOfDay? _prayerTime;
  DateTime? _deathDate;
  bool _collectionSheet = false;
  bool _fundSupport = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _burialPlaceCtrl.dispose();
    _menPlaceCtrl.dispose();
    _womenPlaceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPrayerTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _prayerTime ?? TimeOfDay.now(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(data: ThemeData.light(), child: child!),
      ),
    );
    if (picked != null && mounted) setState(() => _prayerTime = picked);
  }

  Future<void> _pickDeathDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deathDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(data: ThemeData.light(), child: child!),
      ),
    );
    if (picked != null && mounted) setState(() => _deathDate = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final name = _nameCtrl.text.trim();
      final notes = _notesCtrl.text.trim();
      final body = <String, dynamic>{
        'type': 'social_occasion',
        'sub_type': 'death',
        'title': 'نعي — $name',
        'content': notes.isEmpty ? 'نسألكم الدعاء للمتوفى' : notes,
        'related_person_name': name,
        'collection_sheet_enabled': _collectionSheet,
      };
      await ref.read(newsServiceProvider).createNews(body);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر حالة الوفاة بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'حدث خطأ، حاول مرة أخرى';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _timeLabel {
    final t = _prayerTime;
    if (t == null) return '--:--';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _dateLabel {
    final d = _deathDate;
    if (d == null) return 'mm/dd/yyyy';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _iconField(
                          controller: _nameCtrl,
                          hint: 'الاسم الكامل للمتوفى',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المتوفى' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _prayerTimeField()),
                            const SizedBox(width: 12),
                            Expanded(child: _deathDateField()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _iconField(
                          controller: _burialPlaceCtrl,
                          hint: 'اسم المسجد والمقبرة',
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 12),
                        _placeField(
                          controller: _menPlaceCtrl,
                          hint: 'اسم المجلس أو المنزل',
                        ),
                        const SizedBox(height: 12),
                        _placeField(
                          controller: _womenPlaceCtrl,
                          hint: 'اسم المنزل أو القاعة',
                        ),
                        const SizedBox(height: 16),
                        _ToggleCard(
                          title: 'تفعيل صندوق الكشف',
                          subtitle: 'المساهمة في تكاليف العزاء',
                          value: _collectionSheet,
                          onChanged: (v) => setState(() => _collectionSheet = v),
                        ),
                        const SizedBox(height: 12),
                        _ToggleCard(
                          title: 'دعم صندوق الوفيات',
                          subtitle: 'التبرع لجمعية الوفيات',
                          value: _fundSupport,
                          onChanged: (v) => setState(() => _fundSupport = v),
                        ),
                        const SizedBox(height: 16),
                        const _Label('ملاحظات إضافية'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 15,
                            color: _kNameColor,
                          ),
                          decoration: _decoration('أرقام التواصل أو أي تفاصيل أخرى...'),
                        ).withHeight(98),
                        const SizedBox(height: 28),
                        _submitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kSoftBg)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _HeaderCircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              _HeaderCircleButton(
                icon: Icons.notifications_none_rounded,
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إضافة حالة وفاة',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إنا لله وإنا إليه راجعون',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 12,
                    color: _kMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 50,
      decoration: _boxDecoration(16),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(icon, color: _kSecondary, size: 20),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 15,
                color: _kNameColor,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, color: _kMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                errorStyle: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 12,
                  color: _kRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      height: 50,
      decoration: _boxDecoration(16),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.location_on_outlined, color: _kSecondary, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 15,
                color: _kNameColor,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, color: _kMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.chevron_left_rounded, color: _kMuted, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _prayerTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('وقت الصلاة'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickPrayerTime,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _boxDecoration(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _timeLabel,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 16,
                      color: _kNameColor,
                    ),
                  ),
                ),
                Icon(Icons.schedule_rounded, color: _kSecondary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _deathDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('تاريخ الوفاة'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDeathDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _boxDecoration(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dateLabel,
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                      color: _deathDate != null ? _kNameColor : _kMuted,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_rounded, color: _kSecondary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'نشر الإعلان',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                ],
              ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, color: _kMuted),
      filled: true,
      fillColor: _kSoftBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      errorStyle: const TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 12,
        color: _kRed,
      ),
    );
  }

  BoxDecoration _boxDecoration(double radius) {
    return BoxDecoration(
      color: _kSoftBg,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _kNameColor,
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kSoftBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kMuted.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: value
                  ? Icon(Icons.check_rounded, color: AppColors.primary, size: 22)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kNameColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 12,
                      color: _kSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kSoftBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }
}

extension _HeightExt on Widget {
  Widget withHeight(double height) => SizedBox(height: height, child: this);
}
