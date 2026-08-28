import 'package:zaptv/app/home/domain/entities/channel.dart';

class Channel{
  final String id;
  final String name;
  final String image;
  final String group;
  final String streamUrl;

  const Channel({
    required this.id,
    required this.name,
    required this.image,
    required this.group,
    required this.streamUrl
  });

  ChannelEntity toEntity() {
    return ChannelEntity(
      id: id,
      name: name,
      image: image,
      group: group,
      streamUrl: streamUrl
    );
  }
}