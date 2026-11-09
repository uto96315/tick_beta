import 'package:flutter_test/flutter_test.dart';
import 'package:tick/services/notification_copy.dart';

void main() {
  test('segment notifications avoid progress fractions', () {
    final line = segmentNotification('ja', 0, 36);
    expect(line.body, isNot(contains('/')));
    expect(line.body, contains('35'));
  });

  test('end copy stays punchy', () {
    final copy = notificationCopy('ja');
    expect(copy.endTitle, isNotEmpty);
    expect(copy.endBody, isNot(contains('/')));
  });
}
