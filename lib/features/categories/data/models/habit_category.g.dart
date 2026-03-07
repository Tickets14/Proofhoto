// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitCategoryAdapter extends TypeAdapter<HabitCategory> {
  @override
  final int typeId = 3;

  @override
  HabitCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitCategory()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..emoji = fields[2] as String
      ..colorValue = fields[3] as int
      ..sortOrder = fields[4] as int;
  }

  @override
  void write(BinaryWriter writer, HabitCategory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
