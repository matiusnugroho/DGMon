import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dgmon/main.dart';

void main() {
  testWidgets('repro create cash account', (WidgetTester tester) async {
    await tester.pumpWidget(const DgMonApp());

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Cash Accounts'), findsOneWidget);

    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'BCA');
    await tester.enterText(find.widgetWithText(TextFormField, 'Opening balance'), '1000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('BCA'), findsOneWidget);
  });
}
