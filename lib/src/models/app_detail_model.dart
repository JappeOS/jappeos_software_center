import 'app_model.dart';

class AppLink {
  final String label;
  final String url;

  const AppLink({required this.label, required this.url});
}

class AppDetailModel {
  final AppModel app;
  final String sourceLabel;
  final String sourceKey;
  final String longDescription;
  final String? developer;
  final String? license;
  final String? ageRating;
  final int? downloadCount;
  final int? installedSizeBytes;
  final int? downloadSizeBytes;
  final DateTime? installDate;
  final List<String> screenshots;
  final List<AppLink> links;
  final Map<String, String> extraInfo;

  const AppDetailModel({
    required this.app,
    required this.sourceLabel,
    required this.sourceKey,
    required this.longDescription,
    required this.developer,
    required this.license,
    required this.ageRating,
    required this.downloadCount,
    required this.installedSizeBytes,
    required this.downloadSizeBytes,
    required this.installDate,
    required this.screenshots,
    required this.links,
    required this.extraInfo,
  });
}
