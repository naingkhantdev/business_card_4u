import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String get settingsName => 'Name';

  @override
  String get settingsEmail => 'Email';

  @override
  String get settingsAccountActionsSection => 'Account actions';

  @override
  String get settingsDeactivateAccount => 'Deactivate account';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBurmese => 'Burmese';

  @override
  String get chooseLanguageTitle => 'Choose language';

  @override
  String get chooseLanguageSubtitle => 'Pick the language for menus, buttons, and screen text.';

  @override
  String get cardDetailUpdateSuccess => 'Business card updated successfully';

  @override
  String get cardDetailShareYourCard => 'Share Your Card';

  @override
  String get cardDetailShareYourCardSubtitle => 'Others can scan this to save your contact';

  @override
  String get cardDetailDeleteCardTitle => 'Delete Card';

  @override
  String get cardDetailDeleteCardBody => 'Are you sure you want to delete this card?';

  @override
  String get cardDetailDelete => 'Delete';

  @override
  String get cardDetailDeleteSuccess => 'Card deleted successfully';

  @override
  String get cardDetailDeleteFailed => 'Failed to delete card';

  @override
  String get cardDetailShareMyCard => 'Share my card';

  @override
  String get cardDetailShare => 'Share';

  @override
  String get cardDetailEdit => 'Edit';

  @override
  String get cardDetailDeactivateAccount => 'Deactivate Account';

  @override
  String get cardDetailTypeSaved => 'Saved';

  @override
  String get cardDetailTypeBusiness => 'Business';

  @override
  String get cardDetailUnfriend => 'Unfriend';

  @override
  String get cardDetailUnfriendBody => 'Remove this connection?';

  @override
  String get cardDetailFriendRemoved => 'Friend removed';

  @override
  String get cardDetailFriendRemoveFailed => 'Failed to remove friend';

  @override
  String get cardDetailCancelRequest => 'Cancel Request';

  @override
  String get cardDetailCancelRequestBody => 'Cancel the friend request sent to this user?';

  @override
  String get cardDetailFriendRequestCancelled => 'Friend request cancelled';

  @override
  String get cardDetailCancelRequestFailed => 'Failed to cancel request';

  @override
  String get cardDetailFriendRequestSent => 'Friend request sent';

  @override
  String get cardDetailFriendRequestSendFailed => 'Failed to send friend request';

  @override
  String get cardDetailFriendRequestAccepted => 'Friend request accepted';

  @override
  String get cardDetailAcceptRequestFailed => 'Failed to accept request';

  @override
  String get cardDetailFriendRequestDeclined => 'Friend request declined';

  @override
  String get cardDetailDeclineRequestFailed => 'Failed to decline request';

  @override
  String get cardDetailAbout => 'About';

  @override
  String get cardDetailBusinessCardSection => 'Business card';

  @override
  String get cardDetailAddFrontBackPhotos => 'Add front & back photos';

  @override
  String get cardDetailYourProfile => 'Your profile';

  @override
  String get cardDetailConnected => 'Connected';

  @override
  String get cardDetailCall => 'Call';

  @override
  String get cardDetailEmail => 'Email';

  @override
  String get cardDetailMap => 'Map';

  @override
  String get cardDetailWebsite => 'Website';

  @override
  String cardDetailAddedOn(String date) {
    return 'Added $date';
  }

  @override
  String get cardDetailPhone => 'Phone';

  @override
  String get cardDetailAddress => 'Address';

  @override
  String get cardDetailCompanyHeader => 'Company';

  @override
  String get cardDetailContactHeader => 'Contact';

  @override
  String get cardDetailSocialHeader => 'Social';

  @override
  String cardDetailTapToEnlarge(String label) {
    return '$label · tap to enlarge';
  }

  @override
  String get cardDetailAccept => 'Accept';

  @override
  String get cardDetailDecline => 'Decline';

  @override
  String get cardDetailRequestSent => 'Request sent';

  @override
  String get cardDetailConnect => 'Connect';

  @override
  String get cardDetailCancel => 'Cancel';

  @override
  String get cardDetailSocialLinkFallback => 'Link';

  @override
  String get cardItemFriendRequestSent => 'Friend request sent';

  @override
  String get cardItemFriendRequestSendFailed => 'Failed to send request';

  @override
  String get cardItemFriendRequestAccepted => 'Friend request accepted';

  @override
  String get cardItemFriendRequestAcceptFailed => 'Failed to accept request';

  @override
  String get cardItemFriendRequestDeclined => 'Friend request declined';

  @override
  String get cardItemFriendRequestDeclineFailed => 'Failed to decline request';

  @override
  String get cardItemStatusPending => 'Pending';

  @override
  String get cardItemStatusFriend => 'Friend';

  @override
  String get cardItemStatusSaved => 'Saved';

  @override
  String get cardItemStatusProfile => 'Profile';

  @override
  String onboardingStepCounter(num step, num totalSteps) {
    return 'STEP $step / $totalSteps';
  }

  @override
  String get myQrPanelShareEyebrow => 'SHARE';

  @override
  String get myQrPanelTitleEyebrow => 'MY QR CODE';

  @override
  String get myQrPanelShareTitle => 'Share my QR';

  @override
  String get myQrPanelScanTitle => 'Scan to add me';

  @override
  String get myQrPanelCompactBlurb => 'Show this to people nearby so they can add you fast.';

  @override
  String get myQrPanelFullBlurb => 'Let others scan this code to add your card instantly.';

  @override
  String get myQrPanelNoProfileBlurb => 'Create your profile card first to generate your QR.';

  @override
  String get myQrPanelSaveError => 'Could not save the QR code. Please try again.';

  @override
  String get myQrPanelSaving => 'Saving…';

  @override
  String get myQrPanelSaveToGallery => 'Save QR to Gallery';

  @override
  String get imageSourceTakePhoto => 'Take a photo';

  @override
  String get imageSourceRecommended => 'Recommended';

  @override
  String get imageSourceChooseGallery => 'Choose from gallery';

  @override
  String get appSplashTagline => 'SCAN · SAVE · CONNECT';

  @override
  String get fullImageViewerDownloadFailed => 'Could not download image. Please try again.';

  @override
  String get userDrawerManageCompanies => 'Manage Companies';

  @override
  String get userDrawerHelpSupport => 'Help & Support';

  @override
  String get userDrawerLogout => 'Logout';

  @override
  String userDrawerVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get userDrawerDefaultUserName => 'User';

  @override
  String get cardPageNoMatchingCardsTitle => 'No matching cards';

  @override
  String get cardPageNoCardsThisTabTitle => 'No cards match this tab';

  @override
  String get cardPageNoCardsYetTitle => 'No cards yet';

  @override
  String get cardPageFilterHidingCardsSubtitle => 'There are cards in the database, but your current search or company filter is hiding them.\nClear the filter to see them.';

  @override
  String get cardPagePullToRefreshSubtitle => 'Pull down to refresh or add new cards.';

  @override
  String get cardPageMyQrCodeTitle => 'My QR Code';

  @override
  String get cardPageMyQrCodeSubtitle => 'Open this when someone wants to scan your card.';

  @override
  String get cardPageCreateProfileCard => 'Create My Profile Card';

  @override
  String get cardPageProfileCardCreatedSuccess => 'Profile card created successfully';

  @override
  String get cardPageAddACardTitle => 'Add a card';

  @override
  String get cardPageAddACardSubtitle => 'Snap the card or pick a photo — we fill in the details.';

  @override
  String get cardPageScanBusinessCard => 'Scan a business card';

  @override
  String get cardPageScanFastestSubtitle => 'Fastest — reads front and back for you';

  @override
  String get cardPageEnterDetailsManually => 'Enter details manually';

  @override
  String get cardPageScanFrontTitle => 'Scan the front';

  @override
  String get cardPageScanFrontSubtitle => 'Step 1 of 2 — we read the card and fill in the details for you.';

  @override
  String get cardPageScanBackTitle => 'Scan the back';

  @override
  String get cardPageScanBackSubtitle => 'Step 2 of 2 — whatever we find here joins the same card.';

  @override
  String cardPageImageSourceOpenFailed(String source) {
    return 'Could not open the $source. You can still enter the card manually.';
  }

  @override
  String get cardPageSourceCamera => 'camera';

  @override
  String get cardPageSourceGallery => 'gallery';

  @override
  String get cardPageFrontCapturedLabel => 'Front captured';

  @override
  String get cardPageAddBackQuestion => 'Add the back?';

  @override
  String get cardPageAddBackSubtitle => 'The back usually carries the address, extra numbers, and social links the front leaves off.';

  @override
  String get cardPageScanBackTooTitle => 'Scan the back too';

  @override
  String get cardPageScanBackTooSubtitle => 'Recommended — catches what the front misses';

  @override
  String get cardPageSkipFrontOnly => 'Skip — front only';

  @override
  String get cardPageBusinessCardCreatedSuccess => 'Business card created successfully';

  @override
  String get cardPageScanQrCodeTitle => 'Scan QR Code';

  @override
  String get cardPageScanQrCodeSubtitle => 'Add friend by scanning their QR code';

  @override
  String get cardPageSearchUsersTitle => 'Search Users';

  @override
  String get cardPageSearchUsersSubtitle => 'Find users by name or company';

  @override
  String get cardPageFriendsCardsTab => 'Friend\'s Cards';

  @override
  String get cardPageSavedCardsTab => 'Saved Cards';

  @override
  String get cardPageSearchHint => 'Search cards...';

  @override
  String get cardPageFilterByCompanyTooltip => 'Filter by company';

  @override
  String get cardPageAddFriendFabLabel => 'Add Friend';

  @override
  String get cardPageNewCardFabLabel => 'New Card';

  @override
  String get cardPageFilterByCompanySheetTitle => 'Filter by Company';

  @override
  String cardPageCompanyCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count companies',
      one: '1 company',
    );
    return '$_temp0';
  }

  @override
  String get cardPageClearFilter => 'Clear';

  @override
  String get cardPageSearchCompaniesHint => 'Search companies';

  @override
  String get cardPageNoCompaniesAvailable => 'No companies available';

  @override
  String get cardPageAllCompaniesLabel => 'All Companies';

  @override
  String get cardPageAllProfessions => 'All';

  @override
  String get professionEngineer => 'Engineer';

  @override
  String get professionDoctor => 'Doctor';

  @override
  String get professionSailor => 'Sailor';

  @override
  String get professionNurse => 'Nurse';

  @override
  String get professionTeacher => 'Teacher';

  @override
  String get professionLawyer => 'Lawyer';

  @override
  String get professionAccountant => 'Accountant';

  @override
  String get professionDesigner => 'Designer';

  @override
  String get professionManager => 'Manager';

  @override
  String get professionSales => 'Sales';

  @override
  String get professionPickerTitle => 'Profession';

  @override
  String get professionPickerOther => 'Other';

  @override
  String get professionPickerOtherHint => 'Type your profession';

  @override
  String get professionPickerAdd => 'Add';

  @override
  String get professionPickerSuggested => 'Suggested from the position — tap another to change';

  @override
  String cardPageNoCompaniesMatchQuery(String query) {
    return 'No companies match \"$query\"';
  }

  @override
  String get authGateSomethingWrong => 'Something went wrong';

  @override
  String get scanPageTitle => 'Scan QR Code';

  @override
  String get scanPageCardNotFound => 'Card not found for this QR code';

  @override
  String get scanPageErrorScanning => 'Error scanning QR code';

  @override
  String get deactivateAccountTitle => 'Deactivate Account';

  @override
  String get deactivateAccountEnterPassword => 'Please enter your password';

  @override
  String get deactivateAccountFailed => 'Failed to deactivate account';

  @override
  String get deactivateAccountSuccessMessage => 'Your account has been deactivated. Log in again within 7 days to restore it.';

  @override
  String get deactivateAccountHeadline => 'Your account will be turned off now.';

  @override
  String get deactivateAccountSubtext => 'You can get it back by logging in again within 7 days.';

  @override
  String get deactivateAccountPasswordLabel => 'Password';

  @override
  String get deactivateAccountCancel => 'Cancel';

  @override
  String get registerPageTagline => 'Create an account to start sharing your card.';

  @override
  String get registerPageTitle => 'Create your account';

  @override
  String get registerPageSubtitle => 'Enter your email to receive a verification code.';

  @override
  String get registerPageEmailLabel => 'Email';

  @override
  String get registerPageSendCode => 'Send code';

  @override
  String get registerPageCodeExpiry => 'Code expires in 5 minutes.';

  @override
  String get registerPageHaveAccount => 'Already have an account? Log in';

  @override
  String get helpPageTitle => 'Help & Support';

  @override
  String get helpPageContactSection => 'Contact';

  @override
  String get helpPageContactSupport => 'Contact support';

  @override
  String get helpPageHowItWorksSection => 'How BusinessCard4U works';

  @override
  String get helpPageFeatureScan => 'Scan a card and its name, role, phone, email and address fill in on their own.';

  @override
  String get helpPageFeatureCompany => 'Companies are matched or created automatically from the scan — no separate step.';

  @override
  String get helpPageFeatureQr => 'Share your own card instantly with a QR code.';

  @override
  String get helpPageFeatureFriends => 'Connect with other users as friends so their card details stay current on your side.';

  @override
  String get helpPageFaqSection => 'FAQ';

  @override
  String get helpPageFaq1Question => 'Does scanning a card create the company automatically?';

  @override
  String get helpPageFaq1Answer => 'Yes. When the photo names a company that already exists it links to it; when it doesn\'t, BusinessCard4U files a new company right away so you\'re not interrupted mid-scan. You can always change the linked company afterwards from the card\'s edit screen.';

  @override
  String get helpPageFaq2Question => 'What\'s the difference between Saved Cards and Friends?';

  @override
  String get helpPageFaq2Answer => 'Saved Cards are entries you added yourself — from a photo or typed in by hand. Friends are other BusinessCard4U users you\'re connected with, so their card stays up to date on your side whenever they edit it.';

  @override
  String get helpPageFaq3Question => 'Can I fix a field the scanner got wrong?';

  @override
  String get helpPageFaq3Answer => 'Every scanned field is editable — a scan is a best guess, not a final answer. Open the card and correct anything before saving.';

  @override
  String get helpPageFaq4Question => 'How do people find my card?';

  @override
  String get helpPageFaq4Answer => 'Share your QR code from your profile card — anyone who scans it saves your details straight away.';

  @override
  String get companySelectTitle => 'Manage Companies';

  @override
  String get companySelectAddNew => 'Add New Company';

  @override
  String get companySelectCancel => 'Cancel';

  @override
  String get companySelectCreatedSuccess => 'Company created successfully';

  @override
  String get companySelectUpdatedSuccess => 'Company updated successfully';

  @override
  String get companySelectDelete => 'Delete';

  @override
  String get companySelectDeleteTitle => 'Delete Company';

  @override
  String companySelectDeleteConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get companySelectDeletedSuccess => 'Company deleted successfully';

  @override
  String get companySelectDeleteFailed => 'Failed to delete company';

  @override
  String get companySelectEdit => 'Edit';

  @override
  String get companySelectEmptyTitle => 'No companies found';

  @override
  String get companySelectEmptySubtitle => 'Add your first company to get started';

  @override
  String get companySelectGeneralIndustry => 'General Industry';

  @override
  String get loginPageEmailLabel => 'Email';

  @override
  String get loginPagePasswordLabel => 'Password';

  @override
  String get loginPageLogIn => 'Log In';

  @override
  String get loginPageInvalidCredentials => 'Invalid email or password';

  @override
  String get loginPageNoAccountRegister => 'Don\'t have an account? Register';

  @override
  String get loginPageDevelopedBy => 'Developed by Asia Brightway';

  @override
  String get loginPageCancel => 'Cancel';

  @override
  String get loginPageWelcomeBack => 'Welcome back';

  @override
  String get loginPageSubtitle => 'Log in to manage your business cards.';

  @override
  String get searchPageTitle => 'Search Users';

  @override
  String get searchPageHint => 'Enter name or email...';

  @override
  String get searchPageSearchTooltip => 'Search';

  @override
  String get searchPageFilterByLocation => 'Filter by location';

  @override
  String searchPageFilterCity(String city) {
    return 'City: $city';
  }

  @override
  String searchPageFilterState(String state) {
    return 'State: $state';
  }

  @override
  String searchPageFilterCountry(String country) {
    return 'Country: $country';
  }

  @override
  String get searchPageEmptyHint => 'Search by name, email or location';

  @override
  String get searchPageNoResults => 'No users found';

  @override
  String get searchPageErrorOccurred => 'An error occurred while searching';

  @override
  String get searchPageCityLabel => 'City';

  @override
  String get searchPageStateLabel => 'State / Region';

  @override
  String get searchPageCountryLabel => 'Country';

  @override
  String get searchPageClear => 'Clear';

  @override
  String get searchPageApply => 'Apply';

  @override
  String get addCardProfilePhotoSourceTitle => 'Profile photo';

  @override
  String get addCardFrontSourceTitle => 'Card front';

  @override
  String get addCardBackSourceTitle => 'Card back';

  @override
  String get addCardOcrNoTextFound => 'Couldn\'t read any text from that photo. Try better lighting, or fill the form in yourself.';

  @override
  String get addCardScannedDetailsAdded => 'Scanned details added. Check them before saving.';

  @override
  String get addCardScanFailed => 'Could not scan that photo. Please try again.';

  @override
  String addCardCouldNotOpenSource(String source) {
    return 'Could not open the $source.';
  }

  @override
  String get addCardSourceCamera => 'camera';

  @override
  String get addCardSourceGallery => 'gallery';

  @override
  String addCardInvalidEmail(String email) {
    return 'Invalid email: $email';
  }

  @override
  String get addCardPhoneTooShort => 'Each phone must be at least 6 characters';

  @override
  String get addCardUpdateFailed => 'Failed to update card';

  @override
  String get addCardCreateFailed => 'Failed to create card';

  @override
  String get addCardEditTitle => 'Edit Business Card';

  @override
  String get addCardAddTitle => 'Add Business Card';

  @override
  String get addCardPersonalInfoTitle => 'Personal info';

  @override
  String get addCardPersonalInfoSubtitleOwn => 'Your photo, name, and role as others see them';

  @override
  String get addCardPersonalInfoSubtitleOther => 'The name and role printed on the card';

  @override
  String get addCardFullNameLabel => 'Full name';

  @override
  String get addCardFullNameHint => 'e.g. John Doe';

  @override
  String get addCardPositionLabel => 'Position';

  @override
  String get addCardPositionHint => 'e.g. Software Engineer';

  @override
  String get addCardCompanySectionTitle => 'Company';

  @override
  String get addCardCompanySectionSubtitle => 'Links this card to a company record';

  @override
  String get addCardContactDetailsTitle => 'Contact details';

  @override
  String get addCardContactDetailsSubtitle => 'Separate several entries with commas';

  @override
  String get addCardPhonesLabel => 'Phones';

  @override
  String get addCardPhonesHint => 'e.g. 998991112233, ...';

  @override
  String get addCardEmailsLabel => 'Emails';

  @override
  String get addCardEmailsHint => 'e.g. mail@example.com, ...';

  @override
  String get addCardAddressesTitle => 'Addresses';

  @override
  String get addCardAddressesSubtitle => 'Where this person works';

  @override
  String get addCardMoreTitle => 'More';

  @override
  String get addCardMoreSubtitle => 'Anything worth remembering about this contact';

  @override
  String get addCardBioLabel => 'Bio';

  @override
  String get addCardBioHint => 'Short description...';

  @override
  String get addCardYourCardPhotosTitle => 'Your card photos';

  @override
  String get addCardCardPhotosTitle => 'Card photos';

  @override
  String get addCardPhotosSubtitleHasFront => 'Tap a photo to replace it. Scanning only fills empty fields.';

  @override
  String get addCardPhotosSubtitleOwnEmpty => 'Add both sides of your printed card so people can see the real thing.';

  @override
  String get addCardPhotosSubtitleOtherEmpty => 'Add a photo of the card to fill this form automatically.';

  @override
  String get addCardReading => 'Reading…';

  @override
  String get addCardRescan => 'Rescan';

  @override
  String get addCardFrontLabel => 'Front';

  @override
  String get addCardBackLabel => 'Back';

  @override
  String get addCardChangeProfilePhoto => 'Change profile photo';

  @override
  String get addCardAddProfilePhoto => 'Add a profile photo';

  @override
  String get addCardProfilePhotoHelp => 'Shown at the top of your card and next to your name in search results.';

  @override
  String get addCardOptional => 'Optional';

  @override
  String get addCardRequiredToScan => 'Required to scan';

  @override
  String addCardFilingCompany(String name) {
    return 'Filing \"$name\"…';
  }

  @override
  String addCardAddedNewCompany(String name) {
    return 'Added \"$name\" as a new company. Its industry and business type can be filled in any time.';
  }

  @override
  String addCardMatchedCompany(String name) {
    return 'Matched \"$name\" to a company already on file.';
  }

  @override
  String addCardScannedPickCompany(String name) {
    return 'Scanned \"$name\" — pick the matching company';
  }

  @override
  String get addCardChoose => 'Choose';

  @override
  String get addCardChange => 'Change';

  @override
  String get addCardScannedBadge => 'Scanned';

  @override
  String addCardAddressNumber(int number) {
    return 'Address $number';
  }

  @override
  String get addCardStreetLabel => 'Street';

  @override
  String get addCardStreetHint => 'e.g. 123 Main St';

  @override
  String get addCardCityLabel => 'City';

  @override
  String get addCardCityHint => 'e.g. Yangon';

  @override
  String get addCardCityRequired => 'City is required';

  @override
  String get addCardStateLabel => 'State / Region';

  @override
  String get addCardPostalCodeLabel => 'Postal Code';

  @override
  String get addCardCountryLabel => 'Country';

  @override
  String get addCardCountryHint => 'e.g. Myanmar';

  @override
  String get addCardCountryRequired => 'Country is required';

  @override
  String get addCardAddAddress => 'Add address';

  @override
  String get addCardSelectedCompanyLabel => 'Selected company';

  @override
  String get addCardChooseCompany => 'Choose a company';

  @override
  String get addCardSaveChanges => 'Save changes';

  @override
  String get addCardCreateCard => 'Create card';

  @override
  String setupProfileImageSourceError(String source) {
    return 'Could not open the $source.';
  }

  @override
  String get setupProfileSourceCamera => 'camera';

  @override
  String get setupProfileSourceGallery => 'gallery';

  @override
  String get setupProfileImageSheetTitle => 'Profile photo';

  @override
  String get setupProfileImageSheetSubtitle => 'This is the face people see when they find your card.';

  @override
  String get setupProfileFrontSheetTitle => 'Front of your card';

  @override
  String get setupProfileBackSheetTitle => 'Back of your card';

  @override
  String get setupProfileFrontSheetSubtitle => 'We read it and fill in the details below.';

  @override
  String get setupProfileBackSheetSubtitle => 'Often where the address and extra numbers live.';

  @override
  String get setupProfileOcrEmptyError => 'Couldn\'t read that photo. Try better lighting, or type the details in yourself.';

  @override
  String get setupProfileOcrFilledMessage => 'Filled in what we could read. Check it before saving.';

  @override
  String get setupProfileOcrError => 'Could not scan that photo. Please try again.';

  @override
  String get setupProfileFinishLaterMessage => 'You can finish your card any time from the menu.';

  @override
  String get setupProfileSavedMessage => 'Your card is ready. Share it any time from the QR button.';

  @override
  String get setupProfileSaveError => 'Could not save your card. Please try again.';

  @override
  String get setupProfileYourCardLabel => 'Your card';

  @override
  String get setupProfileAccountCreated => 'Account created';

  @override
  String get setupProfileHeadline => 'Complete your card';

  @override
  String get setupProfileSubhead => 'This is what people see when they scan you. Everything here is optional.';

  @override
  String get setupProfileSaveButton => 'Save My Card';

  @override
  String get setupProfileSkipButton => 'Skip for now';

  @override
  String get setupProfilePhotosTitle => 'Your printed card';

  @override
  String get setupProfilePhotosCaption => 'Photograph the front and we read it into the form below.';

  @override
  String get setupProfileReadingLabel => 'READING';

  @override
  String get setupProfileRescanLabel => 'RESCAN';

  @override
  String get setupProfileFrontLabel => 'Front';

  @override
  String get setupProfileBackLabel => 'Back';

  @override
  String get setupProfileProfileTitle => 'Profile';

  @override
  String get setupProfilePhotoAdded => 'PHOTO ADDED';

  @override
  String get setupProfileAddPhoto => 'ADD A PHOTO';

  @override
  String get setupProfilePositionHint => 'Position — e.g. Product Designer';

  @override
  String get setupProfilePhoneHint => 'Phone number';

  @override
  String get setupProfilePhoneMinLength => 'Phone must be at least 6 digits';

  @override
  String get setupProfileCompanyPlaceholder => 'Company (optional)';

  @override
  String get setupProfileChangeLabel => 'Change';

  @override
  String get setupProfileChooseLabel => 'Choose';

  @override
  String get setupProfileFillsFormHint => 'Fills the form';

  @override
  String get otpPageEnterSixDigits => 'Please enter all 6 digits';

  @override
  String get otpPageVerifiedMessage => 'OTP verified';

  @override
  String get otpPageGenericError => 'Something went wrong';

  @override
  String get otpPageResentMessage => 'OTP resent';

  @override
  String get otpPageResendFailed => 'Failed to resend OTP';

  @override
  String get otpPageTagline => 'Enter the code we sent to verify it\'s you.';

  @override
  String get otpPageTitle => 'Verify OTP';

  @override
  String get otpPageSentCodeTo => 'We sent a 6-digit code to';

  @override
  String get otpPageResendNow => 'Resend OTP';

  @override
  String otpPageResendAfter(String time) {
    return 'Resend available after $time';
  }

  @override
  String get otpPageFooterTip => 'Don\'t share your OTP with anyone. This code expires in 5 minutes.';

  @override
  String get otpPageChangeEmail => 'Change email';

  @override
  String get otpPageLoadingWait => 'Please wait...';

  @override
  String get completeRegisterStepLabel => 'Account details';

  @override
  String get completeRegisterStepCompleted => 'Email verified';

  @override
  String get completeRegisterHeadline => 'Finish your account';

  @override
  String get completeRegisterSubhead => 'Two fields and a password. Your card comes next.';

  @override
  String get completeRegisterCreateAccount => 'Create My Account';

  @override
  String get completeRegisterTerms => 'By continuing you agree to our Terms & Privacy.';

  @override
  String get completeRegisterWhoYouAre => 'Who you are';

  @override
  String get completeRegisterFullNameHint => 'Full name';

  @override
  String get completeRegisterFullNameRequired => 'Full name is required';

  @override
  String get completeRegisterFullNameTooShort => 'Enter at least 2 characters';

  @override
  String get completeRegisterSetPassword => 'Set a password';

  @override
  String get completeRegisterPasswordCaption => 'At least 6 characters. Longer is better.';

  @override
  String get completeRegisterPasswordHint => 'Password';

  @override
  String get completeRegisterPasswordRequired => 'Password is required';

  @override
  String get completeRegisterPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get completeRegisterConfirmPasswordHint => 'Confirm password';

  @override
  String get completeRegisterConfirmPasswordRequired => 'Please confirm your password';

  @override
  String get completeRegisterPasswordMismatch => 'Passwords don\'t match';

  @override
  String get completeRegisterVerified => 'VERIFIED';

  @override
  String get completeRegisterShowPassword => 'Show password';

  @override
  String get completeRegisterHidePassword => 'Hide password';

  @override
  String get completeRegisterStrengthTooShort => 'Too short';

  @override
  String get completeRegisterStrengthWeak => 'Weak';

  @override
  String get completeRegisterStrengthGood => 'Good';

  @override
  String get completeRegisterStrengthStrong => 'Strong';

  @override
  String get completeRegisterFailed => 'Registration failed';

  @override
  String get friendRequestsAcceptedToast => 'Friend request accepted';

  @override
  String get friendRequestsAcceptFailed => 'Failed to accept request';

  @override
  String get friendRequestsRejectedToast => 'Friend request rejected';

  @override
  String get friendRequestsRejectFailed => 'Failed to reject request';

  @override
  String get friendRequestsTitle => 'Friend Requests';

  @override
  String get friendRequestsEmpty => 'No pending friend requests';

  @override
  String get friendRequestsJustNow => 'Just now';

  @override
  String friendRequestsMinutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String friendRequestsHoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String friendRequestsDaysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get friendRequestsDefaultSubtitle => 'Requested to add you';

  @override
  String get friendRequestsNowFriends => 'You are now friends';

  @override
  String get friendRequestsReject => 'Reject';

  @override
  String get friendRequestsAccept => 'Accept';

  @override
  String get companyDetailContactDetails => 'Contact Details';

  @override
  String get companyDetailAboutCompany => 'About Company';

  @override
  String get companyDetailSocialPresence => 'Social Presence';

  @override
  String get companyDetailGeneralFallback => 'General';

  @override
  String get companyDetailCorporateFallback => 'Corporate';

  @override
  String get companyFormSaveFailed => 'Failed to save company details';

  @override
  String get companyFormEditTitle => 'Edit Company';

  @override
  String get companyFormNewTitle => 'New Company';

  @override
  String get companyFormProfileTitle => 'Company Profile';

  @override
  String get companyFormProfileSubtitle => 'Fill in the details below to create a premium business profile.';

  @override
  String get companyFormNameLabel => 'Company Name *';

  @override
  String get companyFormNameRequired => 'Name is required';

  @override
  String get companyFormIndustryLabel => 'Industry *';

  @override
  String get companyFormFieldRequired => 'Required';

  @override
  String get companyFormTypeLabel => 'Type *';

  @override
  String get companyFormDescriptionLabel => 'Description';

  @override
  String get companyFormContactInfo => 'Contact Information';

  @override
  String get companyFormAddressLabel => 'Physical Address';

  @override
  String get companyFormWebsiteLabel => 'Website URL';

  @override
  String get companyFormPhoneLabel => 'Phone';

  @override
  String get companyFormEmailLabel => 'Email';

  @override
  String get companyFormUpdateButton => 'UPDATE COMPANY';

  @override
  String get companyFormCreateButton => 'CREATE COMPANY';

  @override
  String get saveToGalleryAccessDenied => 'Allow photo access in Settings to save images.';

  @override
  String get saveToGallerySuccess => 'Saved to gallery';

  @override
  String get saveToGalleryError => 'Could not save image. Please try again.';
}
