// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 4;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String?,
      pronoun: fields[1] as String?,
      firstName: fields[2] as String?,
      fullName: fields[3] as String?,
      age: fields[4] as int?,
      email: fields[5] as String?,
      profileImagePath: fields[6] as String?,
      dateOfBirth: fields[7] as DateTime?,
      address: fields[8] as String?,
      instagramHandle: fields[9] as String?,
      createdAt: fields[10] as DateTime?,
      isOnboardingComplete: fields[11] as bool,
      joinedAt: fields[12] as DateTime?,
      permissionsGranted: fields[13] as bool,
      street: fields[14] as String?,
      state: fields[15] as String?,
      country: fields[16] as String?,
      pinCode: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.pronoun)
      ..writeByte(2)
      ..write(obj.firstName)
      ..writeByte(3)
      ..write(obj.fullName)
      ..writeByte(4)
      ..write(obj.age)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.profileImagePath)
      ..writeByte(7)
      ..write(obj.dateOfBirth)
      ..writeByte(8)
      ..write(obj.address)
      ..writeByte(9)
      ..write(obj.instagramHandle)
      ..writeByte(14)
      ..write(obj.street)
      ..writeByte(15)
      ..write(obj.state)
      ..writeByte(16)
      ..write(obj.country)
      ..writeByte(17)
      ..write(obj.pinCode)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.isOnboardingComplete)
      ..writeByte(12)
      ..write(obj.joinedAt)
      ..writeByte(13)
      ..write(obj.permissionsGranted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
