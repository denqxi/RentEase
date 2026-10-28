import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/notification_doc.dart';

void main() {
  group('NotificationDoc.fromMap', () {
    test('parses standard map correctly', () {
      final now = DateTime(2026, 10, 29, 12, 0);
      final doc = NotificationDoc.fromMap('n1', {
        'recipientId': 'u1',
        'type': 'inquiry',
        'title': 'Test title',
        'body': 'Test body',
        'relatedId': 'inq123',
        'relatedType': 'inquiry',
        'isRead': false,
        'createdAt': Timestamp.fromDate(now),
      });

      expect(doc.notifId, 'n1');
      expect(doc.recipientId, 'u1');
      expect(doc.type, 'inquiry');
      expect(doc.title, 'Test title');
      expect(doc.body, 'Test body');
      expect(doc.relatedId, 'inq123');
      expect(doc.relatedType, 'inquiry');
      expect(doc.isRead, isFalse);
      expect(doc.createdAt, Timestamp.fromDate(now));
    });

    test('handles completely empty or missing map safely without throwing', () {
      final doc = NotificationDoc.fromMap('n2', {});

      expect(doc.notifId, 'n2');
      expect(doc.recipientId, '');
      expect(doc.type, '');
      expect(doc.title, '');
      expect(doc.body, '');
      expect(doc.relatedId, isNull);
      expect(doc.relatedType, isNull);
      expect(doc.isRead, isFalse);
      expect(doc.createdAt, isNull);
    });

    test('handles malformed types for createdAt (string, int, DateTime)', () {
      final date = DateTime(2026, 5, 1, 8, 30);

      // ISO8601 string
      final fromStr = NotificationDoc.fromMap('n3', {
        'createdAt': date.toIso8601String(),
      });
      expect(fromStr.createdAt, Timestamp.fromDate(date));

      // Milliseconds integer
      final fromInt = NotificationDoc.fromMap('n4', {
        'createdAt': date.millisecondsSinceEpoch,
      });
      expect(fromInt.createdAt, Timestamp.fromDate(date));

      // DateTime object
      final fromDt = NotificationDoc.fromMap('n5', {
        'createdAt': date,
      });
      expect(fromDt.createdAt, Timestamp.fromDate(date));

      // Corrupted / unexpected type
      final fromCorrupt = NotificationDoc.fromMap('n6', {
        'createdAt': ['not', 'a', 'date'],
      });
      expect(fromCorrupt.createdAt, isNull);
    });

    test('handles malformed boolean for isRead (numeric, string)', () {
      expect(NotificationDoc.fromMap('1', {'isRead': true}).isRead, isTrue);
      expect(NotificationDoc.fromMap('2', {'isRead': false}).isRead, isFalse);
      expect(NotificationDoc.fromMap('3', {'isRead': 1}).isRead, isTrue);
      expect(NotificationDoc.fromMap('4', {'isRead': 0}).isRead, isFalse);
      expect(NotificationDoc.fromMap('5', {'isRead': 'true'}).isRead, isTrue);
      expect(NotificationDoc.fromMap('6', {'isRead': 'false'}).isRead, isFalse);
      expect(NotificationDoc.fromMap('7', {'isRead': null}).isRead, isFalse);
    });

    test('toMap serializes properly', () {
      final doc = NotificationDoc(
        notifId: 'id1',
        recipientId: 'u1',
        type: 'message',
        title: 'New message',
        body: 'Hello',
        relatedId: 'inq1',
        relatedType: 'inquiry',
        isRead: true,
      );
      final map = doc.toMap();
      expect(map['recipientId'], 'u1');
      expect(map['type'], 'message');
      expect(map['title'], 'New message');
      expect(map['body'], 'Hello');
      expect(map['relatedId'], 'inq1');
      expect(map['relatedType'], 'inquiry');
      expect(map['isRead'], isTrue);
    });
  });
}
