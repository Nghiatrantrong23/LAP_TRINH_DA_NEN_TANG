class Member {
  final String? memberId;
  final String email;
  final String? password;
  final String givenName;
  final String? surname;
  final String? phone;
  final int roleId;
  final String? roleName;
  final bool isEmailConfirmed;
  final bool isActive;
  final String? createdAt;

  Member({
    this.memberId,
    required this.email,
    this.password,
    required this.givenName,
    this.surname,
    this.phone,
    required this.roleId,
    this.roleName,
    this.isEmailConfirmed = false,
    this.isActive = true,
    this.createdAt,
  });

  String get fullName => surname != null && surname!.isNotEmpty ? '$surname $givenName' : givenName;

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      memberId: map['memberId'] ?? map['maThanhVien'],
      email: map['email'] ?? '',
      givenName: map['givenName'] ?? map['ten'] ?? '',
      surname: map['surname'] ?? map['ho'],
      phone: map['phone'] ?? map['soDienThoai'],
      roleId: map['roleId'] ?? map['maVaiTro'] ?? 2,
      roleName: map['roleName'] ?? map['tenVaiTro'] ?? map['role'],
      isEmailConfirmed: map['isEmailConfirmed'] ?? map['daXacThucEmail'] ?? false,
      isActive: map['isActive'] ?? (map['biKhoa'] != null ? !map['biKhoa'] : true),
      createdAt: (map['createdAt'] ?? map['ngayTao'])?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (memberId != null) 'memberId': memberId,
      'email': email,
      if (password != null) 'password': password,
      'givenName': givenName,
      'surname': surname,
      'phone': phone,
      'roleId': roleId,
    };
  }
}
