// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dhikr_set.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DhikrSetAdapter extends TypeAdapter<DhikrSet> {
  @override
  final int typeId = 0;

  @override
  DhikrSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DhikrSet(
      id: fields[0] as String,
      arabic: fields[1] as String,
      transliteration: fields[2] as String,
      translation: fields[3] as String,
      targetCount: fields[4] as int,
      isCustom: fields[5] as bool,
      colorHex: fields[6] as String,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DhikrSet obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.arabic)
      ..writeByte(2)
      ..write(obj.transliteration)
      ..writeByte(3)
      ..write(obj.translation)
      ..writeByte(4)
      ..write(obj.targetCount)
      ..writeByte(5)
      ..write(obj.isCustom)
      ..writeByte(6)
      ..write(obj.colorHex)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DhikrSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
