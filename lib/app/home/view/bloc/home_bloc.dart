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
    (await getChannels.execute()).fold(
      (_) {}, 
      (r) async {
        emit(
          HomeLoadedState(
            currentChannel: r.first,
            channels: r
          )
        );
        if (!currentState.currentChannel.streamUrl.startsWith("http")) return;
        try {
          videoController.open(currentState.currentChannel.streamUrl);
        } catch (_) {}
      }
    );
  }

  FutureOr<void> homePreviousChannelEvent(HomePreviousChannelEvent event, Emitter<HomeState> emit) async {
    if (state is! HomeLoadedState) return;
    if (currentState.channels.indexOf(currentState.currentChannel) != 0) {
      emit(
        currentState.copyWith(
          currentChannel: currentState.channels[currentState.channels.indexOf(currentState.currentChannel) - 1]
        )
      );
      if (!currentState.currentChannel.streamUrl.startsWith("http")) return;
      try {
        videoController.open(currentState.currentChannel.streamUrl);
      } catch (_) {}
    }
  }

  FutureOr<void> homeNextChannelEvent(HomeNextChannelEvent event, Emitter<HomeState> emit) async {
    if (state is! HomeLoadedState) return;
    if (currentState.channels.indexOf(currentState.currentChannel) != (currentState.channels.length-1)) {
      emit(
        currentState.copyWith(
          currentChannel: currentState.channels[currentState.channels.indexOf(currentState.currentChannel) + 1]
        )
      );
      if (!currentState.currentChannel.streamUrl.startsWith("http")) return;
      try {
        videoController.open(currentState.currentChannel.streamUrl);
      } catch (_) {}
    }
  }

  FutureOr<void> homeShowChannelInfoEvent(HomeShowChannelInfoEvent event, Emitter<HomeState> emit) async {
    if (state is! HomeLoadedState) return;
    emit(
      currentState.copyWith(
        showChannelInfo: event.shouldShow
      )
    );
  }

  FutureOr<void> homeSelectChannelEvent(HomeSelectChannelEvent event, Emitter<HomeState> emit) async {
    if (state is! HomeLoadedState) return;
    emit(
      currentState.copyWith(
        currentChannel: event.channel
      )
    );
    if (!currentState.currentChannel.streamUrl.startsWith("http")) return;
    try {
      videoController.open(currentState.currentChannel.streamUrl);
    } catch (_) {}
  }
}
