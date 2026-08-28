import 'package:equatable/equatable.dart';

class ChannelEntity with EquatableMixin {
  final String id;
  final String name;
  final String image;
  final String group;
  final String streamUrl;

  const ChannelEntity({
    required this.id,
    required this.name,
    required this.image,
    required this.group,
    required this.streamUrl
  });
  
  @override
  List<Object?> get props => [id, name, image, group, streamUrl];
}