// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_app/main.dart';
import 'package:finance_app/providers/auth_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/screens/transactions_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Finance app loads the login screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const FinanceApp());
    await tester.pumpAndSettle();

    expect(find.text('FinanceApp'), findsOneWidget);
    expect(find.image(const AssetImage('assets/fincontrol_logo.png')),
        findsOneWidget);
  });

  testWidgets('date filter opens a Portuguese date picker',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          supportedLocales: [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(body: TransactionsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Data inicial'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);
  });
}
