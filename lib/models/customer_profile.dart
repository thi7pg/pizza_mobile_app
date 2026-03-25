class CustomerProfile {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String profileImageUrl;
  final String profileImagePath;
  final String profileImageData;

  const CustomerProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.profileImageUrl,
    required this.profileImagePath,
    required this.profileImageData,
  });

  factory CustomerProfile.fromMap(Map<String, dynamic> data) {
    return CustomerProfile(
      userId: data['userId']?.toString() ?? '',
      fullName: data['fullName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      profileImageUrl: data['profileImageUrl']?.toString() ?? '',
      profileImagePath: data['profileImagePath']?.toString() ?? '',
      profileImageData: data['profileImageData']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'profileImagePath': profileImagePath,
      'profileImageData': profileImageData,
    };
  }
}
