import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dgmon/main.dart';

void main() {
  testWidgets('Dashboard renders core sections', (WidgetTester tester) async {
    await tester.pumpWidget(const DgMonApp());

    expect(find.text('Selamat pagi, Duo'), findsOneWidget);
    expect(find.text('TOTAL SALDO'), findsOneWidget);
    expect(find.text('Transaksi Terbaru'), findsOneWidget);
  });

  testWidgets('Plus button opens add transaction form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DgMonApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Transaksi'), findsOneWidget);
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Tipe'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'Ngopi');
    await tester.enterText(find.byType(TextFormField).at(1), '25000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Ngopi'), findsOneWidget);
    expect(find.text('BRI - Makan - Hari ini'), findsAtLeastNWidgets(2));
  });

  testWidgets('Saving expense updates related cash balance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DgMonApp());

    expect(find.text('Rp 19.980.000'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Sarapan');
    await tester.enterText(find.byType(TextFormField).at(1), '10000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Rp 19.970.000'), findsOneWidget);
  });
}
