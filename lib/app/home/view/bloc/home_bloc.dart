import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/app/home/domain/usecase/get_channels.dart';
import 'package:zaptv/core/services/zap_video_controller.dart';
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ZapVideoController videoController;
  final GetChannels getChannels;

  HomeBloc({
    required this.videoController,
    required this.getChannels
  }) : super(HomeInitial()) {
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

  FutureOr<void> homeInitialEvent(HomeInitialEvent event, Emitter<HomeState> emit) async {
    final result = await getChannels.execute();
    result.fold(
      (_) {},
      (r) {
        if (r.isEmpty) return;
        final initialChannel = r.first;
        emit(
          HomeLoadedState(
            currentChannel: initialChannel,
            channels: r,
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
      },
    );
  }

  FutureOr<void> homePreviousChannelEvent(HomePreviousChannelEvent event, Emitter<HomeState> emit) async {
    if (state is! HomeLoadedState) return;
    final currentIndex = currentState.channels.indexOf(currentState.currentChannel);
    if (currentIndex > 0) {
      final targetChannel = currentState.channels[currentIndex - 1];
      emit(
        currentState.copyWith(
          currentChannel: targetChannel,
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

  FutureOr<void> homeNextChannelEvent(HomeNextChannelEvent event, Emitter<HomeState> emit) async {
    if (state is! HomeLoadedState) return;
    final currentIndex = currentState.channels.indexOf(currentState.currentChannel);
    if (currentIndex >= 0 && currentIndex < currentState.channels.length - 1) {
      final targetChannel = currentState.channels[currentIndex + 1];
      emit(
        currentState.copyWith(
          currentChannel: targetChannel,
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

  FutureOr<void> homeShowChannelInfoEvent(HomeShowChannelInfoEvent event, Emitter<HomeState> emit) async {
    if (state is! HomeLoadedState) return;
    emit(
      currentState.copyWith(
        showChannelInfo: event.shouldShow,
      ),
    );
  }

  FutureOr<void> homeSelectChannelEvent(HomeSelectChannelEvent event, Emitter<HomeState> emit) async {
    if (state is! HomeLoadedState) return;
    final targetChannel = event.channel;
    emit(
      currentState.copyWith(
        currentChannel: targetChannel,
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
