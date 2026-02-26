import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dgmon/main.dart';

void main() {
  testWidgets('Dashboard renders core sections', (WidgetTester tester) async {
    await tester.pumpWidget(const DgMonApp());

    final List<String> possibleGreetings = <String>[
      'Selamat pagi, Duo',
      'Selamat siang, Duo',
      'Selamat sore, Duo',
      'Selamat malam, Duo',
    ];
    final bool hasGreeting = possibleGreetings.any(
      (String greeting) => find.text(greeting).evaluate().isNotEmpty,
    );

    expect(hasGreeting, isTrue);
    expect(find.text('TOTAL SALDO'), findsOneWidget);
    expect(find.text('Transaksi Terbaru'), findsOneWidget);
  });

  testWidgets('Plus button meminta setup data saat masih kosong', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DgMonApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(
      find.text('Belum ada akun kas. Tambah dulu di menu Kas.'),
      findsOneWidget,
    );
    expect(find.text('Tambah Transaksi'), findsNothing);
  });

  testWidgets('Bisa tambah transaksi setelah akun kas dan kategori dibuat', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DgMonApp());

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah akun kas'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama akun'),
      'BRI',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Saldo awal'),
      '20000000',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.category_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah kategori'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama kategori'),
      'Makan',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.dashboard));
    await tester.pumpAndSettle();

    expect(find.text('Rp 20.000.000'), findsAtLeastNWidgets(1));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Sarapan');
    await tester.enterText(find.byType(TextFormField).at(1), '10000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Sarapan'), findsOneWidget);
    expect(find.text('BRI - Makan - Hari ini'), findsAtLeastNWidgets(1));
    expect(find.text('Rp 19.990.000'), findsAtLeastNWidgets(1));
  });
}
