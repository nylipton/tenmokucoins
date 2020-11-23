import 'dart:io';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:tenmoku_coins/display/home_page.dart';

import 'display/filter_page.dart';

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Theme colors from https://coolors.co/f4f1de-e07a5f-3d405b-81b29a-f2cc8f
    ColorScheme tenmokuColorScheme = ColorScheme.light(
      background: Color(0xFFF4F1DE),
      onBackground: Color(0xFF3D405B),
      error: Colors.red,
      onError: Color(0xFF3D405B),
      primary: Color(0xFFE07A5F),
      primaryVariant: Color(0xEEE07A5F),
      onPrimary: Color(0xFFF4F1DE),
      secondary: Color(0xFF81B29A),
      secondaryVariant: Color(0xAA81B29A),
      onSecondary: Color(0xFF3D405B),
      surface: Color(0xFFF4F1DE),
      onSurface: Colors.black,
    );

    ThemeData theme = ThemeData.from(
        colorScheme: tenmokuColorScheme,
        textTheme: GoogleFonts.nunitoTextTheme(Theme
            .of(context)
            .textTheme))
        .copyWith(cupertinoOverrideTheme: NoDefaultCupertinoThemeData());

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
            onGenerateRoute: (settings ) => Router.generateRoute( true, settings ),
            initialRoute: Router.homeRoute,
          ));
    } else {
      return MaterialApp(
        title: 'Tenmoku Coin Trader',
        theme: theme,
        onGenerateRoute: (settings ) => Router.generateRoute( false, settings ),
        initialRoute: Router.homeRoute,
      );
    }
  }
}

class Router {
  static const String homeRoute = '/';
  static const String filterRoute = '/filter';

  static Route<dynamic> generateRoute(bool iOS, RouteSettings settings) {
    PageRoute route;

    switch (settings.name) {
      case homeRoute:
        if( iOS )
          route = CupertinoPageRoute( builder: (_) => HomePage() ) ;
        else
          route = MaterialPageRoute(builder: (_) => HomePage());
        break;
      case filterRoute:
        var tags = settings.arguments ;
        if( iOS )
          route = CupertinoPageRoute(
              fullscreenDialog: true, builder: (_) => FilterPage(tags: tags));
        else
          route = MaterialPageRoute(
            fullscreenDialog: true, builder: (_) => FilterPage());
        break;
      default:
        route = MaterialPageRoute(
            builder: (_) =>
                Scaffold(
                  body: Center(
                      child: Text('No route defined for ${settings.name}')),
                ));
    }
    return route;
  }
}