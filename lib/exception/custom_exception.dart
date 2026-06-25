import '../data/vos/error_vo.dart';

class CustomException implements Exception {
  final ErrorVo errorVo;
  final int? statusCode;

  CustomException({
    required this.errorVo,
    this.statusCode,
  });

  @override
  String toString() {
    return "CustomException(statusCode: $statusCode, message: ${errorVo.message})";
  }
}