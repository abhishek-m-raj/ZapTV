import 'package:equatable/equatable.dart';

class ChannelEntity with EquatableMixin {
  final String id;
  final String name;
  final String image;
  final String group;
  final String streamUrl;
  final String? licenseType;
  final String? licenseKey;

  const ChannelEntity({
    required this.id,
    required this.name,
    required this.image,
    required this.group,
    required this.streamUrl,
    this.licenseType,
    this.licenseKey,
  });
  
  @override
  List<Object?> get props => [id, name, image, group, streamUrl, licenseType, licenseKey];
}