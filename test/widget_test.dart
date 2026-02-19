import 'package:flutter_test/flutter_test.dart';

import 'package:dgmon/main.dart';

void main() {
  testWidgets('Dashboard renders core sections', (WidgetTester tester) async {
    await tester.pumpWidget(const DgMonApp());

    expect(find.text('Good Morning, Duo'), findsOneWidget);
    expect(find.text('TOTAL BALANCE'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);
  });
}
