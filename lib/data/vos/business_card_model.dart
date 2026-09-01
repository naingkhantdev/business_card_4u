import 'package:json_annotation/json_annotation.dart';
import 'address_model.dart';
import 'company_model.dart';
import 'user_model.dart';

part 'business_card_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BusinessCardModel {
  final int id;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String position;
  final List<String> phones;
  final List<String> emails;
  final List<AddressModel> addresses;
  final String? bio;
  @JsonKey(name: 'profile_image')
  final String? profileImage;

  /// Photos of the physical card, stored on the server as paths under /storage.
  @JsonKey(name: 'front_image')
  final String? frontImage;
  @JsonKey(name: 'back_image')
  final String? backImage;
  final CompanyModel? company;
  final UserModel? user;
  @JsonKey(name: 'created_by')
  final int? createdBy;
  @JsonKey(name: 'updated_by')
  final int? updatedBy;
  @JsonKey(name: 'deleted_by')
  final int? deletedBy;
  @JsonKey(name: 'card_type')
  final String cardType;
  @JsonKey(name: 'qr_code_data')
  final String? qrCodeData;
  @JsonKey(name: 'social_links')
  final List<dynamic>? socialLinks;
  @JsonKey(name: 'is_friend')
  final bool isFriend;
  @JsonKey(name: 'friend_status')
  final String friendStatus;
  @JsonKey(name: 'friend_request_status')
  final String? friendRequestStatus;
  final String? tag;
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? createdAt;

  BusinessCardModel({
    required this.id,
    required this.fullName,
    required this.position,
    required this.phones,
    required this.emails,
    required this.addresses,
    this.bio,
    this.profileImage,
    this.frontImage,
    this.backImage,
    this.company,
    this.user,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.cardType = 'user_card',
    this.qrCodeData,
    this.socialLinks,
    this.isFriend = false,
    this.friendStatus = 'none',
    this.friendRequestStatus = 'none',
    this.tag,
    this.createdAt,
  });

  factory BusinessCardModel.fromJson(Map<String, dynamic> json) {
    // Sanitize data to prevent cast errors from backend nulls on required fields
    final safe = Map<String, dynamic>.from(json);
    safe['id'] ??= 0;
    safe['full_name'] ??= '';
    safe['position'] ??= '';
    safe['phones'] ??= <String>[];
    safe['emails'] ??= <String>[];
    // Addresses are structured objects; fold legacy free-text entries
    // (pre-migration data) into the street field.
    final rawAddresses = safe['addresses'];
    safe['addresses'] = rawAddresses is List
        ? rawAddresses
            .map((a) => a is String ? {'street': a} : a)
            .whereType<Map<String, dynamic>>()
            .toList()
        : <Map<String, dynamic>>[];

    // Handle the complex createdAt logic first
    DateTime? createdAt;
    if (safe['request_created_at_myanmar'] != null) {
      createdAt = DateTime.tryParse(safe['request_created_at_myanmar'].toString());
    } else if (safe['request_created_at'] != null) {
      createdAt = DateTime.tryParse(safe['request_created_at'].toString());
    } else if (safe['created_at'] != null) {
      createdAt = DateTime.tryParse(safe['created_at'].toString());
    }

    // Now let json_serializable handle the rest, but override createdAt
    final model = _$BusinessCardModelFromJson(safe);
    return BusinessCardModel(
      id: model.id,
      fullName: model.fullName,
      position: model.position,
      phones: model.phones,
      emails: model.emails,
      addresses: model.addresses,
      bio: model.bio,
      profileImage: model.profileImage,
      frontImage: model.frontImage,
      backImage: model.backImage,
      company: model.company,
      user: model.user,
      createdBy: model.createdBy,
      updatedBy: model.updatedBy,
      deletedBy: model.deletedBy,
      cardType: model.cardType,
      qrCodeData: model.qrCodeData,
      socialLinks: model.socialLinks,
      isFriend: model.isFriend,
      friendStatus: model.friendStatus,
      friendRequestStatus: model.friendRequestStatus,
      tag: model.tag,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => _$BusinessCardModelToJson(this);

  factory BusinessCardModel.empty() {
    return BusinessCardModel(
      id: 0,
      fullName: '',
      position: '',
      phones: [],
      emails: [],
      addresses: [],
    );
  }

  // Helper functions for DateTime
  static DateTime? _dateTimeFromJson(dynamic json) {
    if (json == null) return null;
    return DateTime.tryParse(json.toString());
  }

  static dynamic _dateTimeToJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}