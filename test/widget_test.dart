// Hotel Expense Tracker Widget Tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hotel_expense_tracker/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HotelExpenseTrackerApp());

    // Verify that the app title is present
    expect(find.text('Hotel Expense Tracker'), findsOneWidget);
  });
}
