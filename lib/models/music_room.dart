import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a participant in a music room
class RoomParticipant {
  final String userId;
  final String userName;
  final String? photoUrl;
  final DateTime joinedAt;
  final bool isHost;
  final DateTime lastSeen;

  RoomParticipant({
    required this.userId,
    required this.userName,
    this.photoUrl,
    required this.joinedAt,
    required this.isHost,
    required this.lastSeen,
  });

  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    return RoomParticipant(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      photoUrl: json['photoUrl'] as String?,
      joinedAt: (json['joinedAt'] as Timestamp).toDate(),
      isHost: json['isHost'] as bool? ?? false,
      lastSeen: (json['lastSeen'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'photoUrl': photoUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isHost': isHost,
      'lastSeen': Timestamp.fromDate(lastSeen),
    };
  }

  RoomParticipant copyWith({
    String? userId,
    String? userName,
    String? photoUrl,
    DateTime? joinedAt,
    bool? isHost,
    DateTime? lastSeen,
  }) {
    return RoomParticipant(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      photoUrl: photoUrl ?? this.photoUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      isHost: isHost ?? this.isHost,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

/// Represents the current playback state in a room
class RoomPlaybackState {
  final MediaItem? currentSong;
  final bool isPlaying;
  final Duration position;
  final DateTime lastUpdateTime;
  final List<MediaItem> queue;

  RoomPlaybackState({
    this.currentSong,
    required this.isPlaying,
    required this.position,
    required this.lastUpdateTime,
    required this.queue,
  });

  factory RoomPlaybackState.fromJson(Map<String, dynamic> json) {
    return RoomPlaybackState(
      currentSong: json['currentSong'] != null
          ? MediaItem(
              id: json['currentSong']['id'] as String,
              title: json['currentSong']['title'] as String,
              artist: json['currentSong']['artist'] as String? ?? '',
              album: json['currentSong']['album'] as String? ?? '',
              artUri: json['currentSong']['artUri'] != null
                  ? Uri.parse(json['currentSong']['artUri'] as String)
                  : null,
              duration: json['currentSong']['duration'] != null
                  ? Duration(milliseconds: json['currentSong']['duration'] as int)
                  : null,
              extras: json['currentSong']['extras'] as Map<String, dynamic>?,
            )
          : null,
      isPlaying: json['isPlaying'] as bool? ?? false,
      position: Duration(milliseconds: json['position'] as int? ?? 0),
      lastUpdateTime: (json['lastUpdateTime'] as Timestamp).toDate(),
      queue: (json['queue'] as List<dynamic>?)
              ?.map((item) => MediaItem(
                    id: item['id'] as String,
                    title: item['title'] as String,
                    artist: item['artist'] as String? ?? '',
                    album: item['album'] as String? ?? '',
                    artUri: item['artUri'] != null
                        ? Uri.parse(item['artUri'] as String)
                        : null,
                    duration: item['duration'] != null
                        ? Duration(milliseconds: item['duration'] as int)
                        : null,
                    extras: item['extras'] as Map<String, dynamic>?,
                  ))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentSong': currentSong != null
          ? {
              'id': currentSong!.id,
              'title': currentSong!.title,
              'artist': currentSong!.artist ?? '',
              'album': currentSong!.album ?? '',
              'artUri': currentSong!.artUri?.toString(),
              'duration': currentSong!.duration?.inMilliseconds,
              'extras': currentSong!.extras,
            }
          : null,
      'isPlaying': isPlaying,
      'position': position.inMilliseconds,
      'lastUpdateTime': Timestamp.fromDate(lastUpdateTime),
      'queue': queue
          .map((item) => {
                'id': item.id,
                'title': item.title,
                'artist': item.artist ?? '',
                'album': item.album ?? '',
                'artUri': item.artUri?.toString(),
                'duration': item.duration?.inMilliseconds,
                'extras': item.extras,
              })
          .toList(),
    };
  }

  RoomPlaybackState copyWith({
    MediaItem? currentSong,
    bool? isPlaying,
    Duration? position,
    DateTime? lastUpdateTime,
    List<MediaItem>? queue,
  }) {
    return RoomPlaybackState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      queue: queue ?? this.queue,
    );
  }
}

/// Represents a music room where users can listen together
class MusicRoom {
  final String roomId;
  final String roomCode;
  final String hostId;
  final String hostName;
  final DateTime createdAt;
  final int maxParticipants;
  final RoomPlaybackState playbackState;
  final List<RoomParticipant> participants;
  final List<String> participantIds;

  MusicRoom({
    required this.roomId,
    required this.roomCode,
    required this.hostId,
    required this.hostName,
    required this.createdAt,
    this.maxParticipants = 10,
    required this.playbackState,
    required this.participants,
    this.participantIds = const [],
  });

  factory MusicRoom.fromJson(Map<String, dynamic> json, String roomId) {
    return MusicRoom(
      roomId: roomId,
      roomCode: json['roomCode'] as String,
      hostId: json['hostId'] as String,
      hostName: json['hostName'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      maxParticipants: json['maxParticipants'] as int? ?? 10,
      playbackState: RoomPlaybackState.fromJson(
        json['playbackState'] as Map<String, dynamic>? ?? {},
      ),
      participants: [], // Participants loaded separately from subcollection
      participantIds: json['participantIds'] != null 
          ? List<String>.from(json['participantIds'] as List) 
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomCode': roomCode,
      'hostId': hostId,
      'hostName': hostName,
      'createdAt': Timestamp.fromDate(createdAt),
      'maxParticipants': maxParticipants,
      'playbackState': playbackState.toJson(),
      'participantIds': participantIds,
    };
  }

  MusicRoom copyWith({
    String? roomId,
    String? roomCode,
    String? hostId,
    String? hostName,
    DateTime? createdAt,
    int? maxParticipants,
    RoomPlaybackState? playbackState,
    List<RoomParticipant>? participants,
    List<String>? participantIds,
  }) {
    return MusicRoom(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      createdAt: createdAt ?? this.createdAt,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      playbackState: playbackState ?? this.playbackState,
      participants: participants ?? this.participants,
      participantIds: participantIds ?? this.participantIds,
    );
  }

  bool get isFull => participants.length >= maxParticipants;

  int get participantCount => participants.length;

  bool isUserHost(String userId) => hostId == userId;

  RoomParticipant? getParticipant(String userId) {
    try {
      return participants.firstWhere((p) => p.userId == userId);
    } catch (e) {
      return null;
    }
  }
}
