class Role {
  final int roleId;
  final String roleName;
  final String? description;

  Role({
    required this.roleId,
    required this.roleName,
    this.description,
  });

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      roleId: map['roleId'] ?? map['maVaiTro'] ?? 0,
      roleName: map['roleName'] ?? map['tenVaiTro'] ?? '',
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maVaiTro': roleId,
      'tenVaiTro': roleName,
    };
  }
}
