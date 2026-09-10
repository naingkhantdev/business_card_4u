// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusinessCardModel _$BusinessCardModelFromJson(Map<String, dynamic> json) =>
    BusinessCardModel(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name'] as String,
      position: json['position'] as String,
      phones:
          (json['phones'] as List<dynamic>).map((e) => e as String).toList(),
      emails:
          (json['emails'] as List<dynamic>).map((e) => e as String).toList(),
      addresses: (json['addresses'] as List<dynamic>)
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      bio: json['bio'] as String?,
      profileImage: json['profile_image'] as String?,
      frontImage: json['front_image'] as String?,
      backImage: json['back_image'] as String?,
      company: json['company'] == null
          ? null
          : CompanyModel.fromJson(json['company'] as Map<String, dynamic>),
      user: json['user'] == null
          ? null
          : UserModel.fromJson(json['user'] as Map<String, dynamic>),
      createdBy: (json['created_by'] as num?)?.toInt(),
      updatedBy: (json['updated_by'] as num?)?.toInt(),
      deletedBy: (json['deleted_by'] as num?)?.toInt(),
      cardType: json['card_type'] as String? ?? 'user_card',
      qrCodeData: json['qr_code_data'] as String?,
      socialLinks: json['social_links'] as List<dynamic>?,
      isFriend: json['is_friend'] as bool? ?? false,
      friendStatus: json['friend_status'] as String? ?? 'none',
      friendRequestStatus: json['friend_request_status'] as String? ?? 'none',
      tag: json['tag'] as String?,
      createdAt: BusinessCardModel._dateTimeFromJson(json['created_at']),
    );

Map<String, dynamic> _$BusinessCardModelToJson(BusinessCardModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'position': instance.position,
      'phones': instance.phones,
      'emails': instance.emails,
      'addresses': instance.addresses.map((e) => e.toJson()).toList(),
      'bio': instance.bio,
      'profile_image': instance.profileImage,
      'front_image': instance.frontImage,
      'back_image': instance.backImage,
      'company': instance.company?.toJson(),
      'user': instance.user?.toJson(),
      'created_by': instance.createdBy,
      'updated_by': instance.updatedBy,
      'deleted_by': instance.deletedBy,
      'card_type': instance.cardType,
      'qr_code_data': instance.qrCodeData,
      'social_links': instance.socialLinks,
      'is_friend': instance.isFriend,
      'friend_status': instance.friendStatus,
      'friend_request_status': instance.friendRequestStatus,
      'tag': instance.tag,
      'created_at': BusinessCardModel._dateTimeToJson(instance.createdAt),
    };
