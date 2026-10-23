import 'package:flutter_test/flutter_test.dart';

import 'package:musclemind_app/main.dart';

void main() {
  testWidgets('MuscleMind app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MuscleMindApp());

    expect(find.byType(MuscleMindApp), findsOneWidget);
  });
}