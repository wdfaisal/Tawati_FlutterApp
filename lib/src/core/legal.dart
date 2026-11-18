class LegalLinks {
  const LegalLinks._();

  /// Update these values before production release.
  static const String privacyPolicyUrl = 'https://tawati.app/privacy';
  static const String termsUrl = 'https://tawati.app/terms';
  static const String accountDeletionUrl = 'https://tawati.app/account-deletion';
  static const String supportEmail = 'support@tawati.app';
  static const String supportSubject = 'دعم تطبيق تواتي';
  static const String deleteAccountSubject = 'طلب حذف حساب - تطبيق تواتي';

  static String deleteAccountBody({
    required String name,
    required String phone,
    required String userId,
  }) {
    return [
      'أرغب في حذف حسابي في تطبيق تواتي.',
      '',
      'الاسم: ${name.isEmpty ? '-' : name}',
      'رقم الهاتف: ${phone.isEmpty ? '-' : phone}',
      'معرّف المستخدم: ${userId.isEmpty ? '-' : userId}',
      '',
      'أؤكد أنني مالك هذا الحساب وأطلب معالجة طلب الحذف وفق سياسة الخصوصية والأنظمة المعمول بها.',
    ].join('\n');
  }
}
