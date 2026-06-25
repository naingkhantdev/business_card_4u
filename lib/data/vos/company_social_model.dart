import 'package:json_annotation/json_annotation.dart';

part 'company_social_model.g.dart';

@JsonSerializable()
class CompanySocialModel {
  final int id;
  final String platform;
  final String url;

  CompanySocialModel({
    required this.id,
    required this.platform,
    required this.url,
  });

  factory CompanySocialModel.fromJson(Map<String, dynamic> json) =>
      _$CompanySocialModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompanySocialModelToJson(this);
}
