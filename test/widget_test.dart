import 'package:flutter_test/flutter_test.dart';

import 'package:tawati_mobile/main.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const TawatiApp());
    expect(find.byType(TawatiApp), findsOneWidget);
  });
}
