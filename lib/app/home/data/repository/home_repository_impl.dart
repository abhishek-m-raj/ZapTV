import 'dart:developer' as dev;
import 'package:dartz/dartz.dart';
import 'package:zaptv/app/home/data/models/channel.dart';
import 'package:zaptv/app/home/data/source/iptvorg_remote_datasource.dart';
import 'package:zaptv/app/home/data/source/jiotvgo_remote_datasource.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/app/home/domain/repository/home_repository.dart';
import 'package:zaptv/core/shared/failures.dart';

class HomeRepositoryImpl implements HomeRepository {
  final IptvorgRemoteDataSource iptvRemoteDataSource;
  final JiotvGoRemoteDataSource jiotvGoRemoteDataSource;

  HomeRepositoryImpl({
    required this.iptvRemoteDataSource,
    required this.jiotvGoRemoteDataSource,
  });

  @override
  Future<Either<Failure, List<ChannelEntity>>> getChannels() async {
    dev.log('Starting getChannels request...', name: 'HomeRepositoryImpl');

    List<Channel> jioChannels = [];
    List<Channel> iptvChannels = [];

    try {
      jioChannels = await jiotvGoRemoteDataSource.getAllChannels();
      dev.log('JioTV data source returned ${jioChannels.length} channels', name: 'HomeRepositoryImpl');
    } catch (e) {
      dev.log('Error fetching JioTV channels: $e', name: 'HomeRepositoryImpl');
    }

    try {
      iptvChannels = await iptvRemoteDataSource.getAllPosts();
      dev.log('IPTV-Org data source returned ${iptvChannels.length} channels', name: 'HomeRepositoryImpl');
    } catch (e) {
      dev.log('Error fetching IPTV-Org channels: $e', name: 'HomeRepositoryImpl');
    }

    // Filter out any invalid/blank entries
    jioChannels = jioChannels.where(_isValid).toList();
    iptvChannels = iptvChannels.where(_isValid).toList();

    if (jioChannels.isEmpty && iptvChannels.isEmpty) {
      dev.log('Both JioTV and IPTV-Org returned zero valid channels!', name: 'HomeRepositoryImpl');
      return Left(Failure());
    }

    // Append "-jiotv" to JioTV channel IDs without deduplication/merging
    final List<ChannelEntity> jioEntities = jioChannels.map((ch) {
      final entity = ch.toEntity();
      return ChannelEntity(
        id: '${entity.id}-jiotv',
        name: entity.name,
        image: entity.image,
        group: entity.group,
        streamUrl: entity.streamUrl,
      );
    }).toList();

    final List<ChannelEntity> iptvEntities =
        iptvChannels.map((ch) => ch.toEntity()).toList();

    final List<ChannelEntity> result = [...jioEntities, ...iptvEntities];

    dev.log(
      'Channel collection complete (No deduplication). Total channels: ${result.length} (JioTV: ${jioEntities.length}, IPTV: ${iptvEntities.length})',
      name: 'HomeRepositoryImpl',
    );

    return Right(result);
  }

  bool _isValid(Channel ch) {
    final name = ch.name.trim();
    final url = ch.streamUrl.trim();
    return name.isNotEmpty && url.isNotEmpty && !name.startsWith('#');
  }
}
