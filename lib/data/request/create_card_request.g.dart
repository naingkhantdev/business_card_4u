// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_card_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCardRequest _$CreateCardRequestFromJson(Map<String, dynamic> json) =>
    CreateCardRequest(
      name: json['name'] as String?,
      companyId: (json['company_id'] as num?)?.toInt(),
      position: json['position'] as String?,
      phones:
          (json['phones'] as List<dynamic>?)?.map((e) => e as String).toList(),
      emails:
          (json['emails'] as List<dynamic>?)?.map((e) => e as String).toList(),
      addresses: (json['addresses'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      bio: json['bio'] as String?,
      profileImage: json['profile_image'] as String?,
      cardType: json['card_type'] as String?,
    );

Map<String, dynamic> _$CreateCardRequestToJson(CreateCardRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'company_id': instance.companyId,
      'position': instance.position,
      'phones': instance.phones,
      'emails': instance.emails,
      'addresses': instance.addresses,
      'bio': instance.bio,
      'profile_image': instance.profileImage,
      'card_type': instance.cardType,
    };
