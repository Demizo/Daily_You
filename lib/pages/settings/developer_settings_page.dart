// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/logging.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class DeveloperSettingsPage extends StatelessWidget {
  const DeveloperSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = Provider.of<ConfigProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.developerOptionsTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsToggle(
            title: l10n.developerOptionsTitle,
            hint: l10n.developerOptionsDescription,
            setting: Settings.developerModeEnabled,
            onChanged: (enabled) async {
              await configProvider.set(Settings.developerModeEnabled, enabled);
              if (!enabled) {
                await configProvider.set(
                    Settings.diagnosticLoggingEnabled, false);
                LogBuffer.clear();
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
          SettingsToggle(
            title: l10n.settingsDiagnosticLoggingTitle,
            hint: l10n.settingsDiagnosticLoggingDescription,
            setting: Settings.diagnosticLoggingEnabled,
            onChanged: (enabled) async {
              await configProvider.set(
                  Settings.diagnosticLoggingEnabled, enabled);
            },
          ),
          SettingsIconAction(
            title: l10n.consoleLogsTitle,
            hint: "${LogBuffer.logs.length} entries",
            icon: const Icon(Icons.terminal_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ConsoleLogsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ConsoleLogsPage extends StatefulWidget {
  const ConsoleLogsPage({super.key});

  @override
  State<ConsoleLogsPage> createState() => _ConsoleLogsPageState();
}

class _ConsoleLogsPageState extends State<ConsoleLogsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.consoleLogsTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: l10n.copyLogs,
            onPressed: () {
              final text = LogBuffer.logs.join('\n');
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.logsCopied)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: l10n.clearLogs,
            onPressed: () {
              setState(() {
                LogBuffer.clear();
              });
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: LogBuffer.logChangeNotifier,
        builder: (context, _, __) {
          final logs = LogBuffer.logs;
          if (logs.isEmpty) {
            return Center(
              child: Text(
                l10n.noLogsRecorded,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final line = logs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: SelectableText(
                  line,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
