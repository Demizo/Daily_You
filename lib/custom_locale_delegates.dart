import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class OcMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const OcMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Pretend to support everything
    return true;
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    if (locale.languageCode == 'oc') {
      // Load French localization for Occitan
      return GlobalMaterialLocalizations.delegate.load(const Locale('fr'));
    }
    return GlobalMaterialLocalizations.delegate.load(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}

class OcCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const OcCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Pretend to support everything
    return true;
  }

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    if (locale.languageCode == 'oc') {
      // Load French localization for Occitan
      return GlobalCupertinoLocalizations.delegate.load(const Locale('fr'));
    }
    return GlobalCupertinoLocalizations.delegate.load(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}

class OcWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const OcWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Pretend to support everything
    return true;
  }

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    if (locale.languageCode == 'oc') {
      // Load French localization for Occitan
      return GlobalWidgetsLocalizations.delegate.load(const Locale('fr'));
    }
    return GlobalWidgetsLocalizations.delegate.load(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
