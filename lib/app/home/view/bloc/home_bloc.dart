import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:http/http.dart' as http;
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/app/home/domain/usecase/get_channels.dart';
import 'package:zaptv/core/config/locator.dart';
import 'package:zaptv/core/services/hive_db.dart';
import 'package:zaptv/core/services/settings_service.dart';
import 'package:zaptv/core/services/talker_service.dart';
import 'package:zaptv/core/services/zap_video_controller.dart';
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ZapVideoController videoController;
  final GetChannels getChannels;
  final SettingsService settingsService;
  final HiveDb hiveDb;
  int _streamCheckCounter = 0;

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
    on<HomeChannelErrorEvent>(_homeChannelErrorEvent);

    videoController.onPlaybackError = (error) {
      if (state is! HomeLoadedState) return;
      final ch = currentState.currentChannel;
      final isJio = ch.id.endsWith('-jiotv') || ch.streamUrl.contains('5050');
      if (isJio &&
          (error.contains('500') ||
              error.toLowerCase().contains('server returned 500') ||
              error.contains('InvalidResponseCodeException'))) {
        talker.warning(
          '[JioTV] Playback error 500 detected for ${ch.name} (${ch.id})',
        );
        add(
          HomeChannelErrorEvent(
            channelId: ch.id,
            isPremium: true,
            message:
                'This channel requires a Jio premium subscription (Error 500)',
          ),
        );
      }
    };
  }

  @override
  Future<void> close() {
    videoController.dispose();
    return super.close();
  }

  HomeLoadedState get currentState => state as HomeLoadedState;

  void _playChannel(ChannelEntity channel) {
    if (!channel.streamUrl.startsWith("http")) return;
    try {
      videoController.open(
        channel.streamUrl,
        licenseType: channel.licenseType,
        licenseKey: channel.licenseKey,
      );
    } catch (_) {}

    _checkChannelStream(channel);
  }

  Future<void> _checkChannelStream(ChannelEntity channel) async {
    final isJioChannel =
        channel.id.endsWith('-jiotv') ||
        channel.streamUrl.contains('5050') ||
        channel.streamUrl.contains('/live/');

    if (!isJioChannel) return;

    final currentCheckId = ++_streamCheckCounter;

    try {
      final response = await http
          .get(Uri.parse(channel.streamUrl))
          .timeout(const Duration(seconds: 4));

      if (currentCheckId != _streamCheckCounter) return;
      if (state is! HomeLoadedState ||
          currentState.currentChannel.id != channel.id) {
        return;
      }

      if (response.statusCode == 500) {
        talker.warning(
          '[JioTV] Channel ${channel.name} (${channel.id}) returned HTTP 500 (Premium required)',
        );
        await videoController.stop();
        add(
          HomeChannelErrorEvent(
            channelId: channel.id,
            isPremium: true,
            message:
                'This channel requires a Jio premium subscription (Error 500)',
          ),
        );
      }
    } catch (e) {
      talker.debug('[JioTV] Channel stream probe: $e');
    }
  }

  void _homeChannelErrorEvent(
    HomeChannelErrorEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is! HomeLoadedState) return;
    if (currentState.currentChannel.id != event.channelId) return;

    emit(
      currentState.copyWith(
        isPremiumError: event.isPremium,
        errorMessage: event.message,
        showChannelInfo: true,
      ),
    );
  }

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
          isPremiumError: false,
        ),
      );
      _playChannel(initialChannel);
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
      emit(
        currentState.copyWith(
          currentChannel: targetChannel,
          isPremiumError: false,
          errorMessage: null,
        ),
      );
      _playChannel(targetChannel);
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
      emit(
        currentState.copyWith(
          currentChannel: targetChannel,
          isPremiumError: false,
          errorMessage: null,
        ),
      );
      _playChannel(targetChannel);
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
        isPremiumError: false,
        errorMessage: null,
      ),
    );
    _playChannel(targetChannel);
  }
}
