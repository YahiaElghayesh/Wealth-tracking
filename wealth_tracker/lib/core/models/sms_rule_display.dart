import 'package:flutter/widgets.dart';

/// The Unicode "first strong character" rule -- the same one browsers and
/// the phone's own SMS app use to pick a paragraph's base direction when
/// none is set explicitly. Needed because an English-language screen's
/// ambient `Directionality` is LTR, which would otherwise misalign and
/// visually reorder an Arabic-dominant real bank SMS compared to how it
/// renders in the SMS app itself -- making it hard to tell what a
/// drag-select is actually about to capture, especially for a Latin/
/// English substring (a vendor name, an amount) sitting inside the
/// Arabic. Scans for the first character that is strongly one direction
/// or the other; a message with no such character (pure digits/
/// punctuation) falls back to LTR.
TextDirection detectSampleDirection(String text) {
  for (final rune in text.runes) {
    final isRtl =
        (rune >= 0x0590 && rune <= 0x05FF) || // Hebrew
        (rune >= 0x0600 && rune <= 0x06FF) || // Arabic
        (rune >= 0x0750 && rune <= 0x077F) || // Arabic Supplement
        (rune >= 0x08A0 && rune <= 0x08FF) || // Arabic Extended-A
        (rune >= 0xFB50 && rune <= 0xFDFF) || // Arabic Presentation Forms-A
        (rune >= 0xFE70 && rune <= 0xFEFF); // Arabic Presentation Forms-B
    if (isRtl) return TextDirection.rtl;
    final isLtrLetter =
        (rune >= 0x0041 && rune <= 0x005A) || // A-Z
        (rune >= 0x0061 && rune <= 0x007A) || // a-z
        (rune >= 0x00C0 && rune <= 0x02AF); // Latin-1 Supplement / Extended
    if (isLtrLetter) return TextDirection.ltr;
  }
  return TextDirection.ltr;
}

/// Shared between the SMS Rule editor (tagging a sample) and the Test an
/// SMS screen (showing what a rule requires, tag by tag, when nothing
/// matched) -- one visual language for "this portion means X" in both
/// places.
const smsTagColors = {
  'cardNumber': Color(0x334C6EF5),
  'value': Color(0x3312B886),
  'vendor': Color(0x33F59F00),
  'sender': Color(0x33AE3EC9),
  'currency': Color(0x33FA5252),
  'ignore': Color(0x33868E96),
  'transactionValue': Color(0x33845EF7),
  'transactionCurrency': Color(0x33E64980),
};

const smsTagLabels = {
  'cardNumber': 'Card/account number',
  'value': 'Value',
  'vendor': 'Vendor name',
  'sender': 'Sender name',
  'currency': 'Currency',
  'ignore': 'Varies (date, time, ref #...)',
  'transactionValue': 'Transaction amount (notification only)',
  'transactionCurrency': "Transaction amount's own currency",
};
