import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zogo_realtor/features/home/presentation/screens/my_activities_screen.dart';

void main() {
  group('MyActivitiesScreen UI Tests', () {
    testWidgets('Renders tabs for Visits and Formal Offers for buyer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyActivitiesScreen(hasSellerRole: false),
        ),
      );

      // Verify Title
      expect(find.text('My Activities'), findsOneWidget);

      // Verify Tab bars
      expect(find.textContaining('Visits'), findsOneWidget);
      expect(find.textContaining('Offers'), findsOneWidget);
      expect(find.text('My Listings'), findsNothing);
    });

    testWidgets('Renders Listings tab when hasSellerRole is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyActivitiesScreen(hasSellerRole: true),
        ),
      );

      // Verify Tab bars
      expect(find.textContaining('Visits'), findsOneWidget);
      expect(find.textContaining('Offers'), findsOneWidget);
      expect(find.text('My Listings'), findsOneWidget);
    });
  });
}
