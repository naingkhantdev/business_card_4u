import 'package:business_card_app/services/ocr/card_text_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardTextParser', () {
    test('reads a typical English card', () {
      final scanned = CardTextParser.parse(const [
        OcrLine('Acme Technologies Ltd.', 24),
        OcrLine('John Smith', 40),
        OcrLine('Senior Software Engineer', 20),
        OcrLine('Tel: +95 9 123 456 789', 14),
        OcrLine('Email: John.Smith@acme.com', 14),
        OcrLine('www.acme.com', 14),
        OcrLine('No. 12, Bogyoke Road, Yangon 11181', 14),
      ]);

      expect(scanned.name, 'John Smith');
      expect(scanned.position, 'Senior Software Engineer');
      expect(scanned.companyName, 'Acme Technologies Ltd.');
      expect(scanned.phones, ['+95 9 123 456 789']);
      expect(scanned.emails, ['john.smith@acme.com']);
      expect(scanned.website, 'www.acme.com');
      expect(scanned.address?.street, 'No. 12, Bogyoke Road, Yangon');
      expect(scanned.address?.postalCode, '11181');
    });

    test('falls back to reading order when no geometry is available', () {
      final scanned = CardTextParser.parse(const [
        OcrLine('Jane Doe'),
        OcrLine('Marketing Manager'),
        OcrLine('jane@doe.io'),
      ]);

      expect(scanned.name, 'Jane Doe');
      expect(scanned.position, 'Marketing Manager');
      expect(scanned.emails, ['jane@doe.io']);
    });

    test('takes the line under the name when no job-title word is printed', () {
      final scanned = CardTextParser.parse(const [
        OcrLine('Mya Thet', 30),
        OcrLine('Barista', 16),
        OcrLine('mya@cafe.mm', 12),
      ]);

      expect(scanned.name, 'Mya Thet');
      expect(scanned.position, 'Barista');
    });

    test('keeps several phones and emails, and drops fax numbers', () {
      final scanned = CardTextParser.parse(const [
        OcrLine('Sam Lee', 30),
        OcrLine('M: 09 4567 8912', 12),
        OcrLine('T: 01 234 5678', 12),
        OcrLine('F: 01 234 5679', 12),
        OcrLine('sam@corp.com / sales@corp.com', 12),
      ]);

      expect(scanned.phones, ['09 4567 8912', '01 234 5678']);
      expect(scanned.emails, ['sam@corp.com', 'sales@corp.com']);
    });

    test('does not read years or street numbers as phone numbers', () {
      final scanned = CardTextParser.parse(const [
        OcrLine('Ko Ko Zaw', 30),
        OcrLine('Established 2015', 12),
      ]);

      expect(scanned.phones, isEmpty);
    });

    test('reports nothing for an unreadable photo', () {
      final scanned = CardTextParser.parse(const []);

      expect(scanned.isEmpty, isTrue);
      expect(scanned.rawText, '');
    });

    test('keeps the raw text for every recognised line', () {
      final scanned = CardTextParser.parse(const [
        OcrLine('Line one', 10),
        OcrLine('Line two', 10),
      ]);

      expect(scanned.rawText, 'Line one\nLine two');
    });
  });
}
