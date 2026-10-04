import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/utils/date_utils.dart';

void main() {
  group('greetingFor', () {
    test('morning, afternoon, evening boundaries', () {
      expect(greetingFor(DateTime(2026, 1, 1, 5)), 'Good morning');
      expect(greetingFor(DateTime(2026, 1, 1, 11, 59)), 'Good morning');
      expect(greetingFor(DateTime(2026, 1, 1, 12)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 1, 1, 17, 59)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 1, 1, 18)), 'Good evening');
      expect(greetingFor(DateTime(2026, 1, 1, 23)), 'Good evening');
      expect(greetingFor(DateTime(2026, 1, 1, 2)), 'Good evening');
    });
  });

  group('firstNameOf', () {
    test('takes first word, handles blank/null', () {
      expect(firstNameOf('Ana Marie Reyes'), 'Ana');
      expect(firstNameOf('  Juan '), 'Juan');
      expect(firstNameOf(''), '');
      expect(firstNameOf(null), '');
    });
  });
}
