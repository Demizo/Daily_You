import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class CustomMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const CustomMaterialLocalizationsDelegate();

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

class CustomCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const CustomCupertinoLocalizationsDelegate();

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

class CustomWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const CustomWidgetsLocalizationsDelegate();

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
