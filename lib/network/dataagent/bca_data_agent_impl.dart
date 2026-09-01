import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'bca_data_agent.dart';
import '../bca_api.dart';
import '../dio_client.dart';
import '../../data/vos/business_card_model.dart';
import '../../data/vos/company_model.dart';
import '../../data/vos/error_vo.dart';
import '../../data/vos/user_model.dart';
import '../../data/request/login_request.dart';
import '../../exception/custom_exception.dart';
import '../response/login_response.dart';
import '../response/card_response.dart';

class BcaDataAgentImpl implements BcaDataAgent {
  static final BcaDataAgentImpl _singleton = BcaDataAgentImpl._internal();

  factory BcaDataAgentImpl() {
    return _singleton;
  }

  BcaDataAgentImpl._internal();

  final BcaApi _bcaApi = BcaApi(DioClient.create());

  // ================= AUTH =================
  @override
  Future<LoginResponse?> login(LoginRequest request) async {
    return _guard(() => _bcaApi.userLogin(request));
  }

  @override
  Future<String?> sendOtp(String email) async {
    final response = await _guard(() => _bcaApi.sendOtp({"email": email}));
    return response?.message;
  }

  @override
  Future<String?> verifyOtp(String email, String otp) async {
    final response =
        await _guard(() => _bcaApi.verifyOtp({"email": email, "otp": otp}));
    return response?.message;
  }

  @override
  Future<LoginResponse?> completeRegister(
    String email,
    String name,
    String password,
    String confirmPassword,
  ) async {
    return _guard(() => _bcaApi.completeRegister({
          "email": email,
          "name": name,
          "password": password,
          "password_confirmation": confirmPassword,
        }));
  }

  @override
  Future<void> logout() async {
    await _guard(() => _bcaApi.logout());
  }

