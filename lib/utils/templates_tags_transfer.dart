import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/utils/file_layer.dart';
import 'package:share_plus/share_plus.dart';

const String _tagsFileType = "daily_you_tags";
const String _templatesFileType = "daily_you_templates";
const int _transferFileVersion = 1;

class TemplatesTagsTransfer {
  static Map<String, dynamic> _serializeCategory(TagCategory category) {
    return {
      "name": category.name,
      "icon": category.icon,
      "iconType": category.iconType.name,
      "color": category.color,
    };
  }

  static Map<String, dynamic> _serializeTag(
      Tag tag, Map<int?, TagCategory> categoriesById) {
    return {
      "name": tag.name,
      "tagType": tag.tagType.name,
      "icon": tag.icon,
      "iconType": tag.iconType.name,
      "color": tag.color,
      "categoryName": categoriesById[tag.categoryId]?.name,
    };
  }

  static Uint8List _encode(Map<String, dynamic> data) {
    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }

  static Uint8List exportTags(Set<int> selectedTagIds) {
    final tags = TagsProvider.instance.tags
        .where((tag) => selectedTagIds.contains(tag.id))
        .toList();
    final categoryIds =
        tags.map((tag) => tag.categoryId).whereType<int>().toSet();
    final categories = TagsProvider.instance.categories
        .where((category) => categoryIds.contains(category.id))
        .toList();
    final categoriesById = {
      for (final category in categories) category.id: category,
    };

    final data = {
      "type": _tagsFileType,
      "version": _transferFileVersion,
      "categories": [
        for (final category in categories) _serializeCategory(category),
      ],
      "tags": [
        for (final tag in tags) _serializeTag(tag, categoriesById),
      ],
    };

    return _encode(data);
  }

  static Uint8List exportTemplates(Set<int> selectedTemplateIds) {
    final templates = TemplatesProvider.instance.templates
        .where((template) => selectedTemplateIds.contains(template.id))
        .toList();

    final tagIds = <int>{};
    for (final template in templates) {
      for (final templateTag
          in TagsProvider.instance.getTemplateTagsForTemplate(template.id!)) {
        tagIds.add(templateTag.tagId);
      }
    }
    final tags = TagsProvider.instance.tags
        .where((tag) => tagIds.contains(tag.id))
        .toList();
    final tagsById = {for (final tag in tags) tag.id: tag};

    final categoryIds =
        tags.map((tag) => tag.categoryId).whereType<int>().toSet();
    final categories = TagsProvider.instance.categories
        .where((category) => categoryIds.contains(category.id))
        .toList();
    final categoriesById = {
      for (final category in categories) category.id: category,
    };

    final data = {
      "type": _templatesFileType,
      "version": _transferFileVersion,
      "categories": [
        for (final category in categories) _serializeCategory(category),
      ],
      "tags": [
        for (final tag in tags) _serializeTag(tag, categoriesById),
      ],
      "templates": [
        for (final template in templates)
          {
            "name": template.name,
            "text": template.text,
            "tagNames": TagsProvider.instance
                .getTemplateTagsForTemplate(template.id!)
                .map((templateTag) => tagsById[templateTag.tagId]?.name)
                .whereType<String>()
                .toList(),
          },
      ],
    };

    return _encode(data);
  }

  static Future<bool> saveBytesToFile(
      Uint8List bytes, String fileName, Function(String) updateStatus) async {
    updateStatus("0%");

    try {
      final saveDirectory = await FileLayer.pickDirectory();
      if (saveDirectory == null) return false;

      updateStatus("50%");

      final createdFile =
          await FileLayer.createFile(saveDirectory, fileName, bytes);

      updateStatus("100%");
      return createdFile != null;
    } catch (e) {
      updateStatus("$e");
      await Future.delayed(Duration(seconds: 5));
      return false;
    }
  }

  static Future<void> shareBytes(Uint8List bytes, String fileName) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, mimeType: "application/json")],
      fileNameOverrides: [fileName],
    ));
  }

  static Future<bool> importTransferFile(Function(String) updateStatus) async {
    updateStatus("0%");

    try {
      final selectedFile = await FileLayer.pickFile(
          allowedExtensions: ['json'], mimeTypes: ['application/json']);
      if (selectedFile == null) return false;

      final bytes = await FileLayer.getFileBytes(selectedFile);
      if (bytes == null) return false;

      final jsonData = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (jsonData['type'] != _tagsFileType &&
          jsonData['type'] != _templatesFileType) {
        return false;
      }

      updateStatus("25%");

      final categoryIdByName = <String, int>{
        for (final category in TagsProvider.instance.categories)
          category.name: category.id!,
      };
      for (final rawCategory in (jsonData['categories'] as List? ?? [])) {
        final categoryJson = rawCategory as Map<String, dynamic>;
        final name = categoryJson['name'] as String;
        if (categoryIdByName.containsKey(name)) continue;
        final created = await TagsProvider.instance.addCategory(TagCategory(
          name: name,
          icon: categoryJson['icon'] as String?,
          iconType:
              TagIconType.values.byName(categoryJson['iconType'] as String),
          color: categoryJson['color'] as int?,
          timeCreate: DateTime.now(),
          timeModified: DateTime.now(),
        ));
        categoryIdByName[name] = created.id!;
      }

      updateStatus("50%");

      final tagIdByName = <String, int>{
        for (final tag in TagsProvider.instance.tags) tag.name: tag.id!,
      };
      for (final rawTag in (jsonData['tags'] as List? ?? [])) {
        final tagJson = rawTag as Map<String, dynamic>;
        final name = tagJson['name'] as String;
        if (tagIdByName.containsKey(name)) continue;
        final categoryName = tagJson['categoryName'] as String?;
        await TagsProvider.instance.add(Tag(
          categoryId:
              categoryName != null ? categoryIdByName[categoryName] : null,
          icon: tagJson['icon'] as String?,
          iconType: TagIconType.values.byName(tagJson['iconType'] as String),
          name: name,
          tagType: TagType.values.byName(tagJson['tagType'] as String),
          color: tagJson['color'] as int?,
          timeCreate: DateTime.now(),
          timeModified: DateTime.now(),
        ));
        tagIdByName[name] = TagsProvider.instance.tags.last.id!;
      }

      updateStatus("75%");

      for (final rawTemplate in (jsonData['templates'] as List? ?? [])) {
        final templateJson = rawTemplate as Map<String, dynamic>;
        final created = await TemplatesProvider.instance.add(Template(
          name: templateJson['name'] as String,
          text: templateJson['text'] as String?,
          timeCreate: DateTime.now(),
          timeModified: DateTime.now(),
        ));
        final tagNames =
            (templateJson['tagNames'] as List? ?? []).cast<String>();
        final tagIds = tagNames
            .map((tagName) => tagIdByName[tagName])
            .whereType<int>()
            .toList();
        if (tagIds.isNotEmpty) {
          await TagsProvider.instance.setTemplateTags(created.id!, tagIds);
        }
      }

      updateStatus("100%");
      return true;
    } catch (e) {
      updateStatus("$e");
      await Future.delayed(Duration(seconds: 5));
      return false;
    }
  }
}
