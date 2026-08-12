import 'package:json_annotation/json_annotation.dart';

import '../vos/address_model.dart';

part 'create_card_request.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateCardRequest {
  final String? name;
  @JsonKey(name: 'company_id')
  final int? companyId;
  final String? position;
  final List<String>? phones;
  final List<String>? emails;
  final List<AddressModel>? addresses;
  final String? bio;
  @JsonKey(name: 'profile_image')
  final String? profileImage;
  @JsonKey(name: 'card_type')
  final String? cardType;

  CreateCardRequest({
    this.name,
    this.companyId,
    this.position,
    this.phones,
    this.emails,
    this.addresses,
    this.bio,
    this.profileImage,
    this.cardType,
  });

  factory CreateCardRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCardRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCardRequestToJson(this);
}
