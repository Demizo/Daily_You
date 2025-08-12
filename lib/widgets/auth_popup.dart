import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
}

class _AuthPopupState extends State<AuthPopup> {
  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  String? _error;
  bool _showPassword = false;
  bool _biometricsPrompted = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus password field in unlock mode
    if (widget.mode == AuthPopupMode.unlock && !widget.showBiometrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _passwordFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _oldController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocusNode.dispose();
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

    bool success = false;
    try {
      final bool didAuthenticate = await auth.authenticate(
          options:
              AuthenticationOptions(stickyAuth: false, biometricOnly: true),
          localizedReason: AppLocalizations.of(context)!.unlockAppPrompt);
      success = didAuthenticate;
    } on PlatformException {
      success = false;
    }
    return success;
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
            setState(() => _error = AppLocalizations.of(context)!
                .settingsSecurityIncorrectPassword);
          }
          break;

        case AuthPopupMode.setPassword:
          if (_passwordController.text != _confirmController.text) {
            setState(() => _error = AppLocalizations.of(context)!
                .settingsSecurityPasswordsDoNotMatch);
            break;
          }
          await savePassword(_passwordController.text);
          widget.onSuccess?.call();
          Navigator.of(context).pop();
          break;

        case AuthPopupMode.changePassword:
          final validOld = await validatePassword(_oldController.text);
          if (!validOld) {
            setState(() => _error = AppLocalizations.of(context)!
                .settingsSecurityIncorrectPassword);
            break;
          }
          if (_passwordController.text != _confirmController.text) {
            setState(() => _error = AppLocalizations.of(context)!
                .settingsSecurityPasswordsDoNotMatch);
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
    if (widget.showBiometrics && !_biometricsPrompted) {
      _biometricsPrompted = true;
      _handleBiometric();
    }
    return PopScope(
      canPop: widget.dismissable,
      child: AlertDialog(
        title: Column(children: [
          Center(
              child: Icon(
            Icons.lock_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 32,
          )),
          SizedBox(
            height: 4,
          ),
          Text(widget.title)
        ]),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.mode == AuthPopupMode.changePassword)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _oldController,
                    obscureText: !_showPassword,
                    autocorrect: false,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                        labelText: AppLocalizations.of(context)!
                            .settingsSecurityOldPassword),
                    validator: (v) => v!.isEmpty
                        ? AppLocalizations.of(context)!.requiredPrompt
                        : null,
                  ),
                ),
              if (widget.mode == AuthPopupMode.changePassword) Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: !_showPassword,
                  autocorrect: false,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                      labelText: AppLocalizations.of(context)!
                          .settingsSecurityPassword),
                  validator: (v) => v!.isEmpty
                      ? AppLocalizations.of(context)!.requiredPrompt
                      : null,
                ),
              ),
              if (widget.mode != AuthPopupMode.unlock)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _confirmController,
                    obscureText: !_showPassword,
                    autocorrect: false,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                        labelText: AppLocalizations.of(context)!
                            .settingsSecurityConfirmPassword),
                    validator: (v) => v!.isEmpty
                        ? AppLocalizations.of(context)!.requiredPrompt
                        : null,
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              if (widget.mode == AuthPopupMode.unlock && widget.showBiometrics)
                IconButton(
                  onPressed: _handleBiometric,
                  icon: const Icon(Icons.fingerprint),
                  iconSize: 32,
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          icon: Icon(!_showPassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          }),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : IconButton.filled(
                              onPressed: _handleSubmit,
                              icon: Icon(Icons.check_rounded),
                              iconSize: 28,
                            ),
                    ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}
