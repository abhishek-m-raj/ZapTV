import 'package:dartz/dartz.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/app/home/domain/repository/home_repository.dart';
import 'package:zaptv/core/shared/failures.dart';

class GetChannels {
  final HomeRepository homeRepository;

  GetChannels({
    required this.homeRepository
  });

  Future<Either<Failure, List<ChannelEntity>>> execute() async {
    return await homeRepository.getChannels();
  }
}