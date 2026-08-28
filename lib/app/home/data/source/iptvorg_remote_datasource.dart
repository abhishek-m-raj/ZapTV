import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:m3u_nullsafe/m3u_nullsafe.dart';
import 'package:zaptv/app/home/data/models/channel.dart';

class IptvorgRemoteDataSource {
  IptvorgRemoteDataSource();

  Future<List<Channel>> getAllPosts() async {
    dev.log('Fetching IPTV-Org channels...', name: 'IptvorgRemoteDataSource');

    try {
      final http.Response res = await http.get(
        Uri.parse("https://iptv-org.github.io/iptv/languages/mal.m3u"),
      ).timeout(const Duration(seconds: 10));

      dev.log(
        'IPTV-Org response status: ${res.statusCode}, body length: ${res.body.length}',
        name: 'IptvorgRemoteDataSource',
      );

      if (res.statusCode != 200) {
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

      dev.log(
        'Successfully loaded ${data.length} valid IPTV-Org channels',
        name: 'IptvorgRemoteDataSource',
      );

      return data;
    } catch (e) {
      dev.log(
        'Error fetching IPTV-Org channels: $e',
        name: 'IptvorgRemoteDataSource',
      );
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