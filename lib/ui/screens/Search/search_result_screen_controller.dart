import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shivaaymusic/ui/screens/Settings/settings_screen_controller.dart';

import '../../../utils/helper.dart';
import '../Home/home_screen_controller.dart';
import '/services/music_service.dart';
import '/ui/widgets/sort_widget.dart';

class SearchResultScreenController extends GetxController
    with GetTickerProviderStateMixin {
  final navigationRailCurrentIndex = 0.obs;
  final isResultContentFetced = false.obs;
  final isSeparatedResultContentFetced = false.obs;
  final resultContent = <String, dynamic>{}.obs;
  final separatedResultContent = <String, dynamic>{}.obs;
  final searchError = ''.obs;
  final musicServices = Get.find<MusicServices>();
  final queryString = ''.obs;
  final railItems = <String>[].obs;
  final railitemHeight = Get.size.height.obs;
  final additionalParamNext = {};
  bool continuationInProgress = false;
  TabController? tabController;
  bool isTabTransitionReversed = false;
  final Map<String, ScrollController> scrollControllers = {};

  @override
  void onReady() {
    _getInitSearchResult();
    Get.find<HomeScreenController>().whenHomeScreenOnTop();
    super.onReady();
  }

  Future<void> onDestinationSelected(int value,
      {bool ignoreTabCommand = false}) async {
    if (railItems.isEmpty || value < 0 || value > railItems.length) {
      return;
    }

    isTabTransitionReversed = value > navigationRailCurrentIndex.value;
    isSeparatedResultContentFetced.value = false;
    navigationRailCurrentIndex.value = value;

    if (tabController != null && !ignoreTabCommand) {
      tabController?.animateTo(value);
    }

    if (value > 0 &&
        (!separatedResultContent.containsKey(railItems[value - 1]) ||
            separatedResultContent[railItems[value - 1]].isEmpty)) {
      final tabName = railItems[value - 1];
      final itemCount = (tabName == 'Songs' || tabName == 'Videos') ? 25 : 10;
      try {
        final x = await musicServices.search(
          queryString.value,
          filter: tabName.replaceAll(' ', '_').toLowerCase(),
          limit: itemCount,
          filterParams: resultContent['searchEndpoint']?[tabName],
        );
        separatedResultContent[tabName] = x[tabName] ?? [];
        additionalParamNext[tabName] = x['params'];
      } catch (e) {
        printERROR('Search tab error for $tabName: $e');
        separatedResultContent[tabName] = [];
        additionalParamNext[tabName] = null;
      }

      final scrollController = scrollControllers[tabName];
      // ignore: invalid_use_of_protected_member
      if (scrollController != null && !scrollController.hasListeners) {
        scrollController.addListener(() {
          final maxScroll = scrollController.position.maxScrollExtent;
          final currentScroll = scrollController.position.pixels;
          final params = additionalParamNext[tabName];
          if (params is Map &&
              currentScroll >= maxScroll / 2 &&
              params['additionalParams'] != '&ctoken=null&continuation=null' &&
              !continuationInProgress) {
            continuationInProgress = true;
            getContinuationContents();
          }
        });
      }
    }
    isSeparatedResultContentFetced.value = true;
  }

  Future<void> getContinuationContents() async {
    final tabName = railItems[navigationRailCurrentIndex.value - 1];
    try {
      final x = await musicServices.getSearchContinuation(additionalParamNext[tabName]);
      (separatedResultContent[tabName] as List).addAll(x[tabName] ?? []);
      additionalParamNext[tabName] = x['params'];
      separatedResultContent.refresh();
    } catch (e) {
      printERROR('Search continuation error for $tabName: $e');
    } finally {
      continuationInProgress = false;
    }
  }

  void viewAllCallback(String text) {
    final index = railItems.indexOf(text);
    if (index >= 0) {
      onDestinationSelected(index + 1);
    }
  }

  Future<void> retrySearch() => _getInitSearchResult();

  Future<void> _getInitSearchResult() async {
    isResultContentFetced.value = false;
    searchError.value = '';
    navigationRailCurrentIndex.value = 0;
    railItems.clear();
    resultContent.clear();
    separatedResultContent.clear();
    additionalParamNext.clear();
    for (final controller in scrollControllers.values) {
      controller.dispose();
    }
    scrollControllers.clear();
    tabController?.dispose();
    tabController = null;

    dynamic rawArgs = Get.routing.args;
    rawArgs ??= Get.arguments;
    final query = rawArgs is String ? rawArgs.trim() : rawArgs?.toString().trim() ?? '';

    if (query.isEmpty) {
      searchError.value = 'Search query was empty.';
      isResultContentFetced.value = true;
      return;
    }

    queryString.value = query;

    try {
      final response = await musicServices.search(query);
      resultContent.value = Map<String, dynamic>.from(response);

      const predefinedOrder = [
        'Songs',
        'Videos',
        'Albums',
        'Featured playlists',
        'Community playlists',
        'Playlists',
        'Artists',
      ];
      final allKeys = resultContent.keys.where(predefinedOrder.contains);
      railItems.value = List<String>.from(allKeys.toList()
        ..sort((a, b) => predefinedOrder.indexOf(a).compareTo(predefinedOrder.indexOf(b))));

      final len = railItems.where((element) => element.contains('playlists')).length;
      final calH = 30 + (railItems.length + 1 - len) * 123 + len * 150.0;
      railitemHeight.value = calH >= railitemHeight.value ? calH : railitemHeight.value;

      for (final item in railItems) {
        scrollControllers[item] = ScrollController();
      }

      if (GetPlatform.isDesktop ||
          Get.find<SettingsScreenController>().isBottomNavBarEnabled.isTrue) {
        for (final element in railItems) {
          separatedResultContent[element] = [];
        }
        tabController = TabController(length: railItems.length + 1, vsync: this);
        tabController?.animation?.addListener(() {
          final indexChange = tabController!.offset.round();
          final index = tabController!.index + indexChange;
          if (index != navigationRailCurrentIndex.value) {
            onDestinationSelected(index, ignoreTabCommand: true);
          }
        });
      }

      isResultContentFetced.value = true;
      if (railItems.contains('Songs')) {
        final songsIndex = railItems.indexOf('Songs') + 1;
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!isClosed) {
            onDestinationSelected(songsIndex);
          }
        });
      }
    } catch (e) {
      printERROR('Search request failed for "$query": $e');
      searchError.value = 'Unable to load results right now.';
      isResultContentFetced.value = true;
    }
  }

  void onSort(SortType sortType, bool isAscending, String title) {
    if (title == 'Songs' || title == 'Videos') {
      final songList = separatedResultContent[title].toList();
      sortSongsNVideos(songList, sortType, isAscending);
      separatedResultContent[title] = songList;
    } else if (title.contains('playlists')) {
      final playlists = separatedResultContent[title].toList();
      sortPlayLists(playlists, sortType, isAscending);
      separatedResultContent[title] = playlists;
    } else if (title == 'Artists') {
      final artistList = separatedResultContent[title].toList();
      sortArtist(artistList, sortType, isAscending);
      separatedResultContent[title] = artistList;
    } else if (title == 'Albums') {
      final albumList = separatedResultContent[title].toList();
      sortAlbumNSingles(albumList, sortType, isAscending);
      separatedResultContent[title] = albumList;
    }
  }

  @override
  void onClose() {
    for (final item in scrollControllers.values) {
      item.dispose();
    }
    Get.find<HomeScreenController>().whenHomeScreenOnTop();
    tabController?.dispose();
    super.onClose();
  }
}
