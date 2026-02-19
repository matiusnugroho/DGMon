import 'package:flutter_test/flutter_test.dart';

import 'package:dgmon/main.dart';

void main() {
  testWidgets('Tracker renders base layout', (WidgetTester tester) async {
    await tester.pumpWidget(const DgMonApp());

    expect(find.text('DGMon Expense Tracker'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
  });
}
