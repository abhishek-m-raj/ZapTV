part of 'home_bloc.dart';

sealed class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoadingState extends HomeState {}

class HomeLoadedState extends HomeState {
  final ChannelEntity currentChannel;
  final List<ChannelEntity> channels; // Active playlist
  final List<ChannelEntity> allChannels;
  final bool showChannelInfo;
  final int categoryIndex;
  final bool isPremiumError;
  final String? errorMessage;

  HomeLoadedState({
    required this.currentChannel,
    required this.channels,
    required this.allChannels,
    this.showChannelInfo = false,
    this.categoryIndex = 0,
    this.isPremiumError = false,
    this.errorMessage,
  });

  HomeLoadedState copyWith({
    ChannelEntity? currentChannel,
    List<ChannelEntity>? channels,
    List<ChannelEntity>? allChannels,
    bool? showChannelInfo,
    int? categoryIndex,
    bool? isPremiumError,
    String? errorMessage,
  }) {
    return HomeLoadedState(
      currentChannel: currentChannel ?? this.currentChannel,
      channels: channels ?? this.channels,
      allChannels: allChannels ?? this.allChannels,
      showChannelInfo: showChannelInfo ?? this.showChannelInfo,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      isPremiumError: isPremiumError ?? this.isPremiumError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
