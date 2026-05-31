import 'package:flutter/material.dart';

import 'common_dialog_widget.dart';

class ShortcutsDialog extends StatelessWidget {
  const ShortcutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Keyboard Shortcuts",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: const [
                  _ShortcutItem("Play / Pause", "Space"),
                  _ShortcutItem("Seek Forward 10s", "Right Arrow"),
                  _ShortcutItem("Seek Backward 10s", "Left Arrow"),
                  _ShortcutItem("Great Seek (30s)", "Ctrl + Arrow"),
                  _ShortcutItem("Volume Up / Down", "Up / Down Arrow"),
                  _ShortcutItem("Mute", "M"),
                  _ShortcutItem("Next Song", "Ctrl + N / Alt + Right"),
                  _ShortcutItem("Previous Song", "Ctrl + P / Alt + Left"),
                  _ShortcutItem("Shuffle", "Ctrl + S"),
                  _ShortcutItem("Loop Mode", "Ctrl + L"),
                  _ShortcutItem("Show Lyrics", "L"),
                  _ShortcutItem("Download Song", "Ctrl + Shift + D"),
                  _ShortcutItem("Share Song", "Ctrl + Shift + S"),
                  _ShortcutItem("Sleep Timer", "Ctrl + T"),
                  _ShortcutItem("Open Player", "Ctrl + Up"),
                  _ShortcutItem("Close Player", "Ctrl + Down / Esc"),
                  _ShortcutItem("Search", "Ctrl + F"),
                  _ShortcutItem("Settings", "Ctrl + ,"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutItem extends StatelessWidget {
  final String action;
  final String keys;

  const _ShortcutItem(this.action, this.keys);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            action,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Text(
              keys,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
