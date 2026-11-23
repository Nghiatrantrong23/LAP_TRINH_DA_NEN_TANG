import 'member.dart';

class LoginResponse {
  final String token, refreshToken;
  final DateTime expiresAt;
  final Member member;
  const LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
    required this.member,
  });
  factory LoginResponse.fromMap(Map<String, dynamic> map) => LoginResponse(
    token: map['token'],
    refreshToken: map['refreshToken'],
    expiresAt: DateTime.parse(map['expiresAt']),
    member: Member.fromMap(map['member']),
  );
}
