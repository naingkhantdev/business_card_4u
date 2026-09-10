/// Heuristic parser that turns the raw text lines OCR pulled off a business
/// card into the fields the add-card form expects.
///
/// There is no layout standard for business cards, so every rule here is a
/// guess ranked by how often it holds. The UI must therefore treat every
/// result as a draft the user can correct, never as final data.
class BusinessCardParser {
  const BusinessCardParser._();

  /// Company suffixes, longest first so `Co., Ltd` wins over a bare `Ltd`.
  static const _companyMarkers = <String>[
    'co., ltd',
    'co.,ltd',
    'co ltd',
    'company limited',
    'limited',
    'corporation',
    'incorporated',
    'holdings',
    'group',
    'company',
    'pte',
    'llc',
    'plc',
    'inc',
    'ltd',
    'gmbh',
  ];

  static const _positionMarkers = <String>[
    'chief executive',
    'chief technology',
    'chief financial',
    'chief operating',
    'vice president',
    'president',
    'managing director',
    'director',
    'manager',
    'engineer',
    'developer',
    'designer',
    'consultant',
    'specialist',
    'executive',
    'supervisor',
    'assistant',
    'accountant',
    'architect',
    'analyst',
    'officer',
    'founder',
    'owner',
    'partner',
    'lecturer',
    'teacher',
    'doctor',
    'lawyer',
    'sales',
    'marketing',
    'ceo',
    'cto',
    'cfo',
    'coo',
    'hr',
  ];

  /// Words that mark a line as part of a postal address rather than a name.
  static const _addressMarkers = <String>[
    'street',
    'road',
    'avenue',
    'lane',
    'building',
    'tower',
    'floor',
    'block',
    'township',
    'district',
    'city',
    'region',
    'state',
    'province',
    'suite',
    'unit',
    'no',
    'st',
    'rd',
    'ave',
    'blk',
  ];

  /// Labels OCR picks up alongside the value ("Tel: 09..."). Stripping them
  /// keeps the value clean and stops them being mistaken for a name.
  static const _fieldLabels = <String>[
    'tel',
    'telephone',
    'phone',
    'mobile',
    'ph',
    'hp',
    'fax',
    'email',
    'e-mail',
    'mail',
    'web',
    'website',
    'address',
    'add',
    'addr',
  ];