  @override
  Future<UserModel?> getProfile() async {
    final data = await _guard(() => _bcaApi.getProfile());
    if (data is Map<String, dynamic> && data['user'] != null) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
    }
    return null;
  }

  @override
  Future<String?> deactivateAccount(String password) async {
    final response =
        await _guard(() => _bcaApi.deactivateAccount({"password": password}));
    return response?.message;
  }

  // ================= COMPANIES =================
  @override
  Future<List<CompanyModel>?> getCompanies() async {
    final response = await _guard(() => _bcaApi.getCompanies());
    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => CompanyModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  @override
  Future<CompanyModel?> createCompany(Map<String, dynamic> data) async {
    final response = await _guard(() => _bcaApi.createCompany(data));
    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return CompanyModel.fromJson(Map<String, dynamic>.from(response['data']));
    }
    return null;
  }

  @override
  Future<CompanyModel?> getCompanyDetail(int id) async {
    final response = await _guard(() => _bcaApi.getCompanyDetail(id));
    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return CompanyModel.fromJson(Map<String, dynamic>.from(response['data']));
    }
    return null;
  }

  @override
  Future<CompanyModel?> updateCompany(int id, Map<String, dynamic> data) async {
    final response = await _guard(() => _bcaApi.updateCompany(id, data));
    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return CompanyModel.fromJson(Map<String, dynamic>.from(response['data']));
    }
    return null;
  }

  @override
  Future<String?> deleteCompany(int id) async {
    final response = await _guard(() => _bcaApi.deleteCompany(id));
    return response?.message;
  }

  // ================= BUSINESS CARDS =================
  @override
  Future<CardResponse?> getCards() async {
    return await _guard(() => _bcaApi.getCards());
  }

  // Dedicated for saved cards page: card_type=saved_card + created_by == current user
  @override
  Future<CardResponse?> getSavedCards() async {
    return await _guard(() => _bcaApi.myCards(cardType: 'saved_card'));
  }

  @override
  Future<BusinessCardModel?> createCard(
    Map<String, dynamic> data, {
    XFile? imageFile,
    XFile? frontImageFile,
    XFile? backImageFile,
  }) async {
    final formDataMap = Map<String, dynamic>.from(data);

    // Transform list fields for Laravel multipart array parsing.
    // See comment in bca_api.dart.
    _prepareListFieldsForMultipart(formDataMap);

    // Add image files if present
    await _attachImage(formDataMap, 'profile_image', imageFile);
    await _attachImage(formDataMap, 'front_image', frontImageFile);
    await _attachImage(formDataMap, 'back_image', backImageFile);

    final response = await _guard(() => _bcaApi.createCard(formDataMap));
    return response?.data;
  }

  @override
  Future<BusinessCardModel?> updateCard(
    int id,
    Map<String, dynamic> data, {
    XFile? imageFile,
    XFile? frontImageFile,
    XFile? backImageFile,
  }) async {
    final formDataMap = Map<String, dynamic>.from(data);

    // Transform list fields for Laravel multipart array parsing.
    _prepareListFieldsForMultipart(formDataMap);

    // Required for Laravel to route POST as PUT for multipart (see bca_api.dart comments)
    formDataMap['_method'] = 'PUT';

    // Add image files if present
    await _attachImage(formDataMap, 'profile_image', imageFile);
    await _attachImage(formDataMap, 'front_image', frontImageFile);
    await _attachImage(formDataMap, 'back_image', backImageFile);

    final response = await _guard(() => _bcaApi.updateCard(id, formDataMap));
    return response?.data;
  }

  @override
  Future<String?> deleteCard(int id) async {
    final response = await _guard(() => _bcaApi.deleteCard(id));
    return response?.message;
  }

  @override
  Future<List<BusinessCardModel>?> searchCards(
    String query, {
    int? companyId,
    String cardType = 'user_card',
    String? city,
    String? state,
    String? country,
  }) async {
    final response = await _guard(() => _bcaApi.searchCards(
        query, companyId, cardType, city, state, country));
    return response?.cards;
  }

  @override
  Future<BusinessCardModel?> scanQr(String qrData) async {
    final response =
        await _guard(() => _bcaApi.scanQr({"qr_code_data": qrData}));
    return response?.data;
  }

  @override
  Future<BusinessCardModel?> addFriend(int cardId) async {
    final response = await _guard(() => _bcaApi.addFriend(cardId));
    return response?.data;
  }

  @override
  Future<List<BusinessCardModel>?> getFriendRequests() async {
    final response = await _guard(() => _bcaApi.getFriendRequests());
    return response?.cards;
  }

  @override
  Future<BusinessCardModel?> acceptFriendRequest(int cardId) async {
    final response = await _guard(() => _bcaApi.acceptFriendRequest(cardId));
    return response?.data;
  }

  @override
  Future<void> rejectFriendRequest(int cardId) async {
    await _guard(() => _bcaApi.rejectFriendRequest(cardId));
  }

  @override
  Future<void> removeFriend(int cardId) async {
    await _guard(() => _bcaApi.removeFriend(cardId));
  }

  /// Maps DioException into the app's CustomException carrying the API's
  /// `message` so providers and UI never see raw Dio errors.
  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw CustomException(
        statusCode: e.response?.statusCode,
        errorVo: ErrorVo(message: _messageFromDioError(e)),
      );
    }
  }

  String _messageFromDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      // 422: prefer the per-field `errors` map. Laravel's top-level `message`
      // reads like "The phones.0 field must be at least 6 characters.
      // (and 3 more errors)", which is not something a user should ever see.
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final lines = <String>[];
        errors.forEach((field, messages) {
          if (lines.length >= _maxValidationLines) return;
          final raw = (messages is List && messages.isNotEmpty)
              ? messages.first?.toString()
              : messages?.toString();
          if (raw == null || raw.trim().isEmpty) return;
          lines.add(_humanizeValidationMessage(field.toString(), raw));
        });

        if (lines.isNotEmpty) {
          final remaining = errors.length - lines.length;
          if (remaining > 0) {
            lines.add(remaining == 1
                ? 'And 1 more item needs fixing.'
                : 'And $remaining more items need fixing.');
          }
          return lines.join('\n');
        }
      }

      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        final cleaned = message.trim();
        // Never surface a stack trace, SQL error or exception class name.
        // These leak through whenever the API runs with APP_DEBUG=true.
        if (!_looksTechnical(cleaned)) {
          return cleaned;
        }
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server is taking too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Please check your internet connection.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      default:
        break;
    }

    switch (status) {
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You do not have permission to do that.';
      case 404:
        return 'We could not find what you were looking for.';
      case 409:
        return 'That item has already been changed. Please refresh and retry.';
      case 413:
        return 'That file is too large. Please choose a smaller image.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        if (status != null && status >= 500) {
          return 'Something went wrong on our end. Please try again shortly.';
        }
        return 'Something went wrong. Please try again.';
    }
  }

  /// How many field errors to list before collapsing the rest into a count.
  static const int _maxValidationLines = 3;

  /// Rewrites a Laravel validation message so it names the field the way the
  /// form labels it: "The addresses.0.city field is required." becomes
  /// "Address 1 city is required."
  String _humanizeValidationMessage(String field, String rawMessage) {
    final label = _humanizeFieldName(field);
    var message = rawMessage.trim();

    message = message
        .replaceAll('The $field field', label)
        .replaceAll('The $field', label)
        .replaceAll(field, label);

    if (message.isEmpty) return '$label is invalid.';
    if (!message.endsWith('.')) message = '$message.';
    return message[0].toUpperCase() + message.substring(1);
  }

  /// Turns an API field path into a form label.
  /// `phones.0` -> `Phone 1`, `addresses.0.postal_code` -> `Address 1 postal code`.
  String _humanizeFieldName(String field) {
    const overrides = <String, String>{
      'company_id': 'Company',
      'card_type': 'Card type',
      'qr_code_data': 'QR code',
      'profile_image': 'Profile image',
      'social_links': 'Social links',
      'business_type': 'Business type',
      'current_password': 'Current password',
      'new_password': 'New password',
      'password_confirmation': 'Password confirmation',
      'firebase_token': 'Notification token',
    };

    const singulars = <String, String>{
      'phones': 'Phone',
      'emails': 'Email',
      'addresses': 'Address',
      'socials': 'Social link',
      'social_links': 'Social link',
    };

    final parts = field.split('.');
    final buffer = <String>[];

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      final index = int.tryParse(part);

      // A numeric segment is a list position: show it as a 1-based number
      // attached to the noun before it, e.g. "Phone 1".
      if (index != null) {
        buffer.add('${index + 1}');
        continue;
      }

      final isFirst = buffer.isEmpty;
      final nextIsIndex =
          i + 1 < parts.length && int.tryParse(parts[i + 1]) != null;

      String word;
      if (nextIsIndex && singulars.containsKey(part)) {
        word = singulars[part]!;
      } else if (overrides.containsKey(part)) {
        word = overrides[part]!;
      } else {
        word = part.replaceAll('_', ' ');
      }

      buffer.add(isFirst ? word : word.toLowerCase());
    }

    final label = buffer.join(' ').trim();
    if (label.isEmpty) return 'This field';
    return label[0].toUpperCase() + label.substring(1);
  }

  /// True when a server message is a developer-facing dump rather than
  /// something a user can act on.
  bool _looksTechnical(String message) {
    const markers = [
      'SQLSTATE',
      'Exception',
      'Stack trace',
      'vendor\\laravel',
      'vendor/laravel',
      'Illuminate\\',
      'PDOException',
      'syntax error',
      '.php',
      'Call to ',
      'Undefined ',
    ];
    return markers.any((marker) => message.contains(marker));
  }

  /// Attaches a picked photo as a multipart file, replacing any stored path
  /// the form sent for the same field.
  Future<void> _attachImage(
    Map<String, dynamic> map,
    String field,
    XFile? file,
  ) async {
    if (file == null) return;
    map[field] = MultipartFile.fromBytes(
      await file.readAsBytes(),
      filename: file.name,
    );
  }

  /// Prepares list fields (phones, emails, etc) using 'key[]' naming so that
  /// Laravel's multipart form parser correctly receives them as arrays.
  void _prepareListFieldsForMultipart(Map<String, dynamic> map) {
    const listKeys = ['phones', 'emails', 'addresses', 'social_links'];
    for (final key in listKeys) {
      final value = map[key];
      if (value is! List) continue;
      map.remove(key);
      if (value.isEmpty) continue;

      if (value.first is Map) {
        // Structured entries (addresses): flatten to key[i][field] so Laravel
        // parses them as an array of objects. Null fields are omitted.
        for (var i = 0; i < value.length; i++) {
          final item = value[i] as Map;
          item.forEach((field, fieldValue) {
            if (fieldValue != null) {
              map['$key[$i][$field]'] = fieldValue;
            }
          });
        }
      } else {
        map['$key[]'] = value;
      }
    }
  }
}
