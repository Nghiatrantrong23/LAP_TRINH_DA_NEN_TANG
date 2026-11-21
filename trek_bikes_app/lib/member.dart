class Member {
  final String id, email, givenName, surname, role, rowVersion;
  final String? phone;
  final int roleId;
  final bool isLocked, emailConfirmed;
  const Member({
    required this.id,
    required this.email,
    required this.givenName,
    required this.surname,
    required this.role,
    required this.roleId,
    required this.rowVersion,
    this.phone,
    this.isLocked = false,
    this.emailConfirmed = false,
  });
  String get fullName => '$surname $givenName'.trim();
  bool get isAdmin => role == 'Admin';
  factory Member.fromMap(Map<String, dynamic> map) => Member(
    id: map['id'],
    email: map['email'],
    givenName: map['givenName'],
    surname: map['surname'],
    role: map['role'],
    roleId: map['roleId'],
    rowVersion: map['rowVersion'],
    phone: map['phone'],
    isLocked: map['isLocked'],
    emailConfirmed: map['emailConfirmed'],
  );
}
