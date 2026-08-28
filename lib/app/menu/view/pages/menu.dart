import 'package:av_media_player/index.dart';
import 'package:av_media_player/player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';

class MenuPage extends StatefulWidget {
  final AvMediaPlayer videoController;
  final ChannelEntity currentChannel;
  final List<ChannelEntity> channels;
  final Function(ChannelEntity) onChannelSelected;
  final VoidCallback onPop;

  const MenuPage({
    super.key,
    required this.videoController,
    required this.currentChannel,
    required this.channels,
    required this.onChannelSelected,
    required this.onPop
  });

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late final ScrollController _scrollController;
  late ChannelEntity currentChannel;

  @override
  void initState() {
    currentChannel = widget.currentChannel;
    _scrollController = ScrollController(
      onAttach: (_) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            final double itemHeight = 70;
            final int index = widget.channels.indexOf(widget.currentChannel);
            _scrollController.animateTo(
              itemHeight * index,
              duration: Duration(milliseconds: 800),
              curve: Curves.easeIn
            );
          }
        );
      }
    );
    super.initState();
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
          title: Text(
            "ZapTV"
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.white
                    )
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
                )
              ),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    border: Border.all(
                      color: Colors.white
                    )
                  ),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: AvMediaView(
                          initPlayer: widget.videoController,
                          initAutoPlay: true,
                          initLooping: true,
                        ),
                      )
                    ],
                  ),
                )
              )
            ],
          )
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
    required this.onTap
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onFocusChange: (value) {
          setState(() {
            isFocused = value;
          });
        },
        leading: CachedNetworkImage(
          imageUrl: widget.channel.image,
          imageBuilder: (context, imageProvider) => Container(
            width: 80,
            height: 50,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.contain
              ),
            ),
          ),
          placeholder: (context, url) => SizedBox(
            width: 80,
            height: 50,
          ),
          errorWidget: (context, url, error) => SizedBox(
            width: 80,
            height: 50,
          ),
        ),
        title: Text(
          widget.channel.name,
          style: Theme.of(context).primaryTextTheme.labelLarge!.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer
          ),
        ),
      ),
    );
  }
}