// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShareAdapter extends TypeAdapter<Share> {
  @override
  final int typeId = 0;

  @override
  Share read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Share(
      fields[0] as String,
      fields[1] as String,
      fields[2] as bool,
      (fields[3] as Map).cast<String, String>(),
      (fields[4] as Map).cast<String, String>(),
      (fields[5] as Map).cast<String, String>(),
      fields[6] as String,
      fields[7] as String,
      fields[8] as bool,
      fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Share obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.uploaderUrl)
      ..writeByte(1)
      ..write(obj.formDataName)
      ..writeByte(2)
      ..write(obj.uploadFormData)
      ..writeByte(3)
      ..write(obj.uploadHeaders)
      ..writeByte(4)
      ..write(obj.uploadParameters)
      ..writeByte(5)
      ..write(obj.uploadArguments)
      ..writeByte(6)
      ..write(obj.uploaderResponseParser)
      ..writeByte(7)
      ..write(obj.uploaderErrorParser)
      ..writeByte(8)
      ..write(obj.selectedUploader)
      ..writeByte(9)
      ..write(obj.method);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ViewSelectionAdapter extends TypeAdapter<ViewSelection> {
  @override
  final int typeId = 1;

  @override
  ViewSelection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ViewSelection(
      fields[0] as bool,
      fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ViewSelection obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.addNewView)
      ..writeByte(1)
      ..write(obj.shouldLoadPresets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewSelectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
