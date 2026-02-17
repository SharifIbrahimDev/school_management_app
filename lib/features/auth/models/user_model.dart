class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? schoolName;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.schoolName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? schoolNameFromObject;
    if (json['school'] != null && json['school'] is Map) {
      schoolNameFromObject = json['school']['name'];
    }

    return UserModel(
      id: json['id'],
      fullName: json['full_name'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      schoolName: json['school_name'] ?? schoolNameFromObject ?? 'Dayn Academy',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'school_name': schoolName,
    };
  }
}
