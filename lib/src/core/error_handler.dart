import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

String friendlyError(dynamic e) {
  if (kDebugMode) {
    debugPrint('═══════════ Error Report ═══════════');
    debugPrint('Type: ${e.runtimeType}');
    if (e is DioException) {
      debugPrint('DioExceptionType: ${e.type}');
      debugPrint('Status code: ${e.response?.statusCode}');
      debugPrint('Response data: ${e.response?.data}');
      debugPrint('Message: ${e.message}');
    } else {
      debugPrint('Error: $e');
    }
    debugPrint('═══════════════════════════════════');
  }

  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت';
      case DioExceptionType.connectionError:
        return 'لا يوجد اتصال بالإنترنت';
      case DioExceptionType.badCertificate:
        return 'مشكلة في شهادة الأمان، تأكد من اتصالك الآمن';
      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final body = e.response?.data;
        final serverMsg = body is Map ? body['message'] as String? : null;
        if (serverMsg != null && serverMsg.isNotEmpty) {
          return _mapServerMessage(serverMsg);
        }
        switch (code) {
          case 400:
            return 'البيانات المدخلة غير صحيحة';
          case 401:
            return 'رقم الهاتف أو كلمة المرور غير صحيحة';
          case 403:
            return 'ليس لديك صلاحية للوصول';
          case 404:
            return 'المستخدم غير موجود';
          case 409:
            return 'تعارض في البيانات، حاول مرة أخرى';
          case 422:
            return 'البيانات المدخلة غير صحيحة';
          case 429:
            return 'طلبات كثيرة جداً، حاول لاحقاً';
          case 500:
            return 'خطأ في الخادم، حاول لاحقاً';
          default:
            return 'حدث خطأ في الخادم ($code)';
        }
      case DioExceptionType.unknown:
        return 'حدث خطأ غير متوقع، حاول مرة أخرى';
    }
  }
  return 'حدث خطأ غير متوقع، حاول مرة أخرى';
}

String normalizePhone(String phone) {
  var p = phone.trim();
  if (p.startsWith('+249')) {
    p = '249${p.substring(4)}';
  } else if (p.startsWith('0')) {
    p = '249${p.substring(1)}';
  } else if (p.startsWith('9') && p.length >= 9 && p.length <= 10) {
    p = '249$p';
  }
  return p;
}

String _mapServerMessage(String msg) {
  switch (msg) {
    case 'Invalid credentials':
      return 'رقم الهاتف أو كلمة المرور غير صحيحة';
    case 'Invalid OTP':
      return 'رمز التحقق غير صحيح';
    case 'User not found':
      return 'المستخدم غير موجود';
    case 'OTP sent':
      return 'تم إرسال رمز التحقق';
    case 'Phone number already registered':
      return 'رقم الهاتف مسجل مسبقاً';
    default:
      return msg;
  }
}
