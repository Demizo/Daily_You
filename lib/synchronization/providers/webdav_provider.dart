import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/synchronization/synchronization_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart';

/*
WebDav testing: docker run --rm -p 8080:8080 -v ./data:/data -e RCLONE_USER=username -e RCLONE_PASS=password rclone/rclone:1.71.2 serve webdav /data --addr :8080 --baseurl '/webdav'
 */
class WebdavProvider extends SynchronizationProvider {
  @override
  Future<bool> authorize() async {
    try {
      // Verify required credentials are present.
      final hasCredentials = await Future.wait([
        hasSecret('webdav_server_url'),
        hasSecret('webdav_username'),
        hasSecret('webdav_password'),
      ]);

      if (!hasCredentials.every((exists) => exists)) {
        return false;
      }

      final client = await _createClient();
      final path =
          await getSecret('webdav_path', defaultValue: '/daily-you/') ??
              '/daily-you/';

      try {
        await client.ping();
        await client.mkdirAll(path);

        return true;
      } catch (e) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<Client> _createClient() async {
    final serverUrl = await getSecret('webdav_server_url');
    final username = await getSecret('webdav_username');
    final password = await getSecret('webdav_password');

    if (serverUrl == null || username == null || password == null) {
      throw Exception('Missing WebDAV credentials');
    }

    var client = newClient(serverUrl, user: username, password: password);
    client.setHeaders({'accept-charset': 'utf-8'});

    // Set the connection server timeout time in milliseconds.
    client.setConnectTimeout(8000);

    // Set send data timeout time in milliseconds.
    client.setSendTimeout(8000);

    // Set transfer data time in milliseconds.
    client.setReceiveTimeout(8000);
    return client;
  }

  @override
  Future<SynchronizationResult> synchronize({bool? preferRemote}) async {
    var bytes = await AppDatabase.instance.getDatabaseBytes();
    if (bytes == null) {
      return SynchronizationResult.failure;
    }
    if (!await authorize()) {
      return SynchronizationResult.unauthorized;
    }

    final client = await _createClient();
    final path = await getSecret('webdav_path', defaultValue: '/daily-you/') ??
        '/daily-you/';

    try {
      final existingFiles = await client.readDir(path);
      // TODO check correctly for the conflicts
      if (existingFiles.any((file) => file.name == 'daily_you_backup.db')) {
        if (preferRemote == null) {
          return SynchronizationResult.conflict;
        } else if (preferRemote) {
          try {
            final remoteBytes = await client.read('$path/daily_you_backup.db');
            await AppDatabase.instance.restoreFromBytes(remoteBytes);
            return SynchronizationResult.success;
          } catch (e) {
            return SynchronizationResult.failure;
          }
        }
      }
    } catch (e) {
      // If the directory doesn't exist, we'll create it during upload, so we can ignore this error.
    }

    try {
      await client.write('$path/daily_you_backup.db', bytes);
      return SynchronizationResult.success;
    } catch (e) {
      return SynchronizationResult.failure;
    }
  }

  @override
  StatefulWidget getSettingsWidget() {
    return WebdavSettingsWidget(provider: this);
  }
}

class WebdavSettingsWidget extends StatefulWidget {
  final WebdavProvider provider;
  final VoidCallback? onSaved;

  const WebdavSettingsWidget({
    super.key,
    required this.provider,
    this.onSaved,
  });

  @override
  _WebdavSettingsWidgetState createState() => _WebdavSettingsWidgetState();
}

class _WebdavSettingsWidgetState extends State<WebdavSettingsWidget> {
  late TextEditingController _serverUrlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _pathController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _pathController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final serverUrl = await widget.provider.getSecret('webdav_server_url');
      final username = await widget.provider.getSecret('webdav_username');
      final password = await widget.provider.getSecret('webdav_password');
      final path = await widget.provider.getSecret('webdav_path');

      if (mounted) {
        setState(() {
          _serverUrlController.text = serverUrl ?? '';
          _usernameController.text = username ?? '';
          _passwordController.text = password ?? '';
          _pathController.text = path ?? '/daily-you/';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await widget.provider
          .storeSecret('webdav_server_url', _serverUrlController.text);
      await widget.provider
          .storeSecret('webdav_username', _usernameController.text);
      await widget.provider
          .storeSecret('webdav_password', _passwordController.text);
      await widget.provider.storeSecret('webdav_path', _pathController.text);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "WebDAV Settings",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _serverUrlController,
                  decoration: const InputDecoration(
                    labelText: "Server URL",
                    hintText: "https://example.com/webdav",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pathController,
                  decoration: const InputDecoration(
                    labelText: "Path",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Settings'),
                ),
              ],
            ),
    );
  }
}
