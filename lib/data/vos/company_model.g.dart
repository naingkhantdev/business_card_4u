// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompanyModel _$CompanyModelFromJson(Map<String, dynamic> json) => CompanyModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      industry: json['industry'] as String?,
      businessType: json['business_type'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String?,
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      createdBy: (json['created_by'] as num?)?.toInt(),
      socials: (json['socials'] as List<dynamic>?)
              ?.map(
                  (e) => CompanySocialModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CompanyModelToJson(CompanyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'industry': instance.industry,
      'business_type': instance.businessType,
      'description': instance.description,
      'address': instance.address,
      'website': instance.website,
      'phone': instance.phone,
      'email': instance.email,
      'created_by': instance.createdBy,
      'socials': instance.socials,
    };
