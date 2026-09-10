import 'package:image_picker/image_picker.dart';
import '../../data/vos/business_card_model.dart';
import '../../data/vos/company_model.dart';
import '../../data/vos/user_model.dart';
import '../../data/request/login_request.dart';
import '../response/login_response.dart';
import '../response/card_response.dart';

abstract class BcaDataAgent {
  // ================= AUTH =================
  Future<LoginResponse?> login(LoginRequest request);

  Future<String?> sendOtp(String email);

  Future<String?> verifyOtp(String email, String otp);

  Future<LoginResponse?> completeRegister(
    String email,
    String name,
    String password,
    String confirmPassword,
  );

  Future<void> logout();

  Future<UserModel?> getProfile();

  Future<String?> deactivateAccount(String password);

  // ================= COMPANIES =================
  Future<List<CompanyModel>?> getCompanies();

  Future<CompanyModel?> createCompany(Map<String, dynamic> data);

  Future<CompanyModel?> getCompanyDetail(int id);

  Future<CompanyModel?> updateCompany(int id, Map<String, dynamic> data);

  Future<String?> deleteCompany(int id);

  // ================= BUSINESS CARDS =================
  Future<CardResponse?> getCards();

  Future<CardResponse?> getSavedCards();

  Future<BusinessCardModel?> createCard(
    Map<String, dynamic> data, {
    XFile? imageFile,
    XFile? frontImageFile,
    XFile? backImageFile,
  });

  Future<BusinessCardModel?> updateCard(
    int id,
    Map<String, dynamic> data, {
    XFile? imageFile,
    XFile? frontImageFile,
    XFile? backImageFile,
  });

  Future<String?> deleteCard(int id);

  Future<List<BusinessCardModel>?> searchCards(
    String query, {
    int? companyId,
    String cardType = 'user_card',
    String? city,
    String? state,
    String? country,
  });

  Future<BusinessCardModel?> scanQr(String qrData);

  Future<BusinessCardModel?> addFriend(int cardId);

  Future<List<BusinessCardModel>?> getFriendRequests();

  Future<BusinessCardModel?> acceptFriendRequest(int cardId);

  Future<void> rejectFriendRequest(int cardId);

  Future<void> removeFriend(int cardId);
}
