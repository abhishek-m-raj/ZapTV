import 'package:dartz/dartz.dart';
import 'package:zaptv/app/home/data/models/channel.dart';
import 'package:zaptv/app/home/data/source/iptvorg_remote_datasource.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/app/home/domain/repository/home_repository.dart';
import 'package:zaptv/core/shared/failures.dart';

class HomeRepositoryImpl implements HomeRepository{
  final IptvorgRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({
    required this.remoteDataSource
  });

  @override
  Future<Either<Failure, List<ChannelEntity>>> getChannels() async {
    try {
      final List<Channel> dataModel = await remoteDataSource.getAllPosts();
      final List<ChannelEntity> data = [];
      for (final i in dataModel) {
        data.add(i.toEntity());
      }
      return Right(data);
    } catch (e) {
      return Left(Failure());
    }
  }
}