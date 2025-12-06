import 'dart:async';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/template_dao.dart';
import 'package:daily_you/models/template.dart';
import 'package:flutter/material.dart';

class TemplatesProvider with ChangeNotifier {
  static final TemplatesProvider instance = TemplatesProvider._init();

  TemplatesProvider._init();

  List<Template> templates = List.empty();

  /// Load the provider's data from the app database
  Future<void> load() async {
    templates = await TemplateDao.getAll();
    notifyListeners();
  }

  // CRUD operations

  Future<void> add(Template template) async {
    // Insert the template into the database so that it has an ID
    final templateWithId = await TemplateDao.add(template);
    templates.add(templateWithId);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> remove(Template template) async {
    await TemplateDao.remove(template.id!);
    templates.removeWhere((x) => x.id == template.id);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> update(Template template) async {
    await TemplateDao.update(template);
    final index = templates.indexWhere((x) => x.id == template.id);
    templates[index] = template.copy();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }
}
