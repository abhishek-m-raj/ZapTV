import 'package:zaptv/core/services/hive_db.dart';

class SettingsService {
  final HiveDb _hiveDb;

  static const String keyLoadLastSeenChannel =
      'load_last_seen_channel_on_start';
  static const String keyLoadLastChannelList =
      'load_last_channel_list_on_start';
  static const String keyLastSeenChannelId = 'last_seen_channel_id';
  static const String keyLastChannelListCategory = 'last_channel_list_category';

  SettingsService({required HiveDb hiveDb}) : _hiveDb = hiveDb;

  /// Whether to load the last seen channel on app start (default: true).
  bool get loadLastSeenChannelOnStart =>
      _hiveDb.getData(keyLoadLastSeenChannel) ?? true;

  set loadLastSeenChannelOnStart(bool value) =>
      _hiveDb.putData(keyLoadLastSeenChannel, value);

  /// Whether to restore the last active channel list/category on app start (default: true).
  bool get loadLastChannelListOnStart =>
      _hiveDb.getData(keyLoadLastChannelList) ?? true;

  set loadLastChannelListOnStart(bool value) =>
      _hiveDb.putData(keyLoadLastChannelList, value);

  /// The channel ID of the last seen channel.
  String? get lastSeenChannelId =>
      _hiveDb.getData(keyLastSeenChannelId) as String?;

  set lastSeenChannelId(String? value) =>
      _hiveDb.putData(keyLastSeenChannelId, value);

  /// The category index of the last active channel list (0: All, 1: Favorites, 2: JioTV, 3: IPTV).
  int get lastChannelListCategory =>
      (_hiveDb.getData(keyLastChannelListCategory) as int?) ?? 0;

  set lastChannelListCategory(int value) =>
      _hiveDb.putData(keyLastChannelListCategory, value);
}
