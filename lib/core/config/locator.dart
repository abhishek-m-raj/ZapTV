import 'package:get_it/get_it.dart';
import 'package:zaptv/app/home/data/repository/home_repository_impl.dart';
import 'package:zaptv/app/home/data/source/iptvorg_remote_datasource.dart';
import 'package:zaptv/app/home/domain/repository/home_repository.dart';
import 'package:zaptv/app/home/domain/usecase/get_channels.dart';
import 'package:zaptv/core/services/hive_db.dart';

final GetIt loc = GetIt.instance;

Future<void> setupLocator() async {
  loc.registerSingletonAsync<HiveDb>(() async {
    final instance = HiveDb();
    await instance.init();
    return instance;
  });
  loc.registerFactory<HomeRepository>(() => HomeRepositoryImpl(remoteDataSource: loc()));
  loc.registerFactory(() => IptvorgRemoteDataSource());
  loc.registerFactory(() => GetChannels(homeRepository: loc()));
}