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
      uploaderUrl: fields[0] as String,
      formDataName: fields[1] as String,
      uploadFormData: fields[2] as bool,
      uploadHeaders: (fields[3] as Map).cast<String, String>(),
      uploadParameters: (fields[4] as Map).cast<String, String>(),
      uploadArguments: (fields[5] as Map).cast<String, String>(),
      uploaderResponseParser: fields[6] as String,
      uploaderErrorParser: fields[7] as String,
      selectedUploader: fields[8] as bool,
      method: fields[9] as String?,
      pgpPublicKey: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Share obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.method)
      ..writeByte(10)
      ..write(obj.pgpPublicKey);
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

class NetworkShareAdapter extends TypeAdapter<NetworkShare> {
  @override
  final int typeId = 2;

  @override
  NetworkShare read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NetworkShare(
      protocol: fields[0] as String,
      domain: fields[1] as String,
      username: fields[2] as String,
      password: fields[3] as String,
      folderPath: fields[4] as String,
      port: fields[5] as int,
      selected: fields[6] as bool,
      urlPath: fields[7] as String?,
      pgpPublicKey: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NetworkShare obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.protocol)
      ..writeByte(1)
      ..write(obj.domain)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.folderPath)
      ..writeByte(5)
      ..write(obj.port)
      ..writeByte(6)
      ..write(obj.selected)
      ..writeByte(7)
      ..write(obj.urlPath)
      ..writeByte(8)
      ..write(obj.pgpPublicKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkShareAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
