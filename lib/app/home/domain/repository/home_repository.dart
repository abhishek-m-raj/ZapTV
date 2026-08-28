import 'package:dartz/dartz.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/core/shared/failures.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<ChannelEntity>>> getChannels();
}