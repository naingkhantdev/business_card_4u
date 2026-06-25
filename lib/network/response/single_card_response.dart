import 'package:json_annotation/json_annotation.dart';
import '../../data/vos/business_card_model.dart';

part 'single_card_response.g.dart';

@JsonSerializable(explicitToJson: true)
class SingleCardResponse {
  final String? status;
  final String? message;
  final BusinessCardModel? data;

  SingleCardResponse({this.status, this.message, this.data});

  factory SingleCardResponse.fromJson(Map<String, dynamic> json) =>
      _$SingleCardResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SingleCardResponseToJson(this);
}
