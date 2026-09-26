import 'package:dartz/dartz.dart';
import 'package:zaptv/app/home/data/models/channel.dart';
import 'package:zaptv/app/home/data/source/iptvorg_remote_datasource.dart';
import 'package:zaptv/app/home/data/source/jiotvgo_remote_datasource.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/app/home/domain/repository/home_repository.dart';
import 'package:zaptv/core/services/talker_service.dart';
import 'package:zaptv/core/shared/failures.dart';

import 'package:zaptv/core/config/locator.dart';
import 'package:zaptv/core/services/jiotvgo_process_service.dart';

class HomeRepositoryImpl implements HomeRepository {
  final IptvorgRemoteDataSource iptvRemoteDataSource;
  final JiotvGoRemoteDataSource jiotvGoRemoteDataSource;

  HomeRepositoryImpl({
    required this.iptvRemoteDataSource,
    required this.jiotvGoRemoteDataSource,
  });

  @override
  Future<Either<Failure, List<ChannelEntity>>> getChannels() async {
    talker.info('[Repository] Fetching channels from all sources...');

    List<Channel> jioChannels = [];
    List<Channel> iptvChannels = [];

    final jioService = loc<JiotvGoProcessService>();

    // Always try to fetch JioTV channels if the server is reachable.
    // Don't gate on isLoggedIn() — it's unreliable after a fresh login
    // because the server may need a restart to pick up new credentials.
    // The datasource will gracefully return an empty list if not authenticated.
    await jioService.ensureRunning();

    try {
      jioChannels = await jiotvGoRemoteDataSource.getAllChannels();
      talker.info('[Repository] Received ${jioChannels.length} JioTV channels');
    } catch (e, st) {
      talker.handle(e, st, '[Repository] Error loading JioTV channels');
    }

    try {
      iptvChannels = await iptvRemoteDataSource.getAllPosts();
      talker.info('[Repository] Received ${iptvChannels.length} IPTV channels');
    } catch (e, st) {
      talker.handle(e, st, '[Repository] Error loading IPTV channels');
    }

    // Filter out any invalid/blank entries
    jioChannels = jioChannels.where(_isValid).toList();
    iptvChannels = iptvChannels.where(_isValid).toList();

    if (jioChannels.isEmpty && iptvChannels.isEmpty) {
      talker.error('[Repository] Both sources returned zero valid channels!');
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
        licenseType: entity.licenseType,
        licenseKey: entity.licenseKey,
      );
    }).toList();

    final List<ChannelEntity> iptvEntities =
        iptvChannels.map((ch) => ch.toEntity()).toList();

    final List<ChannelEntity> result = [...jioEntities, ...iptvEntities];

    talker.info(
      '[Repository] Combined channel list ready. Total: ${result.length} (JioTV: ${jioEntities.length}, IPTV: ${iptvEntities.length})',
    );

    return Right(result);
  }

  bool _isValid(Channel ch) {
    final name = ch.name.trim();
    final url = ch.streamUrl.trim();
    return name.isNotEmpty && url.isNotEmpty && !name.startsWith('#');
  }
}
