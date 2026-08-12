import 'package:json_annotation/json_annotation.dart';

part 'address_model.g.dart';

/// Structured address matching the backend contract:
/// {street, city, state, postal_code, country}.
/// City and country are required by the API; state and postal code are
/// optional because not every country uses them.
@JsonSerializable()
class AddressModel {
  final String? street;
  final String? city;
  final String? state;
  @JsonKey(name: 'postal_code')
  final String? postalCode;
  final String? country;

  AddressModel({
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddressModelToJson(this);

  List<String> get _filledParts => [street, city, state, postalCode, country]
      .where((p) => p != null && p.trim().isNotEmpty)
      .map((p) => p!.trim())
      .toList();

  bool get isEmpty => _filledParts.isEmpty;

  /// One-line form for display and map queries, e.g.
  /// "123 Main St, Yangon, Yangon Region, 11181, Myanmar".
  String get displayText => _filledParts.join(', ');
}
