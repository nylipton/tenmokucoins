import 'dart:io';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:tenmoku_coins/display/home_page.dart';
import 'package:tenmoku_coins/display/message_page_widget.dart';

import 'display/interests_page.dart';

import 'package:flutter/cupertino.dart';

void main() {
  // LicenseRegistry.addLicense(() async* {
  //   final license = await rootBundle.loadString('google_fonts/OFL.txt');
  //   yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  // });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp() {
    Logger.level = Level.debug;
  }

  static const lightColor = Color(0xFFF4F1DE);

  static const darkColor = Color(0xFF3D405B);
  static const error = Colors.red;

  static const primary = Color(0xFFE07A5F);

  static const primaryVariant = Color(0xEEE07A5F);

  static const secondary = Color(0xFF81B29A);

  static const secondaryVariant = Color(0xAA81B29A);

  @override
  Widget build(BuildContext context) {
    // Theme colors from https://coolors.co/f4f1de-e07a5f-3d405b-81b29a-f2cc8f
    ColorScheme tenmokuColorScheme = ColorScheme.light(
      background: lightColor,
      onBackground: darkColor,
      error: error,
      onError: darkColor,
      primary: primary,
      primaryVariant: primaryVariant,
      onPrimary: lightColor,
      secondary: secondary,
      secondaryVariant: secondaryVariant,
      onSecondary: darkColor,
      surface: lightColor,
      onSurface: Colors.black,
    );

    ThemeData theme = ThemeData.from(
      colorScheme: tenmokuColorScheme,
      textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme),
    ).copyWith(
        cupertinoOverrideTheme: NoDefaultCupertinoThemeData(),
        appBarTheme: AppBarTheme(
            color: primary,
            textTheme:
                GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)));

    if (Platform.isIOS) {
      //   MaterialBasedCupertinoThemeData cTheme =
      //       MaterialBasedCupertinoThemeData(materialTheme: theme) ;
      // .copyWith(
      //       barBackgroundColor: theme.colorScheme.primary,
      //       primaryContrastingColor: theme.colorScheme.onPrimary,
      // ) ;

      return Theme(
          data: theme,
          child: CupertinoApp(
            localizationsDelegates: [
              DefaultMaterialLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            title: 'Tenmoku Coins',
            onGenerateRoute: (settings) =>
                TenmokuRouter.generateRoute(true, settings),
            initialRoute: TenmokuRouter.homeRoute,
          ));
    } else {
      return MaterialApp(
        title: 'Tenmoku Coin Trader',
        theme: theme,
        onGenerateRoute: (settings) =>
            TenmokuRouter.generateRoute(false, settings),
        initialRoute: TenmokuRouter.homeRoute,
      );
    }
  }
}

class TenmokuRouter {
  static const String homeRoute = '/';
  /// The interests page, which lets users select what tags they are interested in
  static const String interestsRoute = '/interests';
  /// The message page, which lets users see a message and the replies
  static const String messageRoute = '/message';

  static Route<dynamic> generateRoute(bool iOS, RouteSettings settings) {
    PageRoute route;

    switch (settings.name) {
      case homeRoute:
        route = (iOS)
            ? CupertinoPageRoute(builder: (_) => HomePage())
            : MaterialPageRoute(builder: (_) => HomePage());

        break;
      case interestsRoute:
        var tags = settings.arguments;
        route = (iOS)
            ? CupertinoPageRoute(
                fullscreenDialog: true, builder: (_) => InterestsPage(tags))
            : MaterialPageRoute(
                fullscreenDialog: true, builder: (_) => InterestsPage(tags));

        break;
      case messageRoute:
        var message = settings.arguments;
        route = (iOS)
            ? CupertinoPageRoute(
                fullscreenDialog: true, builder: (_) => MessagePageWidget(message))
            : MaterialPageRoute(
                fullscreenDialog: true, builder: (_) => MessagePageWidget(message));
        break;

      default:
        route = MaterialPageRoute(
            builder: (_) => Scaffold(
                  body: Center(
                      child: Text('No route defined for ${settings.name}')),
                ));
    }
    return route;
  }
}
