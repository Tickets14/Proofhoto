// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProofEntryAdapter extends TypeAdapter<ProofEntry> {
  @override
  final int typeId = 1;

  @override
  ProofEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProofEntry()
      ..id = fields[0] as String
      ..habitId = fields[1] as String
      ..imagePath = fields[2] as String
      ..note = fields[3] as String?
      ..completedAt = fields[4] as DateTime;
  }

  @override
  void write(BinaryWriter writer, ProofEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.habitId)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProofEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
