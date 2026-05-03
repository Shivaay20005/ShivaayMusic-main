import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '/utils/app_link_controller.dart' show ProcessLink;
import '/services/music_service.dart';
import '/ui/navigator.dart';
import '../../../services/privacy_service.dart';
import '../../../services/cloud_service.dart';

class SearchScreenController extends GetxController with ProcessLink {
  final textInputController = TextEditingController();
  final musicServices = Get.find<MusicServices>();
  final suggestionList = [].obs;
  final historyQuerylist = [].obs;
  late Box<dynamic> queryBox;
  final urlPasted = false.obs;

  // Desktop search bar related
  final focusNode = FocusNode();
  final isSearchBarInFocus = false.obs;
  final isMicAvailable = false.obs;
  final isListening = false.obs;
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  @override
  onInit() {
    _init();
    super.onInit();
  }

  _init() async {
    if(GetPlatform.isDesktop){
      focusNode.addListener((){
        isSearchBarInFocus.value = focusNode.hasFocus;
      });
    }

    if (GetPlatform.isAndroid) {
      await _initializeVoiceSearch();
    }

    queryBox = await Hive.openBox("searchQuery");
    historyQuerylist.value = queryBox.values.toList().reversed.toList();
  }

  Future<void> _initializeVoiceSearch() async {
    isMicAvailable.value = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'listening') {
          isListening.value = true;
        }
        if (status == 'notListening' || status == 'done') {
          isListening.value = false;
        }
      },
      onError: (_) {
        isListening.value = false;
      },
    );
  }

  Future<void> onChanged(String text) async {
    if(text.contains("https://")){
      urlPasted.value = true; 
      return;
    }
    urlPasted.value = false;
    suggestionList.value = await musicServices.getSearchSuggestion(text);
  }

  Future<void> suggestionInput(String txt) async {
    textInputController.text = txt;
    textInputController.selection =
        TextSelection.collapsed(offset: textInputController.text.length);
    await onChanged(txt);
  }

  Future<void> addToHistryQueryList(String txt) async {
    if (historyQuerylist.length > 9) {
      final queryForRemoval = queryBox.getAt(0);
      await queryBox.deleteAt(0);
      historyQuerylist.removeWhere((element) => element == queryForRemoval);
    }
    if (!historyQuerylist.contains(txt)) {
      if (!Get.find<PrivacyService>().isIncognitoMode.value) {
        await queryBox.add(txt);
        historyQuerylist.insert(0, txt);
      }
    }

    if (Get.isRegistered<CloudService>()) {
      Get.find<CloudService>().syncSearchHistory();
    }

    //reset current query and suggestionlist
    reset();
  }

  Future<void> submitSearchQuery(String val) async {
    final text = val.trim();
    if (text.isEmpty) {
      return;
    }

    if (text.contains("https://")) {
      filterLinks(Uri.parse(text));
      reset();
      return;
    }

    Get.toNamed(
      ScreenNavigationSetup.searchResultScreen,
      id: ScreenNavigationSetup.id,
      arguments: text,
    );
    await addToHistryQueryList(text);
  }

  Future<void> toggleVoiceSearch() async {
    if (!GetPlatform.isAndroid) {
      return;
    }

    if (isListening.value) {
      await _speechToText.stop();
      isListening.value = false;
      return;
    }

    if (!isMicAvailable.value) {
      await _initializeVoiceSearch();
      if (!isMicAvailable.value) {
        Get.snackbar(
          'Mic permission',
          'Microphone permission denied or not available',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    try {
      isListening.value = true;
      await _speechToText.listen(
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.search,
          partialResults: true,
        ),
        onResult: (result) async {
          final query = result.recognizedWords.trim();
          textInputController.text = query;
          textInputController.selection =
              TextSelection.collapsed(offset: textInputController.text.length);
          await onChanged(query);

          if (result.finalResult && query.isNotEmpty) {
            await submitSearchQuery(query);
          }
        },
      );
    } catch (_) {
      isListening.value = false;
      Get.snackbar(
        'Voice search',
        'Unable to start voice input. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void reset() {
    if (isListening.value) {
      _speechToText.stop();
      isListening.value = false;
    }
    urlPasted.value = false;
    textInputController.text = "";
    suggestionList.clear();
  }

  Future<void> removeQueryFromHistory(String txt) async {
    final index = queryBox.values.toList().indexOf(txt);
    await queryBox.deleteAt(index);
    historyQuerylist.remove(txt);
    if (Get.isRegistered<CloudService>()) {
      Get.find<CloudService>().syncSearchHistory();
    }
  }

  @override
  void dispose() {
    if (isListening.value) {
      _speechToText.stop();
    }
    _speechToText.cancel();
    focusNode.dispose();
    textInputController.dispose();
    queryBox.close();
    super.dispose();
  }
}
