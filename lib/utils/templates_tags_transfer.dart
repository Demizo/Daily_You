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

typedef _ItemIdentity = (
  String name,
  String iconType,
  String? icon,
  int? color
);

_ItemIdentity _itemIdentity(
    String name, String iconType, String? icon, int? color) {
  return (name, iconType, icon, color);
}

class TemplatesTagsTransfer {
  static Map<String, dynamic> _serializeCategory(int id, TagCategory category) {
    return {
      "id": id,
      "name": category.name,
      "icon": category.icon,
      "iconType": category.iconType.name,
      "color": category.color,
    };
  }

  static Map<String, dynamic> _serializeTag(
      int id, Tag tag, Map<int, int> categoryIdByDbId) {
    return {
      "id": id,
      "name": tag.name,
      "tagType": tag.tagType.name,
      "icon": tag.icon,
      "iconType": tag.iconType.name,
      "color": tag.color,
      "categoryId":
          tag.categoryId != null ? categoryIdByDbId[tag.categoryId] : null,
    };
  }

  static Uint8List _encode(Map<String, dynamic> data) {
    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }

  static Uint8List exportTags(Set<int> selectedTagIds) {
    final tags = TagsProvider.instance.tags
        .where((tag) => selectedTagIds.contains(tag.id))
        .toList();
    final categoryDbIds =
        tags.map((tag) => tag.categoryId).whereType<int>().toSet();
    final categories = TagsProvider.instance.categories
        .where((category) => categoryDbIds.contains(category.id))
        .toList();
    final categoryIdByDbId = {
      for (var i = 0; i < categories.length; i++) categories[i].id!: i,
    };

    final data = {
      "type": _tagsFileType,
      "version": _transferFileVersion,
      "categories": [
        for (var i = 0; i < categories.length; i++)
          _serializeCategory(i, categories[i]),
      ],
      "tags": [
        for (var i = 0; i < tags.length; i++)
          _serializeTag(i, tags[i], categoryIdByDbId),
      ],
    };

    return _encode(data);
  }

  static Uint8List exportTemplates(Set<int> selectedTemplateIds) {
    final templates = TemplatesProvider.instance.templates
        .where((template) => selectedTemplateIds.contains(template.id))
        .toList();

    final tagDbIds = <int>{};
    for (final template in templates) {
      for (final templateTag
          in TagsProvider.instance.getTemplateTagsForTemplate(template.id!)) {
        tagDbIds.add(templateTag.tagId);
      }
    }
    final tags = TagsProvider.instance.tags
        .where((tag) => tagDbIds.contains(tag.id))
        .toList();
    final tagIdByDbId = {
      for (var i = 0; i < tags.length; i++) tags[i].id!: i,
    };

    final categoryDbIds =
        tags.map((tag) => tag.categoryId).whereType<int>().toSet();
    final categories = TagsProvider.instance.categories
        .where((category) => categoryDbIds.contains(category.id))
        .toList();
    final categoryIdByDbId = {
      for (var i = 0; i < categories.length; i++) categories[i].id!: i,
    };

    final data = {
      "type": _templatesFileType,
      "version": _transferFileVersion,
      "categories": [
        for (var i = 0; i < categories.length; i++)
          _serializeCategory(i, categories[i]),
      ],
      "tags": [
        for (var i = 0; i < tags.length; i++)
          _serializeTag(i, tags[i], categoryIdByDbId),
      ],
      "templates": [
        for (final template in templates)
          {
            "name": template.name,
            "text": template.text,
            "tagIds": TagsProvider.instance
                .getTemplateTagsForTemplate(template.id!)
                .map((templateTag) => tagIdByDbId[templateTag.tagId])
                .whereType<int>()
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

      final categoryIdByIdentity = <_ItemIdentity, int>{
        for (final category in TagsProvider.instance.categories)
          _itemIdentity(category.name, category.iconType.name, category.icon,
              category.color): category.id!,
      };
      final categoryRealIdByFileId = <int, int>{};
      for (final rawCategory in (jsonData['categories'] as List? ?? [])) {
        final categoryJson = rawCategory as Map<String, dynamic>;
        final fileId = categoryJson['id'] as int;
        final name = categoryJson['name'] as String;
        final iconType = categoryJson['iconType'] as String;
        final icon = categoryJson['icon'] as String?;
        final color = categoryJson['color'] as int?;
        final identity = _itemIdentity(name, iconType, icon, color);
        final existingId = categoryIdByIdentity[identity];
        if (existingId != null) {
          categoryRealIdByFileId[fileId] = existingId;
          continue;
        }
        final created = await TagsProvider.instance.addCategory(TagCategory(
          name: name,
          icon: icon,
          iconType: TagIconType.values.byName(iconType),
          color: color,
          timeCreate: DateTime.now(),
          timeModified: DateTime.now(),
        ));
        categoryRealIdByFileId[fileId] = created.id!;
        categoryIdByIdentity[identity] = created.id!;
      }

      updateStatus("50%");

      final tagIdByIdentity = <_ItemIdentity, int>{
        for (final tag in TagsProvider.instance.tags)
          _itemIdentity(tag.name, tag.iconType.name, tag.icon, tag.color):
              tag.id!,
      };
      final tagRealIdByFileId = <int, int>{};
      for (final rawTag in (jsonData['tags'] as List? ?? [])) {
        final tagJson = rawTag as Map<String, dynamic>;
        final fileId = tagJson['id'] as int;
        final name = tagJson['name'] as String;
        final iconType = tagJson['iconType'] as String;
        final icon = tagJson['icon'] as String?;
        final color = tagJson['color'] as int?;
        final identity = _itemIdentity(name, iconType, icon, color);
        final existingId = tagIdByIdentity[identity];
        if (existingId != null) {
          tagRealIdByFileId[fileId] = existingId;
          continue;
        }
        final categoryFileId = tagJson['categoryId'] as int?;
        await TagsProvider.instance.add(Tag(
          categoryId: categoryFileId != null
              ? categoryRealIdByFileId[categoryFileId]
              : null,
          icon: icon,
          iconType: TagIconType.values.byName(iconType),
          name: name,
          tagType: TagType.values.byName(tagJson['tagType'] as String),
          color: color,
          timeCreate: DateTime.now(),
          timeModified: DateTime.now(),
        ));
        final createdId = TagsProvider.instance.tags.last.id!;
        tagRealIdByFileId[fileId] = createdId;
        tagIdByIdentity[identity] = createdId;
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
        final tagFileIds = (templateJson['tagIds'] as List? ?? []).cast<int>();
        final tagIds = tagFileIds
            .map((tagFileId) => tagRealIdByFileId[tagFileId])
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
