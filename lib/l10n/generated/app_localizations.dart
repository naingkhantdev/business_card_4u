import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_my.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('my')
  ];

  /// Title of the Settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountSection;

  /// No description provided for @settingsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsName;

  /// No description provided for @settingsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsEmail;

  /// No description provided for @settingsAccountActionsSection.
  ///
  /// In en, this message translates to:
  /// **'Account actions'**
  String get settingsAccountActionsSection;

  /// No description provided for @settingsDeactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account'**
  String get settingsDeactivateAccount;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageBurmese.
  ///
  /// In en, this message translates to:
  /// **'Burmese'**
  String get languageBurmese;

  /// No description provided for @chooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguageTitle;

  /// No description provided for @chooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the language for menus, buttons, and screen text.'**
  String get chooseLanguageSubtitle;

  /// No description provided for @cardDetailUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Business card updated successfully'**
  String get cardDetailUpdateSuccess;

  /// No description provided for @cardDetailShareYourCard.
  ///
  /// In en, this message translates to:
  /// **'Share Your Card'**
  String get cardDetailShareYourCard;

  /// No description provided for @cardDetailShareYourCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Others can scan this to save your contact'**
  String get cardDetailShareYourCardSubtitle;

  /// No description provided for @cardDetailDeleteCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Card'**
  String get cardDetailDeleteCardTitle;

  /// No description provided for @cardDetailDeleteCardBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this card?'**
  String get cardDetailDeleteCardBody;

  /// No description provided for @cardDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get cardDetailDelete;

  /// No description provided for @cardDetailDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Card deleted successfully'**
  String get cardDetailDeleteSuccess;

  /// No description provided for @cardDetailDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete card'**
  String get cardDetailDeleteFailed;

  /// No description provided for @cardDetailShareMyCard.
  ///
  /// In en, this message translates to:
  /// **'Share my card'**
  String get cardDetailShareMyCard;

  /// No description provided for @cardDetailShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get cardDetailShare;

  /// No description provided for @cardDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get cardDetailEdit;

  /// No description provided for @cardDetailDeactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Account'**
  String get cardDetailDeactivateAccount;

  /// No description provided for @cardDetailTypeSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get cardDetailTypeSaved;

  /// No description provided for @cardDetailTypeBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get cardDetailTypeBusiness;

  /// No description provided for @cardDetailUnfriend.
  ///
  /// In en, this message translates to:
  /// **'Unfriend'**
  String get cardDetailUnfriend;

  /// No description provided for @cardDetailUnfriendBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this connection?'**
  String get cardDetailUnfriendBody;

  /// No description provided for @cardDetailFriendRemoved.
  ///
  /// In en, this message translates to:
  /// **'Friend removed'**
  String get cardDetailFriendRemoved;

  /// No description provided for @cardDetailFriendRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove friend'**
  String get cardDetailFriendRemoveFailed;

  /// No description provided for @cardDetailCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cardDetailCancelRequest;

  /// No description provided for @cardDetailCancelRequestBody.
  ///
  /// In en, this message translates to:
  /// **'Cancel the friend request sent to this user?'**
  String get cardDetailCancelRequestBody;

  /// No description provided for @cardDetailFriendRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Friend request cancelled'**
  String get cardDetailFriendRequestCancelled;

  /// No description provided for @cardDetailCancelRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel request'**
  String get cardDetailCancelRequestFailed;

  /// No description provided for @cardDetailFriendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get cardDetailFriendRequestSent;

  /// No description provided for @cardDetailFriendRequestSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send friend request'**
  String get cardDetailFriendRequestSendFailed;

  /// No description provided for @cardDetailFriendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted'**
  String get cardDetailFriendRequestAccepted;

  /// No description provided for @cardDetailAcceptRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept request'**
  String get cardDetailAcceptRequestFailed;

  /// No description provided for @cardDetailFriendRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Friend request declined'**
  String get cardDetailFriendRequestDeclined;

  /// No description provided for @cardDetailDeclineRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to decline request'**
  String get cardDetailDeclineRequestFailed;

  /// No description provided for @cardDetailAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get cardDetailAbout;

  /// No description provided for @cardDetailBusinessCardSection.
  ///
  /// In en, this message translates to:
  /// **'Business card'**
  String get cardDetailBusinessCardSection;

  /// No description provided for @cardDetailAddFrontBackPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add front & back photos'**
  String get cardDetailAddFrontBackPhotos;

  /// No description provided for @cardDetailYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get cardDetailYourProfile;

  /// No description provided for @cardDetailConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get cardDetailConnected;

  /// No description provided for @cardDetailCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get cardDetailCall;

  /// No description provided for @cardDetailEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get cardDetailEmail;

  /// No description provided for @cardDetailMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get cardDetailMap;

  /// No description provided for @cardDetailWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get cardDetailWebsite;

  /// No description provided for @cardDetailAddedOn.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String cardDetailAddedOn(String date);

  /// No description provided for @cardDetailPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get cardDetailPhone;

  /// No description provided for @cardDetailAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get cardDetailAddress;

  /// No description provided for @cardDetailCompanyHeader.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get cardDetailCompanyHeader;

  /// No description provided for @cardDetailContactHeader.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get cardDetailContactHeader;

  /// No description provided for @cardDetailSocialHeader.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get cardDetailSocialHeader;

  /// No description provided for @cardDetailTapToEnlarge.
  ///
  /// In en, this message translates to:
  /// **'{label} · tap to enlarge'**
  String cardDetailTapToEnlarge(String label);

  /// No description provided for @cardDetailAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get cardDetailAccept;

  /// No description provided for @cardDetailDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get cardDetailDecline;

  /// No description provided for @cardDetailRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get cardDetailRequestSent;

  /// No description provided for @cardDetailConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get cardDetailConnect;

  /// No description provided for @cardDetailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cardDetailCancel;

  /// No description provided for @cardDetailSocialLinkFallback.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get cardDetailSocialLinkFallback;

  /// No description provided for @cardItemFriendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get cardItemFriendRequestSent;

  /// No description provided for @cardItemFriendRequestSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request'**
  String get cardItemFriendRequestSendFailed;

  /// No description provided for @cardItemFriendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted'**
  String get cardItemFriendRequestAccepted;

  /// No description provided for @cardItemFriendRequestAcceptFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept request'**
  String get cardItemFriendRequestAcceptFailed;

  /// No description provided for @cardItemFriendRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Friend request declined'**
  String get cardItemFriendRequestDeclined;

  /// No description provided for @cardItemFriendRequestDeclineFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to decline request'**
  String get cardItemFriendRequestDeclineFailed;

  /// No description provided for @cardItemStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get cardItemStatusPending;

  /// No description provided for @cardItemStatusFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get cardItemStatusFriend;

  /// No description provided for @cardItemStatusSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get cardItemStatusSaved;

  /// No description provided for @cardItemStatusProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get cardItemStatusProfile;

  /// No description provided for @onboardingStepCounter.
  ///
  /// In en, this message translates to:
  /// **'STEP {step} / {totalSteps}'**
  String onboardingStepCounter(num step, num totalSteps);

  /// No description provided for @myQrPanelShareEyebrow.
  ///
  /// In en, this message translates to:
  /// **'SHARE'**
  String get myQrPanelShareEyebrow;

  /// No description provided for @myQrPanelTitleEyebrow.
  ///
  /// In en, this message translates to:
  /// **'MY QR CODE'**
  String get myQrPanelTitleEyebrow;

  /// No description provided for @myQrPanelShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share my QR'**
  String get myQrPanelShareTitle;

  /// No description provided for @myQrPanelScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to add me'**
  String get myQrPanelScanTitle;

  /// No description provided for @myQrPanelCompactBlurb.
  ///
  /// In en, this message translates to:
  /// **'Show this to people nearby so they can add you fast.'**
  String get myQrPanelCompactBlurb;

  /// No description provided for @myQrPanelFullBlurb.
  ///
  /// In en, this message translates to:
  /// **'Let others scan this code to add your card instantly.'**
  String get myQrPanelFullBlurb;

  /// No description provided for @myQrPanelNoProfileBlurb.
  ///
  /// In en, this message translates to:
  /// **'Create your profile card first to generate your QR.'**
  String get myQrPanelNoProfileBlurb;

  /// No description provided for @myQrPanelSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the QR code. Please try again.'**
  String get myQrPanelSaveError;

  /// No description provided for @myQrPanelSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get myQrPanelSaving;

  /// No description provided for @myQrPanelSaveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save QR to Gallery'**
  String get myQrPanelSaveToGallery;

  /// No description provided for @imageSourceTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get imageSourceTakePhoto;

  /// No description provided for @imageSourceRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get imageSourceRecommended;

  /// No description provided for @imageSourceChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get imageSourceChooseGallery;

  /// No description provided for @appSplashTagline.
  ///
  /// In en, this message translates to:
  /// **'SCAN · SAVE · CONNECT'**
  String get appSplashTagline;

  /// No description provided for @fullImageViewerDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download image. Please try again.'**
  String get fullImageViewerDownloadFailed;

  /// No description provided for @userDrawerManageCompanies.
  ///
  /// In en, this message translates to:
  /// **'Manage Companies'**
  String get userDrawerManageCompanies;

  /// No description provided for @userDrawerHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get userDrawerHelpSupport;

  /// No description provided for @userDrawerLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get userDrawerLogout;

  /// No description provided for @userDrawerVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String userDrawerVersion(String version, String build);

  /// No description provided for @userDrawerDefaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userDrawerDefaultUserName;

  /// No description provided for @cardPageNoMatchingCardsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching cards'**
  String get cardPageNoMatchingCardsTitle;

  /// No description provided for @cardPageNoCardsThisTabTitle.
  ///
  /// In en, this message translates to:
  /// **'No cards match this tab'**
  String get cardPageNoCardsThisTabTitle;

  /// No description provided for @cardPageNoCardsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No cards yet'**
  String get cardPageNoCardsYetTitle;

  /// No description provided for @cardPageFilterHidingCardsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'There are cards in the database, but your current search or company filter is hiding them.\nClear the filter to see them.'**
  String get cardPageFilterHidingCardsSubtitle;

  /// No description provided for @cardPagePullToRefreshSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh or add new cards.'**
  String get cardPagePullToRefreshSubtitle;

  /// No description provided for @cardPageMyQrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get cardPageMyQrCodeTitle;

  /// No description provided for @cardPageMyQrCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open this when someone wants to scan your card.'**
  String get cardPageMyQrCodeSubtitle;

  /// No description provided for @cardPageCreateProfileCard.
  ///
  /// In en, this message translates to:
  /// **'Create My Profile Card'**
  String get cardPageCreateProfileCard;

  /// No description provided for @cardPageProfileCardCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile card created successfully'**
  String get cardPageProfileCardCreatedSuccess;

  /// No description provided for @cardPageAddACardTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a card'**
  String get cardPageAddACardTitle;

  /// No description provided for @cardPageAddACardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Snap the card or pick a photo — we fill in the details.'**
  String get cardPageAddACardSubtitle;

  /// No description provided for @cardPageScanBusinessCard.
  ///
  /// In en, this message translates to:
  /// **'Scan a business card'**
  String get cardPageScanBusinessCard;

  /// No description provided for @cardPageScanFastestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fastest — reads front and back for you'**
  String get cardPageScanFastestSubtitle;

  /// No description provided for @cardPageEnterDetailsManually.
  ///
  /// In en, this message translates to:
  /// **'Enter details manually'**
  String get cardPageEnterDetailsManually;

  /// No description provided for @cardPageScanFrontTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the front'**
  String get cardPageScanFrontTitle;

  /// No description provided for @cardPageScanFrontSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2 — we read the card and fill in the details for you.'**
  String get cardPageScanFrontSubtitle;

  /// No description provided for @cardPageScanBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the back'**
  String get cardPageScanBackTitle;

  /// No description provided for @cardPageScanBackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2 — whatever we find here joins the same card.'**
  String get cardPageScanBackSubtitle;

  /// No description provided for @cardPageImageSourceOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the {source}. You can still enter the card manually.'**
  String cardPageImageSourceOpenFailed(String source);

  /// No description provided for @cardPageSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'camera'**
  String get cardPageSourceCamera;

  /// No description provided for @cardPageSourceGallery.
  ///
  /// In en, this message translates to:
  /// **'gallery'**
  String get cardPageSourceGallery;

  /// No description provided for @cardPageFrontCapturedLabel.
  ///
  /// In en, this message translates to:
  /// **'Front captured'**
  String get cardPageFrontCapturedLabel;

  /// No description provided for @cardPageAddBackQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add the back?'**
  String get cardPageAddBackQuestion;

  /// No description provided for @cardPageAddBackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The back usually carries the address, extra numbers, and social links the front leaves off.'**
  String get cardPageAddBackSubtitle;

  /// No description provided for @cardPageScanBackTooTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the back too'**
  String get cardPageScanBackTooTitle;

  /// No description provided for @cardPageScanBackTooSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended — catches what the front misses'**
  String get cardPageScanBackTooSubtitle;

  /// No description provided for @cardPageSkipFrontOnly.
  ///
  /// In en, this message translates to:
  /// **'Skip — front only'**
  String get cardPageSkipFrontOnly;

  /// No description provided for @cardPageBusinessCardCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Business card created successfully'**
  String get cardPageBusinessCardCreatedSuccess;

  /// No description provided for @cardPageScanQrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get cardPageScanQrCodeTitle;

  /// No description provided for @cardPageScanQrCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add friend by scanning their QR code'**
  String get cardPageScanQrCodeSubtitle;

  /// No description provided for @cardPageSearchUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Users'**
  String get cardPageSearchUsersTitle;

  /// No description provided for @cardPageSearchUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find users by name or company'**
  String get cardPageSearchUsersSubtitle;

  /// No description provided for @cardPageFriendsCardsTab.
  ///
  /// In en, this message translates to:
  /// **'Friend\'s Cards'**
  String get cardPageFriendsCardsTab;

  /// No description provided for @cardPageSavedCardsTab.
  ///
  /// In en, this message translates to:
  /// **'Saved Cards'**
  String get cardPageSavedCardsTab;

  /// No description provided for @cardPageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search cards...'**
  String get cardPageSearchHint;

  /// No description provided for @cardPageFilterByCompanyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter by company'**
  String get cardPageFilterByCompanyTooltip;

  /// No description provided for @cardPageAddFriendFabLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get cardPageAddFriendFabLabel;

  /// No description provided for @cardPageNewCardFabLabel.
  ///
  /// In en, this message translates to:
  /// **'New Card'**
  String get cardPageNewCardFabLabel;

  /// No description provided for @cardPageFilterByCompanySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by Company'**
  String get cardPageFilterByCompanySheetTitle;

  /// No description provided for @cardPageCompanyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 company} other{{count} companies}}'**
  String cardPageCompanyCount(num count);

  /// No description provided for @cardPageClearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get cardPageClearFilter;

  /// No description provided for @cardPageSearchCompaniesHint.
  ///
  /// In en, this message translates to:
  /// **'Search companies'**
  String get cardPageSearchCompaniesHint;

  /// No description provided for @cardPageNoCompaniesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No companies available'**
  String get cardPageNoCompaniesAvailable;

  /// No description provided for @cardPageAllCompaniesLabel.
  ///
  /// In en, this message translates to:
  /// **'All Companies'**
  String get cardPageAllCompaniesLabel;

  /// No description provided for @cardPageAllProfessions.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get cardPageAllProfessions;

  /// No description provided for @professionEngineer.
  ///
  /// In en, this message translates to:
  /// **'Engineer'**
  String get professionEngineer;

  /// No description provided for @professionDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get professionDoctor;

  /// No description provided for @professionSailor.
  ///
  /// In en, this message translates to:
  /// **'Sailor'**
  String get professionSailor;

  /// No description provided for @professionNurse.
  ///
  /// In en, this message translates to:
  /// **'Nurse'**
  String get professionNurse;

  /// No description provided for @professionTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get professionTeacher;

  /// No description provided for @professionLawyer.
  ///
  /// In en, this message translates to:
  /// **'Lawyer'**
  String get professionLawyer;

  /// No description provided for @professionAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get professionAccountant;

  /// No description provided for @professionDesigner.
  ///
  /// In en, this message translates to:
  /// **'Designer'**
  String get professionDesigner;

  /// No description provided for @professionManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get professionManager;

  /// No description provided for @professionSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get professionSales;

  /// No description provided for @professionPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get professionPickerTitle;

  /// No description provided for @professionPickerOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get professionPickerOther;

  /// No description provided for @professionPickerOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Type your profession'**
  String get professionPickerOtherHint;

  /// No description provided for @professionPickerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get professionPickerAdd;

  /// No description provided for @professionPickerSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested from the position — tap another to change'**
  String get professionPickerSuggested;

  /// No description provided for @cardPageNoCompaniesMatchQuery.
  ///
  /// In en, this message translates to:
  /// **'No companies match \"{query}\"'**
  String cardPageNoCompaniesMatchQuery(String query);

  /// No description provided for @authGateSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get authGateSomethingWrong;

  /// No description provided for @scanPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanPageTitle;

  /// No description provided for @scanPageCardNotFound.
  ///
  /// In en, this message translates to:
  /// **'Card not found for this QR code'**
  String get scanPageCardNotFound;

  /// No description provided for @scanPageErrorScanning.
  ///
  /// In en, this message translates to:
  /// **'Error scanning QR code'**
  String get scanPageErrorScanning;

  /// No description provided for @deactivateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Account'**
  String get deactivateAccountTitle;

  /// No description provided for @deactivateAccountEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get deactivateAccountEnterPassword;

  /// No description provided for @deactivateAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to deactivate account'**
  String get deactivateAccountFailed;

  /// No description provided for @deactivateAccountSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deactivated. Log in again within 7 days to restore it.'**
  String get deactivateAccountSuccessMessage;

  /// No description provided for @deactivateAccountHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your account will be turned off now.'**
  String get deactivateAccountHeadline;

  /// No description provided for @deactivateAccountSubtext.
  ///
  /// In en, this message translates to:
  /// **'You can get it back by logging in again within 7 days.'**
  String get deactivateAccountSubtext;

  /// No description provided for @deactivateAccountPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get deactivateAccountPasswordLabel;

  /// No description provided for @deactivateAccountCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deactivateAccountCancel;

  /// No description provided for @registerPageTagline.
  ///
  /// In en, this message translates to:
  /// **'Create an account to start sharing your card.'**
  String get registerPageTagline;

  /// No description provided for @registerPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerPageTitle;

  /// No description provided for @registerPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a verification code.'**
  String get registerPageSubtitle;

  /// No description provided for @registerPageEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get registerPageEmailLabel;

  /// No description provided for @registerPageSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get registerPageSendCode;

  /// No description provided for @registerPageCodeExpiry.
  ///
  /// In en, this message translates to:
  /// **'Code expires in 5 minutes.'**
  String get registerPageCodeExpiry;

  /// No description provided for @registerPageHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get registerPageHaveAccount;

  /// No description provided for @helpPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpPageTitle;

  /// No description provided for @helpPageContactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get helpPageContactSection;

  /// No description provided for @helpPageContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get helpPageContactSupport;

  /// No description provided for @helpPageHowItWorksSection.
  ///
  /// In en, this message translates to:
  /// **'How BusinessCard4U works'**
  String get helpPageHowItWorksSection;

  /// No description provided for @helpPageFeatureScan.
  ///
  /// In en, this message translates to:
  /// **'Scan a card and its name, role, phone, email and address fill in on their own.'**
  String get helpPageFeatureScan;

  /// No description provided for @helpPageFeatureCompany.
  ///
  /// In en, this message translates to:
  /// **'Companies are matched or created automatically from the scan — no separate step.'**
  String get helpPageFeatureCompany;

  /// No description provided for @helpPageFeatureQr.
  ///
  /// In en, this message translates to:
  /// **'Share your own card instantly with a QR code.'**
  String get helpPageFeatureQr;

  /// No description provided for @helpPageFeatureFriends.
  ///
  /// In en, this message translates to:
  /// **'Connect with other users as friends so their card details stay current on your side.'**
  String get helpPageFeatureFriends;

  /// No description provided for @helpPageFaqSection.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get helpPageFaqSection;

  /// No description provided for @helpPageFaq1Question.
  ///
  /// In en, this message translates to:
  /// **'Does scanning a card create the company automatically?'**
  String get helpPageFaq1Question;

  /// No description provided for @helpPageFaq1Answer.
  ///
  /// In en, this message translates to:
  /// **'Yes. When the photo names a company that already exists it links to it; when it doesn\'t, BusinessCard4U files a new company right away so you\'re not interrupted mid-scan. You can always change the linked company afterwards from the card\'s edit screen.'**
  String get helpPageFaq1Answer;

  /// No description provided for @helpPageFaq2Question.
  ///
  /// In en, this message translates to:
  /// **'What\'s the difference between Saved Cards and Friends?'**
  String get helpPageFaq2Question;

  /// No description provided for @helpPageFaq2Answer.
  ///
  /// In en, this message translates to:
  /// **'Saved Cards are entries you added yourself — from a photo or typed in by hand. Friends are other BusinessCard4U users you\'re connected with, so their card stays up to date on your side whenever they edit it.'**
  String get helpPageFaq2Answer;

  /// No description provided for @helpPageFaq3Question.
  ///
  /// In en, this message translates to:
  /// **'Can I fix a field the scanner got wrong?'**
  String get helpPageFaq3Question;

  /// No description provided for @helpPageFaq3Answer.
  ///
  /// In en, this message translates to:
  /// **'Every scanned field is editable — a scan is a best guess, not a final answer. Open the card and correct anything before saving.'**
  String get helpPageFaq3Answer;

  /// No description provided for @helpPageFaq4Question.
  ///
  /// In en, this message translates to:
  /// **'How do people find my card?'**
  String get helpPageFaq4Question;

  /// No description provided for @helpPageFaq4Answer.
  ///
  /// In en, this message translates to:
  /// **'Share your QR code from your profile card — anyone who scans it saves your details straight away.'**
  String get helpPageFaq4Answer;

  /// No description provided for @companySelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Companies'**
  String get companySelectTitle;

  /// No description provided for @companySelectAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add New Company'**
  String get companySelectAddNew;

  /// No description provided for @companySelectCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get companySelectCancel;

  /// No description provided for @companySelectCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Company created successfully'**
  String get companySelectCreatedSuccess;

  /// No description provided for @companySelectUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Company updated successfully'**
  String get companySelectUpdatedSuccess;

  /// No description provided for @companySelectDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get companySelectDelete;

  /// No description provided for @companySelectDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Company'**
  String get companySelectDeleteTitle;

  /// No description provided for @companySelectDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String companySelectDeleteConfirm(String name);

  /// No description provided for @companySelectDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Company deleted successfully'**
  String get companySelectDeletedSuccess;

  /// No description provided for @companySelectDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete company'**
  String get companySelectDeleteFailed;

  /// No description provided for @companySelectEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get companySelectEdit;

  /// No description provided for @companySelectEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No companies found'**
  String get companySelectEmptyTitle;

  /// No description provided for @companySelectEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first company to get started'**
  String get companySelectEmptySubtitle;

  /// No description provided for @companySelectGeneralIndustry.
  ///
  /// In en, this message translates to:
  /// **'General Industry'**
  String get companySelectGeneralIndustry;

  /// No description provided for @loginPageEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginPageEmailLabel;

  /// No description provided for @loginPagePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPagePasswordLabel;

  /// No description provided for @loginPageLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginPageLogIn;

  /// No description provided for @loginPageInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get loginPageInvalidCredentials;

  /// No description provided for @loginPageNoAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get loginPageNoAccountRegister;

  /// No description provided for @loginPageDevelopedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by Asia Brightway'**
  String get loginPageDevelopedBy;

  /// No description provided for @loginPageCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get loginPageCancel;

  /// No description provided for @loginPageWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginPageWelcomeBack;

  /// No description provided for @loginPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to manage your business cards.'**
  String get loginPageSubtitle;

  /// No description provided for @searchPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Users'**
  String get searchPageTitle;

  /// No description provided for @searchPageHint.
  ///
  /// In en, this message translates to:
  /// **'Enter name or email...'**
  String get searchPageHint;

  /// No description provided for @searchPageSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchPageSearchTooltip;

  /// No description provided for @searchPageFilterByLocation.
  ///
  /// In en, this message translates to:
  /// **'Filter by location'**
  String get searchPageFilterByLocation;

  /// No description provided for @searchPageFilterCity.
  ///
  /// In en, this message translates to:
  /// **'City: {city}'**
  String searchPageFilterCity(String city);

  /// No description provided for @searchPageFilterState.
  ///
  /// In en, this message translates to:
  /// **'State: {state}'**
  String searchPageFilterState(String state);

  /// No description provided for @searchPageFilterCountry.
  ///
  /// In en, this message translates to:
  /// **'Country: {country}'**
  String searchPageFilterCountry(String country);

  /// No description provided for @searchPageEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email or location'**
  String get searchPageEmptyHint;

  /// No description provided for @searchPageNoResults.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get searchPageNoResults;

  /// No description provided for @searchPageErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while searching'**
  String get searchPageErrorOccurred;

  /// No description provided for @searchPageCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get searchPageCityLabel;

  /// No description provided for @searchPageStateLabel.
  ///
  /// In en, this message translates to:
  /// **'State / Region'**
  String get searchPageStateLabel;

  /// No description provided for @searchPageCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get searchPageCountryLabel;

  /// No description provided for @searchPageClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchPageClear;

  /// No description provided for @searchPageApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get searchPageApply;

  /// No description provided for @addCardProfilePhotoSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get addCardProfilePhotoSourceTitle;

  /// No description provided for @addCardFrontSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Card front'**
  String get addCardFrontSourceTitle;

  /// No description provided for @addCardBackSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Card back'**
  String get addCardBackSourceTitle;

  /// No description provided for @addCardOcrNoTextFound.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read any text from that photo. Try better lighting, or fill the form in yourself.'**
  String get addCardOcrNoTextFound;

  /// No description provided for @addCardScannedDetailsAdded.
  ///
  /// In en, this message translates to:
  /// **'Scanned details added. Check them before saving.'**
  String get addCardScannedDetailsAdded;

  /// No description provided for @addCardScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not scan that photo. Please try again.'**
  String get addCardScanFailed;

  /// No description provided for @addCardCouldNotOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Could not open the {source}.'**
  String addCardCouldNotOpenSource(String source);

  /// No description provided for @addCardSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'camera'**
  String get addCardSourceCamera;

  /// No description provided for @addCardSourceGallery.
  ///
  /// In en, this message translates to:
  /// **'gallery'**
  String get addCardSourceGallery;

  /// No description provided for @addCardInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email: {email}'**
  String addCardInvalidEmail(String email);

  /// No description provided for @addCardPhoneTooShort.
  ///
  /// In en, this message translates to:
  /// **'Each phone must be at least 6 characters'**
  String get addCardPhoneTooShort;

  /// No description provided for @addCardUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update card'**
  String get addCardUpdateFailed;

  /// No description provided for @addCardCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create card'**
  String get addCardCreateFailed;

  /// No description provided for @addCardEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Business Card'**
  String get addCardEditTitle;

  /// No description provided for @addCardAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Business Card'**
  String get addCardAddTitle;

  /// No description provided for @addCardPersonalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get addCardPersonalInfoTitle;

  /// No description provided for @addCardPersonalInfoSubtitleOwn.
  ///
  /// In en, this message translates to:
  /// **'Your photo, name, and role as others see them'**
  String get addCardPersonalInfoSubtitleOwn;

  /// No description provided for @addCardPersonalInfoSubtitleOther.
  ///
  /// In en, this message translates to:
  /// **'The name and role printed on the card'**
  String get addCardPersonalInfoSubtitleOther;

  /// No description provided for @addCardFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get addCardFullNameLabel;

  /// No description provided for @addCardFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. John Doe'**
  String get addCardFullNameHint;

  /// No description provided for @addCardPositionLabel.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get addCardPositionLabel;

  /// No description provided for @addCardPositionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Software Engineer'**
  String get addCardPositionHint;

  /// No description provided for @addCardCompanySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get addCardCompanySectionTitle;

  /// No description provided for @addCardCompanySectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Links this card to a company record'**
  String get addCardCompanySectionSubtitle;

  /// No description provided for @addCardContactDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get addCardContactDetailsTitle;

  /// No description provided for @addCardContactDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Separate several entries with commas'**
  String get addCardContactDetailsSubtitle;

  /// No description provided for @addCardPhonesLabel.
  ///
  /// In en, this message translates to:
  /// **'Phones'**
  String get addCardPhonesLabel;

  /// No description provided for @addCardPhonesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 998991112233, ...'**
  String get addCardPhonesHint;

  /// No description provided for @addCardEmailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Emails'**
  String get addCardEmailsLabel;

  /// No description provided for @addCardEmailsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. mail@example.com, ...'**
  String get addCardEmailsHint;

  /// No description provided for @addCardAddressesTitle.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addCardAddressesTitle;

  /// No description provided for @addCardAddressesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where this person works'**
  String get addCardAddressesSubtitle;

  /// No description provided for @addCardMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get addCardMoreTitle;

  /// No description provided for @addCardMoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anything worth remembering about this contact'**
  String get addCardMoreSubtitle;

  /// No description provided for @addCardBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get addCardBioLabel;

  /// No description provided for @addCardBioHint.
  ///
  /// In en, this message translates to:
  /// **'Short description...'**
  String get addCardBioHint;

  /// No description provided for @addCardYourCardPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Your card photos'**
  String get addCardYourCardPhotosTitle;

  /// No description provided for @addCardCardPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Card photos'**
  String get addCardCardPhotosTitle;

  /// No description provided for @addCardPhotosSubtitleHasFront.
  ///
  /// In en, this message translates to:
  /// **'Tap a photo to replace it. Scanning only fills empty fields.'**
  String get addCardPhotosSubtitleHasFront;

  /// No description provided for @addCardPhotosSubtitleOwnEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add both sides of your printed card so people can see the real thing.'**
  String get addCardPhotosSubtitleOwnEmpty;

  /// No description provided for @addCardPhotosSubtitleOtherEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of the card to fill this form automatically.'**
  String get addCardPhotosSubtitleOtherEmpty;

  /// No description provided for @addCardReading.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get addCardReading;

  /// No description provided for @addCardRescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get addCardRescan;

  /// No description provided for @addCardFrontLabel.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get addCardFrontLabel;

  /// No description provided for @addCardBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get addCardBackLabel;

  /// No description provided for @addCardChangeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get addCardChangeProfilePhoto;

  /// No description provided for @addCardAddProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a profile photo'**
  String get addCardAddProfilePhoto;

  /// No description provided for @addCardProfilePhotoHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown at the top of your card and next to your name in search results.'**
  String get addCardProfilePhotoHelp;

  /// No description provided for @addCardOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get addCardOptional;

  /// No description provided for @addCardRequiredToScan.
  ///
  /// In en, this message translates to:
  /// **'Required to scan'**
  String get addCardRequiredToScan;

  /// No description provided for @addCardFilingCompany.
  ///
  /// In en, this message translates to:
  /// **'Filing \"{name}\"…'**
  String addCardFilingCompany(String name);

  /// No description provided for @addCardAddedNewCompany.
  ///
  /// In en, this message translates to:
  /// **'Added \"{name}\" as a new company. Its industry and business type can be filled in any time.'**
  String addCardAddedNewCompany(String name);

  /// No description provided for @addCardMatchedCompany.
  ///
  /// In en, this message translates to:
  /// **'Matched \"{name}\" to a company already on file.'**
  String addCardMatchedCompany(String name);

  /// No description provided for @addCardScannedPickCompany.
  ///
  /// In en, this message translates to:
  /// **'Scanned \"{name}\" — pick the matching company'**
  String addCardScannedPickCompany(String name);

  /// No description provided for @addCardChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get addCardChoose;

  /// No description provided for @addCardChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get addCardChange;

  /// No description provided for @addCardScannedBadge.
  ///
  /// In en, this message translates to:
  /// **'Scanned'**
  String get addCardScannedBadge;

  /// No description provided for @addCardAddressNumber.
  ///
  /// In en, this message translates to:
  /// **'Address {number}'**
  String addCardAddressNumber(int number);

  /// No description provided for @addCardStreetLabel.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get addCardStreetLabel;

  /// No description provided for @addCardStreetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 123 Main St'**
  String get addCardStreetHint;

  /// No description provided for @addCardCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get addCardCityLabel;

  /// No description provided for @addCardCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Yangon'**
  String get addCardCityHint;

  /// No description provided for @addCardCityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get addCardCityRequired;

  /// No description provided for @addCardStateLabel.
  ///
  /// In en, this message translates to:
  /// **'State / Region'**
  String get addCardStateLabel;

  /// No description provided for @addCardPostalCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get addCardPostalCodeLabel;

  /// No description provided for @addCardCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get addCardCountryLabel;

  /// No description provided for @addCardCountryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Myanmar'**
  String get addCardCountryHint;

  /// No description provided for @addCardCountryRequired.
  ///
  /// In en, this message translates to:
  /// **'Country is required'**
  String get addCardCountryRequired;

  /// No description provided for @addCardAddAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addCardAddAddress;

  /// No description provided for @addCardSelectedCompanyLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected company'**
  String get addCardSelectedCompanyLabel;

  /// No description provided for @addCardChooseCompany.
  ///
  /// In en, this message translates to:
  /// **'Choose a company'**
  String get addCardChooseCompany;

  /// No description provided for @addCardSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get addCardSaveChanges;

  /// No description provided for @addCardCreateCard.
  ///
  /// In en, this message translates to:
  /// **'Create card'**
  String get addCardCreateCard;

  /// No description provided for @setupProfileImageSourceError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the {source}.'**
  String setupProfileImageSourceError(String source);

  /// No description provided for @setupProfileSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'camera'**
  String get setupProfileSourceCamera;

  /// No description provided for @setupProfileSourceGallery.
  ///
  /// In en, this message translates to:
  /// **'gallery'**
  String get setupProfileSourceGallery;

  /// No description provided for @setupProfileImageSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get setupProfileImageSheetTitle;

  /// No description provided for @setupProfileImageSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is the face people see when they find your card.'**
  String get setupProfileImageSheetSubtitle;

  /// No description provided for @setupProfileFrontSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Front of your card'**
  String get setupProfileFrontSheetTitle;

  /// No description provided for @setupProfileBackSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Back of your card'**
  String get setupProfileBackSheetTitle;

  /// No description provided for @setupProfileFrontSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We read it and fill in the details below.'**
  String get setupProfileFrontSheetSubtitle;

  /// No description provided for @setupProfileBackSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Often where the address and extra numbers live.'**
  String get setupProfileBackSheetSubtitle;

  /// No description provided for @setupProfileOcrEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that photo. Try better lighting, or type the details in yourself.'**
  String get setupProfileOcrEmptyError;

  /// No description provided for @setupProfileOcrFilledMessage.
  ///
  /// In en, this message translates to:
  /// **'Filled in what we could read. Check it before saving.'**
  String get setupProfileOcrFilledMessage;

  /// No description provided for @setupProfileOcrError.
  ///
  /// In en, this message translates to:
  /// **'Could not scan that photo. Please try again.'**
  String get setupProfileOcrError;

  /// No description provided for @setupProfileFinishLaterMessage.
  ///
  /// In en, this message translates to:
  /// **'You can finish your card any time from the menu.'**
  String get setupProfileFinishLaterMessage;

  /// No description provided for @setupProfileSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your card is ready. Share it any time from the QR button.'**
  String get setupProfileSavedMessage;

  /// No description provided for @setupProfileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your card. Please try again.'**
  String get setupProfileSaveError;

  /// No description provided for @setupProfileYourCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Your card'**
  String get setupProfileYourCardLabel;

  /// No description provided for @setupProfileAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get setupProfileAccountCreated;

  /// No description provided for @setupProfileHeadline.
  ///
  /// In en, this message translates to:
  /// **'Complete your card'**
  String get setupProfileHeadline;

  /// No description provided for @setupProfileSubhead.
  ///
  /// In en, this message translates to:
  /// **'This is what people see when they scan you. Everything here is optional.'**
  String get setupProfileSubhead;

  /// No description provided for @setupProfileSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save My Card'**
  String get setupProfileSaveButton;

  /// No description provided for @setupProfileSkipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get setupProfileSkipButton;

  /// No description provided for @setupProfilePhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Your printed card'**
  String get setupProfilePhotosTitle;

  /// No description provided for @setupProfilePhotosCaption.
  ///
  /// In en, this message translates to:
  /// **'Photograph the front and we read it into the form below.'**
  String get setupProfilePhotosCaption;

  /// No description provided for @setupProfileReadingLabel.
  ///
  /// In en, this message translates to:
  /// **'READING'**
  String get setupProfileReadingLabel;

  /// No description provided for @setupProfileRescanLabel.
  ///
  /// In en, this message translates to:
  /// **'RESCAN'**
  String get setupProfileRescanLabel;

  /// No description provided for @setupProfileFrontLabel.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get setupProfileFrontLabel;

  /// No description provided for @setupProfileBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get setupProfileBackLabel;

  /// No description provided for @setupProfileProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get setupProfileProfileTitle;

  /// No description provided for @setupProfilePhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'PHOTO ADDED'**
  String get setupProfilePhotoAdded;

  /// No description provided for @setupProfileAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'ADD A PHOTO'**
  String get setupProfileAddPhoto;

  /// No description provided for @setupProfilePositionHint.
  ///
  /// In en, this message translates to:
  /// **'Position — e.g. Product Designer'**
  String get setupProfilePositionHint;

  /// No description provided for @setupProfilePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get setupProfilePhoneHint;

  /// No description provided for @setupProfilePhoneMinLength.
  ///
  /// In en, this message translates to:
  /// **'Phone must be at least 6 digits'**
  String get setupProfilePhoneMinLength;

  /// No description provided for @setupProfileCompanyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Company (optional)'**
  String get setupProfileCompanyPlaceholder;

  /// No description provided for @setupProfileChangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get setupProfileChangeLabel;

  /// No description provided for @setupProfileChooseLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get setupProfileChooseLabel;

  /// No description provided for @setupProfileFillsFormHint.
  ///
  /// In en, this message translates to:
  /// **'Fills the form'**
  String get setupProfileFillsFormHint;

  /// No description provided for @otpPageEnterSixDigits.
  ///
  /// In en, this message translates to:
  /// **'Please enter all 6 digits'**
  String get otpPageEnterSixDigits;

  /// No description provided for @otpPageVerifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'OTP verified'**
  String get otpPageVerifiedMessage;

  /// No description provided for @otpPageGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get otpPageGenericError;

  /// No description provided for @otpPageResentMessage.
  ///
  /// In en, this message translates to:
  /// **'OTP resent'**
  String get otpPageResentMessage;

  /// No description provided for @otpPageResendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP'**
  String get otpPageResendFailed;

  /// No description provided for @otpPageTagline.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent to verify it\'s you.'**
  String get otpPageTagline;

  /// No description provided for @otpPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get otpPageTitle;

  /// No description provided for @otpPageSentCodeTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to'**
  String get otpPageSentCodeTo;

  /// No description provided for @otpPageResendNow.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get otpPageResendNow;

  /// No description provided for @otpPageResendAfter.
  ///
  /// In en, this message translates to:
  /// **'Resend available after {time}'**
  String otpPageResendAfter(String time);

  /// No description provided for @otpPageFooterTip.
  ///
  /// In en, this message translates to:
  /// **'Don\'t share your OTP with anyone. This code expires in 5 minutes.'**
  String get otpPageFooterTip;

  /// No description provided for @otpPageChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get otpPageChangeEmail;

  /// No description provided for @otpPageLoadingWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get otpPageLoadingWait;

  /// No description provided for @completeRegisterStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get completeRegisterStepLabel;

  /// No description provided for @completeRegisterStepCompleted.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get completeRegisterStepCompleted;

  /// No description provided for @completeRegisterHeadline.
  ///
  /// In en, this message translates to:
  /// **'Finish your account'**
  String get completeRegisterHeadline;

  /// No description provided for @completeRegisterSubhead.
  ///
  /// In en, this message translates to:
  /// **'Two fields and a password. Your card comes next.'**
  String get completeRegisterSubhead;

  /// No description provided for @completeRegisterCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create My Account'**
  String get completeRegisterCreateAccount;

  /// No description provided for @completeRegisterTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms & Privacy.'**
  String get completeRegisterTerms;

  /// No description provided for @completeRegisterWhoYouAre.
  ///
  /// In en, this message translates to:
  /// **'Who you are'**
  String get completeRegisterWhoYouAre;

  /// No description provided for @completeRegisterFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get completeRegisterFullNameHint;

  /// No description provided for @completeRegisterFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get completeRegisterFullNameRequired;

  /// No description provided for @completeRegisterFullNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters'**
  String get completeRegisterFullNameTooShort;

  /// No description provided for @completeRegisterSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a password'**
  String get completeRegisterSetPassword;

  /// No description provided for @completeRegisterPasswordCaption.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters. Longer is better.'**
  String get completeRegisterPasswordCaption;

  /// No description provided for @completeRegisterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get completeRegisterPasswordHint;

  /// No description provided for @completeRegisterPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get completeRegisterPasswordRequired;

  /// No description provided for @completeRegisterPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get completeRegisterPasswordTooShort;

  /// No description provided for @completeRegisterConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get completeRegisterConfirmPasswordHint;

  /// No description provided for @completeRegisterConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get completeRegisterConfirmPasswordRequired;

  /// No description provided for @completeRegisterPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get completeRegisterPasswordMismatch;

  /// No description provided for @completeRegisterVerified.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get completeRegisterVerified;

  /// No description provided for @completeRegisterShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get completeRegisterShowPassword;

  /// No description provided for @completeRegisterHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get completeRegisterHidePassword;

  /// No description provided for @completeRegisterStrengthTooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short'**
  String get completeRegisterStrengthTooShort;

  /// No description provided for @completeRegisterStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get completeRegisterStrengthWeak;

  /// No description provided for @completeRegisterStrengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get completeRegisterStrengthGood;

  /// No description provided for @completeRegisterStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get completeRegisterStrengthStrong;

  /// No description provided for @completeRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get completeRegisterFailed;

  /// No description provided for @friendRequestsAcceptedToast.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted'**
  String get friendRequestsAcceptedToast;

  /// No description provided for @friendRequestsAcceptFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept request'**
  String get friendRequestsAcceptFailed;

  /// No description provided for @friendRequestsRejectedToast.
  ///
  /// In en, this message translates to:
  /// **'Friend request rejected'**
  String get friendRequestsRejectedToast;

  /// No description provided for @friendRequestsRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject request'**
  String get friendRequestsRejectFailed;

  /// No description provided for @friendRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend Requests'**
  String get friendRequestsTitle;

  /// No description provided for @friendRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending friend requests'**
  String get friendRequestsEmpty;

  /// No description provided for @friendRequestsJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get friendRequestsJustNow;

  /// No description provided for @friendRequestsMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 minute ago} other{{count} minutes ago}}'**
  String friendRequestsMinutesAgo(num count);

  /// No description provided for @friendRequestsHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 hour ago} other{{count} hours ago}}'**
  String friendRequestsHoursAgo(num count);

  /// No description provided for @friendRequestsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day ago} other{{count} days ago}}'**
  String friendRequestsDaysAgo(num count);

  /// No description provided for @friendRequestsDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Requested to add you'**
  String get friendRequestsDefaultSubtitle;

  /// No description provided for @friendRequestsNowFriends.
  ///
  /// In en, this message translates to:
  /// **'You are now friends'**
  String get friendRequestsNowFriends;

  /// No description provided for @friendRequestsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get friendRequestsReject;

  /// No description provided for @friendRequestsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendRequestsAccept;

  /// No description provided for @companyDetailContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get companyDetailContactDetails;

  /// No description provided for @companyDetailAboutCompany.
  ///
  /// In en, this message translates to:
  /// **'About Company'**
  String get companyDetailAboutCompany;

  /// No description provided for @companyDetailSocialPresence.
  ///
  /// In en, this message translates to:
  /// **'Social Presence'**
  String get companyDetailSocialPresence;

  /// No description provided for @companyDetailGeneralFallback.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get companyDetailGeneralFallback;

  /// No description provided for @companyDetailCorporateFallback.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get companyDetailCorporateFallback;

  /// No description provided for @companyFormSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save company details'**
  String get companyFormSaveFailed;

  /// No description provided for @companyFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Company'**
  String get companyFormEditTitle;

  /// No description provided for @companyFormNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Company'**
  String get companyFormNewTitle;

  /// No description provided for @companyFormProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Profile'**
  String get companyFormProfileTitle;

  /// No description provided for @companyFormProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details below to create a premium business profile.'**
  String get companyFormProfileSubtitle;

  /// No description provided for @companyFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name *'**
  String get companyFormNameLabel;

  /// No description provided for @companyFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get companyFormNameRequired;

  /// No description provided for @companyFormIndustryLabel.
  ///
  /// In en, this message translates to:
  /// **'Industry *'**
  String get companyFormIndustryLabel;

  /// No description provided for @companyFormFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get companyFormFieldRequired;

  /// No description provided for @companyFormTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type *'**
  String get companyFormTypeLabel;

  /// No description provided for @companyFormDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get companyFormDescriptionLabel;

  /// No description provided for @companyFormContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get companyFormContactInfo;

  /// No description provided for @companyFormAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Physical Address'**
  String get companyFormAddressLabel;

  /// No description provided for @companyFormWebsiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website URL'**
  String get companyFormWebsiteLabel;

  /// No description provided for @companyFormPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get companyFormPhoneLabel;

  /// No description provided for @companyFormEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get companyFormEmailLabel;

  /// No description provided for @companyFormUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'UPDATE COMPANY'**
  String get companyFormUpdateButton;

  /// No description provided for @companyFormCreateButton.
  ///
  /// In en, this message translates to:
  /// **'CREATE COMPANY'**
  String get companyFormCreateButton;

  /// No description provided for @saveToGalleryAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow photo access in Settings to save images.'**
  String get saveToGalleryAccessDenied;

  /// No description provided for @saveToGallerySuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved to gallery'**
  String get saveToGallerySuccess;

  /// No description provided for @saveToGalleryError.
  ///
  /// In en, this message translates to:
  /// **'Could not save image. Please try again.'**
  String get saveToGalleryError;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'my'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'my': return AppLocalizationsMy();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
