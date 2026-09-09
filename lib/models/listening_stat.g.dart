// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listening_stat.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ListeningStatDayAdapter extends TypeAdapter<ListeningStatDay> {
  @override
  final int typeId = 20;

  @override
  ListeningStatDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final rawMetadata = fields[3] as Map?;
    final metadata = <String, Map<String, String>>{};
    rawMetadata?.forEach((key, value) {
      if (value is Map) {
        metadata[key.toString()] = value.map(
          (metadataKey, metadataValue) =>
              MapEntry(metadataKey.toString(), metadataValue.toString()),
        );
      }
    });
    return ListeningStatDay(
      date: fields[0] as String,
      totalSeconds: fields[1] as int,
      songStats: (fields[2] as Map?)?.cast<String, int>(),
      songMetadata: metadata,
    );
  }

  @override
  void write(BinaryWriter writer, ListeningStatDay obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.totalSeconds)
      ..writeByte(2)
      ..write(obj.songStats)
      ..writeByte(3)
      ..write(obj.songMetadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListeningStatDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
