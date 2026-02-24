import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dgmon/main.dart';

void main() {
  testWidgets('repro create cash account', (WidgetTester tester) async {
    await tester.pumpWidget(const DgMonApp());

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan Kas'), findsOneWidget);

    await tester.tap(find.text('Tambah').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama akun'),
      'BCA',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Saldo awal'),
      '1000',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('BCA'), findsAtLeastNWidgets(1));
  });
}
