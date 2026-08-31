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
      expect(result.isCharge, isTrue);
      expect(result.lastFourDigits, '4912');
      expect(result.availableBalanceAfter, 85891.16);
    });

    test('a charge SMS missing the last-4-digits or available-limit portions still parses', () {
      const body = 'Your credit card was charged for EGP 100 at Somewhere on 01/01/26 at 09:05.';

      final result = parseBankSms(body);

      expect(result, isNotNull);
      expect(result!.vendor, 'Somewhere');
      expect(result.lastFourDigits, isNull);
      expect(result.availableBalanceAfter, isNull);
    });

    test('an available-limit figure in a different currency is not trusted', () {
      const body = 'Your credit card ending with#4912 was charged for EGP 100 at Somewhere '
          'on 01/01/26 at 09:05. Card available limit is USD 500.';

      final result = parseBankSms(body);

      expect(result!.availableBalanceAfter, isNull);
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

    test('parses the real NBE Arabic charge-alert format', () {
      const body = 'تم خصم USD 84.44 من بطاقة الائتمان رقم 8455  عند HODJAPASHA CULT يوم '
          '08-26 الساعة 22:27 المتاح 491269.64 جم والمتبقي من حد الاستخدام الشهري بالعملة '
          'الأجنبية بما يعادل 154722.75 جم للمزيد اتصل ب 19623.';

      final result = parseBankSms(body);

      expect(result, isNotNull);
      expect(result!.vendor, 'HODJAPASHA CULT');
      expect(result.currency, 'USD');
      expect(result.amount, 85.0);
      expect(result.isCharge, isTrue);
      expect(result.lastFourDigits, '8455');
      // Stated in EGP even though the charge itself was in USD — the card
      // is billed in EGP, so the balance the user cares about tracking is
      // this figure, not one in the charge's own currency.
      expect(result.availableBalanceAfter, 491269.64);
      expect(result.availableBalanceCurrency, 'EGP');
    });

    test('NBE date with no year rolls back to last year if it would otherwise be in the future', () {
      final futureMonth = DateTime.now().month == 12 ? 1 : DateTime.now().month + 1;
      final body = 'تم خصم EGP 100 من بطاقة الائتمان رقم 1234  عند Somewhere يوم '
          '${futureMonth.toString().padLeft(2, '0')}-15 الساعة 09:00 المتاح 5000 جم';

      final result = parseBankSms(body);

      expect(result, isNotNull);
      expect(result!.occurredAt.isAfter(DateTime.now()), isFalse);
    });

    test('parses the real CIB Arabic payment-alert format (paying down the card)', () {
      const body = 'نشكركم على سداد مبلغ 8860.36 جم لبطاقة رقم 8455 يوم 28/08';

      final result = parseBankSms(body);

      expect(result, isNotNull);
      expect(result!.currency, 'EGP');
      // NOT rounded up, unlike a charge -- this never becomes a ledger
      // entry, only feeds the card balance's add-the-amount math, where
      // rounding up would overstate the real balance.
      expect(result.amount, 8860.36);
      expect(result.isCharge, isFalse);
      expect(result.lastFourDigits, '8455');
      expect(result.availableBalanceAfter, isNull);
    });

    test('parses the real NBE Arabic payment-alert format (paying down the card)', () {
      const body = 'تم سداد مبلغ 100000.00 جم فى بطاقتكم الائتمانية المنتهية بـ 4912 بتاريخ 21-08-26';

      final result = parseBankSms(body);

      expect(result, isNotNull);
      expect(result!.currency, 'EGP');
      expect(result.amount, 100000.0);
      expect(result.isCharge, isFalse);
      expect(result.lastFourDigits, '4912');
      expect(result.occurredAt, DateTime(2026, 8, 21));
      expect(result.availableBalanceAfter, isNull);
    });

    test('parses the real Arabic refund-alert format', () {
      const body = 'لقد تم رد EGP1500.00 على بطاقتكم الائتمانية المنتهية بـ# 4912 من Amazon Marketpl'
          '. يرجى ملاحظة أن هذا المبلغ سيتم إضافته إلى رصيد بطاقتك ولا يتم اعتباره بمثابة دفعة '
          'للمديونيات المستحقة لهذا الشهر.';

      final result = parseBankSms(body);

      expect(result, isNotNull);
      expect(result!.currency, 'EGP');
      expect(result.amount, 1500.0);
      expect(result.isCharge, isFalse);
      expect(result.lastFourDigits, '4912');
      expect(result.availableBalanceAfter, isNull);
    });

    test('parses the same refund format even with invisible RTL marks banks embed around numbers', () {
      // Real Arabic bank SMS often surrounds a Western-digit number sitting
      // inside right-to-left prose with invisible bidi control characters
      // (here: RTL mark \u200f around "EGP1500.00" and "4912") so it
      // displays correctly -- these aren't whitespace, so `\s*` in the
      // pattern wouldn't bridge across one uncorrected. This is the same
      // body as the previous test, just with those marks spliced in.
      const body = 'لقد تم رد \u200fEGP1500.00\u200f على بطاقتكم الائتمانية المنتهية بـ# \u200f4912\u200f '
          'من Amazon Marketpl. يرجى ملاحظة أن هذا المبلغ سيتم إضافته إلى رصيد بطاقتك ولا يتم اعتباره '
          'بمثابة دفعة للمديونيات المستحقة لهذا الشهر.';

      final result = parseBankSms(body);

      expect(result, isNotNull);
      expect(result!.currency, 'EGP');
      expect(result.amount, 1500.0);
      expect(result.lastFourDigits, '4912');
    });
  });
}
