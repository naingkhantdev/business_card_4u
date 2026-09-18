import 'package:json_annotation/json_annotation.dart';
import 'company_social_model.dart';

part 'company_model.g.dart';

@JsonSerializable()
class CompanyModel {
  final int id;
  final String name;
  final String? industry;
  @JsonKey(name: 'business_type')
  final String? businessType;
  final String? description;
  final String? address;
  final String? website;
  final String? phone;
  final String? email;
  @JsonKey(name: 'created_by')
  final int? createdBy;
  final List<CompanySocialModel> socials;

  CompanyModel({
    required this.id,
    required this.name,
    this.industry,
    this.businessType,
    this.description,
    this.address,
    this.website,
    this.phone,
    this.email,
    this.createdBy,
    this.socials = const [],
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    final raw = json['socials'];
    final parsedSocials = (raw is List)
        ? raw
            .whereType<Map<String, dynamic>>()
            .map((e) => CompanySocialModel.fromJson(e))
            .toList()
        : <CompanySocialModel>[];

    return CompanyModel(
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
      socials: parsedSocials,
    );
  }

  Map<String, dynamic> toJson() => _$CompanyModelToJson(this);
}

/// One page of the companies list, as returned by `GET /companies`.
///
/// Hand-written rather than `@JsonSerializable()`: the API nests paging info
/// under `meta` while `data` stays a plain list, so there is no single object
/// shape to generate a codec for — plucking the two fields here is simpler.
class CompanyPage {
  final List<CompanyModel> companies;
  final bool hasMore;

  const CompanyPage({required this.companies, required this.hasMore});

  factory CompanyPage.fromResponse(dynamic response) {
    if (response is! Map<String, dynamic> || response['data'] is! List) {
      return const CompanyPage(companies: [], hasMore: false);
    }

    final companies = (response['data'] as List)
        .whereType<Map>()
        .map((item) => CompanyModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    final meta = response['meta'];
    final hasMore = meta is Map && meta['has_more'] == true;

    return CompanyPage(companies: companies, hasMore: hasMore);
  }
}