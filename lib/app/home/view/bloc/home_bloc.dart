import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/app/home/domain/usecase/get_channels.dart';
import 'package:zaptv/core/config/locator.dart';
import 'package:zaptv/core/services/hive_db.dart';
import 'package:zaptv/core/services/settings_service.dart';
import 'package:zaptv/core/services/zap_video_controller.dart';
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ZapVideoController videoController;
  final GetChannels getChannels;
  final SettingsService settingsService;
  final HiveDb hiveDb;

  HomeBloc({
    required this.videoController,
    required this.getChannels,
    SettingsService? settingsService,
    HiveDb? hiveDb,
  }) : settingsService = settingsService ?? loc<SettingsService>(),
       hiveDb = hiveDb ?? loc<HiveDb>(),
       super(HomeInitial()) {
    on<HomeInitialEvent>(homeInitialEvent);
    on<HomePreviousChannelEvent>(homePreviousChannelEvent);
    on<HomeNextChannelEvent>(homeNextChannelEvent);
    on<HomeShowChannelInfoEvent>(homeShowChannelInfoEvent);
    on<HomeSelectChannelEvent>(homeSelectChannelEvent);
  }

  @override
  Future<void> close() {
    videoController.dispose();
    return super.close();
  }

  HomeLoadedState get currentState => state as HomeLoadedState;

  FutureOr<void> homeInitialEvent(
    HomeInitialEvent event,
    Emitter<HomeState> emit,
  ) async {
    final result = await getChannels.execute();
    result.fold((_) {}, (r) {
      if (r.isEmpty) return;

      int categoryIndex = 0;
      List<ChannelEntity> activePlaylist = r;

      if (settingsService.loadLastChannelListOnStart) {
        final savedCategory = settingsService.lastChannelListCategory;
        if (savedCategory >= 0 && savedCategory <= 3) {
          categoryIndex = savedCategory;
          if (categoryIndex == 1) {
            final favs = r
                .where((c) => hiveDb.getData(c.id, 'fav') == true)
                .toList();
            if (favs.isNotEmpty) {
              activePlaylist = favs;
            } else {
              categoryIndex = 0;
            }
          } else if (categoryIndex == 2) {
            final jios = r.where((c) => c.id.endsWith('-jiotv')).toList();
            if (jios.isNotEmpty) {
              activePlaylist = jios;
            } else {
              categoryIndex = 0;
            }
          } else if (categoryIndex == 3) {
            final iptvs = r.where((c) => !c.id.endsWith('-jiotv')).toList();
            if (iptvs.isNotEmpty) {
              activePlaylist = iptvs;
            } else {
              categoryIndex = 0;
            }
          }
        }
      }

      ChannelEntity initialChannel = activePlaylist.first;

      if (settingsService.loadLastSeenChannelOnStart) {
        final lastId = settingsService.lastSeenChannelId;
        if (lastId != null && lastId.isNotEmpty) {
          final inPlaylist = activePlaylist
              .where((c) => c.id == lastId)
              .firstOrNull;
          if (inPlaylist != null) {
            initialChannel = inPlaylist;
          } else {
            final inAll = r.where((c) => c.id == lastId).firstOrNull;
            if (inAll != null) {
              initialChannel = inAll;
              activePlaylist = r;
              categoryIndex = 0;
            }
          }
        }
      }

      settingsService.lastSeenChannelId = initialChannel.id;
      if (settingsService.loadLastChannelListOnStart) {
        settingsService.lastChannelListCategory = categoryIndex;
      }

      emit(
        HomeLoadedState(
          currentChannel: initialChannel,
          channels: activePlaylist,
          allChannels: r,
          categoryIndex: categoryIndex,
        ),
      );
      if (!initialChannel.streamUrl.startsWith("http")) return;
      try {
        videoController.open(
          initialChannel.streamUrl,
          licenseType: initialChannel.licenseType,
          licenseKey: initialChannel.licenseKey,
        );
      } catch (_) {}
    });
  }

  FutureOr<void> homePreviousChannelEvent(
    HomePreviousChannelEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoadedState) return;
    final currentIndex = currentState.channels.indexOf(
      currentState.currentChannel,
    );
    if (currentIndex > 0) {
      final targetChannel = currentState.channels[currentIndex - 1];
      settingsService.lastSeenChannelId = targetChannel.id;
      emit(currentState.copyWith(currentChannel: targetChannel));
      if (!targetChannel.streamUrl.startsWith("http")) return;
      try {
        videoController.open(
          targetChannel.streamUrl,
          licenseType: targetChannel.licenseType,
          licenseKey: targetChannel.licenseKey,
        );
      } catch (_) {}
    }
  }

  FutureOr<void> homeNextChannelEvent(
    HomeNextChannelEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoadedState) return;
    final currentIndex = currentState.channels.indexOf(
      currentState.currentChannel,
    );
    if (currentIndex >= 0 && currentIndex < currentState.channels.length - 1) {
      final targetChannel = currentState.channels[currentIndex + 1];
      settingsService.lastSeenChannelId = targetChannel.id;
      emit(currentState.copyWith(currentChannel: targetChannel));
      if (!targetChannel.streamUrl.startsWith("http")) return;
      try {
        videoController.open(
          targetChannel.streamUrl,
          licenseType: targetChannel.licenseType,
          licenseKey: targetChannel.licenseKey,
        );
      } catch (_) {}
    }
  }

  FutureOr<void> homeShowChannelInfoEvent(
    HomeShowChannelInfoEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoadedState) return;
    emit(currentState.copyWith(showChannelInfo: event.shouldShow));
  }

  FutureOr<void> homeSelectChannelEvent(
    HomeSelectChannelEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoadedState) return;
    final targetChannel = event.channel;
    settingsService.lastSeenChannelId = targetChannel.id;
    if (event.categoryIndex != null) {
      settingsService.lastChannelListCategory = event.categoryIndex!;
    }
    emit(
      currentState.copyWith(
        currentChannel: targetChannel,
        channels: event.activePlaylist ?? currentState.channels,
        categoryIndex: event.categoryIndex ?? currentState.categoryIndex,
      ),
    );
    if (!targetChannel.streamUrl.startsWith("http")) return;
    try {
      videoController.open(
        targetChannel.streamUrl,
        licenseType: targetChannel.licenseType,
        licenseKey: targetChannel.licenseKey,
      );
    } catch (_) {}
  }
}
