// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'single_card_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SingleCardResponse _$SingleCardResponseFromJson(Map<String, dynamic> json) =>
    SingleCardResponse(
      status: json['status'] as String?,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : BusinessCardModel.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SingleCardResponseToJson(SingleCardResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'data': instance.data?.toJson(),
    };
