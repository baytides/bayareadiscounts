import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import '../providers/programs_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_prefs_provider.dart';
import '../config/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  String _buildNumber = '';
  String _cacheSize = 'Calculating...';
  bool _checkingForUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    if (!mounted) return;
    final provider = context.read<ProgramsProvider>();

    final packageInfo = await PackageInfo.fromPlatform();
    final cacheSize = await provider.getCacheSize();

    if (mounted) {
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _cacheSize = _formatBytes(cacheSize);
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 Bytes';
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    final i = (bytes > 0) ? (bytes.bitLength - 1) ~/ 10 : 0;
    final size = bytes / (1 << (i * 10));
    return '${size.toStringAsFixed(2)} ${sizes[i]}';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _checkForUpdate() async {
    if (_checkingForUpdate) return;

    setState(() => _checkingForUpdate = true);

    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/baytides/baynavigator/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestTag = data['tag_name'] as String? ?? '';
        final latestVersion = latestTag.startsWith('v') ? latestTag.substring(1) : latestTag;

        // Compare versions
        final currentBuild = int.tryParse(_buildNumber) ?? 0;
        final latestBuild = _extractBuildNumber(latestVersion);

        if (latestBuild > currentBuild) {
          _showUpdateDialog(latestVersion, data['html_url'] as String? ?? '');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have the latest version')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not check for updates')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not check for updates')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _checkingForUpdate = false);
      }
    }
  }

  int _extractBuildNumber(String version) {
    // Version format: 1.5.31+43 or just 1.5.31
    final parts = version.split('+');
    if (parts.length > 1) {
      return int.tryParse(parts[1]) ?? 0;
    }
    // If no build number, try to extract from version (e.g., 1.5.31 -> 43 based on pattern)
    // For simplicity, compare version strings
    final versionParts = parts[0].split('.');
    if (versionParts.length >= 3) {
      // Use patch version as a rough build indicator
      return int.tryParse(versionParts[2]) ?? 0;
    }
    return 0;
  }

  String _getDownloadUrl() {
    const baseUrl = 'https://github.com/baytides/baynavigator/releases/latest/download';
    if (Platform.isAndroid) {
      return '$baseUrl/bay-navigator.apk';
    } else if (Platform.isMacOS) {
      return '$baseUrl/Bay-Area-Discounts-macOS.dmg';
    } else if (Platform.isWindows) {
      return '$baseUrl/Bay-Area-Discounts-Windows-Setup.exe';
    } else if (Platform.isLinux) {
      return '$baseUrl/Bay-Area-Discounts-Linux.tar.gz';
    }
    return 'https://github.com/baytides/baynavigator/releases/latest';
  }

  void _showUpdateDialog(String newVersion, String releaseUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Text('A new version ($newVersion) is available. Would you like to download it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl(_getDownloadUrl());
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: Column(
                children: [
                  Semantics(
                    image: true,
                    label: 'Bay Navigator logo',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/favicons/web-app-manifest-512x512.png',
                        width: 80,
                        height: 80,
                        semanticLabel: 'Bay Navigator logo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bay Navigator',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your guide to local savings & benefits',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Profile Section
            Consumer2<UserPrefsProvider, ProgramsProvider>(
              builder: (context, userPrefs, programsProvider, child) {
                final groups = userPrefs.selectedGroups;
                final countyId = userPrefs.selectedCounty;

                // Get group names
                final groupNames = groups
                    .map((id) => programsProvider.groups.where((g) => g.id == id).firstOrNull?.name)
                    .whereType<String>()
                    .toList();

                // Get county name
                final countyName = countyId != null
                    ? programsProvider.areas.where((a) => a.id == countyId).firstOrNull?.name
                    : null;

                return _buildSection(
                  context,
                  title: 'Your Profile',
                  children: [
                    if (userPrefs.hasPreferences) ...[
                      if (groupNames.isNotEmpty)
                        _buildRow(context, 'Groups', groupNames.join(', ')),
                      if (groupNames.isNotEmpty && countyName != null)
                        _buildDivider(context),
                      if (countyName != null)
                        _buildRow(context, 'County', countyName),
                      _buildDivider(context),
                    ],
                    _buildButton(
                      context,
                      icon: '✏️',
                      label: userPrefs.hasPreferences ? 'Edit Profile' : 'Set Up Profile',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        userPrefs.reopenOnboarding();
                      },
                    ),
                    if (userPrefs.hasPreferences) ...[
                      _buildDivider(context),
                      _buildButton(
                        context,
                        label: 'Clear Profile',
                        isDanger: true,
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Clear Profile'),
                              content: const Text(
                                'This will remove your profile preferences. You can set them up again anytime.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.danger,
                                  ),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && context.mounted) {
                            await userPrefs.clearPreferences();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile cleared')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ],
                );
              },
            ),

            // About Section
            _buildSection(
              context,
              title: 'About',
              children: [
                _buildRow(context, 'App Version', _version),
                Consumer<ProgramsProvider>(
                  builder: (context, provider, child) {
                    final metadata = provider.metadata;
                    if (metadata == null) return const SizedBox.shrink();
                    return Column(
                      children: [
                        _buildDivider(context),
                        _buildRow(context, 'Database Version', metadata.version),
                        _buildDivider(context),
                        _buildRow(context, 'Total Programs', '${metadata.totalPrograms}'),
                        _buildDivider(context),
                        _buildRow(
                          context,
                          'Last Updated',
                          _formatDate(metadata.generatedAt),
                        ),
                      ],
                    );
                  },
                ),
                _buildDivider(context),
                _buildButton(
                  context,
                  icon: '🔄',
                  label: 'Refresh Database',
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final provider = context.read<ProgramsProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    final hasUpdate = await provider.refreshMetadata();
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            hasUpdate
                                ? 'Database updated!'
                                : 'Already up to date',
                          ),
                        ),
                      );
                    }
                  },
                ),
                // Show Check for Update on Android and desktop (iOS must update via App Store)
                if (Platform.isAndroid || Platform.isMacOS || Platform.isWindows || Platform.isLinux) ...[
                  _buildDivider(context),
                  _buildButton(
                    context,
                    icon: _checkingForUpdate ? '⏳' : '📲',
                    label: _checkingForUpdate ? 'Checking...' : 'Check for App Update',
                    onTap: _checkingForUpdate ? () {} : () {
                      HapticFeedback.lightImpact();
                      _checkForUpdate();
                    },
                  ),
                ],
                _buildDivider(context),
                _buildButton(
                  context,
                  icon: '🌐',
                  label: 'baynavigator.org',
                  onTap: () => _launchUrl('https://baynavigator.org'),
                ),
                _buildDivider(context),
                _buildButton(
                  context,
                  icon: '🌊',
                  label: 'baytides.org',
                  onTap: () => _launchUrl('https://baytides.org'),
                ),
              ],
            ),

            // Appearance Section
            _buildSection(
              context,
              title: 'Appearance',
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return _buildButton(
                      context,
                      icon: isDark ? '🌙' : '☀️',
                      label: 'Theme',
                      value: themeProvider.modeLabel,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showThemeDialog(context);
                      },
                    );
                  },
                ),
              ],
            ),

            // Storage Section
            _buildSection(
              context,
              title: 'Storage',
              children: [
                _buildRow(context, 'Cache Size', _cacheSize),
                _buildDivider(context),
                _buildButton(
                  context,
                  label: 'Clear Cache',
                  isDanger: true,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final provider = context.read<ProgramsProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Clear Cache'),
                        content: const Text(
                          'This will remove all cached program data. The app will re-download data on next use.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger,
                            ),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      await provider.clearCache();
                      setState(() {
                        _cacheSize = '0 Bytes';
                      });
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Cache cleared')),
                      );
                    }
                  },
                ),
              ],
            ),

            // Support Section
            _buildSection(
              context,
              title: 'Support Our Work',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Help Keep This App Free',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bay Navigator is a volunteer-run project. Your donation helps us maintain the app and add new programs.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _launchUrl('https://baytides.org/donate');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Donate via Website',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),

            // Links Section
            _buildSection(
              context,
              title: 'Links',
              children: [
                _buildButton(
                  context,
                  icon: '🌐',
                  label: 'Visit Website',
                  onTap: () => _launchUrl('https://baynavigator.org'),
                ),
                _buildDivider(context),
                _buildButton(
                  context,
                  icon: '🌊',
                  label: 'Bay Tides (Parent Org)',
                  onTap: () => _launchUrl('https://baytides.org'),
                ),
              ],
            ),

            // Feedback Section
            _buildSection(
              context,
              title: 'Feedback',
              children: [
                _buildButton(
                  context,
                  icon: '💬',
                  label: 'Send Feedback',
                  onTap: () => _launchUrl(
                    'https://github.com/baytides/baynavigator/issues/new?labels=feedback',
                  ),
                ),
                _buildDivider(context),
                _buildButton(
                  context,
                  icon: '🐛',
                  label: 'Report an Issue',
                  onTap: () => _launchUrl(
                    'https://github.com/baytides/baynavigator/issues/new?labels=bug',
                  ),
                ),
              ],
            ),

            // Legal Section
            _buildSection(
              context,
              title: 'Legal & Privacy',
              children: [
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    return _buildSwitchRow(
                      context,
                      label: 'Crash Reporting',
                      subtitle: 'Help improve the app by sending anonymous crash reports',
                      value: settings.crashReportingEnabled,
                      onChanged: (value) async {
                        HapticFeedback.lightImpact();
                        final messenger = ScaffoldMessenger.of(context);
                        await settings.setCrashReportingEnabled(value);
                        if (!value && mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Crash reporting disabled. Restart app for full effect.',
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
                _buildDivider(context),
                _buildButton(
                  context,
                  icon: '⚠️',
                  label: 'Disclaimer',
                  onTap: () => _showDisclaimer(context),
                ),
                _buildDivider(context),
                _buildButton(
                  context,
                  icon: '📄',
                  label: 'Terms of Service',
                  onTap: () => _launchUrl('https://baynavigator.org/terms'),
                ),
                _buildDivider(context),
                _buildButton(
                  context,
                  icon: '🔒',
                  label: 'Privacy Policy',
                  onTap: () => _launchUrl('https://baynavigator.org/privacy'),
                ),
              ],
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(
                    'Bay Navigator - a Bay Tides project',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connecting residents to public benefits and community resources',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    String? icon,
    required String label,
    String? value,
    bool isDanger = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDanger ? AppColors.danger : AppColors.primary,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            if (!isDanger)
              Icon(
                Icons.chevron_right,
                color: isDarkTheme ? AppColors.darkBorder : AppColors.lightBorder,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            thumbColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? Colors.white : null),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 16,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Appearance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in AppThemeMode.values)
              ListTile(
                title: Text(mode.name[0].toUpperCase() + mode.name.substring(1)),
                leading: Icon(
                  themeProvider.mode == mode
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: themeProvider.mode == mode ? AppColors.primary : null,
                ),
                onTap: () {
                  themeProvider.setMode(mode);
                  Navigator.pop(dialogContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disclaimer'),
        content: const Text(
          'This app is not affiliated with, endorsed by, or connected to any government agency. Bay Navigator is an independent project of Bay Tides, a 501(c)(3) nonprofit organization.\n\nProgram information is compiled from publicly available sources. Each program listing includes a link to the official source where you can verify current eligibility requirements and apply directly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }
}
