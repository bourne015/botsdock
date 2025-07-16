// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:botsdock/apps/chat/models/mcp/mcp_settings_providers.dart';
import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/utils/global.dart';
import 'package:botsdock/data/theme.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:botsdock/l10n/gallery_localizations.dart';
import 'package:botsdock/constants.dart';
import 'package:botsdock/data/gallery_options.dart';
import 'package:botsdock/routes.dart';
//import 'package:get_storage/get_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // GoogleFonts.config.allowRuntimeFetching = false;
  // //await GetStorage.init();

  // if (defaultTargetPlatform != TargetPlatform.linux &&
  //     defaultTargetPlatform != TargetPlatform.windows &&
  //     defaultTargetPlatform != TargetPlatform.macOS) {
  WidgetsFlutterBinding.ensureInitialized();
  // }
  final prefs = await SharedPreferences.getInstance();
  Global.setUp(prefs);
  // final initialSettingsRepo = SettingsRepositoryImpl(prefs);
  // final initialServerList = await initialSettingsRepo.getMcpServerList();
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      // settingsRepositoryProvider.overrideWith(
      //   (ref) => SettingsRepositoryImpl(ref.watch(sharedPreferencesProvider)),
      // ),
      // mcpServerListProvider.overrideWith((ref) => initialServerList),
    ],
    child: const GalleryApp(),
  ));
}

class GalleryApp extends rp.ConsumerWidget {
  const GalleryApp({
    super.key,
    this.initialRoute,
    this.isTestMode = false,
  });

  final String? initialRoute;
  final bool isTestMode;

  @override
  Widget build(BuildContext context, rp.WidgetRef ref) {
    return ModelBinding(
      initialModel: GalleryOptions(
        themeMode: ThemeMode.system,
        textScaleFactor: systemTextScaleFactorOption,
        locale: null,
        timeDilation: timeDilation,
        platform: defaultTargetPlatform,
        isTestMode: isTestMode,
      ),
      child: Builder(
        builder: (context) {
          final options = GalleryOptions.of(context);
          final hasHinge = MediaQuery.of(context).hinge?.bounds != null;
          User user = ref.watch(userProvider);
          return MaterialApp(
            restorationScopeId: 'rootGallery',
            title: "AI启示录",
            debugShowCheckedModeBanner: false,
            themeMode: user.settings?.themeMode ?? ThemeMode.system,
            theme: ChatThemeData.lightThemeData.copyWith(
              platform: options.platform,
            ),
            darkTheme: ChatThemeData.darkThemeData.copyWith(
              platform: options.platform,
            ),
            localizationsDelegates: const [
              ...GalleryLocalizations.localizationsDelegates,
              //LocaleNamesLocalizationsDelegate()
            ],
            initialRoute: initialRoute,
            //supportedLocales: GalleryLocalizations.supportedLocales,
            supportedLocales: [
              Locale('zh'),
            ],
            locale: options.locale,
            localeListResolutionCallback: (locales, supportedLocales) {
              deviceLocale = locales?.first;
              return basicLocaleListResolution(locales, supportedLocales);
            },
            onGenerateRoute: (settings) =>
                RouteConfiguration.onGenerateRoute(settings, hasHinge),
          );
        },
      ),
    );
  }
}
