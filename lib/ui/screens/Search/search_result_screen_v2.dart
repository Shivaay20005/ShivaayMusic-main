import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shivaaymusic/ui/widgets/loader.dart';
import 'package:shivaaymusic/ui/widgets/search_related_widgets.dart';

import '../../navigator.dart';
import '../../widgets/separate_tab_item_widget.dart';
import 'search_result_screen_controller.dart';

class SearchResultScreenBN extends StatelessWidget {
  const SearchResultScreenBN({super.key});

  @override
  Widget build(BuildContext context) {
    final searchResScrController = Get.find<SearchResultScreenController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final topPadding = context.isLandscape ? 30.0 : 14.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 18, 17),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.onSurface.withValues(alpha: 0.07),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Get.nestedKey(ScreenNavigationSetup.id)!
                            .currentState!
                            .pop();
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Search results',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.secondary.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                searchResScrController.queryString.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.secondary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Search again',
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.onSurface.withValues(alpha: 0.07),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Get.nestedKey(ScreenNavigationSetup.id)!
                            .currentState!
                            .pop();
                      },
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (searchResScrController.searchError.isNotEmpty) {
                    return _ResultsErrorState(
                      message: searchResScrController.searchError.value,
                      onRetry: searchResScrController.retrySearch,
                    );
                  }

                  if (searchResScrController.isResultContentFetced.isTrue &&
                      searchResScrController.railItems.isEmpty) {
                    return _NoResultsState(
                      query: searchResScrController.queryString.value,
                    );
                  }

                  if (!searchResScrController.isResultContentFetced.isTrue) {
                    return const _ResultsLoadingState();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 14, right: 6),
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(alpha: 0.055),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: scheme.onSurface.withValues(alpha: 0.07),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: ButtonsTabBar(
                              onTap: searchResScrController.onDestinationSelected,
                              controller: searchResScrController.tabController,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 17),
                              backgroundColor: scheme.secondary,
                              unselectedBackgroundColor: Colors.transparent,
                              borderWidth: 0,
                              buttonMargin: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                              borderColor: Colors.transparent,
                              labelStyle: TextStyle(
                                color: scheme.onSecondary,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                              unselectedLabelStyle: TextStyle(
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.62),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                              tabs: [
                                Tab(text: 'results'.tr),
                                ...searchResScrController.railItems.map(
                                  (item) => Tab(
                                    text: item.toLowerCase().removeAllWhitespace.tr,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: TabBarView(
                            controller: searchResScrController.tabController,
                            children: [
                              const ResultWidget(isv2Used: true),
                              ...searchResScrController.railItems.map((tabName) {
                                if (tabName == 'Songs' || tabName == 'Videos') {
                                  return SeparateTabItemWidget(
                                    isResultWidget: true,
                                    hideTitle: true,
                                    items: const [],
                                    title: tabName,
                                    isCompleteList: true,
                                    scrollController: searchResScrController
                                        .scrollControllers[tabName],
                                  );
                                }
                                return SeparateTabItemWidget(
                                  title: tabName,
                                  hideTitle: true,
                                  items: const [],
                                  scrollController: searchResScrController
                                      .scrollControllers[tabName],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsLoadingState extends StatelessWidget {
  const _ResultsLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.graphic_eq_rounded, color: scheme.secondary, size: 32),
          ),
          const SizedBox(height: 18),
          const LoadingIndicator(),
          const SizedBox(height: 14),
          Text(
            'Finding your sound...',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsErrorState extends StatelessWidget {
  const _ResultsErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 84,
              width: 84,
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_tethering_error_rounded, color: scheme.secondary, size: 38),
            ),
            const SizedBox(height: 18),
            Text(
              'Search could not load',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.secondary,
                foregroundColor: scheme.onSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 84,
              width: 84,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.music_off_rounded,
                size: 38,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.42),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No music found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Try a different search for “$query”.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
