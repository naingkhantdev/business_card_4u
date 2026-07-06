// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_social_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompanySocialModel _$CompanySocialModelFromJson(Map<String, dynamic> json) =>
    CompanySocialModel(
      id: (json['id'] as num).toInt(),
      platform: json['platform'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$CompanySocialModelToJson(CompanySocialModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'platform': instance.platform,
      'url': instance.url,
    };
