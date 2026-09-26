part of 'home_bloc.dart';

sealed class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoadingState extends HomeState {}

class HomeLoadedState extends HomeState {
  final ChannelEntity currentChannel;
  final List<ChannelEntity> channels; // Active playlist
  final List<ChannelEntity> allChannels;
  final bool showChannelInfo;

  HomeLoadedState({
    required this.currentChannel,
    required this.channels,
    required this.allChannels,
    this.showChannelInfo = false
  });

  HomeLoadedState copyWith({
    ChannelEntity? currentChannel,
    List<ChannelEntity>? channels,
    List<ChannelEntity>? allChannels,
    bool? showChannelInfo
  }) {
    return HomeLoadedState(
      currentChannel: currentChannel ?? this.currentChannel,
      channels: channels ?? this.channels,
      allChannels: allChannels ?? this.allChannels,
      showChannelInfo: showChannelInfo ?? this.showChannelInfo
    );
  }
}