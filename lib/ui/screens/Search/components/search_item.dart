import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/ui/screens/Search/search_screen_controller.dart';

import '../../../navigator.dart';

class SearchItem extends StatelessWidget {
  final String queryString;
  final bool isHistoryString;

  const SearchItem({
    super.key,
    required this.queryString,
    required this.isHistoryString,
  });

  @override
  Widget build(BuildContext context) {
    final searchScreenController = Get.find<SearchScreenController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.62);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Get.toNamed(
            ScreenNavigationSetup.searchResultScreen,
            id: ScreenNavigationSetup.id,
            arguments: queryString,
          );
          searchScreenController.addToHistryQueryList(queryString);
          if (GetPlatform.isDesktop) {
            searchScreenController.focusNode.unfocus();
          }
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: isHistoryString
                      ? scheme.onSurface.withValues(alpha: 0.08)
                      : scheme.secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isHistoryString
                      ? Icons.history_rounded
                      : Icons.search_rounded,
                  size: 20,
                  color: isHistoryString ? muted : scheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      queryString,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isHistoryString ? 'Recent search' : 'Search suggestion',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isHistoryString)
                IconButton(
                  tooltip: 'Remove from history',
                  iconSize: 18,
                  splashRadius: 20,
                  visualDensity: const VisualDensity(horizontal: -2),
                  onPressed: () {
                    searchScreenController.removeQueryFromHistory(queryString);
                  },
                  icon: Icon(Icons.close_rounded, color: muted),
                ),
              IconButton(
                tooltip: 'Use suggestion',
                iconSize: 20,
                splashRadius: 20,
                visualDensity: const VisualDensity(horizontal: -2),
                onPressed: () {
                  searchScreenController.suggestionInput(queryString);
                },
                icon: Icon(
                  Icons.arrow_outward_rounded,
                  color: scheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
