import 'package:json_annotation/json_annotation.dart';

part 'add_response.g.dart';

@JsonSerializable()
class AddResponse {
  final String? message;

  AddResponse({this.message});

  factory AddResponse.fromJson(Map<String, dynamic> json) =>
      _$AddResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AddResponseToJson(this);
}
