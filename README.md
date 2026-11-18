# Tawati Mobile (تواتي)

تطبيق المستخدم النهائي لمنصة تواتي — Flutter، عربي RTL.

## تشغيل التطبيق على الباك اند

عنوان الـ API معرّف في مكان واحد فقط: `lib/src/core/app_config.dart`.

```dart
const String kDefaultApiBaseUrl = 'http://10.131.76.182:3000/api/v1';
```

هذا هو عنوان IP الجهاز على شبكة الواي فاي (LAN). عند تغيّر الشبكة أو تغيّر IP الجهاز
غيّر هذا السطر، أو — بدون تعديل الكود — مرّر العنوان وقت التشغيل:

```bash
# جهاز حقيقي على نفس شبكة الواي فاي
flutter run --dart-define=API_BASE_URL=http://10.131.76.182:3000/api/v1

# محاكي أندرويد (10.0.2.2 = localhost الخاص بالجهاز المضيف)
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

# نسخة الويب محليًا (منفذ ثابت حتى تعمل CORS بثبات)
flutter run -d chrome --web-port=4500 --dart-define=API_BASE_URL=http://10.131.76.182:3000/api/v1

# نسخة الإنتاج
flutter build apk --release --dart-define=API_BASE_URL=https://api.tawati.app/api/v1
```

المتغير الواحد يغذّي ثلاث نقاط كانت منفصلة سابقًا:

| الاستخدام | المصدر |
|-----------|--------|
| طلبات الـ API (Dio) | `kApiBaseUrl` |
| عناوين الصور والملفات `/uploads/...` | `resolveMediaUrl` / `kServerOrigin` |
| اتصال Socket.IO (الشات والتنبيهات) | `kServerOrigin` (بدون `/api/v1`) |

## متطلبات التشغيل المحلي

1. شغّل الباك اند: `cd ../backend && npm start` (يستمع على المنفذ 3000).
2. تأكد أن الجوال/الجهاز والكمبيوتر على نفس شبكة الواي فاي.
3. اسمح للمنفذ في جدار الحماية (Windows):

```powershell
New-NetFirewallRule -DisplayName "Tawati API 3000" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
```

4. للتحقق سريعًا من الوصول من الجوال، افتح في المتصفح:
   `http://10.131.76.182:3000/health`

## ملاحظات

- أندرويد يسمح حاليًا بـ HTTP غير المشفّر لعناوين التطوير فقط عبر
  `android/app/src/main/res/xml/network_security_config.xml`
  (`10.131.76.182`, `localhost`). أضف IP جديد هناك إن لزم، وأزل هذه الاستثناءات
  قبل الإنتاج لأن الـ API سيكون على HTTPS.
- نسخة الويب تُخزّن التوكن في الذاكرة فقط (لا `flutter_secure_storage`) لأنها
  تحتاج سياقًا آمنًا (HTTPS أو localhost).
- الباك اند يسمح تلقائيًا بأصول التطوير (`localhost` بأي منفذ وأي IP محلي) عندما
  `NODE_ENV !== production`، مع بقاء قائمة `ALLOWED_ORIGINS` هي الحاكمة في الإنتاج.
