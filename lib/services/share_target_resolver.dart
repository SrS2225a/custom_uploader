import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:collection/collection.dart';
import '../views/components/radial_upload_picker.dart';
import 'database.dart';

class ShareTarget {
  final Share? http;
  final NetworkShare? network;

  ShareTarget.http(this.http) : network = null;
  ShareTarget.network(this.network) : http = null;
}

List<ShareTarget> _getAllUploadTargets() {
  final  targets = <ShareTarget>[];

  final httpBox = Hive.box<Share>("custom_upload");
  for(final s in httpBox.values) {
    targets.add(ShareTarget.http(s));
  }

  final networkBox = Hive.box<NetworkShare>("share_upload");
  for(final s in networkBox.values) {
    targets.add(ShareTarget.network(s));
  }

  return targets;
}

Future<ShareTarget?> _showSharePicker(BuildContext context, List<ShareTarget> targets) async {
  if (targets.isEmpty) return null;
  if (targets.length == 1) return targets.first;

  return await showDialog<ShareTarget>(
    context: context,
    barrierDismissible: true,
    builder: (_) => RadialUploaderPicker(
      targets: targets,
      onSelected: (target) => Navigator.pop(context, target),
    ),
  );
}

Future<(ShareTarget?, bool)> resolveShareTargetIntent(BuildContext context) async {
  final targets = _getAllUploadTargets();
  if (targets.isEmpty) return (null, false);

  final settingsBox = Hive.box(SharePrefs.boxName);
  final askEveryTime = settingsBox.get(
      SharePrefs.keyAskEveryTime, defaultValue: false) as bool;

  // Find previously selected uploader
  if(askEveryTime) {
    final selected = await _showSharePicker(context, targets);
    if (selected != null) {
      final prefs = Hive.box(SharePrefs.boxName);

      if (selected.http != null) {
        prefs.put(SharePrefs.keyLastUploaderType, 'http');
        prefs.put(
          SharePrefs.keyLastUploaderKey,
          selected.http!.key,
        );
      } else if (selected.network != null) {
        prefs.put(SharePrefs.keyLastUploaderType, 'ftp');
        prefs.put(
          SharePrefs.keyLastUploaderKey,
          selected.network!.key,
        );
      }
      return (selected, askEveryTime);
    }
  }
  else {
    ShareTarget? lastSelected;
    final httpBox = Hive.box<Share>("custom_upload");
    final selectedHttp = httpBox.values.firstWhereOrNull((s) =>
    s.selectedUploader);
    if (selectedHttp != null) lastSelected = ShareTarget.http(selectedHttp);

    if (lastSelected == null) {
      final networkBox = Hive.box<NetworkShare>("share_upload");
      final selectedNetwork = networkBox.values.firstWhereOrNull((n) =>
      n.selected);
      if (selectedNetwork != null) {
        lastSelected = ShareTarget.network(selectedNetwork);
      }
    }
    return (lastSelected, askEveryTime);
  }

  return (null, askEveryTime);
}

ShareTarget? resolveShareTargetUI(BuildContext context) {
  ShareTarget? lastSelected;
  final httpBox = Hive.box<Share>("custom_upload");
  final selectedHttp = httpBox.values.firstWhereOrNull((s) =>
  s.selectedUploader);
  if (selectedHttp != null) lastSelected = ShareTarget.http(selectedHttp);

  if (lastSelected == null) {
    final networkBox = Hive.box<NetworkShare>("share_upload");
    final selectedNetwork = networkBox.values.firstWhereOrNull((n) =>
    n.selected);
    if (selectedNetwork != null) {
      lastSelected = ShareTarget.network(selectedNetwork);
    }
  }
  return lastSelected;
}