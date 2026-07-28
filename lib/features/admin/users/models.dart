class AdminUser {
  final int id;
  final String email;
  final String name;
  final String role; // ADMIN | PROVIDER | PATIENT
  final String status; // PENDING | APPROVED | REJECTED
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: j['id'] as int,
        email: j['email'] as String,
        name: j['name'] as String,
        role: j['role'] as String,
        status: j['status'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
