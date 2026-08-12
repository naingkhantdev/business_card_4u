import 'package:business_card_app/data/vos/address_model.dart';
import 'package:business_card_app/data/vos/business_card_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddressModel', () {
    test('serializes with snake_case postal_code key', () {
      final model = AddressModel(
        street: '123 Main St',
        city: 'Yangon',
        state: 'Yangon Region',
        postalCode: '11181',
        country: 'Myanmar',
      );

      final json = model.toJson();
      expect(json['postal_code'], '11181');

      final decoded = AddressModel.fromJson(json);
      expect(decoded.city, 'Yangon');
      expect(decoded.postalCode, '11181');
    });

    test('displayText joins only filled parts', () {
      final model = AddressModel(city: 'Dublin', country: 'Ireland');
      expect(model.displayText, 'Dublin, Ireland');
      expect(model.isEmpty, isFalse);
      expect(AddressModel().isEmpty, isTrue);
    });
  });

  group('BusinessCardModel addresses', () {
    test('parses structured address objects', () {
      final card = BusinessCardModel.fromJson({
        'id': 1,
        'addresses': [
          {
            'street': '55 Baker St',
            'city': 'London',
            'state': null,
            'postal_code': 'NW1 6XE',
            'country': 'United Kingdom',
          },
        ],
      });

      expect(card.addresses, hasLength(1));
      expect(card.addresses.first.city, 'London');
      expect(card.addresses.first.postalCode, 'NW1 6XE');
    });

    test('folds legacy free-text addresses into street', () {
      final card = BusinessCardModel.fromJson({
        'id': 1,
        'addresses': ['No 12, Old Town Road'],
      });

      expect(card.addresses, hasLength(1));
      expect(card.addresses.first.street, 'No 12, Old Town Road');
      expect(card.addresses.first.city, isNull);
    });

    test('handles null addresses', () {
      final card = BusinessCardModel.fromJson({'id': 1});
      expect(card.addresses, isEmpty);
    });
  });
}
