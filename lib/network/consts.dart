import 'package:flutter_dotenv/flutter_dotenv.dart';

String get kBaseUrl =>
    dotenv.env['BASE_URL'] ?? 'http://192.168.99.200:8001/api/';

const kEndPointLogin = "login";
const kEndPointSendOtp = "send-otp";
const kEndPointVerifyOtp = "verify-otp";
const kEndPointCompleteRegister = "complete-register";
const kEndPointLogout = "logout";
const kEndPointMe = "me";
const kEndPointDeactivateAccount = "deactivate-account";

const kEndPointCompanies = 'companies';
const kEndPointBusinessCards = 'business-cards';
const kEndPointMyBusinessCards = 'my-business-cards';

const kEndPointChangePassword = 'change-password';
const kEndPointRefreshToken = 'refresh-token';
const kEndPointForgotPassword = 'forgot-password';
const kEndPointResetPassword = 'reset-password';
