import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';

const _kNameColor = Color(0xFF1A242B);
const _kSecondary = Color(0xFF62707B);
const _kMuted = Color(0xFF9CAFB8);
const _kSoftBg = Color(0xFFF1F5F8);

class _CategoryOption {
  final String label;
  final String type;
  final String? subType;

  const _CategoryOption(this.label, this.type, [this.subType]);
}

const _categories = [
  _CategoryOption('إعلان عام', 'general'),
  _CategoryOption('إعلان مهم', 'important'),
  _CategoryOption('إعلان المنصة', 'platform_announcement'),
  _CategoryOption('مناسبة اجتماعية', 'social_occasion'),
  _CategoryOption('حفل زفاف', 'social_occasion', 'wedding'),
];

class AddAnnouncementScreen extends ConsumerStatefulWidget {
  const AddAnnouncementScreen({super.key});

  @override
  ConsumerState<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends ConsumerState<AddAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _quillCtrl = QuillController.basic();

  String? _imagePath;
  _CategoryOption? _category;
  TimeOfDay? _time;
  DateTime? _date;
  bool _submitting = false;
  bool _showSchedule = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _quillCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _imagePath = picked.path);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(data: ThemeData.light(), child: child!),
      ),
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(data: ThemeData.light(), child: child!),
      ),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final delta = _quillCtrl.document.toDelta();
    final plainText = delta.toString().trim();
    if (plainText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة وصف الإعلان')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      String? imageUrl;
      if (_imagePath != null) {
        imageUrl = await ref.read(newsServiceProvider).uploadImage(_imagePath!);
      }
      final body = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'content': plainText,
        'type': _category?.type ?? 'general',
        if (_category?.subType != null) 'sub_type': _category!.subType,
        'image': ?imageUrl,
      };
      await ref.read(newsServiceProvider).createNews(body);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر الإعلان بنجاح')),
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
    final t = _time;
    if (t == null) return '--:--';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _dateLabel {
    final d = _date;
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
                        _imageUploadBox(),
                        const SizedBox(height: 20),
                        const _Label('عنوان الإعلان'),
                        const SizedBox(height: 8),
                        _field(
                          controller: _titleCtrl,
                          hint: 'مبادرة تواتي أولاً وأخيراً',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال عنوان الإعلان' : null,
                        ),
                        const SizedBox(height: 16),
                        const _Label('تصنيف الإعلان'),
                        const SizedBox(height: 8),
                        _categoryField(),
                        const SizedBox(height: 16),
                        const _Label('وصف الإعلان'),
                        const SizedBox(height: 8),
                        _richEditor(),
                        const SizedBox(height: 16),
                        _scheduleToggle(),
                        if (_showSchedule) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _timeField()),
                              const SizedBox(width: 12),
                              Expanded(child: _dateField()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const _Label('الموقع'),
                          const SizedBox(height: 8),
                          _locationField(),
                        ],
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
            child: Text(
              'إضافة إعلان جديد',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageUploadBox() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 192,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _kSoftBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kMuted, width: 2),
        ),
        child: _imagePath != null
            ? Image.file(File(_imagePath!), fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'اضغط هنا لتحميل صورة',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'يفضل أن تكون بمقاس 1200x800 بكسل',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 12,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 15,
        color: _kNameColor,
      ),
      decoration: _decoration(hint).copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      ),
    );
  }

  Widget _richEditor() {
    return Container(
      decoration: BoxDecoration(
        color: _kSoftBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          QuillSimpleToolbar(
            controller: _quillCtrl,
            config: QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: true,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: false,
              showInlineCode: false,
              showColorButton: true,
              showBackgroundColorButton: true,
              showClearFormat: true,
              showAlignmentButtons: false,
              showLeftAlignment: false,
              showCenterAlignment: false,
              showRightAlignment: false,
              showJustifyAlignment: false,
              showHeaderStyle: false,
              showListBullets: true,
              showListNumbers: false,
              showListCheck: false,
              showCodeBlock: false,
              showQuote: false,
              showIndent: false,
              showLink: false,
              showDividers: false,
            ),
          ),
          const Divider(height: 1, color: _kMuted),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 180),
            child: QuillEditor.basic(
              controller: _quillCtrl,
              config: QuillEditorConfig(
                scrollable: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                placeholder: 'اكتب تفاصيل الإعلان هنا...',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleToggle() {
    return InkWell(
      onTap: () => setState(() => _showSchedule = !_showSchedule),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _boxDecoration(12),
        child: Row(
          children: [
            Icon(
              _showSchedule ? Icons.access_time_filled_rounded : Icons.access_time_rounded,
              color: _showSchedule ? AppColors.primary : _kSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _showSchedule ? 'تعطيل جدولة الإعلان' : 'تحديد موعد النشر (اختياري)',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _showSchedule ? AppColors.primary : _kSecondary,
                ),
              ),
            ),
            Icon(
              _showSchedule ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
              color: _showSchedule ? AppColors.primary : _kMuted,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryField() {
    return InkWell(
      onTap: () => _showCategorySheet(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _boxDecoration(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _category?.label ?? 'اختر التصنيف المناسب',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 15,
                  color: _category != null ? _kNameColor : _kMuted,
                ),
              ),
            ),
            Icon(Icons.expand_more_rounded, color: _kMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategorySheet() async {
    final selected = await showModalBottomSheet<_CategoryOption>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تصنيف الإعلان',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kNameColor,
                  ),
                ),
                const SizedBox(height: 8),
                ..._categories.map((option) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _category?.type == option.type && _category?.subType == option.subType
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        option.label,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 15,
                          color: _kNameColor,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, option),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _category = selected);
  }

  Widget _timeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('الوقت'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickTime,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _boxDecoration(12),
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

  Widget _dateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('التاريخ'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _boxDecoration(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dateLabel,
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                      color: _date != null ? _kNameColor : _kMuted,
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

  Widget _locationField() {
    return Container(
      height: 50,
      decoration: _boxDecoration(12),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.location_on_outlined, color: _kSecondary, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: _locationCtrl,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 15,
                color: _kNameColor,
              ),
              decoration: InputDecoration(
                hintText: 'حدد الموقع أو اكتبه يدويًا',
                hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, color: _kMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.location_searching_rounded, color: _kSecondary, size: 20),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorStyle: const TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 12,
        color: Color(0xFFEF4444),
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
