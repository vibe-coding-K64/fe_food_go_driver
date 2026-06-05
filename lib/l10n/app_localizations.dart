import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @driverGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String driverGreeting(String name);

  /// No description provided for @noOrdersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No orders available nearby'**
  String get noOrdersAvailable;

  /// No description provided for @noOrdersAvailableDescription.
  ///
  /// In en, this message translates to:
  /// **'There are no delivery orders in your area right now. Stay online to receive new orders!'**
  String get noOrdersAvailableDescription;

  /// No description provided for @loadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Loading orders...'**
  String get loadingOrders;

  /// No description provided for @acceptingOrder.
  ///
  /// In en, this message translates to:
  /// **'Accepting order...'**
  String get acceptingOrder;

  /// No description provided for @orderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted!'**
  String get orderAccepted;

  /// No description provided for @acceptOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept order. Please try again.'**
  String get acceptOrderFailed;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String km(String value);

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'{amount} VND'**
  String currency(String amount);

  /// No description provided for @toggleOnline.
  ///
  /// In en, this message translates to:
  /// **'Toggle online status'**
  String get toggleOnline;

  /// No description provided for @receivingOrders.
  ///
  /// In en, this message translates to:
  /// **'Receiving orders'**
  String get receivingOrders;

  /// No description provided for @switchingStatus.
  ///
  /// In en, this message translates to:
  /// **'Switching...'**
  String get switchingStatus;

  /// No description provided for @acceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get acceptOrder;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @busy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get busy;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @welcomeDriver.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Driver'**
  String get welcomeDriver;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @registerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get registerPrompt;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLink;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vietnamese;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @pickupAddress.
  ///
  /// In en, this message translates to:
  /// **'Pickup Address'**
  String get pickupAddress;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time'**
  String get estimatedTime;

  /// No description provided for @orderAmount.
  ///
  /// In en, this message translates to:
  /// **'Order Amount'**
  String get orderAmount;

  /// No description provided for @earning.
  ///
  /// In en, this message translates to:
  /// **'Earning'**
  String get earning;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @splash.
  ///
  /// In en, this message translates to:
  /// **'Food Go Driver'**
  String get splash;

  /// Title of the registration page
  ///
  /// In en, this message translates to:
  /// **'Driver Registration'**
  String get registerTitle;

  /// Subtitle on the registration page
  ///
  /// In en, this message translates to:
  /// **'Join us as a Food Go driver'**
  String get registerSubtitle;

  /// Label for full name field
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get registerFullNameLabel;

  /// Hint for full name field
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get registerFullNameHint;

  /// Validation message for empty full name
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get registerFullNameRequired;

  /// Validation message for short full name
  ///
  /// In en, this message translates to:
  /// **'Full name must be at least 2 characters'**
  String get registerFullNameTooShort;

  /// Label for phone number field
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get registerPhoneLabel;

  /// Hint for phone number field
  ///
  /// In en, this message translates to:
  /// **'0xxx xxx xxx'**
  String get registerPhoneHint;

  /// Validation message for empty phone
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get registerPhoneRequired;

  /// Validation message for invalid phone format
  ///
  /// In en, this message translates to:
  /// **'Invalid Vietnamese phone number'**
  String get registerInvalidPhone;

  /// Label for vehicle plate field
  ///
  /// In en, this message translates to:
  /// **'Vehicle Plate'**
  String get registerVehiclePlateLabel;

  /// Hint for vehicle plate field
  ///
  /// In en, this message translates to:
  /// **'e.g. 51A-12345'**
  String get registerVehiclePlateHint;

  /// Validation message for empty vehicle plate
  ///
  /// In en, this message translates to:
  /// **'Vehicle plate is required'**
  String get registerVehiclePlateRequired;

  /// Validation message for invalid vehicle plate format
  ///
  /// In en, this message translates to:
  /// **'Invalid vehicle plate (e.g. 51A-12345)'**
  String get registerInvalidVehiclePlate;

  /// Label for driver license field
  ///
  /// In en, this message translates to:
  /// **'Driver License'**
  String get registerDriverLicenseLabel;

  /// Hint for driver license field
  ///
  /// In en, this message translates to:
  /// **'e.g. A1-123456789'**
  String get registerDriverLicenseHint;

  /// Validation message for empty driver license
  ///
  /// In en, this message translates to:
  /// **'Driver license is required'**
  String get registerDriverLicenseRequired;

  /// Validation message for short driver license
  ///
  /// In en, this message translates to:
  /// **'Driver license is too short'**
  String get registerDriverLicenseTooShort;

  /// Hint for password field
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters with uppercase and number'**
  String get registerPasswordHint;

  /// Validation message for short password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get registerPasswordTooShort;

  /// Validation message for missing uppercase in password
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 1 uppercase letter'**
  String get registerPasswordNeedUppercase;

  /// Validation message for missing number in password
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 1 number'**
  String get registerPasswordNeedNumber;

  /// Password strength section title
  ///
  /// In en, this message translates to:
  /// **'Password requirements:'**
  String get registerPasswordStrength;

  /// Password requirement: minimum chars
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get registerPasswordMinChars;

  /// Password requirement: uppercase
  ///
  /// In en, this message translates to:
  /// **'At least 1 uppercase letter'**
  String get registerPasswordUppercase;

  /// Password requirement: number
  ///
  /// In en, this message translates to:
  /// **'At least 1 number'**
  String get registerPasswordNumber;

  /// Label for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get registerConfirmPasswordLabel;

  /// Hint for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get registerConfirmPasswordHint;

  /// Validation message for empty confirm password
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get registerConfirmPasswordRequired;

  /// Validation message for password mismatch
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get registerConfirmPasswordMismatch;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// Loading text when sending OTP
  ///
  /// In en, this message translates to:
  /// **'Sending verification code...'**
  String get registerSendingOtp;

  /// Success message after registration
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registerSuccess;

  /// Subtitle after successful registration
  ///
  /// In en, this message translates to:
  /// **'Welcome to Food Go!'**
  String get registerSuccessSubtitle;

  /// Title of OTP verification dialog
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get otpVerificationTitle;

  /// Message shown after OTP is sent
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to\n{email}'**
  String otpEmailSent(String email);

  /// OTP verify button text
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerifyButton;

  /// Text before resend button
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? '**
  String get otpNoReceive;

  /// OTP resend button text
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get otpResendButton;

  /// Link to change email
  ///
  /// In en, this message translates to:
  /// **'Change email address'**
  String get otpChangeEmail;

  /// Validation message for incomplete OTP
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete 6-digit code'**
  String get otpEnterFullCode;

  /// Back button tooltip
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Title of forgot password page
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// Validation message for empty email
  ///
  /// In en, this message translates to:
  /// **'Email/Phone is required'**
  String get forgotPasswordEmailRequired;

  /// Validation message for invalid email or phone
  ///
  /// In en, this message translates to:
  /// **'Invalid email or phone number'**
  String get forgotPasswordInvalidEmailOrPhone;

  /// Title of step 1 - email input
  ///
  /// In en, this message translates to:
  /// **'Find Account'**
  String get forgotPasswordStep1Title;

  /// Subtitle of step 1
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email or phone number to receive a verification code'**
  String get forgotPasswordStep1Subtitle;

  /// Label for email/phone field
  ///
  /// In en, this message translates to:
  /// **'Email or Phone Number'**
  String get forgotPasswordEmailLabel;

  /// Hint for email/phone field
  ///
  /// In en, this message translates to:
  /// **'driver@example.com or 0xxx xxx xxx'**
  String get forgotPasswordEmailHint;

  /// Button text to send OTP
  ///
  /// In en, this message translates to:
  /// **'Send OTP Code'**
  String get forgotPasswordSendOtp;

  /// Title of step 2 - OTP input
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get forgotPasswordStep2Title;

  /// Subtitle of step 2
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to\n{email}'**
  String forgotPasswordStep2Subtitle(String email);

  /// Countdown label
  ///
  /// In en, this message translates to:
  /// **'Code expires in'**
  String get forgotPasswordCountdown;

  /// Button text to verify OTP
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get forgotPasswordVerifyOtp;

  /// Text before resend button
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? '**
  String get forgotPasswordNoReceive;

  /// Resend OTP button text
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get forgotPasswordResend;

  /// Title of step 3 - new password
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get forgotPasswordStep3Title;

  /// Subtitle of step 3
  ///
  /// In en, this message translates to:
  /// **'Enter a new password for your account'**
  String get forgotPasswordStep3Subtitle;

  /// Label for new password field
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get forgotPasswordNewPasswordLabel;

  /// Hint for new password field
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get forgotPasswordNewPasswordHint;

  /// Validation for empty password
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get forgotPasswordPasswordRequired;

  /// Validation for short password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get forgotPasswordPasswordTooShort;

  /// Label for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get forgotPasswordConfirmPasswordLabel;

  /// Hint for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get forgotPasswordConfirmPasswordHint;

  /// Validation for empty confirm password
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get forgotPasswordConfirmRequired;

  /// Validation for password mismatch
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get forgotPasswordConfirmMismatch;

  /// Button text to reset password
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get forgotPasswordResetButton;

  /// Title of success dialog
  ///
  /// In en, this message translates to:
  /// **'Reset Successful!'**
  String get forgotPasswordSuccessTitle;

  /// Message of success dialog
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed successfully. Please log in again.'**
  String get forgotPasswordSuccessMessage;

  /// No description provided for @forgotPasswordGoToLogin.
  ///
  /// In en, this message translates to:
  /// **'Login Now'**
  String get forgotPasswordGoToLogin;

  /// No description provided for @newOrderRequest.
  ///
  /// In en, this message translates to:
  /// **'New Order Request'**
  String get newOrderRequest;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @orderDetail.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetail;

  /// No description provided for @pickupFrom.
  ///
  /// In en, this message translates to:
  /// **'Pickup from'**
  String get pickupFrom;

  /// No description provided for @deliveredTo.
  ///
  /// In en, this message translates to:
  /// **'Delivered to'**
  String get deliveredTo;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderItems;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @orderNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get orderNote;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @confirmPickup.
  ///
  /// In en, this message translates to:
  /// **'Confirm Pickup'**
  String get confirmPickup;

  /// No description provided for @confirmDelivered.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivered'**
  String get confirmDelivered;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// No description provided for @issueReason.
  ///
  /// In en, this message translates to:
  /// **'Issue Reason'**
  String get issueReason;

  /// No description provided for @orderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order pickup confirmed'**
  String get orderConfirmed;

  /// No description provided for @orderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Order delivered successfully'**
  String get orderDelivered;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @availableOrders.
  ///
  /// In en, this message translates to:
  /// **'Available Orders'**
  String get availableOrders;

  /// No description provided for @noAvailableOrders.
  ///
  /// In en, this message translates to:
  /// **'No available orders'**
  String get noAvailableOrders;

  /// No description provided for @orderTaken.
  ///
  /// In en, this message translates to:
  /// **'Order taken'**
  String get orderTaken;

  /// No description provided for @orderDeclined.
  ///
  /// In en, this message translates to:
  /// **'Order declined'**
  String get orderDeclined;

  /// No description provided for @viewDetail.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetail;

  /// No description provided for @tapToViewDetail.
  ///
  /// In en, this message translates to:
  /// **'Tap to view details'**
  String get tapToViewDetail;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @withdrawAmount.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Amount'**
  String get withdrawAmount;

  /// No description provided for @minWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Minimum: 50,000 VND'**
  String get minWithdraw;

  /// No description provided for @confirmWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Confirm Withdrawal'**
  String get confirmWithdraw;

  /// No description provided for @withdrawSuccess.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request successful!'**
  String get withdrawSuccess;

  /// No description provided for @bankInfo.
  ///
  /// In en, this message translates to:
  /// **'Bank Information'**
  String get bankInfo;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @transactionPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get transactionPending;

  /// No description provided for @transactionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get transactionCompleted;

  /// No description provided for @transactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get transactionFailed;

  /// No description provided for @transactionEarning.
  ///
  /// In en, this message translates to:
  /// **'Earning'**
  String get transactionEarning;

  /// No description provided for @transactionWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get transactionWithdrawal;

  /// No description provided for @transactionRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get transactionRefund;

  /// No description provided for @transactionDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionDate;

  /// No description provided for @transactionAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionAmount;

  /// No description provided for @totalWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Total Withdrawn'**
  String get totalWithdrawn;

  /// No description provided for @netAmount.
  ///
  /// In en, this message translates to:
  /// **'Net Amount'**
  String get netAmount;

  /// No description provided for @withdrawFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get withdrawFee;

  /// No description provided for @allTransactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get allTransactions;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @refunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get refunds;

  /// No description provided for @withdrawals.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals'**
  String get withdrawals;

  /// No description provided for @noBankLinked.
  ///
  /// In en, this message translates to:
  /// **'No bank account linked'**
  String get noBankLinked;

  /// No description provided for @linkBankNow.
  ///
  /// In en, this message translates to:
  /// **'Link Now'**
  String get linkBankNow;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get bankAccount;

  /// No description provided for @accountHolder.
  ///
  /// In en, this message translates to:
  /// **'Account Holder'**
  String get accountHolder;

  /// No description provided for @reasonCantFindAddress.
  ///
  /// In en, this message translates to:
  /// **'Cannot find delivery address'**
  String get reasonCantFindAddress;

  /// No description provided for @reasonCustomerNotAnswer.
  ///
  /// In en, this message translates to:
  /// **'Customer not answering'**
  String get reasonCustomerNotAnswer;

  /// No description provided for @reasonStoreClosed.
  ///
  /// In en, this message translates to:
  /// **'Store closed / out of stock'**
  String get reasonStoreClosed;

  /// No description provided for @reasonTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic, delivery delayed'**
  String get reasonTraffic;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other reasons'**
  String get reasonOther;

  /// No description provided for @pickupOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm pickup from {storeName}?'**
  String pickupOrderConfirm(String storeName);

  /// No description provided for @deliverOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm delivery to {customerName}?'**
  String deliverOrderConfirm(String customerName);

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to decline this order?'**
  String get cancelOrderConfirm;

  /// No description provided for @autoDeclineIn.
  ///
  /// In en, this message translates to:
  /// **'Auto decline in {seconds}s'**
  String autoDeclineIn(int seconds);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @totalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get totalEarned;

  /// No description provided for @totalTrips.
  ///
  /// In en, this message translates to:
  /// **'Total Trips'**
  String get totalTrips;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @delivering.
  ///
  /// In en, this message translates to:
  /// **'Delivering'**
  String get delivering;

  /// No description provided for @waitingForOrder.
  ///
  /// In en, this message translates to:
  /// **'Waiting for order'**
  String get waitingForOrder;

  /// No description provided for @deliveringNow.
  ///
  /// In en, this message translates to:
  /// **'Delivering'**
  String get deliveringNow;

  /// No description provided for @pickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get pickedUp;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @confirmCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancel Order'**
  String get confirmCancelOrder;

  /// No description provided for @confirmCancelOrderMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this delivery? This action may affect your rating.'**
  String get confirmCancelOrderMessage;

  /// No description provided for @allOrders.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allOrders;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @openMaps.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get openMaps;

  /// No description provided for @callReceiver.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callReceiver;

  /// No description provided for @driverInfo.
  ///
  /// In en, this message translates to:
  /// **'Driver Info'**
  String get driverInfo;

  /// No description provided for @earningsToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Earnings'**
  String get earningsToday;

  /// No description provided for @homeAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get homeAccept;

  /// No description provided for @homeDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get homeDeliveryFee;

  /// No description provided for @balanceAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get balanceAvailable;

  /// No description provided for @pendingBalance.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingBalance;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @recentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get recentOrders;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noRecentOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noRecentOrders;

  /// No description provided for @todayStats.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Stats'**
  String get todayStats;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalance;

  /// No description provided for @activeOrder.
  ///
  /// In en, this message translates to:
  /// **'Active Order'**
  String get activeOrder;

  /// No description provided for @orderCode.
  ///
  /// In en, this message translates to:
  /// **'Order Code'**
  String get orderCode;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @locationService.
  ///
  /// In en, this message translates to:
  /// **'Location Service'**
  String get locationService;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location service is disabled. Please enable it to use online features.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to go online.'**
  String get locationPermissionDenied;

  /// No description provided for @offlinePrompt.
  ///
  /// In en, this message translates to:
  /// **'Turn on Online status to start receiving delivery orders'**
  String get offlinePrompt;

  /// No description provided for @searchingForOrders.
  ///
  /// In en, this message translates to:
  /// **'Searching for orders around you...'**
  String get searchingForOrders;

  /// No description provided for @cancelOrderWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: Cancel Order'**
  String get cancelOrderWarning;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
