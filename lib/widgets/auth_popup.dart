import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthPopupMode { unlock, setPassword, changePassword }

class AuthPopup extends StatefulWidget {
  final AuthPopupMode mode;
  final String title;
  final bool showBiometrics;
  final bool dismissable;
  final VoidCallback? onSuccess;

  const AuthPopup({
    super.key,
    required this.mode,
    required this.title,
    required this.showBiometrics,
    required this.dismissable,
    this.onSuccess,
  });

  @override
  State<AuthPopup> createState() => _AuthPopupState();

  static Future<bool> hasPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey("app_password_hash");
  }
}

class _AuthPopupState extends State<AuthPopup> {
  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _oldController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  static const _passwordKey = 'app_password_hash';

  Future<String> _hashPassword(String password) async {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_passwordKey, await _hashPassword(password));
  }

  Future<bool> validatePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_passwordKey);
    if (storedHash == null) return false;
    return storedHash == await _hashPassword(password);
  }

  Future<bool> authenticateWithBiometrics() async {
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics;
    if (!canCheck) return false;

    return await auth.authenticate(
      localizedReason: AppLocalizations.of(context)!.unlockAppPrompt,
      options:
          const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      switch (widget.mode) {
        case AuthPopupMode.unlock:
          final valid = await validatePassword(_passwordController.text);
          if (valid) {
            widget.onSuccess?.call();
            Navigator.of(context).pop();
          } else {
            setState(() => _error = 'Incorrect password');
          }
          break;

        case AuthPopupMode.setPassword:
          if (_passwordController.text != _confirmController.text) {
            setState(() => _error = 'Passwords do not match');
            break;
          }
          await savePassword(_passwordController.text);
          widget.onSuccess?.call();
          Navigator.of(context).pop();
          break;

        case AuthPopupMode.changePassword:
          final validOld = await validatePassword(_oldController.text);
          if (!validOld) {
            setState(() => _error = 'Old password incorrect');
            break;
          }
          if (_passwordController.text != _confirmController.text) {
            setState(() => _error = 'New passwords do not match');
            break;
          }
          await savePassword(_passwordController.text);
          widget.onSuccess?.call();
          Navigator.of(context).pop();
          break;
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleBiometric() async {
    final ok = await authenticateWithBiometrics();
    if (ok) {
      widget.onSuccess?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.dismissable,
      child: AlertDialog(
        title: Text(widget.title),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.mode == AuthPopupMode.changePassword)
                TextFormField(
                  controller: _oldController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Old Password'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              if (widget.mode != AuthPopupMode.unlock)
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm Password'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
        actions: [
          if (widget.mode == AuthPopupMode.unlock && widget.showBiometrics)
            IconButton(
              icon: const Icon(Icons.fingerprint),
              onPressed: _handleBiometric,
            ),
          TextButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const CircularProgressIndicator()
                : Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }
}
