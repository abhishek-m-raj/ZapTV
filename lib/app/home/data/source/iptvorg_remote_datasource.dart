import 'package:http/http.dart' as http;
import 'package:m3u_nullsafe/m3u_nullsafe.dart';
import 'package:zaptv/app/home/data/models/channel.dart';
import 'package:zaptv/core/services/talker_service.dart';

class IptvorgRemoteDataSource {
  IptvorgRemoteDataSource();

  Future<List<Channel>> getAllPosts() async {
    talker.info('[IPTV-Org] Fetching channel list...');

    try {
      final http.Response res = await http.get(
        Uri.parse("https://iptv-org.github.io/iptv/languages/mal.m3u"),
      ).timeout(const Duration(seconds: 10));

      talker.info(
        '[IPTV-Org] Response status: ${res.statusCode}, length: ${res.body.length}',
      );

      if (res.statusCode != 200) {
        talker.error('[IPTV-Org] HTTP request failed: status ${res.statusCode}');
        return [];
      }

      final List<M3uGenericEntry> playlist =
          await M3uParser.parse(_sanitizeM3U(res.body));
      final List<Channel> data = [];

      for (final i in playlist) {
        final title = i.title.trim();
        final link = i.link.trim();
        final tvgId = i.attributes["tvg-id"]?.trim() ?? "";

        // Skip blank channel names, header comments, or empty stream links
        if (title.isEmpty || link.isEmpty || title.startsWith('#')) continue;

        data.add(
          Channel(
            id: tvgId.isNotEmpty ? tvgId : title,
            name: title,
            image: i.attributes["tvg-logo"] ?? "",
            group: i.attributes["group-title"] ?? "IPTV",
            streamUrl: link,
          ),
        );
      }

      talker.info(
        '[IPTV-Org] Successfully loaded ${data.length} channels',
      );

      return data;
    } catch (e, st) {
      talker.handle(e, st, '[IPTV-Org] Error fetching channels');
      return [];
    }
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