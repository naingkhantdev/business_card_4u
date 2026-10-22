import '../../data/vos/address_model.dart';
import '../../data/vos/scanned_card_data.dart';

/// One line of recognised text plus the height of its bounding box.
///
/// Height is the strongest available signal for the person's name: on almost
/// every card it is set in the largest type on the front.
class OcrLine {
  final String text;
  final double height;

  const OcrLine(this.text, [this.height = 0]);
}

/// Turns the lines an OCR engine read off an English/Latin-script business card
/// into form values.
///
/// Pure and synchronous on purpose — the ML Kit plugin is only responsible for
/// producing [OcrLine]s, so all the guessing lives here where it can be tested
/// without a device.
class CardTextParser {
  const CardTextParser._();

  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]*\w');
  static final RegExp _url = RegExp(
    r'(https?://|www\.)[^\s,;]+',
    caseSensitive: false,
  );

  /// A run of digits with the usual separators and an optional leading +.
  static final RegExp _phone = RegExp(r'\+?\d[\d\s()./-]{5,}\d');

  static final RegExp _postalCode = RegExp(r'\b\d{4,6}\b');

  /// Labels that sit in front of a value and carry no information themselves.
  static final RegExp _fieldLabel = RegExp(
    r'^\s*(tel|telephone|phone|mobile|cell|hp|fax|email|e-?mail|web|website|url|address|addr|office|direct)\s*[:.\-]?\s*',
    caseSensitive: false,
  );

  static final RegExp _faxLine =
      RegExp(r'\b(fax|f\s*[:.])', caseSensitive: false);

  static const List<String> _companyMarkers = [
    'ltd',
    'limited',
    'llc',
    'inc',
    'co.',
    'corp',
    'corporation',
    'company',
    'group',
    'holdings',
    'technologies',
    'technology',
    'solutions',
    'systems',
    'services',
    'enterprise',
    'enterprises',
    'industries',
    'international',
    'pte',
    'plc',
    'gmbh',
    'bank',
    'studio',
    'labs',
    'agency',
    'consulting',
  ];

  static const List<String> _positionMarkers = [
    'ceo',
    'cto',
    'coo',
    'cfo',
    'founder',
    'owner',
    'president',
    'director',
    'manager',
    'supervisor',
    'executive',
    'officer',
    'engineer',
    'developer',
    'designer',
    'architect',
    'analyst',
    'consultant',
    'specialist',
    'coordinator',
    'assistant',
    'associate',
    'lead',
    'head of',
    'chief',
    'senior',
    'junior',
    'intern',
    'accountant',
    'marketing',
    'sales',
    'support',
    'technician',
    'administrator',
  ];

  static const List<String> _addressMarkers = [
    'street',
    ' st.',
    ' st,',
    'road',
    ' rd',
    'avenue',
    ' ave',
    'boulevard',
    'blvd',
    'lane',
    'drive',
    'suite',
    'ste.',
    'floor',
    ' fl.',
    'building',
    'bldg',
    'block',
    'tower',
    'township',
    'district',
    'p.o. box',
    'po box',
    'no.',
    '#',
  ];

  static ScannedCardData parse(List<OcrLine> lines) {
    final emails = <String>[];
    final phones = <String>[];
    final addressLines = <String>[];
    final leftovers = <OcrLine>[];
    final rawLines = <String>[];
    String? website;

    for (final line in lines) {
      final original = line.text.trim();
      if (original.isEmpty) continue;
      rawLines.add(original);

      var rest = original;

      for (final match in _email.allMatches(rest)) {
        final email = match.group(0)!.toLowerCase();
        if (!emails.contains(email)) emails.add(email);
      }
      rest = rest.replaceAll(_email, ' ');

      for (final match in _url.allMatches(rest)) {
        website ??= match.group(0)!;
      }
      rest = rest.replaceAll(_url, ' ');

      // Fax numbers have nowhere to go in this app, so they are dropped rather
      // than mixed into the phone list.
      if (!_faxLine.hasMatch(original)) {
        for (final match in _phone.allMatches(rest)) {
          final phone = _normalizePhone(match.group(0)!);
          if (phone != null && !phones.contains(phone)) phones.add(phone);
        }
      }
      rest = rest.replaceAll(_phone, ' ');

      rest = rest.replaceFirst(_fieldLabel, '');
      rest = rest.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      // What remains is punctuation left behind by a value that was stripped.
      if (rest.replaceAll(RegExp(r'[^\w]'), '').isEmpty) continue;

      if (_looksLikeAddress(rest)) {
        addressLines.add(rest);
      } else {
        leftovers.add(OcrLine(rest, line.height));
      }
    }

    final companyName = _pickCompany(leftovers);
    final name = _pickName(leftovers, companyName);
    final position = _pickPosition(leftovers, name, companyName);

    return ScannedCardData(
      name: name,
      position: position,
      companyName: companyName,
      phones: phones,
      emails: emails,
      website: website,
      address: _buildAddress(addressLines),
      rawText: rawLines.join('\n'),
    );
  }

  static String? _normalizePhone(String raw) {
    final collapsed = raw.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    final digits = collapsed.replaceAll(RegExp(r'\D'), '');
    // Guards against years, postal codes and street numbers reading as phones.
    if (digits.length < 7 || digits.length > 15) return null;
    return collapsed;
  }

  static bool _looksLikeAddress(String text) {
    final lower = ' ${text.toLowerCase()} ';
    if (_addressMarkers.any(lower.contains)) return true;
    // "Yangon 11181, Myanmar" — a postal code sitting next to words.
    return _postalCode.hasMatch(text) && RegExp(r'[A-Za-z]{3,}').hasMatch(text);
  }

  static bool _containsMarker(String text, List<String> markers) {
    final lower = text.toLowerCase();
    return markers.any(lower.contains);
  }

  static String? _pickCompany(List<OcrLine> lines) {
    for (final line in lines) {
      if (_containsMarker(line.text, _companyMarkers)) return line.text;
    }
    return null;
  }

  /// The name is the largest remaining line that reads like a person's name:
  /// two to four mostly-alphabetic words.
  static String? _pickName(List<OcrLine> lines, String? companyName) {
    final candidates = lines
        .where((l) => l.text != companyName)
        .where((l) => !_containsMarker(l.text, _positionMarkers))
        .where((l) => _looksLikePersonName(l.text))
        .toList();

    if (candidates.isEmpty) return null;

    final tallest = candidates.reduce((a, b) => b.height > a.height ? b : a);
    // Heights are all zero when the engine reports no geometry; fall back to
    // the first candidate, which is highest on the card in reading order.
    return tallest.height > 0 ? tallest.text : candidates.first.text;
  }

  static bool _looksLikePersonName(String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length < 2 || words.length > 4) return false;
    final letters = text.replaceAll(RegExp(r'[^A-Za-z]'), '').length;
    final total = text.replaceAll(RegExp(r'\s'), '').length;
    return total > 0 && letters / total >= 0.8;
  }

  static String? _pickPosition(
    List<OcrLine> lines,
    String? name,
    String? companyName,
  ) {
    final available =
        lines.where((l) => l.text != name && l.text != companyName).toList();

    for (final line in available) {
      if (_containsMarker(line.text, _positionMarkers)) return line.text;
    }

    // No keyword matched: the line directly under the name is the next guess.
    if (name != null) {
      final nameIndex = lines.indexWhere((l) => l.text == name);
      if (nameIndex != -1 && nameIndex + 1 < lines.length) {
        final next = lines[nameIndex + 1];
        if (next.text != companyName) return next.text;
      }
    }
    return null;
  }

  /// Countries a printed address is checked against before a city is
  /// guessed. Without a recognised country to anchor on, the last couple of
  /// comma-separated segments are just as likely to be another street
  /// fragment as a city — e.g. "No. 12, Bogyoke Road, Yangon 11181" has no
  /// country printed at all, so nothing past the postal code should be
  /// pulled out as city. Recognising the country first keeps that case safe
  /// while still catching cards that do print one.
  static const List<String> _countries = [
    'myanmar',
    'thailand',
    'singapore',
    'malaysia',
    'china',
    'japan',
    'south korea',
    'korea',
    'india',
    'vietnam',
    'cambodia',
    'laos',
    'indonesia',
    'philippines',
    'australia',
    'united states',
    'usa',
    'u.s.a',
    'united kingdom',
    'uk',
    'canada',
    'germany',
    'france',
    'italy',
    'spain',
    'united arab emirates',
    'uae',
    'hong kong',
    'taiwan',
    'bangladesh',
    'sri lanka',
    'nepal',
    'pakistan',
    'switzerland',
    'netherlands',
  ];

  /// Address lines are joined and split on commas, with a postal code pulled
  /// out first because it can sit anywhere. When the last segment names a
  /// recognised country, that segment and the one before it (the city) are
  /// pulled out and whatever remains ahead of them is the street.
  static AddressModel? _buildAddress(List<String> addressLines) {
    if (addressLines.isEmpty) return null;

    final parts = addressLines
        .join(', ')
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    String? postalCode;
    for (var i = 0; i < parts.length; i++) {
      final match = _postalCode.firstMatch(parts[i]);
      if (match == null) continue;
      postalCode = match.group(0);
      final rest = parts[i].replaceRange(match.start, match.end, '').trim();
      if (rest.isEmpty) {
        parts.removeAt(i);
      } else {
        parts[i] = rest;
      }
      break;
    }

    String? city;
    String? country;
    if (parts.isNotEmpty && _countries.contains(parts.last.toLowerCase())) {
      country = parts.removeLast();
      if (parts.isNotEmpty) city = parts.removeLast();
    }

    final street = parts.isEmpty ? null : parts.join(', ');
    if (street == null && city == null && country == null && postalCode == null) {
      return null;
    }
    return AddressModel(
      street: street,
      city: city,
      country: country,
      postalCode: postalCode,
    );
  }
}
