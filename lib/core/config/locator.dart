import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:zaptv/app/home/data/repository/home_repository_impl.dart';
import 'package:zaptv/app/home/data/source/iptvorg_remote_datasource.dart';
import 'package:zaptv/app/home/data/source/jiotvgo_remote_datasource.dart';
import 'package:zaptv/app/home/domain/repository/home_repository.dart';
import 'package:zaptv/app/home/domain/usecase/get_channels.dart';
import 'package:zaptv/core/services/hive_db.dart';
import 'package:zaptv/core/services/jiotvgo_process_service.dart';

final GetIt loc = GetIt.instance;

Future<void> setupLocator() async {
  loc.registerSingletonAsync<HiveDb>(() async {
    final instance = HiveDb();
    await instance.init();
    return instance;
  });
  
  final jiotvService = JiotvGoProcessService();
  loc.registerSingleton<JiotvGoProcessService>(jiotvService);
  // Auto-start JioTV-Go background process asynchronously
  unawaited(jiotvService.initAndStart());

  loc.registerFactory(() => IptvorgRemoteDataSource());
  loc.registerFactory(() => JiotvGoRemoteDataSource());
  loc.registerFactory<HomeRepository>(
    () => HomeRepositoryImpl(
      iptvRemoteDataSource: loc(),
      jiotvGoRemoteDataSource: loc(),
    ),
  );
  loc.registerFactory(() => GetChannels(homeRepository: loc()));
}
