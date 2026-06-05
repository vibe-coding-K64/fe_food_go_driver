// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get login => 'Đăng nhập';

  @override
  String get homeTitle => 'Trang chủ';

  @override
  String driverGreeting(String name) {
    return 'Xin chào, $name';
  }

  @override
  String get noOrdersAvailable => 'Chưa có đơn hàng nào quanh bạn';

  @override
  String get noOrdersAvailableDescription =>
      'Hiện chưa có đơn giao hàng nào trong khu vực của bạn. Hãy trực tuyến để nhận đơn mới!';

  @override
  String get loadingOrders => 'Đang tải đơn hàng...';

  @override
  String get acceptingOrder => 'Đang nhận đơn...';

  @override
  String get orderAccepted => 'Đã nhận đơn!';

  @override
  String get acceptOrderFailed => 'Không thể nhận đơn. Vui lòng thử lại.';

  @override
  String km(String value) {
    return '$value km';
  }

  @override
  String currency(String amount) {
    return '$amount VND';
  }

  @override
  String get toggleOnline => 'Bật/tắt trạng thái trực tuyến';

  @override
  String get receivingOrders => 'Đang nhận đơn';

  @override
  String get switchingStatus => 'Đang chuyển...';

  @override
  String get acceptOrder => 'Nhận đơn';

  @override
  String get status => 'Trạng thái';

  @override
  String get wallet => 'Ví';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Trang chủ';

  @override
  String get orders => 'Đơn hàng';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get darkMode => 'Chế độ tối';

  @override
  String get lightMode => 'Chế độ sáng';

  @override
  String get orderDetails => 'Chi tiết đơn hàng';

  @override
  String get pickup => 'Lấy hàng';

  @override
  String get delivery => 'Giao hàng';

  @override
  String get delivered => 'Đã giao';

  @override
  String get cancelled => 'Đã hủy';

  @override
  String get available => 'Sẵn sàng';

  @override
  String get busy => 'Bận';

  @override
  String get online => 'Trực tuyến';

  @override
  String get offline => 'Ngoại tuyến';

  @override
  String get welcomeDriver => 'Chào tài xế!';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Mật khẩu';

  @override
  String get emailRequired => 'Email không được để trống';

  @override
  String get invalidEmail => '�ịa chỉ email không hợp lệ';

  @override
  String get passwordRequired => 'Mật khẩu không được để trống';

  @override
  String get passwordTooShort => 'Mật khẩu phải có ít nhất 6 ký tự';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get loginButton => 'Đăng nhập';

  @override
  String get registerPrompt => 'Đã có tài khoản?';

  @override
  String get registerLink => 'Đăng ký';

  @override
  String get totalOrders => 'Tổng đơn hàng';

  @override
  String get rating => 'Đánh giá';

  @override
  String get changeLanguage => 'Đổi ngôn ngữ';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get accept => 'Chấp nhận';

  @override
  String get reject => 'Từ chối';

  @override
  String get customerName => 'Tên khách hàng';

  @override
  String get pickupAddress => 'Địa chỉ lấy hàng';

  @override
  String get deliveryAddress => 'Địa chỉ giao hàng';

  @override
  String get distance => 'Khoảng cách';

  @override
  String get estimatedTime => 'Thời gian ước tính';

  @override
  String get orderAmount => 'Giá trị đơn hàng';

  @override
  String get earning => 'Thu nhập';

  @override
  String get call => 'Gọi';

  @override
  String get navigate => 'Điều hướng';

  @override
  String get complete => 'Hoàn thành';

  @override
  String get splash => 'Food Go Driver';

  @override
  String get registerTitle => 'Đăng ký Tài xế';

  @override
  String get registerSubtitle => 'Trở thành tài xế Food Go';

  @override
  String get registerFullNameLabel => 'Họ và Tên';

  @override
  String get registerFullNameHint => 'Nhập họ và tên của bạn';

  @override
  String get registerFullNameRequired => 'Họ và tên không được để trống';

  @override
  String get registerFullNameTooShort => 'Họ và tên phải có ít nhất 2 ký tự';

  @override
  String get registerPhoneLabel => 'Số Điện Thoại';

  @override
  String get registerPhoneHint => '0xxx xxx xxx';

  @override
  String get registerPhoneRequired => 'Số điện thoại không được để trống';

  @override
  String get registerInvalidPhone => 'Số điện thoại Việt Nam không hợp lệ';

  @override
  String get registerVehiclePlateLabel => 'Biển Số Xe';

  @override
  String get registerVehiclePlateHint => 'VD: 51A-12345';

  @override
  String get registerVehiclePlateRequired => 'Biển số xe không được để trống';

  @override
  String get registerInvalidVehiclePlate =>
      'Biển số xe không hợp lệ (VD: 51A-12345)';

  @override
  String get registerDriverLicenseLabel => 'Giấy Phép Lái Xe';

  @override
  String get registerDriverLicenseHint => 'VD: A1-123456789';

  @override
  String get registerDriverLicenseRequired =>
      'Giấy phép lái xe không được để trống';

  @override
  String get registerDriverLicenseTooShort => 'Giấy phép lái xe quá ngắn';

  @override
  String get registerPasswordHint => 'Tối thiểu 8 ký tự, có chữ in hoa và số';

  @override
  String get registerPasswordTooShort => 'Mật khẩu phải có ít nhất 8 ký tự';

  @override
  String get registerPasswordNeedUppercase =>
      'Mật khẩu phải chứa ít nhất 1 chữ in hoa';

  @override
  String get registerPasswordNeedNumber =>
      'Mật khẩu phải chứa ít nhất 1 chữ số';

  @override
  String get registerPasswordStrength => 'Yêu cầu về mật khẩu:';

  @override
  String get registerPasswordMinChars => 'Ít nhất 8 ký tự';

  @override
  String get registerPasswordUppercase => 'Ít nhất 1 chữ in hoa';

  @override
  String get registerPasswordNumber => 'Ít nhất 1 chữ số';

  @override
  String get registerConfirmPasswordLabel => 'Xác Nhận Mật Khẩu';

  @override
  String get registerConfirmPasswordHint => 'Nhập lại mật khẩu';

  @override
  String get registerConfirmPasswordRequired => 'Vui lòng xác nhận mật khẩu';

  @override
  String get registerConfirmPasswordMismatch => 'Mật khẩu không khớp';

  @override
  String get registerButton => 'Đăng ký';

  @override
  String get registerSendingOtp => 'Đang gửi mã xác minh...';

  @override
  String get registerSuccess => 'Đăng ký thành công!';

  @override
  String get registerSuccessSubtitle => 'Chào mừng bạn đến Food Go!';

  @override
  String get otpVerificationTitle => 'Xác Minh Email';

  @override
  String otpEmailSent(String email) {
    return 'Chúng tôi đã gửi mã 6 chữ số đến\n$email';
  }

  @override
  String get otpVerifyButton => 'Xác minh';

  @override
  String get otpNoReceive => 'Không nhận được mã? ';

  @override
  String get otpResendButton => 'Gửi lại';

  @override
  String get otpChangeEmail => 'Đổi địa chỉ email';

  @override
  String get otpEnterFullCode => 'Vui lòng nhập đủ 6 chữ số';

  @override
  String get back => 'Quay lại';

  @override
  String get forgotPasswordTitle => 'Quên Mật Khẩu';

  @override
  String get forgotPasswordEmailRequired => 'Email/SĐT không được để trống';

  @override
  String get forgotPasswordInvalidEmailOrPhone => 'Email hoặc SĐT không hợp lệ';

  @override
  String get forgotPasswordStep1Title => 'Tìm Tài Khoản';

  @override
  String get forgotPasswordStep1Subtitle =>
      'Nhập email hoặc số điện thoại đã đăng ký để nhận mã xác minh';

  @override
  String get forgotPasswordEmailLabel => 'Email hoặc Số Điện Thoại';

  @override
  String get forgotPasswordEmailHint => 'driver@example.com hoặc 0xxx xxx xxx';

  @override
  String get forgotPasswordSendOtp => 'Gửi mã OTP';

  @override
  String get forgotPasswordStep2Title => 'Nhập Mã Xác Minh';

  @override
  String forgotPasswordStep2Subtitle(String email) {
    return 'Chúng tôi đã gửi mã 6 chữ số đến\n$email';
  }

  @override
  String get forgotPasswordCountdown => 'Mã có hiệu lực trong';

  @override
  String get forgotPasswordVerifyOtp => 'Xác nhận';

  @override
  String get forgotPasswordNoReceive => 'Không nhận được mã? ';

  @override
  String get forgotPasswordResend => 'Gửi lại';

  @override
  String get forgotPasswordStep3Title => 'Đặt Mật Khẩu Mới';

  @override
  String get forgotPasswordStep3Subtitle =>
      'Nhập mật khẩu mới cho tài khoản của bạn';

  @override
  String get forgotPasswordNewPasswordLabel => 'Mật Khẩu Mới';

  @override
  String get forgotPasswordNewPasswordHint => 'Tối thiểu 6 ký tự';

  @override
  String get forgotPasswordPasswordRequired => 'Mật khẩu không được để trống';

  @override
  String get forgotPasswordPasswordTooShort =>
      'Mật khẩu phải có ít nhất 6 ký tự';

  @override
  String get forgotPasswordConfirmPasswordLabel => 'Xác Nhận Mật Khẩu';

  @override
  String get forgotPasswordConfirmPasswordHint => 'Nhập lại mật khẩu mới';

  @override
  String get forgotPasswordConfirmRequired => 'Vui lòng xác nhận mật khẩu';

  @override
  String get forgotPasswordConfirmMismatch => 'Mật khẩu không khớp';

  @override
  String get forgotPasswordResetButton => 'Đổi Mật Khẩu';

  @override
  String get forgotPasswordSuccessTitle => 'Đặt Lại Thành Công!';

  @override
  String get forgotPasswordSuccessMessage =>
      'Mật khẩu của bạn đã được thay đổi thành công. Vui lòng đăng nhập lại.';

  @override
  String get forgotPasswordGoToLogin => 'Đăng Nhập Ngay';

  @override
  String get newOrderRequest => 'Yêu cầu đơn hàng mới';

  @override
  String get decline => 'Từ chối';

  @override
  String get orderDetail => 'Chi tiết đơn hàng';

  @override
  String get pickupFrom => 'Lấy hàng tại';

  @override
  String get deliveredTo => 'Giao đến';

  @override
  String get orderItems => 'Danh sách món';

  @override
  String get paymentMethod => 'Phương thức thanh toán';

  @override
  String get orderNote => 'Ghi chú';

  @override
  String get totalAmount => 'Tổng tiền';

  @override
  String itemsCount(int count) {
    return '$count món';
  }

  @override
  String get confirmPickup => 'Xác nhận đã lấy hàng';

  @override
  String get confirmDelivered => 'Xác nhận đã giao hàng';

  @override
  String get reportIssue => 'Báo sự cố';

  @override
  String get issueReason => 'Lý do báo sự cố';

  @override
  String get orderConfirmed => 'Đã xác nhận lấy hàng';

  @override
  String get orderDelivered => 'Đã giao hàng thành công';

  @override
  String get notifications => 'Thông báo';

  @override
  String get markAllRead => 'Đánh dấu đã đọc tất cả';

  @override
  String get noNotifications => 'Chưa có thông báo nào';

  @override
  String get availableOrders => 'Đơn khả dụng';

  @override
  String get noAvailableOrders => 'Không có đơn hàng nào khả dụng';

  @override
  String get orderTaken => 'Đơn đã được nhận';

  @override
  String get orderDeclined => 'Đã từ chối đơn';

  @override
  String get viewDetail => 'Xem chi tiết';

  @override
  String get tapToViewDetail => 'Nhấn để xem chi tiết';

  @override
  String get withdraw => 'Rút tiền';

  @override
  String get withdrawAmount => 'Số tiền rút';

  @override
  String get minWithdraw => 'Số tiền tối thiểu: 50.000đ';

  @override
  String get confirmWithdraw => 'Xác nhận rút tiền';

  @override
  String get withdrawSuccess => 'Yêu cầu rút tiền thành công!';

  @override
  String get bankInfo => 'Thông tin ngân hàng';

  @override
  String get transactionId => 'Mã giao dịch';

  @override
  String get transactionPending => 'Đang chờ';

  @override
  String get transactionCompleted => 'Hoàn thành';

  @override
  String get transactionFailed => 'Thất bại';

  @override
  String get transactionEarning => 'Thu nhập';

  @override
  String get transactionWithdrawal => 'Rút tiền';

  @override
  String get transactionRefund => 'Hoàn tiền';

  @override
  String get transactionDate => 'Thời gian';

  @override
  String get transactionAmount => 'Số tiền';

  @override
  String get totalWithdrawn => 'Đã rút';

  @override
  String get netAmount => 'Thực nhận';

  @override
  String get withdrawFee => 'Phí rút';

  @override
  String get allTransactions => 'Tất cả giao dịch';

  @override
  String get earnings => 'Thu nhập';

  @override
  String get refunds => 'Hoàn tiền';

  @override
  String get withdrawals => 'Rút tiền';

  @override
  String get noBankLinked => 'Bạn chưa liên kết ngân hàng';

  @override
  String get linkBankNow => 'Liên kết ngay';

  @override
  String get bankAccount => 'Số tài khoản';

  @override
  String get accountHolder => 'Tên chủ tài khoản';

  @override
  String get reasonCantFindAddress => 'Không tìm thấy địa chỉ giao hàng';

  @override
  String get reasonCustomerNotAnswer => 'Khách hàng không nghe máy';

  @override
  String get reasonStoreClosed => 'Cửa hàng đóng cửa / hết hàng';

  @override
  String get reasonTraffic => 'Tắc đường, giao trễ';

  @override
  String get reasonOther => 'Lý do khác';

  @override
  String pickupOrderConfirm(String storeName) {
    return 'Xác nhận đã lấy hàng từ $storeName?';
  }

  @override
  String deliverOrderConfirm(String customerName) {
    return 'Xác nhận đã giao hàng cho $customerName?';
  }

  @override
  String get cancelOrderConfirm => 'Bạn có chắc từ chối đơn hàng này?';

  @override
  String autoDeclineIn(int seconds) {
    return 'Tự động từ chối sau ${seconds}s';
  }

  @override
  String get confirm => 'Xác nhận';

  @override
  String get cancel => 'Hủy';

  @override
  String get totalEarned => 'Tổng thu nhập';

  @override
  String get totalTrips => 'Tổng chuyến';

  @override
  String get completed => 'Hoàn thành';

  @override
  String get delivering => 'Đang giao';

  @override
  String get waitingForOrder => 'Chờ đơn';

  @override
  String get deliveringNow => 'Đang giao';

  @override
  String get pickedUp => 'Đã lấy hàng';

  @override
  String get cancelOrder => 'Hủy đơn';

  @override
  String get confirmCancelOrder => 'Xác nhận hủy đơn';

  @override
  String get confirmCancelOrderMessage =>
      'Bạn có chắc muốn hủy đơn giao hàng này? Hành động này có thể ảnh hưởng đến đánh giá của bạn.';

  @override
  String get allOrders => 'Tất cả';

  @override
  String get transactionHistory => 'Lịch sử giao dịch';

  @override
  String get openMaps => 'Chỉ đường';

  @override
  String get callReceiver => 'Gọi';

  @override
  String get driverInfo => 'Thông tin tài xế';

  @override
  String get earningsToday => 'Thu nhập hôm nay';

  @override
  String get homeAccept => 'Nhận đơn';

  @override
  String get homeDeliveryFee => 'Tiền cước';

  @override
  String get balanceAvailable => 'Số dư khả dụng';

  @override
  String get pendingBalance => 'Đang chờ';

  @override
  String get today => 'Hôm nay';

  @override
  String get recentOrders => 'Đơn gần đây';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get noRecentOrders => 'Chưa có đơn nào';

  @override
  String get todayStats => 'Thống kê hôm nay';

  @override
  String get walletBalance => 'Số dư ví';

  @override
  String get activeOrder => 'Đơn đang giao';

  @override
  String get orderCode => 'Mã đơn';

  @override
  String get phone => 'Điện thoại';

  @override
  String get locationService => 'Dịch vụ vị trí';

  @override
  String get locationServiceDisabled =>
      'Dịch vụ vị trí đang tắt. Vui lòng bật để sử dụng tính năng online.';

  @override
  String get locationPermissionDenied =>
      'Ứng dụng cần quyền truy cập vị trí để hoạt động online.';

  @override
  String get offlinePrompt =>
      'Bật trạng thái Online để bắt đầu nhận đơn giao hàng';

  @override
  String get searchingForOrders => 'Đang tìm kiếm đơn hàng quanh bạn...';

  @override
  String get cancelOrderWarning => 'Cảnh báo: Hủy đơn';

  @override
  String get map => 'Bản đồ';
}
