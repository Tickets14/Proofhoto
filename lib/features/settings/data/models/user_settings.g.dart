// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 2;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings()
      ..isDarkMode = fields[0] as bool
      ..notificationsEnabled = fields[1] as bool
      ..streakFreezeCount = fields[2] as int
      ..usedFreezes = (fields[3] as List).cast<String>()
      ..themeMode = fields[4] == null ? 'system' : fields[4] as String
      ..lastReviewShownWeek = fields[5] as String?
      ..focusModeEnabled = fields[6] == null ? false : fields[6] as bool
      ..focusModeStartTime = fields[7] as String?
      ..focusModeEndTime = fields[8] as String?;
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.isDarkMode)
      ..writeByte(1)
      ..write(obj.notificationsEnabled)
      ..writeByte(2)
      ..write(obj.streakFreezeCount)
      ..writeByte(3)
      ..write(obj.usedFreezes)
      ..writeByte(4)
      ..write(obj.themeMode)
      ..writeByte(5)
      ..write(obj.lastReviewShownWeek)
      ..writeByte(6)
      ..write(obj.focusModeEnabled)
      ..writeByte(7)
      ..write(obj.focusModeStartTime)
      ..writeByte(8)
      ..write(obj.focusModeEndTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
