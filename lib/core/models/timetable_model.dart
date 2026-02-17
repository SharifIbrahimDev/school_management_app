
class TimetableModel {
  final int id;
  final int classId;
  final int sectionId;
  final int subjectId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  
  // Relations
  final String? className;
  final String? sectionName;
  final String? subjectName;

  TimetableModel({
    required this.id,
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.className,
    this.sectionName,
    this.subjectName,
  });

  factory TimetableModel.fromMap(Map<String, dynamic> map) {
    return TimetableModel(
      id: map['id'],
      classId: map['class_id'],
      sectionId: map['section_id'],
      subjectId: map['subject_id'],
      dayOfWeek: map['day_of_week'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      className: map['class_model']?['name'],
      sectionName: map['section']?['section_name'],
      subjectName: map['subject']?['name'],
    );
  }
}
