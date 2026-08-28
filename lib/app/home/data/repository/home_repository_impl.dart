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
    List<Channel> jioChannels = [];
    List<Channel> iptvChannels = [];

    try {
      jioChannels = await jiotvGoRemoteDataSource.getAllChannels();
    } catch (_) {
      // JioTV-Go instance may be unreachable or offline
    }

    try {
      iptvChannels = await iptvRemoteDataSource.getAllPosts();
    } catch (_) {
      // IPTV-Org source error
    }

    if (jioChannels.isEmpty && iptvChannels.isEmpty) {
      return Left(Failure());
    }

    return Right([
      ...jioChannels.map((ch) => ch.toEntity()),
      ...iptvChannels.map((ch) => ch.toEntity()),
    ]);
  }

  // String _normalizeName(String name) {
  //   return name
  //       .toLowerCase()
  //       .replaceAll(RegExp(r'\b(hd|sd|fhd|4k)\b', caseSensitive: false), '')
  //       .replaceAll(RegExp(r'[^a-z0-9]'), '')
  //       .trim();
  // }
}
