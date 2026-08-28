import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';

class ChannelInfo extends StatelessWidget {
  final ChannelEntity currentChannel;

  const ChannelInfo({
    super.key,
    required this.currentChannel
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 12,
      left: 50,
      right: 50,
      child: Container(
        width: 500,
        height: 120,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).colorScheme.primaryContainer,
          border: Border.all(
            color: Colors.white,
            width: 1
          )
        ),
        child: Column(
          children: [
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: currentChannel.image,
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
                SizedBox(width: 10),
                Text(
                  currentChannel.name,
                  style: Theme.of(context).primaryTextTheme.labelLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer
                  ),
                )
              ],
            )
          ],
        ),
      )
    );
  }
}
