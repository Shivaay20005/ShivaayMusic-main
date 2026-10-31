import 'package:shivaaymusic/services/stream_service.dart'show Audio;

class SMStreamingData {
  final bool playable;
  final String statusMSG;
  final Audio? lowQualityAudio;
  final Audio? highQualityAudio;
  int qualityIndex = 1;
  SMStreamingData({
    required this.playable,
    required this.statusMSG,
    this.lowQualityAudio,
    this.highQualityAudio,
  });

  setQualityIndex(int index) {
    qualityIndex = index;
  }

  Audio? get audio => qualityIndex == 0 ? lowQualityAudio : highQualityAudio;

  factory SMStreamingData.fromJson(dynamic json) {
    final status = (json is Map && json['statusMSG'] != null)
        ? json['statusMSG'].toString()
        : "";
    if (json is! Map || json['playable'] != true) {
      return SMStreamingData(playable: false, statusMSG: status);
    }
    final lowJson = json['lowQualityAudio'];
    final highJson = json['highQualityAudio'];
    // A playable response without audio formats cannot be played; treat it as
    // an error instead of throwing while constructing Audio.fromJson(null).
    if (lowJson is! Map || highJson is! Map) {
      return SMStreamingData(playable: false, statusMSG: status);
    }
    final lowQualityAudio = Audio.fromJson(lowJson);
    final highQualityAudio = Audio.fromJson(highJson);
    // A stream entry without any URL cannot be played; surface a real error
    // instead of handing an empty URL to just_audio.
    if (lowQualityAudio.url.isEmpty && highQualityAudio.url.isEmpty) {
      return SMStreamingData(
          playable: false,
          statusMSG: status.isEmpty || status == "OK"
              ? "Unable to load this song"
              : status);
    }
    return SMStreamingData(
        playable: true,
        statusMSG: status,
        lowQualityAudio: lowQualityAudio,
        highQualityAudio: highQualityAudio);
  }

  Map<String, dynamic> toJson() => {
        "playable": playable,
        "statusMSG": statusMSG,
        "lowQualityAudio": lowQualityAudio?.toJson(),
        "highQualityAudio": highQualityAudio?.toJson(),
      };
}
