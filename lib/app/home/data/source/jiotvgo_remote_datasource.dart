import 'package:http/http.dart' as http;
import 'package:m3u_nullsafe/m3u_nullsafe.dart';
import 'package:zaptv/app/home/data/models/channel.dart';

class JiotvGoRemoteDataSource {
  static const String playlistUrl = "http://localhost:5001/playlist.m3u";

  JiotvGoRemoteDataSource();

  Future<List<Channel>> getAllChannels() async {
    final http.Response res = await http
        .get(Uri.parse(playlistUrl))
        .timeout(const Duration(seconds: 5));

    if (res.statusCode != 200) {
      throw Exception('Failed to load JioTV-Go playlist: ${res.statusCode}');
    }

    final List<M3uGenericEntry> playlist =
        await M3uParser.parse(_sanitizeM3U(res.body));
    final List<Channel> data = [];

    for (M3uGenericEntry i in playlist) {
      data.add(
        Channel(
          id: i.attributes["tvg-id"]?.isNotEmpty == true
              ? i.attributes["tvg-id"]!
              : i.title,
          name: i.title,
          image: i.attributes["tvg-logo"] ?? "",
          group: i.attributes["group-title"] ?? "JioTV",
          streamUrl: i.link,
        ),
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
