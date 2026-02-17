// Note: UserModel import assumes UserModel exists in user_model.dart, 
// if not full implementation might be needed or dynamic mapping

class MessageModel {
  final int id;
  final int senderId;
  final int recipientId;
  final String subject;
  final String body;
  final bool isRead;
  final DateTime? readAt;
  final int? parentMessageId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relationships
  final String? senderName;
  final String? senderRole;
  final String? recipientName;
  final String? recipientRole;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.subject,
    required this.body,
    required this.isRead,
    this.readAt,
    this.parentMessageId,
    required this.createdAt,
    required this.updatedAt,
    this.senderName,
    this.senderRole,
    this.recipientName,
    this.recipientRole,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as int,
      senderId: map['sender_id'] as int,
      recipientId: map['recipient_id'] as int,
      subject: map['subject'] ?? 'No Subject',
      body: map['body'] as String,
      isRead: map['is_read'] == 1 || map['is_read'] == true,
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      parentMessageId: map['parent_message_id'] as int?,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      senderName: map['sender']?['full_name'],
      senderRole: map['sender']?['role'],
      recipientName: map['recipient']?['full_name'],
      recipientRole: map['recipient']?['role'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'subject': subject,
      'body': body,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'parent_message_id': parentMessageId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class UserSelectModel {
  final int id;
  final String name;
  final String role;
  final String email;

  UserSelectModel({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
  });

  factory UserSelectModel.fromMap(Map<String, dynamic> map) {
    return UserSelectModel(
      id: map['id'],
      name: map['full_name'],
      role: map['role'],
      email: map['email'],
    );
  }
}
