class Login {
  final String email, password;
  const Login({required this.email, required this.password});
  Map<String, dynamic> toMap() => {'email': email.trim(), 'password': password};
}
