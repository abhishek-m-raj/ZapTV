import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/app/home/view/bloc/home_bloc.dart';
import 'package:zaptv/app/home/view/widgets/channel_info.dart';
import 'package:zaptv/app/home/view/widgets/premium_channel_overlay.dart';
import 'package:zaptv/app/menu/view/pages/menu.dart';
import 'package:zaptv/core/config/locator.dart';
import 'package:zaptv/core/services/zap_video_controller.dart';
import 'package:zaptv/core/widgets/zap_video_view.dart';
import 'package:zaptv/core/services/hive_db.dart';
import 'package:zaptv/app/menu/view/widgets/jiotv_login_dialog.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeLogin();
    });
  }

  Future<void> _checkFirstTimeLogin() async {
    try {
      final hiveDb = loc<HiveDb>();
      final hasSeenLogin = hiveDb.getData('has_seen_jio_login') ?? false;
      if (!hasSeenLogin) {
        final loggedIn = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const JiotvLoginDialog(),
        );

        await hiveDb.putData('has_seen_jio_login', true);

        if (loggedIn == true) {
          bloc.add(HomeInitialEvent());
        }
      }
    } catch (_) {}
  }

  void showChannelInfo() {
    channelInfoTimer?.cancel();
    bloc.add(HomeShowChannelInfoEvent());
    channelInfoTimer = Timer(const Duration(seconds: 5), () async {
      bloc.add(HomeShowChannelInfoEvent(false));
    });
  }

  bool onKeyEvent(KeyEvent event) {
    // Ignore key events if the HomePage is not the top-most active route (e.g. dialog or menu is open)
    if (ModalRoute.of(context)?.isCurrent != true) return false;

    final LogicalKeyboardKey key = event.logicalKey;
    final bool isKeyUp = event is KeyUpEvent;
    if (isKeyUp) return false;
    if (isMenuOpened) return false;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowRight) {
      bloc.add(HomeNextChannelEvent());
      showChannelInfo();
      return true;
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft) {
      bloc.add(HomePreviousChannelEvent());
      showChannelInfo();
      return true;
    } else if (key == LogicalKeyboardKey.info ||
        key == LogicalKeyboardKey.keyI) {
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
    setState(() {
      isMenuOpened = true;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuPage(
          currentChannel: bloc.currentState.currentChannel,
          channels: bloc.currentState.allChannels,
          initialCategoryIndex: bloc.currentState.categoryIndex,
          onChannelSelected:
              (
                ChannelEntity channel,
                List<ChannelEntity> activePlaylist,
                int categoryIndex,
              ) {
                bloc.add(
                  HomeSelectChannelEvent(
                    channel,
                    activePlaylist: activePlaylist,
                    categoryIndex: categoryIndex,
                  ),
                );
              },
          onJioLoginSuccess: () {
            bloc.add(HomeInitialEvent());
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
                  fit: BoxFit.contain,
                ),
                if (state is HomeLoadedState && state.isPremiumError)
                  PremiumChannelOverlay(
                    channel: state.currentChannel,
                    onOpenMenu: openMenu,
                  ),
                if (state is HomeLoadedState && state.showChannelInfo)
                  ChannelInfo(
                    currentChannel: state.currentChannel,
                    isPremiumError: state.isPremiumError,
                  ),
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
