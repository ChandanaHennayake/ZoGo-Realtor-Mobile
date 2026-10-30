import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zogo_realtor/features/buyer/models/buyer_property_details.dart';
import 'package:zogo_realtor/features/buyer/models/buyer_property_list_item.dart';
import 'package:zogo_realtor/features/buyer/presentation/widgets/visit_request_contact_sheet.dart';

void main() {
  group('Agent contact & visit request model tests', () {
    test('BuyerPropertyDetails parses agent fields from JSON', () {
      final json = {
        'propertyId': 'prop-123',
        'referenceNo': 'ZG-001',
        'title': 'Luxury Colombo Apartment',
        'askingPrice': 45000000,
        'agentUserId': 'user-agent-999',
        'agentName': 'ZoGo Agent Colombo',
        'agentPhoneNumber': '0770000002',
        'districtId': 1,
        'districtName': 'Colombo',
      };

      final details = BuyerPropertyDetails.fromJson(json);

      expect(details.propertyId, 'prop-123');
      expect(details.agentUserId, 'user-agent-999');
      expect(details.agentName, 'ZoGo Agent Colombo');
      expect(details.agentPhoneNumber, '0770000002');
    });

    test('BuyerPropertyListItem parses agent fields and provides locationDisplay', () {
      final json = {
        'propertyId': 'prop-456',
        'referenceNo': 'ZG-002',
        'title': 'Kandy Villa',
        'askingPrice': 25000000,
        'agentUserId': 'user-agent-888',
        'agentName': 'Kandy Agent',
        'agentPhoneNumber': '0771234567',
        'city': 'Kandy',
        'districtName': 'Kandy',
      };

      final item = BuyerPropertyListItem.fromJson(json);

      expect(item.propertyId, 'prop-456');
      expect(item.agentUserId, 'user-agent-888');
      expect(item.agentName, 'Kandy Agent');
      expect(item.agentPhoneNumber, '0771234567');
      expect(item.locationDisplay, 'Kandy, Kandy');
    });
  });

  group('VisitRequestContactSheet UI Widget Tests', () {
    testWidgets('Renders agent name, phone number, and Call/Chat options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitRequestContactSheet(
              propertyId: 'prop-123',
              propertyTitle: 'Luxury Sea View Villa',
              agentName: 'Saman Perera',
              agentPhoneNumber: '0770000002',
              districtName: 'Colombo',
              onScheduleAlternative: () {},
            ),
          ),
        ),
      );

      // Verify title and prompt
      expect(find.text('Request Property Visit'), findsOneWidget);
      expect(find.text('Choose how you want to connect with the assigned agent'), findsOneWidget);

      // Verify Agent details from account
      expect(find.text('Saman Perera'), findsOneWidget);
      expect(find.text('0770000002'), findsOneWidget);
      expect(find.text('VERIFIED AGENT'), findsOneWidget);
      expect(find.text('District: Colombo'), findsOneWidget);

      // Verify Call and Chat buttons
      expect(find.text('Call Agent Mobile'), findsOneWidget);
      expect(find.text('Dial 0770000002 to schedule visit directly'), findsOneWidget);
      expect(find.text('Chat with Agent'), findsOneWidget);
      expect(find.text('Or pick a date & time slot online'), findsOneWidget);
    });
  });
}

