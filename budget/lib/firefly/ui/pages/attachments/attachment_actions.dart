import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/resources/attachments_api.dart';
import 'package:budget/firefly/db/attachment_queries.dart';
import 'package:budget/firefly/ui/settings/connection_controller.dart';
import 'package:budget/platform/capabilities.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

enum FireflyAttachmentSource { file, gallery, camera }

typedef FireflyPickedFile = ({
  String name,
  Stream<List<int>> bytes,
  String? mime,
});

/// Platform hooks for picking and opening files; tests replace them.
class FireflyAttachmentActions {
  FireflyAttachmentActions._();

  static List<FireflyAttachmentSource> Function() sources = () => [
        FireflyAttachmentSource.file,
        if (PlatformCapabilities.isMobile) FireflyAttachmentSource.gallery,
        if (PlatformCapabilities.supportsCamera) FireflyAttachmentSource.camera,
      ];

  static Future<FireflyPickedFile?> Function(FireflyAttachmentSource) pick =
      _pick;

  static Future<AttachmentsApi?> Function() api =
      () async => (await FireflySync.resolve())?.engine.context.api.attachments;

  static Future<bool> Function(String path) launch =
      (path) => launchUrl(Uri.file(path));

  static Directory? supportDirectory;
}

Future<FireflyPickedFile?> _pick(FireflyAttachmentSource source) async {
  if (source == FireflyAttachmentSource.file) {
    final result = await FilePicker.platform.pickFiles(withData: kIsWeb);
    final file = result?.files.singleOrNull;
    if (file == null) return null;
    final path = file.path;
    return (
      name: file.name,
      bytes: path == null
          ? Stream.value(List<int>.from(file.bytes ?? const <int>[]))
          : File(path).openRead(),
      mime: null,
    );
  }
  final photo = await ImagePicker().pickImage(
      source: source == FireflyAttachmentSource.camera
          ? ImageSource.camera
          : ImageSource.gallery);
  if (photo == null) return null;
  return (name: photo.name, bytes: photo.openRead(), mime: photo.mimeType);
}

String fireflySourceLabel(FireflyAttachmentSource source) => switch (source) {
      FireflyAttachmentSource.file => 'select-file'.tr(),
      FireflyAttachmentSource.gallery => 'select-photo'.tr(),
      FireflyAttachmentSource.camera => 'take-photo'.tr(),
    };

String fireflyAttachmentError(Object error) {
  if (error is! FireflyAttachmentException) {
    return 'firefly-attachments-error-unavailable'.tr();
  }
  return switch (error.failure) {
    FireflyAttachmentFailure.size => 'firefly-attachments-error-size',
    FireflyAttachmentFailure.integrity => 'firefly-attachments-error-integrity',
    FireflyAttachmentFailure.unavailable =>
      'firefly-attachments-error-unavailable',
    FireflyAttachmentFailure.invalidName => 'firefly-attachments-error-name',
  }
      .tr();
}

String fireflyAttachmentLabel(Attachment row) => row.title ?? row.filename;

String fireflyAttachmentSize(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Fetches the file if needed, then hands it to the platform viewer.
Future<String?> openFireflyAttachmentFile(
    FinanceDatabase db, Attachment row) async {
  try {
    final api = await FireflyAttachmentActions.api();
    final path = api == null
        ? (await FireflyAttachmentFiles(
                    FireflyAttachmentActions.supportDirectory)
                .verified(row))
            .path
        : await db.openFireflyAttachment(row.attachmentPk, api,
            supportDirectory: FireflyAttachmentActions.supportDirectory);
    if (!await FireflyAttachmentActions.launch(path)) {
      return 'firefly-attachments-error-open'.tr();
    }
    return null;
  } catch (error) {
    return fireflyAttachmentError(error);
  }
}
