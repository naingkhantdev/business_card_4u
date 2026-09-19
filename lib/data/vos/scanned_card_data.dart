import 'address_model.dart';

/// Fields extracted from a photo of a physical business card.
///
/// Every field is a best-effort guess — the user always reviews and edits the
/// form before saving, so a wrong guess is a nuisance, never a data error.
class ScannedCardData {
  final String? name;
  final String? position;

  /// Company printed on the card. The API links cards to companies by id, so
  /// this is only surfaced as a hint next to the company picker.
  final String? companyName;

  final List<String> phones;
  final List<String> emails;
  final String? website;
  final AddressModel? address;

  /// Everything the recogniser read, in reading order. Useful for debugging and
  /// as a fallback the user can copy from.
  final String rawText;

  const ScannedCardData({
    this.name,
    this.position,
    this.companyName,
    this.phones = const [],
    this.emails = const [],
    this.website,
    this.address,
    this.rawText = '',
  });

  static const ScannedCardData empty = ScannedCardData();

  bool get isEmpty =>
      name == null &&
      position == null &&
      companyName == null &&
      phones.isEmpty &&
      emails.isEmpty &&
      website == null &&
      address == null;

  bool get isNotEmpty => !isEmpty;
}
