import 'package:json_annotation/json_annotation.dart';
import '../../data/vos/business_card_model.dart';

part 'card_response.g.dart';

@JsonSerializable(explicitToJson: true)
class CardResponse {
  final List<BusinessCardModel>? cards;

  CardResponse({this.cards});

  factory CardResponse.fromJson(dynamic json) {
    List data;

    if (json is List) {
      data = json;
    } else if (json is Map<String, dynamic> && json['data'] != null) {
      data = json['data'] as List;
    } else {
      data = [];
    }

    return CardResponse(
      cards: data
          .map((e) => BusinessCardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => _$CardResponseToJson(this);
}
