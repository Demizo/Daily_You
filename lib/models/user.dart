// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

const String usersTable = 'users';

class UserFields {
  static const List<String> values = [
    id,
    authId,
    name,
    email,
    timeCreate,
    timeModified,
  ];
  static const String id = 'id';
  static const String authId = 'auth_id';
  static const String name = 'name';
  static const String email = 'email';
  static const String timeCreate = 'time_create';
  static const String timeModified = 'time_modified';
}

/// Model lưu thông tin người dùng.
///
/// Hỗ trợ liên kết tài khoản xác thực bên ngoài (Firebase Auth, Supabase Auth)
/// qua trường [authId]. Tuyệt đối không lưu mật khẩu thô dạng văn bản.
class User {
  final int? id;

  /// ID người dùng từ hệ thống Auth ngoài (Firebase UID, Supabase UUID, v.v.).
  /// Có thể null nếu người dùng đang dùng profile local/guest.
  final String? authId;

  final String name;
  final String? email;
  final DateTime timeCreate;
  final DateTime timeModified;

  const User({
    this.id,
    this.authId,
    required this.name,
    this.email,
    required this.timeCreate,
    required this.timeModified,
  });

  static const _unset = Object();

  User copy({
    int? id,
    Object? authId = _unset,
    String? name,
    Object? email = _unset,
    DateTime? timeCreate,
    DateTime? timeModified,
  }) =>
      User(
        id: id ?? this.id,
        authId: authId == _unset ? this.authId : authId as String?,
        name: name ?? this.name,
        email: email == _unset ? this.email : email as String?,
        timeCreate: timeCreate ?? this.timeCreate,
        timeModified: timeModified ?? this.timeModified,
      );

  static User fromJson(Map<String, Object?> json) => User(
        id: json[UserFields.id] as int?,
        authId: json[UserFields.authId] as String?,
        name: json[UserFields.name] as String,
        email: json[UserFields.email] as String?,
        timeCreate: DateTime.parse(json[UserFields.timeCreate] as String),
        timeModified: DateTime.parse(json[UserFields.timeModified] as String),
      );

  Map<String, Object?> toJson() => {
        UserFields.id: id,
        UserFields.authId: authId,
        UserFields.name: name,
        UserFields.email: email,
        UserFields.timeCreate: timeCreate.toIso8601String(),
        UserFields.timeModified: timeModified.toIso8601String(),
      };
}
