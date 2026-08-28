part of 'home_bloc.dart';

sealed class HomeEvent {}

class HomeInitialEvent extends HomeEvent {}

class HomePreviousChannelEvent extends HomeEvent {}

class HomeNextChannelEvent extends HomeEvent {}

class HomeShowChannelInfoEvent extends HomeEvent {
  final bool shouldShow;
  HomeShowChannelInfoEvent([
    this.shouldShow = true
  ]);
}

class HomeSelectChannelEvent extends HomeEvent {
  final ChannelEntity channel;
  HomeSelectChannelEvent(this.channel);
}