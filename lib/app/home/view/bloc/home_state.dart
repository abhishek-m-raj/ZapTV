part of 'home_bloc.dart';

sealed class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoadingState extends HomeState {}

class HomeLoadedState extends HomeState {
  final ChannelEntity currentChannel;
  final List<ChannelEntity> channels;
  final bool showChannelInfo;

  HomeLoadedState({
    required this.currentChannel,
    required this.channels,
    this.showChannelInfo = false
  });

  HomeLoadedState copyWith({
    ChannelEntity? currentChannel,
    List<ChannelEntity>? channels,
    bool? showChannelInfo
  }) {
    return HomeLoadedState(
      currentChannel: currentChannel ?? this.currentChannel,
      channels: channels ?? this.channels,
      showChannelInfo: showChannelInfo ?? this.showChannelInfo
    );
  }
}