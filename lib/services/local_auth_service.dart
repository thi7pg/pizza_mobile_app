class LocalAuthService {
  static String? userEmail;
  static String? userDisplayName;
  static String? userPhone;
  static String? userAddress;

  static bool get isLoggedIn => userEmail != null;

  static void signIn({required String email, String? displayName}) {
    userEmail = email;
    userDisplayName = displayName ?? email;
  }

  static void signOut() {
    userEmail = null;
    userDisplayName = null;
    userPhone = null;
    userAddress = null;
  }

  static void updateProfile({String? displayName, String? phone, String? address}) {
    if (displayName != null) userDisplayName = displayName;
    if (phone != null) userPhone = phone;
    if (address != null) userAddress = address;
  }
}

