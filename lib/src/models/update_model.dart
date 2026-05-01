import 'app_model.dart';

class UpdateModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String sourceKey;
  final String appId;
  final int? downloadSizeBytes;
  final String? version;
  final bool isSystem;
  final AppModel? app;

  const UpdateModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.sourceKey,
    required this.appId,
    required this.downloadSizeBytes,
    required this.version,
    required this.isSystem,
    required this.app,
  });
}
