import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:m3u_nullsafe/m3u_nullsafe.dart';
import 'package:zaptv/app/home/data/models/channel.dart';
import 'package:zaptv/core/services/talker_service.dart';

class JiotvGoRemoteDataSource {
  static const String playlistUrl = "http://localhost:5001/playlist.m3u";
  static const String jsonChannelsUrl = "http://localhost:5001/channels";

  JiotvGoRemoteDataSource();

  Future<List<Channel>> getAllChannels() async {
    talker.info('[JioTV] Fetching JioTV-Go channel list...');

    // Retry loop for server startup delay
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final channels = await _tryFetchPlaylist();
        if (channels.isNotEmpty) {
          talker.info(
            '[JioTV] Loaded ${channels.length} channels via M3U (Attempt $attempt)',
          );
          return channels;
        }
      } catch (e) {
        talker.warning(
          '[JioTV] Attempt $attempt M3U fetch failed: $e',
        );
      }

      // Try JSON endpoint fallback
      try {
        final jsonChannels = await _tryFetchJsonChannels();
        if (jsonChannels.isNotEmpty) {
          talker.info(
            '[JioTV] Loaded ${jsonChannels.length} channels via JSON API (Attempt $attempt)',
          );
          return jsonChannels;
        }
      } catch (e) {
        talker.warning(
          '[JioTV] Attempt $attempt JSON fetch failed: $e',
        );
      }

      if (attempt < 3) {
        await Future.delayed(Duration(milliseconds: 1000 * attempt));
      }
    }

    talker.error(
      '[JioTV] All attempts to fetch JioTV channels failed or returned empty list.',
    );
    return [];
  }

  Future<List<Channel>> _tryFetchPlaylist() async {
    final res = await http
        .get(Uri.parse(playlistUrl))
        .timeout(const Duration(seconds: 5));

    talker.debug(
      '[JioTV] M3U fetch response status: ${res.statusCode}, body length: ${res.body.length}',
    );

    if (res.statusCode != 200) {
      throw Exception('HTTP status ${res.statusCode}');
    }

    final List<M3uGenericEntry> playlist =
        await M3uParser.parse(_sanitizeM3U(res.body));
    final List<Channel> data = [];

    for (final i in playlist) {
      final title = i.title.trim();
      final link = i.link.trim();
      final tvgId = i.attributes["tvg-id"]?.trim() ?? "";

      // Strict validation: skip blank channel names, header comments, or missing links
      if (title.isEmpty || link.isEmpty || title.startsWith('#')) continue;

      data.add(
        Channel(
          id: tvgId.isNotEmpty ? tvgId : title,
          name: title,
          image: i.attributes["tvg-logo"] ?? "",
          group: i.attributes["group-title"] ?? "JioTV",
          streamUrl: link,
        ),
      );
    }
    return data;
  }

  Future<List<Channel>> _tryFetchJsonChannels() async {
    final res = await http
        .get(Uri.parse(jsonChannelsUrl))
        .timeout(const Duration(seconds: 5));

    talker.debug(
      '[JioTV] JSON channels response status: ${res.statusCode}, body length: ${res.body.length}',
    );

    if (res.statusCode != 200) {
      throw Exception('HTTP status ${res.statusCode}');
    }

    final List<dynamic> jsonList = jsonDecode(res.body);
    final List<Channel> data = [];

    for (final item in jsonList) {
      if (item is! Map) continue;
      final id = item['id']?.toString() ?? item['channel_id']?.toString() ?? '';
      final name = item['name']?.toString().trim() ?? item['channel_name']?.toString().trim() ?? '';
      final logo = item['logo']?.toString() ?? item['logo_url']?.toString() ?? item['icon']?.toString() ?? '';
      final group = item['category']?.toString() ?? item['group']?.toString() ?? 'JioTV';
      final streamUrl = 'http://localhost:5001/live/$id.m3u8';

      if (name.isNotEmpty && id.isNotEmpty) {
        data.add(
          Channel(
            id: id,
            name: name,
            image: logo,
            group: group,
            streamUrl: streamUrl,
          ),
        );
      }
    }
    return data;
  }

  String _sanitizeM3U(String rawM3u) {
    final lines = rawM3u.split('\n');
    final buffer = StringBuffer();

    bool skipBlock = false;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('#EXTINF')) {
        skipBlock = false;
      }

      if (line.startsWith('#EXTVLCOPT')) {
        skipBlock = true;
      }

      if (line.startsWith('http') && skipBlock) {
        continue;
      }

      if (!skipBlock && line.isNotEmpty) {
        buffer.writeln(line);
      }
    }

    return buffer.toString();
  }
}
