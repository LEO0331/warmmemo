import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/data/services/input_analytics_service.dart';

void main() {
  group('InputAnalyticsService', () {
    test('tracks counters and daily counters', () async {
      final db = FakeFirebaseFirestore();
      final service = InputAnalyticsService(firestore: db);

      await service.trackFieldError(
        uid: 'u1',
        screen: 'memorial_page',
        field: 'proposal_schedule',
        errorCode: 'date_format_invalid',
        message: '日期格式錯誤',
      );
      await service.trackFieldError(
        uid: 'u1',
        screen: 'memorial_page',
        field: 'proposal_schedule',
        errorCode: 'date_format_invalid',
      );

      final doc = await db
          .collection('users')
          .doc('u1')
          .collection('meta')
          .doc('inputValidationAnalytics')
          .get();
      final data = doc.data();
      expect(data, isNotNull);

      final counters = Map<String, dynamic>.from(data!['counters'] as Map);
      expect(
        counters['memorial_page__proposal_schedule__date_format_invalid'],
        2,
      );

      final daily = Map<String, dynamic>.from(data['dailyCounters'] as Map);
      expect(daily.isNotEmpty, isTrue);
      final todayMap = Map<String, dynamic>.from(daily.values.first as Map);
      expect(
        todayMap['memorial_page__proposal_schedule__date_format_invalid'],
        2,
      );
      expect(data['lastEvent'], isA<Map<String, dynamic>>());
    });
  });
}
