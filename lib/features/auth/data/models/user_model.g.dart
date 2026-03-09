// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 2;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      email: fields[0] as String,
      password: fields[1] as String,
      shopName: fields[2] as String,
      expiryDate: fields[3] as DateTime?,
      isSuperAdmin: fields[4] as bool,
      phoneNumber: fields[5] as String,
      upiId: fields[6] as String,
      addressLine1: fields[7] as String,
      addressLine2: fields[8] as String,
      footerText: fields[9] as String,
      qrCodePath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.email)
      ..writeByte(1)
      ..write(obj.password)
      ..writeByte(2)
      ..write(obj.shopName)
      ..writeByte(3)
      ..write(obj.expiryDate)
      ..writeByte(4)
      ..write(obj.isSuperAdmin)
      ..writeByte(5)
      ..write(obj.phoneNumber)
      ..writeByte(6)
      ..write(obj.upiId)
      ..writeByte(7)
      ..write(obj.addressLine1)
      ..writeByte(8)
      ..write(obj.addressLine2)
      ..writeByte(9)
      ..write(obj.footerText)
      ..writeByte(10)
      ..write(obj.qrCodePath);
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
