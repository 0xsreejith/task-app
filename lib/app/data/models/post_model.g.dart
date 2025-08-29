// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PostModelAdapter extends TypeAdapter<PostModel> {
  @override
  final int typeId = 1;

  @override
  PostModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PostModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      username: fields[2] as String,
      userAvatar: fields[3] as String,
      imageUrl: fields[4] as String,
      caption: fields[5] as String,
      likes: fields[6] == null ? 0 : fields[6] as int,
      isLiked: fields[7] == null ? false : fields[7] as bool,
      createdAt: fields[8] as DateTime?,
      comments: fields[9] == null ? [] : (fields[9] as List?)?.cast<Comment>(),
    );
  }

  @override
  void write(BinaryWriter writer, PostModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.userAvatar)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.caption)
      ..writeByte(6)
      ..write(obj.likes)
      ..writeByte(7)
      ..write(obj.isLiked)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.comments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
