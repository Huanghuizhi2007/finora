import 'package:finora/data/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version compare detects newer releases', () {
    expect(UpdateService.isNewer('0.2.3', '0.2.2'), isTrue);
    expect(UpdateService.isNewer('0.2.2', '0.2.2'), isFalse);
    expect(UpdateService.isNewer('0.2.1', '0.2.2'), isFalse);
    expect(UpdateService.isNewer('0.3.0', '0.2.9'), isTrue);
  });
}
