class LoginResponse {
  final bool success;
  final String? token;
  final String? refreshToken;
  final String message;
  final String? role;
  final String? email;
  final String? fullName;
  final String? memberId;

  LoginResponse({
    required this.success,
    this.token,
    this.refreshToken,
    required this.message,
    this.role,
    this.email,
    this.fullName,
    this.memberId,
  });

  factory LoginResponse.fromMap(Map<String, dynamic> map) {
    return LoginResponse(
      success: map['success'] ?? false,
      token: map['token'],
      refreshToken: map['refreshToken'],
      message: map['message'] ?? '',
      role: map['role'] ?? map['tenVaiTro'],
      email: map['email'],
      fullName: map['fullName'],
      memberId: map['memberId'] ?? map['maThanhVien'],
    );
  }
}
