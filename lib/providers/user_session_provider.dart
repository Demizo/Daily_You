// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/user_dao.dart';
import 'package:daily_you/models/user.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý phiên làm việc của người dùng hiện tại (User Session).
///
/// Hỗ trợ kiểm thử Đa người dùng (Multi-user Testing):
/// Cho phép tạo nhiều tài khoản, chuyển đổi giữa các học viên và tự động
/// đồng bộ dữ liệu tiến độ, lịch sử học tập tương ứng với từng người.
class UserSessionProvider with ChangeNotifier {
  static final UserSessionProvider instance = UserSessionProvider._init();
  UserSessionProvider._init();

  static const String _prefKeyCurrentUserId = 'learning_english_current_user_id';

  User? _currentUser;
  List<User> _allUsers = [];
  bool _isLoaded = false;

  User? get currentUser => _currentUser;
  List<User> get allUsers => List.unmodifiable(_allUsers);
  bool get isLoaded => _isLoaded;
  int get currentUserId => _currentUser?.id ?? 1;

  /// Tải thông tin người dùng từ cơ sở dữ liệu SQLite.
  ///
  /// Nếu chưa có người dùng nào, hệ thống sẽ tự động khởi tạo học viên mặc định.
  Future<void> init() async {
    if (_isLoaded) return;
    await reloadUsers();
    _isLoaded = true;
  }

  /// Làm mới danh sách người dùng từ CSDL.
  Future<void> reloadUsers() async {
    _allUsers = await UserDao.getAll();

    // Nếu CSDL chưa có người dùng nào, tạo sẵn học viên mặc định
    if (_allUsers.isEmpty) {
      final defaultUser = await UserDao.add(User(
        name: 'Học viên Demo (A)',
        email: 'learner.a@dailyyou.edu.vn',
        timeCreate: DateTime.now(),
        timeModified: DateTime.now(),
      ));
      _allUsers = [defaultUser];
    }

    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt(_prefKeyCurrentUserId);

    if (savedId != null) {
      _currentUser = _allUsers.where((u) => u.id == savedId).firstOrNull ??
          _allUsers.first;
    } else {
      _currentUser = _allUsers.first;
    }

    notifyListeners();
  }

  /// Đăng ký thêm một học viên mới và chuyển ngay sang tài khoản này.
  Future<User> registerUser({
    required String name,
    String? email,
    String? authId,
  }) async {
    final now = DateTime.now();
    final newUser = await UserDao.add(User(
      name: name.trim(),
      email: email?.trim().isEmpty == true ? null : email?.trim(),
      authId: authId,
      timeCreate: now,
      timeModified: now,
    ));

    _allUsers = [newUser, ..._allUsers];
    await switchUser(newUser);
    return newUser;
  }

  /// Chuyển đổi sang tài khoản học viên khác.
  Future<void> switchUser(User user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    if (user.id != null) {
      await prefs.setInt(_prefKeyCurrentUserId, user.id!);
    }
    notifyListeners();
  }

  /// Xóa tài khoản học viên (chỉ xóa nếu còn hơn 1 tài khoản).
  Future<bool> deleteUser(int userId) async {
    if (_allUsers.length <= 1) return false;
    await UserDao.remove(userId);
    _allUsers.removeWhere((u) => u.id == userId);
    if (_currentUser?.id == userId) {
      await switchUser(_allUsers.first);
    } else {
      notifyListeners();
    }
    return true;
  }

  /// Cập nhật thông tin học viên.
  Future<void> updateProfile({required String name, String? email}) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copy(
      name: name.trim(),
      email: email?.trim(),
      timeModified: DateTime.now(),
    );
    await UserDao.update(updated);

    final idx = _allUsers.indexWhere((u) => u.id == updated.id);
    if (idx != -1) {
      _allUsers[idx] = updated;
    }
    _currentUser = updated;
    notifyListeners();
  }
}
