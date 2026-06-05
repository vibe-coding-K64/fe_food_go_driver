// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get homeTitle => 'Home';

  @override
  String driverGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get noOrdersAvailable => 'No orders available nearby';

  @override
  String get noOrdersAvailableDescription =>
      'There are no delivery orders in your area right now. Stay online to receive new orders!';

  @override
  String get loadingOrders => 'Loading orders...';

  @override
  String get acceptingOrder => 'Accepting order...';

  @override
  String get orderAccepted => 'Order accepted!';

  @override
  String get acceptOrderFailed => 'Failed to accept order. Please try again.';

  @override
  String km(String value) {
    return '$value km';
  }

  @override
  String currency(String amount) {
    return '$amount VND';
  }

  @override
  String get toggleOnline => 'Toggle online status';

  @override
  String get receivingOrders => 'Receiving orders';

  @override
  String get switchingStatus => 'Switching...';

  @override
  String get acceptOrder => 'Accept Order';

  @override
  String get status => 'Status';

  @override
  String get wallet => 'Wallet';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Home';

  @override
  String get orders => 'Orders';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get pickup => 'Pickup';

  @override
  String get delivery => 'Delivery';

  @override
  String get delivered => 'Delivered';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get available => 'Available';

  @override
  String get busy => 'Busy';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get welcomeDriver => 'Welcome, Driver';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get loginButton => 'Login';

  @override
  String get registerPrompt => 'Don\'t have an account?';

  @override
  String get registerLink => 'Register';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get rating => 'Rating';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Vietnamese';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get customerName => 'Customer Name';

  @override
  String get pickupAddress => 'Pickup Address';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get distance => 'Distance';

  @override
  String get estimatedTime => 'Estimated Time';

  @override
  String get orderAmount => 'Order Amount';

  @override
  String get earning => 'Earning';

  @override
  String get call => 'Call';

  @override
  String get navigate => 'Navigate';

  @override
  String get complete => 'Complete';

  @override
  String get splash => 'Food Go Driver';

  @override
  String get registerTitle => 'Driver Registration';

  @override
  String get registerSubtitle => 'Join us as a Food Go driver';

  @override
  String get registerFullNameLabel => 'Full Name';

  @override
  String get registerFullNameHint => 'Enter your full name';

  @override
  String get registerFullNameRequired => 'Full name is required';

  @override
  String get registerFullNameTooShort =>
      'Full name must be at least 2 characters';

  @override
  String get registerPhoneLabel => 'Phone Number';

  @override
  String get registerPhoneHint => '0xxx xxx xxx';

  @override
  String get registerPhoneRequired => 'Phone number is required';

  @override
  String get registerInvalidPhone => 'Invalid Vietnamese phone number';

  @override
  String get registerVehiclePlateLabel => 'Vehicle Plate';

  @override
  String get registerVehiclePlateHint => 'e.g. 51A-12345';

  @override
  String get registerVehiclePlateRequired => 'Vehicle plate is required';

  @override
  String get registerInvalidVehiclePlate =>
      'Invalid vehicle plate (e.g. 51A-12345)';

  @override
  String get registerDriverLicenseLabel => 'Driver License';

  @override
  String get registerDriverLicenseHint => 'e.g. A1-123456789';

  @override
  String get registerDriverLicenseRequired => 'Driver license is required';

  @override
  String get registerDriverLicenseTooShort => 'Driver license is too short';

  @override
  String get registerPasswordHint =>
      'Min. 8 characters with uppercase and number';

  @override
  String get registerPasswordTooShort =>
      'Password must be at least 8 characters';

  @override
  String get registerPasswordNeedUppercase =>
      'Password must contain at least 1 uppercase letter';

  @override
  String get registerPasswordNeedNumber =>
      'Password must contain at least 1 number';

  @override
  String get registerPasswordStrength => 'Password requirements:';

  @override
  String get registerPasswordMinChars => 'At least 8 characters';

  @override
  String get registerPasswordUppercase => 'At least 1 uppercase letter';

  @override
  String get registerPasswordNumber => 'At least 1 number';

  @override
  String get registerConfirmPasswordLabel => 'Confirm Password';

  @override
  String get registerConfirmPasswordHint => 'Re-enter your password';

  @override
  String get registerConfirmPasswordRequired => 'Please confirm your password';

  @override
  String get registerConfirmPasswordMismatch => 'Passwords do not match';

  @override
  String get registerButton => 'Register';

  @override
  String get registerSendingOtp => 'Sending verification code...';

  @override
  String get registerSuccess => 'Registration successful!';

  @override
  String get registerSuccessSubtitle => 'Welcome to Food Go!';

  @override
  String get otpVerificationTitle => 'Verify Your Email';

  @override
  String otpEmailSent(String email) {
    return 'We sent a 6-digit code to\n$email';
  }

  @override
  String get otpVerifyButton => 'Verify';

  @override
  String get otpNoReceive => 'Didn\'t receive the code? ';

  @override
  String get otpResendButton => 'Resend';

  @override
  String get otpChangeEmail => 'Change email address';

  @override
  String get otpEnterFullCode => 'Please enter the complete 6-digit code';

  @override
  String get back => 'Back';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordEmailRequired => 'Email/Phone is required';

  @override
  String get forgotPasswordInvalidEmailOrPhone =>
      'Invalid email or phone number';

  @override
  String get forgotPasswordStep1Title => 'Find Account';

  @override
  String get forgotPasswordStep1Subtitle =>
      'Enter your registered email or phone number to receive a verification code';

  @override
  String get forgotPasswordEmailLabel => 'Email or Phone Number';

  @override
  String get forgotPasswordEmailHint => 'driver@example.com or 0xxx xxx xxx';

  @override
  String get forgotPasswordSendOtp => 'Send OTP Code';

  @override
  String get forgotPasswordStep2Title => 'Enter Verification Code';

  @override
  String forgotPasswordStep2Subtitle(String email) {
    return 'We sent a 6-digit code to\n$email';
  }

  @override
  String get forgotPasswordCountdown => 'Code expires in';

  @override
  String get forgotPasswordVerifyOtp => 'Verify';

  @override
  String get forgotPasswordNoReceive => 'Didn\'t receive the code? ';

  @override
  String get forgotPasswordResend => 'Resend';

  @override
  String get forgotPasswordStep3Title => 'Set New Password';

  @override
  String get forgotPasswordStep3Subtitle =>
      'Enter a new password for your account';

  @override
  String get forgotPasswordNewPasswordLabel => 'New Password';

  @override
  String get forgotPasswordNewPasswordHint => 'Minimum 6 characters';

  @override
  String get forgotPasswordPasswordRequired => 'Password is required';

  @override
  String get forgotPasswordPasswordTooShort =>
      'Password must be at least 6 characters';

  @override
  String get forgotPasswordConfirmPasswordLabel => 'Confirm Password';

  @override
  String get forgotPasswordConfirmPasswordHint => 'Re-enter your new password';

  @override
  String get forgotPasswordConfirmRequired => 'Please confirm your password';

  @override
  String get forgotPasswordConfirmMismatch => 'Passwords do not match';

  @override
  String get forgotPasswordResetButton => 'Change Password';

  @override
  String get forgotPasswordSuccessTitle => 'Reset Successful!';

  @override
  String get forgotPasswordSuccessMessage =>
      'Your password has been changed successfully. Please log in again.';

  @override
  String get forgotPasswordGoToLogin => 'Login Now';

  @override
  String get newOrderRequest => 'New Order Request';

  @override
  String get decline => 'Decline';

  @override
  String get orderDetail => 'Order Details';

  @override
  String get pickupFrom => 'Pickup from';

  @override
  String get deliveredTo => 'Delivered to';

  @override
  String get orderItems => 'Order Items';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get orderNote => 'Note';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String get confirmPickup => 'Confirm Pickup';

  @override
  String get confirmDelivered => 'Confirm Delivered';

  @override
  String get reportIssue => 'Report Issue';

  @override
  String get issueReason => 'Issue Reason';

  @override
  String get orderConfirmed => 'Order pickup confirmed';

  @override
  String get orderDelivered => 'Order delivered successfully';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get availableOrders => 'Available Orders';

  @override
  String get noAvailableOrders => 'No available orders';

  @override
  String get orderTaken => 'Order taken';

  @override
  String get orderDeclined => 'Order declined';

  @override
  String get viewDetail => 'View Details';

  @override
  String get tapToViewDetail => 'Tap to view details';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get withdrawAmount => 'Withdraw Amount';

  @override
  String get minWithdraw => 'Minimum: 50,000 VND';

  @override
  String get confirmWithdraw => 'Confirm Withdrawal';

  @override
  String get withdrawSuccess => 'Withdrawal request successful!';

  @override
  String get bankInfo => 'Bank Information';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get transactionPending => 'Pending';

  @override
  String get transactionCompleted => 'Completed';

  @override
  String get transactionFailed => 'Failed';

  @override
  String get transactionEarning => 'Earning';

  @override
  String get transactionWithdrawal => 'Withdrawal';

  @override
  String get transactionRefund => 'Refund';

  @override
  String get transactionDate => 'Date';

  @override
  String get transactionAmount => 'Amount';

  @override
  String get totalWithdrawn => 'Total Withdrawn';

  @override
  String get netAmount => 'Net Amount';

  @override
  String get withdrawFee => 'Fee';

  @override
  String get allTransactions => 'All Transactions';

  @override
  String get earnings => 'Earnings';

  @override
  String get refunds => 'Refunds';

  @override
  String get withdrawals => 'Withdrawals';

  @override
  String get noBankLinked => 'No bank account linked';

  @override
  String get linkBankNow => 'Link Now';

  @override
  String get bankAccount => 'Account Number';

  @override
  String get accountHolder => 'Account Holder';

  @override
  String get reasonCantFindAddress => 'Cannot find delivery address';

  @override
  String get reasonCustomerNotAnswer => 'Customer not answering';

  @override
  String get reasonStoreClosed => 'Store closed / out of stock';

  @override
  String get reasonTraffic => 'Traffic, delivery delayed';

  @override
  String get reasonOther => 'Other reasons';

  @override
  String pickupOrderConfirm(String storeName) {
    return 'Confirm pickup from $storeName?';
  }

  @override
  String deliverOrderConfirm(String customerName) {
    return 'Confirm delivery to $customerName?';
  }

  @override
  String get cancelOrderConfirm =>
      'Are you sure you want to decline this order?';

  @override
  String autoDeclineIn(int seconds) {
    return 'Auto decline in ${seconds}s';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get totalEarned => 'Total Earned';

  @override
  String get totalTrips => 'Total Trips';

  @override
  String get completed => 'Completed';

  @override
  String get delivering => 'Delivering';

  @override
  String get waitingForOrder => 'Waiting for order';

  @override
  String get deliveringNow => 'Delivering';

  @override
  String get pickedUp => 'Picked Up';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get confirmCancelOrder => 'Confirm Cancel Order';

  @override
  String get confirmCancelOrderMessage =>
      'Are you sure you want to cancel this delivery? This action may affect your rating.';

  @override
  String get allOrders => 'All';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get openMaps => 'Navigate';

  @override
  String get callReceiver => 'Call';

  @override
  String get driverInfo => 'Driver Info';

  @override
  String get earningsToday => 'Today\'s Earnings';

  @override
  String get homeAccept => 'Accept Order';

  @override
  String get homeDeliveryFee => 'Delivery Fee';

  @override
  String get balanceAvailable => 'Available Balance';

  @override
  String get pendingBalance => 'Pending';

  @override
  String get today => 'Today';

  @override
  String get recentOrders => 'Recent Orders';

  @override
  String get viewAll => 'View All';

  @override
  String get noRecentOrders => 'No orders yet';

  @override
  String get todayStats => 'Today\'s Stats';

  @override
  String get walletBalance => 'Wallet Balance';

  @override
  String get activeOrder => 'Active Order';

  @override
  String get orderCode => 'Order Code';

  @override
  String get phone => 'Phone';

  @override
  String get locationService => 'Location Service';

  @override
  String get locationServiceDisabled =>
      'Location service is disabled. Please enable it to use online features.';

  @override
  String get locationPermissionDenied =>
      'Location permission is required to go online.';

  @override
  String get offlinePrompt =>
      'Turn on Online status to start receiving delivery orders';

  @override
  String get searchingForOrders => 'Searching for orders around you...';

  @override
  String get cancelOrderWarning => 'Warning: Cancel Order';

  @override
  String get map => 'Map';
}
