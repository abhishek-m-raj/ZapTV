import 'package:flutter/material.dart';
import 'package:zaptv/app/menu/view/widgets/jiotv_login_dialog.dart';
import 'package:zaptv/core/config/locator.dart';
import 'package:zaptv/core/services/jiotvgo_process_service.dart';
import 'package:zaptv/core/services/settings_service.dart';
import 'package:zaptv/core/widgets/tv_focusable_button.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onJioLoginSuccess;

  const SettingsPage({super.key, this.onJioLoginSuccess});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = loc<SettingsService>();
  final JiotvGoProcessService _jiotvService = loc<JiotvGoProcessService>();

  late bool _loadLastSeenChannel;
  late bool _loadLastChannelList;
  bool _isJioLoggedIn = false;
  bool _checkingJio = true;
  int _selectedTabIndex = 0; // 0: Playback, 1: JioTV, 2: About

  @override
  void initState() {
    super.initState();
    _loadLastSeenChannel = _settingsService.loadLastSeenChannelOnStart;
    _loadLastChannelList = _settingsService.loadLastChannelListOnStart;
    _checkJioStatus();
  }

  Future<void> _checkJioStatus() async {
    try {
      final loggedIn = await _jiotvService.isLoggedIn();
      if (mounted) {
        setState(() {
          _isJioLoggedIn = loggedIn;
          _checkingJio = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _checkingJio = false;
        });
      }
    }
  }

  Future<void> _handleJioLogin() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const JiotvLoginDialog(),
    );
    if (result == true) {
      await _checkJioStatus();
      widget.onJioLoginSuccess?.call();
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E29),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.amber, size: 24),
            SizedBox(width: 10),
            Text(
              "Log Out of JioTV?",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to log out? JioTV live channels will be disabled until you log in again.",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TvFocusableButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            label: const Text("Cancel"),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          const SizedBox(width: 8),
          TvFocusableButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            label: const Text("Log Out"),
            unfocusedBackgroundColor: Colors.red.withValues(alpha: 0.15),
            unfocusedTextColor: Colors.redAccent,
            focusedBackgroundColor: Colors.redAccent,
            focusedTextColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _checkingJio = true);
      await _jiotvService.logout();
      await _checkJioStatus();
      widget.onJioLoginSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E13),
      body: Row(
        children: [
          // LEFT NAVIGATION RAIL
          Container(
            width: 270,
            color: const Color(0xFF13151D),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Settings Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Settings",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 20),

                // Nav Tabs
                _SettingsNavItem(
                  icon: Icons.play_circle_outline,
                  label: "Playback & Startup",
                  isSelected: _selectedTabIndex == 0,
                  onSelect: () => setState(() => _selectedTabIndex = 0),
                ),
                const SizedBox(height: 8),
                _SettingsNavItem(
                  icon: Icons.cell_tower,
                  label: "JioTV Account",
                  isSelected: _selectedTabIndex == 1,
                  badgeText: _isJioLoggedIn ? "ACTIVE" : null,
                  badgeColor: const Color(0xFF00E676),
                  onSelect: () => setState(() => _selectedTabIndex = 1),
                ),
                const SizedBox(height: 8),
                _SettingsNavItem(
                  icon: Icons.info_outline,
                  label: "About ZapTV",
                  isSelected: _selectedTabIndex == 2,
                  onSelect: () => setState(() => _selectedTabIndex = 2),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "ZapTV v1.0.0",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const VerticalDivider(color: Colors.white10, width: 1),

          // RIGHT CONTENT PANE
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _buildSelectedTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildPlaybackTab();
      case 1:
        return _buildJioTab();
      case 2:
      default:
        return _buildAboutTab();
    }
  }

  // TAB 0: Playback & Startup
  Widget _buildPlaybackTab() {
    return ListView(
      key: const ValueKey('tab_playback'),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      children: [
        const _SectionHeader(
          title: "Startup & Playback",
          subtitle:
              "Configure how ZapTV initializes channels and playlists upon opening the app.",
        ),
        const SizedBox(height: 28),
        TvSettingsSwitchTile(
          autofocus: true,
          icon: Icons.tv,
          title: "Load last seen channel on app start",
          subtitle:
              "Automatically resume playing the channel you were watching before exiting ZapTV.",
          value: _loadLastSeenChannel,
          onChanged: (val) {
            setState(() {
              _loadLastSeenChannel = val;
              _settingsService.loadLastSeenChannelOnStart = val;
            });
          },
        ),
        const SizedBox(height: 14),
        TvSettingsSwitchTile(
          icon: Icons.format_list_bulleted,
          title: "Load last channel list on start",
          subtitle:
              "Automatically restore your last active playlist category (All Channels, Favorites, JioTV, or IPTV).",
          value: _loadLastChannelList,
          onChanged: (val) {
            setState(() {
              _loadLastChannelList = val;
              _settingsService.loadLastChannelListOnStart = val;
            });
          },
        ),
      ],
    );
  }

  // TAB 1: JioTV Integration
  Widget _buildJioTab() {
    return ListView(
      key: const ValueKey('tab_jiotv'),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      children: [
        const _SectionHeader(
          title: "JioTV Integration",
          subtitle:
              "Connect your Jio mobile account to unlock live TV channels with local FFI streaming.",
        ),
        const SizedBox(height: 28),
        if (_checkingJio)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF161822),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161822),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isJioLoggedIn
                    ? const Color(0xFF00E676).withValues(alpha: 0.3)
                    : Colors.amber.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isJioLoggedIn
                            ? const Color(0xFF00E676).withValues(alpha: 0.15)
                            : Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isJioLoggedIn ? Icons.verified : Icons.cell_tower,
                        color: _isJioLoggedIn
                            ? const Color(0xFF00E676)
                            : Colors.amber,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "JioTV Mobile Account",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _isJioLoggedIn
                                      ? const Color(
                                          0xFF00E676,
                                        ).withValues(alpha: 0.2)
                                      : Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _isJioLoggedIn
                                        ? const Color(0xFF00E676)
                                        : Colors.amber,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _isJioLoggedIn
                                      ? "CONNECTED"
                                      : "NOT CONNECTED",
                                  style: TextStyle(
                                    color: _isJioLoggedIn
                                        ? const Color(0xFF00E676)
                                        : Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isJioLoggedIn
                                ? "Authenticated successfully. JioTV live channels are active in your playlist and streaming locally via FFI on port 5050."
                                : "Log in using your Jio phone number to access full live channels, sports broadcasts, and regional networks.",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (!_isJioLoggedIn) ...[
                      TvFocusableButton(
                        autofocus: true,
                        onPressed: _handleJioLogin,
                        icon: const Icon(Icons.login),
                        label: const Text("Log In to JioTV"),
                      ),
                    ] else ...[
                      TvFocusableButton(
                        autofocus: true,
                        onPressed: _handleJioLogin,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Re-authenticate / Change Number"),
                      ),
                      const SizedBox(width: 14),
                      TvFocusableButton(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text("Log Out"),
                        unfocusedBackgroundColor: Colors.red.withValues(
                          alpha: 0.15,
                        ),
                        unfocusedTextColor: Colors.redAccent,
                        focusedBackgroundColor: Colors.redAccent,
                        focusedTextColor: Colors.white,
                        focusedBorderColor: Colors.white,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // TAB 2: About ZapTV
  Widget _buildAboutTab() {
    return ListView(
      key: const ValueKey('tab_about'),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      children: [
        // App Header Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161822),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tv, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ZapTV",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "v1.0.0",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Developer & Links Info Tiles
        const _AboutInfoTile(
          icon: Icons.person_outline,
          title: "Developer",
          value: "Abhishek M Raj",
        ),
        const SizedBox(height: 10),
        const _AboutInfoTile(
          icon: Icons.code,
          title: "GitHub Repository",
          value: "https://github.com/abhishek-m-raj/ZapTV",
        ),
        const SizedBox(height: 10),
        const _AboutInfoTile(
          icon: Icons.language,
          title: "Portfolio",
          value: "https://www.abhishekmraj.me/",
        ),
      ],
    );
  }
}

class _AboutInfoTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;

  const _AboutInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  State<_AboutInfoTile> createState() => _AboutInfoTileState();
}

class _AboutInfoTileState extends State<_AboutInfoTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onFocusChange: (val) => setState(() => _isFocused = val),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _isFocused ? const Color(0xFF222634) : const Color(0xFF161822),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFocused
                ? Colors.white
                : Colors.white.withValues(alpha: 0.08),
            width: _isFocused ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.icon,
                color: _isFocused ? Colors.white : Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: _isFocused ? Colors.white70 : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.value,
                    style: TextStyle(
                      color: _isFocused
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _SettingsNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback onSelect;

  const _SettingsNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.badgeText,
    this.badgeColor,
    required this.onSelect,
  });

  @override
  State<_SettingsNavItem> createState() => _SettingsNavItemState();
}

class _SettingsNavItemState extends State<_SettingsNavItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _isFocused;

    return InkWell(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        if (focused) widget.onSelect();
      },
      onTap: widget.onSelect,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isFocused
              ? Colors.white.withValues(alpha: 0.16)
              : (widget.isSelected
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isFocused ? Colors.white : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              color: active ? Colors.white : Colors.white60,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (widget.badgeText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (widget.badgeColor ?? Colors.green).withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.badgeText!,
                  style: TextStyle(
                    color: widget.badgeColor ?? Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom TV-friendly switch tile with seamless remote focus and no native Switch trap
class TvSettingsSwitchTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool autofocus;

  const TvSettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  State<TvSettingsSwitchTile> createState() => _TvSettingsSwitchTileState();
}

class _TvSettingsSwitchTileState extends State<TvSettingsSwitchTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      onTap: () {
        widget.onChanged(!widget.value);
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(
          _isFocused ? 1.015 : 1.0,
          _isFocused ? 1.015 : 1.0,
          1.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: _isFocused ? const Color(0xFF222634) : const Color(0xFF161822),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isFocused
                ? Colors.white
                : Colors.white.withValues(alpha: 0.08),
            width: _isFocused ? 2.0 : 1.0,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icon in rounded container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isFocused
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                color: _isFocused ? Colors.white : Colors.white70,
                size: 22,
              ),
            ),
            const SizedBox(width: 20),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: _isFocused
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: _isFocused ? Colors.white70 : Colors.white54,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Custom TV Toggle Switch
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 52,
              height: 30,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: widget.value
                    ? (_isFocused
                          ? const Color(0xFF00E676)
                          : const Color(0xFF00C853))
                    : const Color(0xFF2C303E),
                border: Border.all(
                  color: widget.value
                      ? (_isFocused ? Colors.white : const Color(0xFF00E676))
                      : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: widget.value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
