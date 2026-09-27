part of 'home_bloc.dart';

sealed class HomeEvent {}

class HomeInitialEvent extends HomeEvent {}

class HomePreviousChannelEvent extends HomeEvent {}

class HomeNextChannelEvent extends HomeEvent {}

class HomeShowChannelInfoEvent extends HomeEvent {
  final bool shouldShow;
  HomeShowChannelInfoEvent([this.shouldShow = true]);
}

class HomeSelectChannelEvent extends HomeEvent {
  final ChannelEntity channel;
  final List<ChannelEntity>? activePlaylist;
  final int? categoryIndex;
  HomeSelectChannelEvent(
    this.channel, {
    this.activePlaylist,
    this.categoryIndex,
  });
}

class HomeChannelErrorEvent extends HomeEvent {
  final String channelId;
  final bool isPremium;
  final String message;

  HomeChannelErrorEvent({
    required this.channelId,
    required this.isPremium,
    required this.message,
  });
}
