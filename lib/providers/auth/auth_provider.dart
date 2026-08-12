import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../network/dataagent/bca_data_agent.dart';
import '../../data/request/login_request.dart';
import '../../data/vos/user_model.dart';
import '../../exception/custom_exception.dart';
import '../../services/storage/token_storage.dart';
import '../../services/auth/auth_session.dart';
import '../../utils/app_result.dart';
import '../../fcm/push_notification_service.dart';
import '../data_agent_providers.dart';
import '../card/card_provider.dart';
import '../company/company_provider.dart';

// Auth State Model
class AuthState {
  final bool isLoggedIn;
  final UserModel? currentUser;
  final bool isCheckingSession;
  final String? pendingMessage;
  final bool isLoading;
  final String? lastErrorMessage;

  AuthState({
    this.isLoggedIn = false,
    this.currentUser,
    this.isCheckingSession = false,
    this.pendingMessage,
    this.isLoading = false,
    this.lastErrorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserModel? currentUser,
    bool? isCheckingSession,
    String? pendingMessage,
    bool? isLoading,
    String? lastErrorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentUser: currentUser ?? this.currentUser,
      isCheckingSession: isCheckingSession ?? this.isCheckingSession,
      pendingMessage: pendingMessage ?? this.pendingMessage,
      isLoading: isLoading ?? this.isLoading,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
    );
  }
}

// Auth Provider
final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthState> {
  late final BcaDataAgent _dataAgent;
  late final VoidCallback _unauthorizedListener;

  @override
  Future<AuthState> build() async {
    _dataAgent = ref.read(bcaDataAgentProvider);
    _unauthorizedListener = () async {
      if (state.value?.isLoggedIn == true || state.value?.currentUser != null) {
        await logout();
      }
    };
    AuthSession.unauthorizedTick.addListener(_unauthorizedListener);

    ref.onDispose(() {
      AuthSession.unauthorizedTick.removeListener(_unauthorizedListener);
    });

    return _checkLogin();
  }

  Future<AuthState> _checkLogin() async {
    state = const AsyncLoading();
    try {
      final token = await TokenStorage.read();
      if (token == null) {
        return AuthState(
          isLoggedIn: false,
          isCheckingSession: false,
        );
      }

      final user = await _dataAgent.getProfile();
      return AuthState(
        isLoggedIn: true,
        currentUser: user,
        isCheckingSession: false,
      );
    } catch (e) {
      await TokenStorage.clear();
      return AuthState(
        isLoggedIn: false,
        isCheckingSession: false,
      );
    }
  }

  Future<AppResult> login(String email, String password) async {
    // First, make sure state has data so we can copyWith
    final currentState = state.valueOrNull ?? AuthState();
    state = AsyncData(currentState.copyWith(isLoading: true));
    try {
      final firebaseToken = await PushNotificationService.getToken();
      final request = await _dataAgent.login(
        LoginRequest(
          email: email,
          password: password,
          firebaseToken: firebaseToken,
        ),
      );

      await TokenStorage.save(request!.token);
      final user = UserModel.fromJson(request.user);

      ref.invalidate(cardProvider);
      ref.invalidate(companyProvider);

      state = AsyncData(AuthState(
        isLoggedIn: true,
        currentUser: user,
        isLoading: false,
        pendingMessage: request.message,
        lastErrorMessage: null,
      ));

      return AppResult(true, request.message);
    } catch (e) {
      final message = _errorMessage(e, 'Login failed');
      state = AsyncData(AuthState(
        isLoggedIn: false,
        isLoading: false,
        pendingMessage: null,
        lastErrorMessage: message,
      ));
      return AppResult(false, message);
    }
  }

  String _errorMessage(Object error, String fallback) {
    if (error is CustomException) return error.errorVo.message;
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? fallback : message;
  }

  void cancelLoading() {
    final currentState = state.valueOrNull ?? AuthState();
    state = AsyncData(currentState.copyWith(isLoading: false));
  }

  Future<AppResult> sendOtp(String email) async {
    try {
      final message = await _dataAgent.sendOtp(email);
      return AppResult(true, message);
    } catch (e) {
      return AppResult(false, _errorMessage(e, 'Failed to send OTP'));
    }
  }

  Future<AppResult> verifyOtpOnly(String email, String otp) async {
    try {
      final message = await _dataAgent.verifyOtp(email, otp);
      return AppResult(true, message);
    } catch (e) {
      return AppResult(false, _errorMessage(e, 'OTP verification failed'));
    }
  }

  Future<AppResult> completeRegister(
    String email,
    String name,
    String password,
    String confirmPassword,
  ) async {
    state = const AsyncLoading();
    try {
      final res = await _dataAgent.completeRegister(
        email,
        name,
        password,
        confirmPassword,
      );

      await TokenStorage.save(res!.token);
      final user = UserModel.fromJson(res.user);

      ref.invalidate(cardProvider);
      ref.invalidate(companyProvider);

      state = AsyncData(AuthState(
        isLoggedIn: true,
        currentUser: user,
        pendingMessage: res.message,
      ));

      return AppResult(true, res.message);
    } catch (e) {
      // Reset loading state, otherwise the page spinner never clears.
      state = AsyncData(AuthState(isLoggedIn: false, isLoading: false));
      return AppResult(false, _errorMessage(e, 'Registration failed'));
    }
  }

  Future<void> logout() async {
    await _dataAgent.logout();
    await TokenStorage.clear();
    ref.invalidate(cardProvider);
    ref.invalidate(companyProvider);
    state = AsyncData(AuthState(
      isLoggedIn: false,
      currentUser: null,
      pendingMessage: 'Logged out successfully',
    ));
  }

  Future<AppResult> deactivateAccount(String password) async {
    try {
      final message = await _dataAgent.deactivateAccount(password);
      await TokenStorage.clear();
      ref.invalidate(cardProvider);
      ref.invalidate(companyProvider);
      state = AsyncData(AuthState(
        isLoggedIn: false,
        currentUser: null,
        pendingMessage: message,
      ));
      return AppResult(true, message);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      return AppResult(
          false, message.isEmpty ? 'Failed to deactivate account' : message);
    }
  }

  void clearPendingMessage() {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(pendingMessage: null));
    }
  }

  String? consumePendingMessage() {
    final message = state.value?.pendingMessage;
    if (message != null) {
      state = AsyncData(state.value!.copyWith(pendingMessage: null));
    }
    return message;
  }

  Future<void> completeDeactivatedLogout(String message) async {
    await TokenStorage.clear();
    ref.invalidate(cardProvider);
    ref.invalidate(companyProvider);
    state = AsyncData(AuthState(
      isLoggedIn: false,
      currentUser: null,
      pendingMessage: message,
    ));
  }
}
