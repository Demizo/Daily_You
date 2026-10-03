import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart' as sdk;
import 'package:material_ui/material_ui.dart';

class OccitanFrenchFallbackDelegate<T> extends LocalizationsDelegate<T> {
  const OccitanFrenchFallbackDelegate(this.delegate);

  final LocalizationsDelegate<T> delegate;

  @override
  Type get type => delegate.type;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) =>
      delegate.load(locale.languageCode == 'oc' ? const Locale('fr') : locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}

const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  OccitanFrenchFallbackDelegate(GlobalMaterialLocalizations.delegate),
  OccitanFrenchFallbackDelegate(GlobalCupertinoLocalizations.delegate),
  OccitanFrenchFallbackDelegate(sdk.GlobalWidgetsLocalizations.delegate),
];

const sdkLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  OccitanFrenchFallbackDelegate(sdk.GlobalMaterialLocalizations.delegate),
  OccitanFrenchFallbackDelegate(sdk.GlobalCupertinoLocalizations.delegate),
  OccitanFrenchFallbackDelegate(sdk.GlobalWidgetsLocalizations.delegate),
];
