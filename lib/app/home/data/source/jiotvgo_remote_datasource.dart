import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:m3u_nullsafe/m3u_nullsafe.dart';
import 'package:zaptv/app/home/data/models/channel.dart';
import 'package:zaptv/core/services/talker_service.dart';

class JiotvGoRemoteDataSource {
  static const String playlistUrl = "http://localhost:5050/playlist.m3u";
  static const String jsonChannelsUrl = "http://localhost:5050/channels";

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
      final licenseType = i.attributes["inputstream-adaptive-license_type"]?.trim() ?? i.attributes["license-type"]?.trim();
      final licenseKey = i.attributes["inputstream-adaptive-license_key"]?.trim() ?? i.attributes["license-key"]?.trim();

      // Strict validation: skip blank channel names, header comments, or missing links
      if (title.isEmpty || link.isEmpty || title.startsWith('#')) continue;

      data.add(
        Channel(
          id: tvgId.isNotEmpty ? tvgId : title,
          name: title,
          image: i.attributes["tvg-logo"] ?? "",
          group: i.attributes["group-title"] ?? "JioTV",
          streamUrl: link,
          licenseType: licenseType,
          licenseKey: licenseKey,
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

    final decoded = jsonDecode(res.body);
    
    if (decoded is Map) {
      // The server returned an object instead of a list. This usually means an error (e.g. not logged in).
      throw Exception('Server returned error object: $decoded');
    }
    
    final List<dynamic> jsonList = decoded as List<dynamic>;
    final List<Channel> data = [];

    for (final item in jsonList) {
      if (item is! Map) continue;
      final id = item['id']?.toString() ?? item['channel_id']?.toString() ?? '';
      final name = item['name']?.toString().trim() ?? item['channel_name']?.toString().trim() ?? '';
      final logo = item['logo']?.toString() ?? item['logo_url']?.toString() ?? item['icon']?.toString() ?? '';
      final group = item['category']?.toString() ?? item['group']?.toString() ?? 'JioTV';
      final streamUrl = 'http://localhost:5050/live/$id.m3u8';
      final licenseType = item['license_type']?.toString() ?? item['drm_type']?.toString();
      final licenseKey = item['license_key']?.toString() ?? item['drm_key']?.toString();

      if (name.isNotEmpty && id.isNotEmpty) {
        data.add(
          Channel(
            id: id,
            name: name,
            image: logo,
            group: group,
            streamUrl: streamUrl,
            licenseType: licenseType,
            licenseKey: licenseKey,
          ),
        );
      }
    }
    return data;
  }

  String _sanitizeM3U(String rawM3u) {
    final lines = rawM3u.split('\n');
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');

    String? currentExtInf;
    final Map<String, String> currentProps = {};

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('#EXTM3U')) continue;

      if (line.startsWith('#EXTINF')) {
        if (currentExtInf != null) {
          buffer.writeln(_buildExtInfLine(currentExtInf, currentProps));
          currentProps.clear();
        }
        currentExtInf = line;
      } else if (line.startsWith('#KODIPROP:')) {
        final propContent = line.substring('#KODIPROP:'.length);
        final eqIdx = propContent.indexOf('=');
        if (eqIdx != -1) {
          final key = propContent.substring(0, eqIdx).trim();
          final val = propContent.substring(eqIdx + 1).trim();
          currentProps[key] = val;
        }
      } else if (line.startsWith('#')) {
        continue;
      } else {
        if (currentExtInf != null) {
          buffer.writeln(_buildExtInfLine(currentExtInf, currentProps));
          currentExtInf = null;
          currentProps.clear();
        }
        buffer.writeln(line);
      }
    }

    if (currentExtInf != null) {
      buffer.writeln(_buildExtInfLine(currentExtInf, currentProps));
    }

    return buffer.toString();
  }

  String _buildExtInfLine(String extInf, Map<String, String> props) {
    if (props.isEmpty) return extInf;

    final commaIdx = extInf.lastIndexOf(',');
    if (commaIdx == -1) {
      final sb = StringBuffer(extInf);
      props.forEach((key, value) {
        final cleanKey = key.replaceAll('.', '-');
        sb.write(' $cleanKey="$value"');
      });
      return sb.toString();
    }

    final attributesPart = extInf.substring(0, commaIdx);
    final namePart = extInf.substring(commaIdx);

    final sb = StringBuffer(attributesPart);
    props.forEach((key, value) {
      final cleanKey = key.replaceAll('.', '-');
      sb.write(' $cleanKey="$value"');
    });
    sb.write(namePart);
    return sb.toString();
  }
}
