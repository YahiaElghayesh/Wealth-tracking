import 'package:flutter_test/flutter_test.dart';

import 'package:wealth_tracker/data/sms/bank_sms_parser.dart';

void main() {
  group('parseBankSms', () {
    test('parses the real CIB charge-alert format, rounding the amount up', () {
      const body = 'Your credit card ending with#4912 was charged for EGP 958.54 at Breadfast '
          'on 27/08/26  at 13:30. Card available limit is EGP  85891.16. For more details, '
          'please visit https://cib.eg/mb';

      final result = parseBankSms(body);

      expect(result, isNotNull);
      expect(result!.vendor, 'Breadfast');
      expect(result.currency, 'EGP');
      expect(result.amount, 959.0);
      expect(result.occurredAt, DateTime(2026, 8, 27, 13, 30));
    });

    test('a whole-number charge is not altered', () {
      const body = 'Your credit card ending with#1234 was charged for EGP 200 at Amazon '
          'on 01/01/26 at 09:05. Card available limit is EGP 1000.';

      final result = parseBankSms(body);

      expect(result!.amount, 200.0);
    });

    test('a multi-word vendor name is captured in full', () {
      const body = 'Your credit card ending with#1234 was charged for EGP 50.10 at Food Store '
          'on 01/01/26 at 09:05. Card available limit is EGP 1000.';

      final result = parseBankSms(body);

      expect(result!.vendor, 'Food Store');
      expect(result.amount, 51.0);
    });

    test('unrelated SMS text returns null', () {
      expect(parseBankSms('Your OTP is 123456. Do not share it with anyone.'), isNull);
    });
  });
}
