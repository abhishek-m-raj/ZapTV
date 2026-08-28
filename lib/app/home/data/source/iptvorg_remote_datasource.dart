import 'package:http/http.dart' as http;
import 'package:m3u_nullsafe/m3u_nullsafe.dart';
import 'package:zaptv/app/home/data/models/channel.dart';

class IptvorgRemoteDataSource {
  IptvorgRemoteDataSource();

  Future<List<Channel>> getAllPosts() async {
    final http.Response res = await http.get(
      Uri.parse("https://iptv-org.github.io/iptv/languages/mal.m3u"),
    );
    final List<M3uGenericEntry> playlist = await M3uParser.parse(_sanitizeM3U(res.body));
    final List<Channel> data = [];
    for (M3uGenericEntry i in playlist) {
      data.add(
        Channel(
          id: i.attributes["tvg-id"] ?? "",
          name: i.title,
          image: i.attributes["tvg-logo"] ?? "",
          group: i.attributes["group-title"] ?? "",
          streamUrl: i.link
        )
      );
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