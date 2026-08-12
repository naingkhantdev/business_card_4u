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
    await _bcaApi.logout();
  }

  @override
  Future<UserModel?> getProfile() async {
    final data = await _bcaApi.getProfile();
    if (data is Map<String, dynamic> && data['user'] != null) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
    }
    return null;
  }

  @override
  Future<String?> deactivateAccount(String password) async {
    final response = await _bcaApi.deactivateAccount({"password": password});
    return response?.message;
  }

  // ================= COMPANIES =================
  @override
  Future<List<CompanyModel>?> getCompanies() async {
    final response = await _bcaApi.getCompanies();
    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => CompanyModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  @override
  Future<CompanyModel?> createCompany(Map<String, dynamic> data) async {
    final response = await _bcaApi.createCompany(data);
    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return CompanyModel.fromJson(Map<String, dynamic>.from(response['data']));
    }
    return null;
  }

  @override
  Future<CompanyModel?> getCompanyDetail(int id) async {
    final response = await _bcaApi.getCompanyDetail(id);
    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return CompanyModel.fromJson(Map<String, dynamic>.from(response['data']));
    }
    return null;
  }

  @override
  Future<CompanyModel?> updateCompany(int id, Map<String, dynamic> data) async {
    final response = await _bcaApi.updateCompany(id, data);
    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return CompanyModel.fromJson(Map<String, dynamic>.from(response['data']));
    }
    return null;
  }

  @override
  Future<String?> deleteCompany(int id) async {
    final response = await _bcaApi.deleteCompany(id);
    return response?.message;
  }

  // ================= BUSINESS CARDS =================
  @override
  Future<CardResponse?> getCards() async {
    return await _bcaApi.getCards();
  }

  // Dedicated for saved cards page: card_type=saved_card + created_by == current user
  @override
  Future<CardResponse?> getSavedCards() async {
    return await _bcaApi.myCards(cardType: 'saved_card');
  }

  @override
  Future<BusinessCardModel?> createCard(
    Map<String, dynamic> data, {
    XFile? imageFile,
  }) async {
    final formDataMap = Map<String, dynamic>.from(data);

    // Transform list fields for Laravel multipart array parsing.
    // See comment in bca_api.dart.
    _prepareListFieldsForMultipart(formDataMap);

    // Add image file if present
    if (imageFile != null) {
      formDataMap['profile_image'] = MultipartFile.fromBytes(
        await imageFile.readAsBytes(),
        filename: imageFile.name,
      );
    }

    final response = await _bcaApi.createCard(formDataMap);
    return response?.data;
  }

  @override
  Future<BusinessCardModel?> updateCard(
    int id,
    Map<String, dynamic> data, {
    XFile? imageFile,
  }) async {
    final formDataMap = Map<String, dynamic>.from(data);

    // Transform list fields for Laravel multipart array parsing.
    _prepareListFieldsForMultipart(formDataMap);

    // Required for Laravel to route POST as PUT for multipart (see bca_api.dart comments)
    formDataMap['_method'] = 'PUT';

    // Add image file if present
    if (imageFile != null) {
      formDataMap['profile_image'] = MultipartFile.fromBytes(
        await imageFile.readAsBytes(),
        filename: imageFile.name,
      );
    }

    final response = await _bcaApi.updateCard(id, formDataMap);
    return response?.data;
  }

  @override
  Future<String?> deleteCard(int id) async {
    final response = await _bcaApi.deleteCard(id);
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
    final response = await _bcaApi.searchCards(
        query, companyId, cardType, city, state, country);
    return response?.cards;
  }

  @override
  Future<BusinessCardModel?> scanQr(String qrData) async {
    final response = await _bcaApi.scanQr({"qr_code_data": qrData});
    return response?.data;
  }

  @override
  Future<BusinessCardModel?> addFriend(int cardId) async {
    final response = await _bcaApi.addFriend(cardId);
    return response?.data;
  }

  @override
  Future<List<BusinessCardModel>?> getFriendRequests() async {
    final response = await _bcaApi.getFriendRequests();
    return response?.cards;
  }

  @override
  Future<BusinessCardModel?> acceptFriendRequest(int cardId) async {
    final response = await _bcaApi.acceptFriendRequest(cardId);
    return response?.data;
  }

  @override
  Future<void> rejectFriendRequest(int cardId) async {
    await _bcaApi.rejectFriendRequest(cardId);
  }

  @override
  Future<void> removeFriend(int cardId) async {
    await _bcaApi.removeFriend(cardId);
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
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
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
