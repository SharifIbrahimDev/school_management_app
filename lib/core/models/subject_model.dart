class SubjectModel {
  final int id;
  final int schoolId;
  final String name;
  final String? code;
  final int? classId;
  final int? teacherId;
  final String? description;
  final String? className;
  final String? teacherName;

  SubjectModel({
    required this.id,
    required this.schoolId,
    required this.name,
    this.code,
    this.classId,
    this.teacherId,
    this.description,
    this.className,
    this.teacherName,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'],
      schoolId: map['school_id'],
      name: map['name'],
      code: map['code'],
      classId: map['class_id'],
      teacherId: map['teacher_id'],
      description: map['description'],
      className: map['academic_class']?['class_name'], // Relationship name from Controller
      teacherName: map['teacher']?['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'code': code,
      'class_id': classId,
      'teacher_id': teacherId,
      'description': description,
    };
  }
}
