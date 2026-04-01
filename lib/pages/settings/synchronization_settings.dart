import 'package:daily_you/config_provider.dart';
import 'package:daily_you/synchronization/synchronization_provider.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SynchronizationSettings extends StatefulWidget {
  const SynchronizationSettings({super.key});

  @override
  State<SynchronizationSettings> createState() =>
      _SynchronizationSettingsState();
}

class _SynchronizationSettingsState extends State<SynchronizationSettings> {
  final _formKey = GlobalKey<FormState>();
  SynchronizationProvider? _currentProvider;
  bool _isAuthorizing = false;
  bool _isSynchronizing = false;

  @override
  void initState() {
    super.initState();
  }

  void _initializeProvider(String providerType) {
    try {
      setState(() {
        _currentProvider = ProviderFactory.createProvider(providerType);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing provider: $e')),
      );
    }
  }

  Future<void> _handleAuthorize() async {
    if (_currentProvider == null) return;

    setState(() => _isAuthorizing = true);

    try {
      final success = await _currentProvider!.authorize();

      if (mounted) {
        setState(() => _isAuthorizing = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authorization successful!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authorization failed!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAuthorizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authorization error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSynchronize({bool? preferRemote}) async {
    if (_currentProvider == null) return;

    setState(() => _isSynchronizing = true);

    try {
      final result = await _currentProvider!.synchronize();

      if (mounted) {
        setState(() => _isSynchronizing = false);

        String message;
        Color backgroundColor;
        bool showRemoteLocalQuestion = false;

        // TODO: fix this UI implementation and handle conflict resolution!

        switch (result.status) {
          case SynchronizationResultStatus.success:
            message = 'Synchronization completed successfully!';
            backgroundColor = Colors.green;
            break;
          case SynchronizationResultStatus.failure:
            message = 'Synchronization failed!';
            backgroundColor = Colors.red;
            break;
          case SynchronizationResultStatus.conflict:
            message = 'Conflict detected during synchronization!';
            backgroundColor = Colors.orange;
            showRemoteLocalQuestion = true;
            break;
          case SynchronizationResultStatus.unauthorized:
            message = 'Unauthorized! Please authorize first.';
            backgroundColor = Colors.red;
            break;
          case SynchronizationResultStatus.encryptionMismatch:
            message = 'Encryption setting must be same in app and on the remote';
            backgroundColor = Colors.red;
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
          ),
        );

        if (showRemoteLocalQuestion) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Conflict Detected'),
              content: const Text(
                  'A conflict was detected during synchronization. Do you want to prefer remote changes?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleSynchronize(preferRemote: true);
                  },
                  child: const Text('Prefer Remote'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleSynchronize(preferRemote: false);
                  },
                  child: const Text('Prefer Local'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSynchronizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synchronization error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final providerItems = <String>{'none', ...ProviderFactory.supportedProviders}.toList();
    final savedProvider = configProvider.get(ConfigKey.syncProvider) as String?;
    final selectedProvider =  providerItems.contains(savedProvider) ? savedProvider : 'none';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Synchronization"), // TODO: localization
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsToggle(
            title: "Enable synchronization",
            settingsKey: ConfigKey.syncEnabled,
            onChanged: (value) {
              configProvider.set(ConfigKey.syncEnabled, value);
              if (!value) {
                setState(() => _currentProvider = null);
              }
            },
          ),
          if (configProvider.get(ConfigKey.syncEnabled)) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Divider(),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedProvider,
                      decoration: const InputDecoration(
                        labelText: 'Sync Provider',
                        border: OutlineInputBorder(),
                      ),
                      items: providerItems.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value == 'none' ? 'NONE' : value.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null && newValue != 'none') {
                          configProvider.set(ConfigKey.syncProvider, newValue);
                          _initializeProvider(newValue);
                        } else {
                          configProvider.set(ConfigKey.syncProvider, 'none');
                          setState(() => _currentProvider = null);
                        }
                      },
                    ),
                  ),
                  // Provider settings widget
                  if (_currentProvider != null) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _currentProvider!.getSettingsWidget(),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isAuthorizing ? null : _handleAuthorize,
                              icon: _isAuthorizing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login),
                              label: Text(_isAuthorizing
                                  ? 'Authorizing...'
                                  : 'Authorize'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSynchronizing
                                  ? null
                                  : _handleSynchronize,
                              icon: _isSynchronizing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.sync),
                              label: Text(_isSynchronizing
                                  ? 'Syncing...'
                                  : 'Synchronize'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
