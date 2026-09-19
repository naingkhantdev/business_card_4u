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

  /// Existing stored paths, echoed back on edit so the server keeps the photo
  /// when no new file is attached. New photos travel as multipart files.
  @JsonKey(name: 'front_image')
  final String? frontImage;
  @JsonKey(name: 'back_image')
  final String? backImage;
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
    this.frontImage,
    this.backImage,
    this.cardType,
  });

  factory CreateCardRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCardRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCardRequestToJson(this);
}
