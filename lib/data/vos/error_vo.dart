import 'package:json_annotation/json_annotation.dart';

part 'error_vo.g.dart';

@JsonSerializable()
class ErrorVo {
  final String message;

  ErrorVo({
    required this.message,
  });

  factory ErrorVo.fromJson(Map<String, dynamic> json) =>
      _$ErrorVoFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorVoToJson(this);
}
