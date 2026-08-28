import 'package:talker_flutter/talker_flutter.dart';

/// Global Talker logger instance for structured logging, video traces, and error logging across ZapTV.
final Talker talker = TalkerFlutter.init(
  settings: TalkerSettings(
    maxHistoryItems: 1000,
    useConsoleLogs: true,
  ),
);
