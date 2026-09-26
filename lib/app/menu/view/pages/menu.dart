import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/app/menu/view/widgets/jiotv_login_dialog.dart';
import 'package:zaptv/core/config/locator.dart';
import 'package:zaptv/core/services/jiotvgo_process_service.dart';
import 'package:zaptv/core/services/zap_video_controller.dart';
import 'package:zaptv/core/widgets/zap_video_view.dart';
import 'package:zaptv/core/widgets/tv_focusable_button.dart';

class MenuPage extends StatefulWidget {
  final ZapVideoController videoController;
  final ChannelEntity currentChannel;
  final List<ChannelEntity> channels;
  final Function(ChannelEntity) onChannelSelected;
  final VoidCallback onPop;
  final VoidCallback? onJioLoginSuccess;

  const MenuPage({
    super.key,
    required this.videoController,
    required this.currentChannel,
    required this.channels,
    required this.onChannelSelected,
    required this.onPop,
    this.onJioLoginSuccess,
  });

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late final ScrollController _scrollController;
  late ChannelEntity currentChannel;
  bool _isJioLoggedIn = false;

  @override
  void initState() {
    currentChannel = widget.currentChannel;
    _checkJioLoginStatus();
    _scrollController = ScrollController(
      onAttach: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final double itemHeight = 70;
          final int index = widget.channels.indexOf(widget.currentChannel);
          _scrollController.animateTo(
            itemHeight * index,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeIn,
          );
        });
      },
    );
    super.initState();
  }

  Future<void> _checkJioLoginStatus() async {
    try {
      final service = loc<JiotvGoProcessService>();
      final loggedIn = await service.isLoggedIn();
      if (mounted) {
        setState(() {
          _isJioLoggedIn = loggedIn;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.onPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("ZapTV"),
        ),
        body: Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TvFocusableButton(
                      isJioLoggedIn: _isJioLoggedIn,
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => const JiotvLoginDialog(),
                        );
                        if (result == true) {
                          _checkJioLoginStatus();
                          widget.onJioLoginSuccess?.call();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      icon: Icon(_isJioLoggedIn ? Icons.check_circle : Icons.login),
                      label: Text(
                        _isJioLoggedIn ? "JioTV: Logged In" : "JioTV Login",
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.transparent,
                          border: Border.all(color: Colors.white),
                        ),
                        child: ListView.separated(
                    controller: _scrollController,
                    clipBehavior: Clip.hardEdge,
                    itemCount: widget.channels.length,
                    itemBuilder: (context, index) {
                      final ChannelEntity channel = widget.channels[index];
                      return ChannelListTile(
                        key: ValueKey(channel.id),
                        channel: channel,
                        currentChannel: currentChannel,
                        onTap: () {
                          widget.onChannelSelected(channel);
                          setState(() {
                            currentChannel = channel;
                          });
                        },
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(height: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
          const SizedBox(width: 8),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    border: Border.all(color: Colors.white),
                  ),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ZapVideoView(
                          controller: widget.videoController,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChannelListTile extends StatefulWidget {
  final ChannelEntity channel;
  final ChannelEntity currentChannel;
  final VoidCallback onTap;

  const ChannelListTile({
    super.key,
    required this.channel,
    required this.currentChannel,
    required this.onTap,
  });

  @override
  State<ChannelListTile> createState() => _ChannelListTileState();
}

class _ChannelListTileState extends State<ChannelListTile> {
  late bool isFocused;

  @override
  void initState() {
    isFocused = false;
    super.initState();
  }

  bool get isSelected => widget.channel == widget.currentChannel;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListTile(
        selected: isSelected,
        selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        focusColor: Theme.of(context).colorScheme.primaryContainer,
        contentPadding: EdgeInsets.all(8),
        onTap: widget.onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onFocusChange: (value) {
          setState(() {
            isFocused = value;
          });
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        leading: CachedNetworkImage(
          imageUrl: widget.channel.image,
          imageBuilder: (context, imageProvider) => Container(
            width: 80,
            height: 50,
            decoration: BoxDecoration(
              image: DecorationImage(image: imageProvider, fit: BoxFit.contain),
            ),
          ),
          placeholder: (context, url) => SizedBox(width: 80, height: 50),
          errorWidget: (context, url, error) => SizedBox(width: 80, height: 50),
        ),
        title: Text(
          widget.channel.name,
          style: Theme.of(context).primaryTextTheme.labelLarge!.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}


