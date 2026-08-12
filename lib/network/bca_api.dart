import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';

import 'consts.dart';
import '../data/request/login_request.dart';
import 'response/login_response.dart';
import 'response/card_response.dart';
import 'response/add_response.dart';
import 'response/single_card_response.dart';

part 'bca_api.g.dart';

typedef ParseErrorLogger = dynamic;

@RestApi()
abstract class BcaApi {
  factory BcaApi(Dio dio, {String? baseUrl, dynamic errorLogger}) = _BcaApi;

  // ================= AUTH =================
  @POST(kEndPointLogin)
  Future<LoginResponse?> userLogin(
      @Body() LoginRequest body,
      );

  @POST(kEndPointSendOtp)
  Future<AddResponse?> sendOtp(
      @Body() Map<String, dynamic> body,
      );

  @POST(kEndPointVerifyOtp)
  Future<AddResponse?> verifyOtp(
      @Body() Map<String, dynamic> body,
      );

  @POST(kEndPointCompleteRegister)
  Future<LoginResponse?> completeRegister(
      @Body() Map<String, dynamic> body,
      );

  @POST(kEndPointLogout)
  Future<AddResponse?> logout();

  @POST(kEndPointMe)
  Future<Object?> getProfile();

  // NEW — was missing. Backend: POST /change-password (current_password, new_password, new_password_confirmation)
  @POST(kEndPointChangePassword)
  Future<AddResponse?> changePassword(
      @Body() Map<String, dynamic> body,
      );

  // NEW — was missing. Backend: POST /refresh-token, no body, returns only {"token": ...} (no status/message),
  // so it doesn't fit AddResponse/LoginResponse shapes — read json['token'] manually from the result.
  @POST(kEndPointRefreshToken)
  Future<Object?> refreshToken();

  @POST(kEndPointDeactivateAccount)
  Future<AddResponse?> deactivateAccount(
      @Body() Map<String, dynamic> body,
      );

  // NEW — was missing. Backend: POST /forgot-password (email)
  @POST(kEndPointForgotPassword)
  Future<AddResponse?> forgotPassword(
      @Body() Map<String, dynamic> body,
      );

  // NEW — was missing. Backend: POST /reset-password (token, email, password, password_confirmation)
  @POST(kEndPointResetPassword)
  Future<AddResponse?> resetPassword(
      @Body() Map<String, dynamic> body,
      );

  // ================= COMPANIES =================
  @GET(kEndPointCompanies)
  Future<Object?> getCompanies();

  @POST(kEndPointCompanies)
  Future<Object?> createCompany(
      @Body() Map<String, dynamic> body,
      );

  @GET("$kEndPointCompanies/{id}")
  Future<Object?> getCompanyDetail(
      @Path("id") int id,
      );

  @PUT("$kEndPointCompanies/{id}")
  Future<Object?> updateCompany(
      @Path("id") int id,
      @Body() Map<String, dynamic> body,
      );

  @DELETE("$kEndPointCompanies/{id}")
  Future<AddResponse?> deleteCompany(
      @Path("id") int id,
      );

  // ================= BUSINESS CARDS =================
  @GET(kEndPointBusinessCards)
  Future<CardResponse?> getCards();

  // GET /my-business-cards?card_type=saved_card for saved cards of current user
  @GET(kEndPointMyBusinessCards)
  Future<CardResponse?> myCards({
    @Query("card_type") String? cardType,
  });

  // NOTE on phones/emails/addresses/social_links: Laravel only treats repeated multipart
  // field names as an array if the key itself ends in []. When you build the `body` map for
  // this call, use keys like 'phones[]', 'emails[]' with List<String> values
  // (or 'phones[0]', 'phones[1]', ... ), not a bare 'phones' key, or the backend will only
  // see the last value and fail the `array` validation rule.
  // Addresses are structured objects and must be flattened to
  // 'addresses[0][street]', 'addresses[0][city]', ... keys
  // (see _prepareListFieldsForMultipart in bca_data_agent_impl.dart).
  @MultiPart()
  @POST(kEndPointBusinessCards)
  Future<SingleCardResponse?> createCard(
      @Part() Map<String, dynamic> body,
      );

  // CHANGED from @PUT to @POST. PHP does not populate the request body/$_FILES for a
  // multipart payload on a PUT request — this is a PHP-level limitation, not a Laravel bug.
  // Sending this as PUT will arrive at the controller with an effectively empty body even for
  // plain text fields, let alone the file. The fix is Laravel's method-override convention:
  // we send a real POST to the same URL and include '_method': 'PUT' in the body map, and
  // Laravel reads that and routes it to the existing `Route::put(...)` handler — no backend
  // route changes needed. Make sure every call site adds '_method': 'PUT' to the map it passes in.
  @MultiPart()
  @POST("$kEndPointBusinessCards/{id}")
  Future<SingleCardResponse?> updateCard(
      @Path("id") int id,
      @Part() Map<String, dynamic> body, // must include body['_method'] = 'PUT'
      );

  @DELETE("$kEndPointBusinessCards/{id}")
  Future<AddResponse?> deleteCard(
      @Path("id") int id,
      );

  // CHANGED return type: the backend wraps results as {status, message, data: [...]}, not a
  // bare JSON array, so this needs the same envelope type as getCards/myCards.
  @GET("$kEndPointBusinessCards/search")
  Future<CardResponse?> searchCards(
      @Query("query") String query,
      @Query("company_id") int? companyId,
      @Query("card_type") String? cardType,
      @Query("city") String? city,
      @Query("state") String? state,
      @Query("country") String? country,
      );

  // CHANGED return type: backend wraps the single card as {status, message, data: {...}}.
  @POST("$kEndPointBusinessCards/scan-qr")
  Future<SingleCardResponse?> scanQr(
      @Body() Map<String, dynamic> body,
      );

  // CHANGED return type: backend wraps the single card as {status, message, data: {...}}.
  @POST("$kEndPointBusinessCards/{id}/add-friend")
  Future<SingleCardResponse?> addFriend(
      @Path("id") int id,
      );

  // CHANGED return type: backend wraps the list as {status, message, data: [...]}.
  @GET("$kEndPointBusinessCards/friend-requests")
  Future<CardResponse?> getFriendRequests();

  // CHANGED return type: backend wraps the single card as {status, message, data: {...}}.
  @POST("$kEndPointBusinessCards/{id}/accept-friend")
  Future<SingleCardResponse?> acceptFriendRequest(
      @Path("id") int id,
      );

  // Unchanged — backend returns plain {status, message} with no data, so AddResponse is correct.
  @POST("$kEndPointBusinessCards/{id}/reject-friend")
  Future<AddResponse?> rejectFriendRequest(
      @Path("id") int id,
      );

  // Unchanged — backend returns plain {status, message} with no data, so AddResponse is correct.
  @POST("$kEndPointBusinessCards/{id}/unfriend")
  Future<AddResponse?> removeFriend(
      @Path("id") int id,
      );
}