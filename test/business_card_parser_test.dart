import 'package:business_card_app/utils/business_card_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusinessCardParser', () {
    test('reads a conventional card', () {
      final result = BusinessCardParser.parse([
        'Aung Myat Thu',
        'Senior Software Engineer',
        'Golden Tech Co., Ltd',
        'Tel: 09 4211 55678',
        'aung.myat@goldentech.com.mm',
        'www.goldentech.com.mm',
        'No. 45, Bogyoke Road, Pabedan Township, Yangon',
      ]);

      expect(result.name, 'Aung Myat Thu');
      expect(result.position, 'Senior Software Engineer');
      expect(result.company, 'Golden Tech Co., Ltd');
      expect(result.phones, ['09421155678']);
      expect(result.emails, ['aung.myat@goldentech.com.mm']);
      expect(result.websites, contains('www.goldentech.com.mm'));
      expect(result.addressLines.join(' '), contains('Bogyoke Road'));
    });

    test('normalizes phone punctuation and keeps a leading plus', () {
      final result = BusinessCardParser.parse([
        'Jane Cooper',
        '+95 (9) 771-234-567',
      ]);

      expect(result.phones, ['+959771234567']);
    });

    test('rejects digit runs too short or too long to be a phone', () {
      final result = BusinessCardParser.parse([
        'Jane Cooper',
        'Est. 1998',
        'Ref 1234567890123456789',
      ]);

      expect(result.phones, isEmpty);
    });

    test('collects several emails and drops duplicates', () {
      final result = BusinessCardParser.parse([
        'Sales Team',
        'sales@acme.io, Support@ACME.io',
        'sales@acme.io',
      ]);

      expect(result.emails, ['sales@acme.io', 'support@acme.io']);
    });

    test('takes the line after the name as company when no legal suffix', () {
      final result = BusinessCardParser.parse([
        'Maria Santos',
        'Bright Studio',
        'maria@bright.studio',
      ]);

      expect(result.name, 'Maria Santos');
      expect(result.company, 'Bright Studio');
    });

    test('does not mistake an address line for a name', () {
      final result = BusinessCardParser.parse([
        'Tower B, 12th Floor',
        'Daw Khin Aye',
      ]);

      expect(result.name, 'Daw Khin Aye');
    });

    test('strips a field label from the value it precedes', () {
      final result = BusinessCardParser.parse([
        'Ko Ko Lwin',
        'Mobile: 09788112233',
        'Email: koko@example.com',
      ]);

      expect(result.name, 'Ko Ko Lwin');
      expect(result.phones, ['09788112233']);
      expect(result.emails, ['koko@example.com']);
    });

    test('back side only fills what the front left empty', () {
      final result = BusinessCardParser.parse(
        [
          'Hla Hla Win',
          '09 555 111 222',
        ],
        backLines: [
          'Wrong Name Here',
          'Marketing Manager',
          'hla@example.com',
        ],
      );

      expect(result.name, 'Hla Hla Win');
      expect(result.position, 'Marketing Manager');
      expect(result.emails, ['hla@example.com']);
      expect(result.phones, ['09555111222']);
    });

    test('reports empty when nothing usable was recognized', () {
      final result = BusinessCardParser.parse(['', '   ', '***', '///']);

      expect(result.isEmpty, isTrue);
    });

    test('splits multi-line blocks OCR returns as one string', () {
      final result = BusinessCardParser.parse([
        'Thura Zaw\nProject Director',
        'thura@example.org',
      ]);

      expect(result.name, 'Thura Zaw');
      expect(result.position, 'Project Director');
    });
  });
}
