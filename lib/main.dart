import 'package:flutter/material.dart';
import 'package:custom_uploader/views/home_page.dart';
import 'package:flutter/services.dart';
import 'package:custom_uploader/utils/init_database.dart';
import 'package:custom_uploader/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDatabase();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,  // Generated delegate
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),        // English
        Locale('fr'),        // French
        Locale('de'),        // German
        Locale('es'),        // Spanish
        Locale('ru'),        // Russian
        Locale('zh'),        // Simplified Chinese
        Locale('it'),        // Italian
        Locale('ja'),        // Japanese
        Locale('ar'),        // Arabic
        Locale('pt', 'BR'),  // Brazilian Portuguese
        Locale('pl'),        // Polish
        Locale('nl'),        // Dutch
        Locale('tr'),        // Turkish
        Locale('ko'),        // Korean
        Locale('pt'),        // Portuguese
        Locale('uk'),        // Ukrainian
        Locale('zh', 'Hant'),// Traditional Chinese
        Locale('vi'),        // Vietnamese
        Locale('sv'),        // Swedish
        Locale('cs'),        // Czech
        Locale('da'),        // Danish
        Locale('ro'),        // Romanian
        Locale('hu'),        // Hungarian
        Locale('fi'),        // Finnish
        Locale('el'),        // Greek
        Locale('no'),        // Norwegian
        Locale('he'),        // Hebrew
        Locale('af'),        // Afrikaans
        Locale('ca'),        // Catalan
        Locale('sr', 'Cyrl'),// Serbian (Cyrillic)
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        for (var locale in supportedLocales) {
          if (locale.languageCode == deviceLocale?.languageCode &&
              (locale.countryCode == null || locale.countryCode == deviceLocale?.countryCode)) {
            return locale;
          }
        }
        return supportedLocales.first; // fallback locale
      },
      home: HomePage(),
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: ThemeMode.system,
    );
  }
}