  static final _emailPattern =
      RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}');

  static final _websitePattern = RegExp(
    r'(?:https?://|www\.)[^\s,;]+|\b[A-Za-z0-9\-]+\.(?:com|net|org|io|co|mm|dev|app|biz|info)(?:\.[a-z]{2})?\b',
    caseSensitive: false,
  );

  /// A run of digits and phone punctuation. Filtered further by digit count,
  /// since dates and postal codes match this shape too.
  static final _phonePattern = RegExp(r'\+?\d[\d\s\-().]{5,}\d');

  static final _labelPattern =
      RegExp(r'^\s*([A-Za-z.\-]{1,12})\s*[:\-–]\s*(.+)$');

  /// Parses [lines] from the front of a card, optionally merged with [backLines].
  ///
  /// Back-side text only fills fields the front left empty, and contributes
  /// extra phones and emails. Fronts carry the identity; backs are usually a
  /// logo, a map or a second language.
  static ParsedCardData parse(
    List<String> lines, {
    List<String> backLines = const [],
  }) {
    final front = _clean(lines);
    final back = _clean(backLines);

    final frontResult = _parseSide(front);
    if (back.isEmpty) return frontResult;

    return frontResult.mergedWith(_parseSide(back));
  }

  static ParsedCardData _parseSide(List<String> lines) {
    // Lines are claimed as they are identified, so a later, weaker rule cannot
    // reuse a line a stronger rule already consumed.
    final claimed = <int>{};

    final emails = <String>[];
    final phones = <String>[];
    final websites = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      final lineEmails =
          _emailPattern.allMatches(line).map((m) => m.group(0)!).toList();
      if (lineEmails.isNotEmpty) {
        _addAll(emails, lineEmails.map((e) => e.toLowerCase()));
        claimed.add(i);
      }

      // Strip emails before looking for sites, or the domain half of an
      // address is picked up as a website of its own.
      var remainder = line.replaceAll(_emailPattern, ' ');

      final lineSites = _websitePattern
          .allMatches(remainder)
          .map((m) => m.group(0)!)
          .toList();
      if (lineSites.isNotEmpty) {
        _addAll(websites, lineSites.map(_normalizeWebsite));
        claimed.add(i);
        remainder = remainder.replaceAll(_websitePattern, ' ');
      }

      final linePhones = _phonePattern
          .allMatches(remainder)
          .map((m) => _normalizePhone(m.group(0)!))
          .where(_isPlausiblePhone)
          .toList();
      if (linePhones.isNotEmpty) {
        _addAll(phones, linePhones);
        claimed.add(i);
      }
    }

    String? company;
    for (var i = 0; i < lines.length; i++) {
      if (claimed.contains(i)) continue;
      if (_hasMarker(lines[i], _companyMarkers)) {
        company = _stripLabel(lines[i]);
        claimed.add(i);
        break;
      }
    }

    String? position;
    for (var i = 0; i < lines.length; i++) {
      if (claimed.contains(i)) continue;
      if (_hasMarker(lines[i], _positionMarkers)) {
        position = _stripLabel(lines[i]);
        claimed.add(i);
        break;
      }
    }

    // The name is the first unclaimed line that reads like a person: a couple
    // of words, no digits, not an address fragment. Cards lead with the name
    // often enough that first-match beats any scoring scheme here.
    String? name;
    var nameIndex = -1;
    for (var i = 0; i < lines.length; i++) {
      if (claimed.contains(i)) continue;
      if (_looksLikeName(lines[i])) {
        name = _stripLabel(lines[i]);
        nameIndex = i;
        break;
      }
    }
    if (nameIndex != -1) claimed.add(nameIndex);

    // A company with no legal suffix is common. If an unclaimed line sits
    // after the name and is not address-like, take it as the company.
    if (company == null && nameIndex != -1) {
      for (var i = nameIndex + 1; i < lines.length; i++) {
        if (claimed.contains(i)) continue;
        if (_hasMarker(lines[i], _addressMarkers)) continue;
        company = _stripLabel(lines[i]);
        claimed.add(i);
        break;
      }
    }

    final addressLines = <String>[];
    for (var i = 0; i < lines.length; i++) {
      if (claimed.contains(i)) continue;
      addressLines.add(_stripLabel(lines[i]));
    }

    return ParsedCardData(
      name: name,
      position: position,
      company: company,
      phones: phones,
      emails: emails,
      websites: websites,
      addressLines: addressLines,
    );
  }

  static List<String> _clean(List<String> lines) {
    return lines
        .expand((line) => line.split('\n'))
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static void _addAll(List<String> target, Iterable<String> values) {
    for (final value in values) {
      if (value.isEmpty) continue;
      if (target.contains(value)) continue;
      target.add(value);
    }
  }

  static bool _hasMarker(String line, List<String> markers) {
    final lower = line.toLowerCase();
    for (final marker in markers) {
      // Short markers like `hr` or `inc` would hit inside ordinary words, so
      // they have to sit on a word boundary.
      final pattern = RegExp(
        '(^|[^a-z])${RegExp.escape(marker)}([^a-z]|\$)',
        caseSensitive: false,
      );
      if (pattern.hasMatch(lower)) return true;
    }
    return false;
  }

  /// Removes a leading `Tel:` / `Email -` style label from a line.
  static String _stripLabel(String line) {
    final match = _labelPattern.firstMatch(line);
    if (match != null) {
      final label = match.group(1)!.toLowerCase().replaceAll('.', '');
      if (_fieldLabels.contains(label)) {
        return match.group(2)!.trim();
      }
    }
    return line.trim();
  }

  static bool _looksLikeName(String line) {
    final candidate = _stripLabel(line);
    if (candidate.length < 3 || candidate.length > 40) return false;
    if (RegExp(r'\d').hasMatch(candidate)) return false;
    if (_hasMarker(candidate, _addressMarkers)) return false;

    final words = candidate.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty || words.length > 5) return false;

    // Reject lines that are mostly punctuation or symbols — OCR noise from
    // logos and borders reads that way.
    final letters = candidate.replaceAll(RegExp(r'[^A-Za-z]'), '');
    return letters.length >= candidate.length * 0.6;
  }

  static String _normalizePhone(String raw) {
    final trimmed = raw.trim();
    final leadingPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    return leadingPlus ? '+$digits' : digits;
  }

  /// The API rejects phones under 6 characters; anything past 15 digits is a
  /// run-together OCR artifact rather than a number.
  static bool _isPlausiblePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 6 && digits.length <= 15;
  }

  static String _normalizeWebsite(String raw) {
    return raw.trim().replaceAll(RegExp(r'[.,;]+$'), '').toLowerCase();
  }
}

/// One card's worth of fields recovered from OCR. Every field is optional — a
/// blurry capture may yield nothing but a phone number.
class ParsedCardData {
  final String? name;
  final String? position;
  final String? company;
  final List<String> phones;
  final List<String> emails;
  final List<String> websites;
  final List<String> addressLines;

  const ParsedCardData({
    this.name,
    this.position,
    this.company,
    this.phones = const [],
    this.emails = const [],
    this.websites = const [],
    this.addressLines = const [],
  });

  /// True when nothing usable came back, so the caller can tell the user the
  /// scan failed instead of silently opening an empty form.
  bool get isEmpty =>
      name == null &&
      position == null &&
      company == null &&
      phones.isEmpty &&
      emails.isEmpty &&
      websites.isEmpty &&
      addressLines.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Folds [other] in as a secondary source: single-value fields are taken only
  /// when this side had none; list fields are appended without repeats.
  ParsedCardData mergedWith(ParsedCardData other) {
    List<String> union(List<String> a, List<String> b) {
      final result = List<String>.from(a);
      for (final value in b) {
        if (!result.contains(value)) result.add(value);
      }
      return result;
    }

    return ParsedCardData(
      name: name ?? other.name,
      position: position ?? other.position,
      company: company ?? other.company,
      phones: union(phones, other.phones),
      emails: union(emails, other.emails),
      websites: union(websites, other.websites),
      addressLines: union(addressLines, other.addressLines),
    );
  }
}
