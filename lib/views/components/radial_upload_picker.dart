import 'package:flutter/material.dart';

import '../../services/share_target_resolver.dart';
import '../../utils/build_favicon.dart';

class RadialUploaderPicker extends StatelessWidget {
  final List<ShareTarget> targets;
  final ShareTarget? defaultShare;
  final void Function(ShareTarget) onSelected;

  const RadialUploaderPicker({
    super.key,
    required this.targets,
    required this.onSelected,
    this.defaultShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.black.withOpacity(0.65),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: targets.map((target) {
                final isDefault = target == defaultShare;

                final label = _labelFor(target);
                final icon = _iconFor(target);

                return Semantics(
                  label: label,
                  button: true,
                  selected: isDefault,
                  child: InkResponse(
                    onTap: () => onSelected(target),
                    radius: 48,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.surface,
                            border: isDefault
                                ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 3,
                            )
                                : null,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: icon,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 90,
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  String _labelFor(ShareTarget target) {
    String removeProtocol(String url) => url.replaceAll(RegExp(r'^[a-zA-Z]+:\/\/'), '');
    if (target.http != null) {
      return removeProtocol(target.http!.uploaderUrl);
    }
    if (target.network != null) {
      return removeProtocol(target.network!.domain);
    }
    return 'Unknown';
  }

  Widget _iconFor(ShareTarget target) {
    if (target.http != null) {
      return buildFaviconImage(target.http!.uploaderUrl);
    }
    if (target.network != null) {
      return buildFaviconImage(target.network!.domain ?? "");
    }
    return const Icon(Icons.public);
  }
}
