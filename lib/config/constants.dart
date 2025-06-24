class AppUrl {
  static const String baseUrl = 'https://node-bikerr.onrender.com';

  static const String appBaseUrl = '$baseUrl/api/v1';
  static const String S3_BASE_URL =
      'https://bikerr.s3.eu-north-1.amazonaws.com';

  static const String refreshAccessToken = '$appBaseUrl/auth/refresh-token';
  static const String loginApi = '$appBaseUrl/auth/loginUser';
  static const String registerApi = '$appBaseUrl/auth/createUser';
  static const String verifyEmail = '$appBaseUrl/auth/verifyEmail';
  static const String updateFCM = '$appBaseUrl/users/addtoken';
  static const String forgotPassword = '$appBaseUrl/auth/forgot-Password';
  static const String verifyForgotPasswordOtp =
      '$appBaseUrl/auth/verifyresetPasswordWithOtp';
  static const String resetPassword = '$appBaseUrl/auth/reset-Password';

  //chat api endpoints
  static const String getAllMessagesInAChatRoom = '$appBaseUrl/chats/messages';
  //conversation api
  static const String getAllUserConversations =
      '$appBaseUrl/chats/getUserChatRooms';
  static const String getAllChatRooms = '$appBaseUrl/chats/chatRooms';
  static const String contactsApi = '$appBaseUrl/contacts';
  static const String chatApi = '$appBaseUrl/chat';

  static String generateUploadUrl = '$appBaseUrl/uploads/generate-upload-url';
  static String getChatRoomDetails = '$appBaseUrl/chats/getChatRoomDetail';

  static String sendMessage = '$appBaseUrl/chats/send';
  static String updateLastReadMessages = '$appBaseUrl/chats/updateLastRead';
  static String replyToMessage = '$appBaseUrl/chats/messages/reply';
  static String removeUser = '$appBaseUrl/chats/removeUser';
  static String joinNewChatRoom = '$appBaseUrl/chats/join';

}

class AppLogos {
  static const String lock = 'assets/images/logo_lock.svg';
  static const String user = 'assets/images/logo_user.svg';
  static const String phone = 'assets/images/logo_phone.svg';
  static const String at = 'assets/images/logo_at.svg';
  static const String bikerr = 'assets/images/logo_bikerr.svg';
  static const String bikerrPng = 'assets/images/logo_bikerr.png';
  static const String emailSent = 'assets/images/email_sent.svg';
  static const String autBgDots = 'assets/images/auth_bg_dots.svg';
  static const String arrowBack = 'assets/images/logo_arrow_back.svg';
  static const String profile = 'assets/images/logo_profile.svg';
  static const String drawer = 'assets/images/logo_drawer.svg';
  static const String home = 'assets/images/logo_home.svg';
  static const String rental = 'assets/images/logo_rental.svg';
  static const String track = 'assets/images/logo_track.svg';
  static const String mapMarker = 'assets/images/logo_map_marker.png';
  static const String shop = 'assets/images/logo_shop.svg';
  static const String report = 'assets/images/logo_report.svg';
  static const String notification = 'assets/images/logo_notification.svg';
  static const String notificationsReceived =
      'assets/images/logo_notification_received.svg';
  static const String messages = 'assets/images/logo_message.svg';
  static const String post = 'assets/images/logo_post.svg';
  static const String joinGroup = 'assets/images/logo_join_group.svg';
  static const String search = 'assets/images/logo_search.svg';
  static const String navigation_marker = 'assets/images/logo_navigation_marker.svg';
}

class AppText {
  // In your constants.dart file
  static
  String kDefaultGroupImage = "https://images.pexels.com/photos/2549941/pexels-photo-2549941.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2";
// Or any other default image URL you prefer
  static const String signUP = 'SIGN UP';
  static const String login = 'LOGIN';
  static const String forgotPassword = 'FORGOT PASSWORD';
  static const String verifyOTP = 'Please Enter your OTP';
  static const String resetPassword = 'Please Reset your Password';
}
