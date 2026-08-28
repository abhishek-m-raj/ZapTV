import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/app/home/view/bloc/home_bloc.dart';
import 'package:zaptv/app/home/view/widgets/channel_info.dart';
import 'package:zaptv/app/menu/view/pages/menu.dart';
import 'package:zaptv/core/config/locator.dart';
import 'package:zaptv/core/services/zap_video_controller.dart';
import 'package:zaptv/core/widgets/zap_video_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  late final HomeBloc bloc;
  late bool isMenuOpened;
  Timer? channelInfoTimer;

  @override
  void initState() {
    bloc = HomeBloc(videoController: ZapVideoController(), getChannels: loc());
    bloc.add(HomeInitialEvent());
    showChannelInfo();
    ServicesBinding.instance.keyboard.addHandler(onKeyEvent);
    isMenuOpened = false;
    super.initState();
  }

  void showChannelInfo() {
    channelInfoTimer?.cancel();
    bloc.add(HomeShowChannelInfoEvent());
    channelInfoTimer = Timer(Duration(seconds: 5), () async {
      bloc.add(HomeShowChannelInfoEvent(false));
    });
  }

  bool onKeyEvent(KeyEvent event) {
    final LogicalKeyboardKey key = event.logicalKey;
    final bool isKeyUp = event is KeyUpEvent;
    if (isKeyUp) return false;
    if (isMenuOpened) return false;
    if (key == LogicalKeyboardKey.arrowUp) {
      showChannelInfo();
      return true;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      bloc.add(HomePreviousChannelEvent());
      showChannelInfo();
      return true;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      bloc.add(HomeNextChannelEvent());
      showChannelInfo();
      return true;
    } else if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.keyM ||
        key == LogicalKeyboardKey.contextMenu) {
      return openMenu();
    } else {
      return false;
    }
  }

  bool openMenu() {
    if (bloc.state is! HomeLoadedState) return false;
    isMenuOpened = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuPage(
          videoController: bloc.videoController,
          currentChannel: bloc.currentState.currentChannel,
          channels: bloc.currentState.channels,
          onChannelSelected: (ChannelEntity channel) {
            bloc.add(HomeSelectChannelEvent(channel));
          },
          onPop: () async {
            await Future.delayed(const Duration(milliseconds: 500));
            setState(() {
              isMenuOpened = false;
            });
          },
        ),
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HomeBloc, HomeState>(
        bloc: bloc,
        builder: (context, state) {
          return GestureDetector(
            onLongPress: () {
              openMenu();
            },
            onSecondaryTap: () {
              openMenu();
            },
            onTap: () {
              showChannelInfo();
            },
            onHorizontalDragStart: onHorizontalDragStartEvent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ZapVideoView(
                  controller: bloc.videoController,
                  fit: BoxFit.cover,
                ),
                if (state is HomeLoadedState && state.showChannelInfo)
                  ChannelInfo(currentChannel: state.currentChannel),
              ],
            ),
          );
        },
      ),
    );
  }

  void onHorizontalDragStartEvent(DragStartDetails details) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    if (details.globalPosition.dx < (screenWidth / 2)) {
      bloc.add(HomePreviousChannelEvent());
      showChannelInfo();
    } else {
      bloc.add(HomeNextChannelEvent());
      showChannelInfo();
    }
  }
}
