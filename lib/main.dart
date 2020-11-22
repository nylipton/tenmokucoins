import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';

import 'bloc/reddit_client_cubit.dart';
import 'bloc/subreddit_cubit.dart';
import 'display/listings_page.dart';

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
      primaryVariant: Color(0xAAE07A5F),
      onPrimary: Color(0xFF3D405B),

      secondary: Color(0xFF81B29A),
      secondaryVariant: Color(0xAA81B29A),
      onSecondary: Color(0xFF3D405B),

      surface: Color(0xFFF4F1DE),
      onSurface: Colors.black,
    );

    ThemeData theme = ThemeData.from(
            colorScheme: tenmokuColorScheme,
            textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme))
        .copyWith(cupertinoOverrideTheme: NoDefaultCupertinoThemeData(

    ));

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
        title: 'Tenmoku Coins',
        home: MultiBlocProvider(
          providers: [
            BlocProvider<RedditClientCubit>(
              create: (context) => RedditClientCubit(),
            ),
            BlocProvider<SubredditBloc>(create: (context) {
              var bloc = SubredditBloc();
              bloc.setRedditClientCubit(
                  BlocProvider.of<RedditClientCubit>(context));
              return bloc;
            }),
          ],
          child: ListingsPage(title: 'Tenmoku Coins'),
        ),
      ) ) ;
    } else {
      return MaterialApp(
        title: 'Tenmoku Coin Trader',
        theme: theme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<RedditClientCubit>(
              create: (context) => RedditClientCubit(),
            ),
            BlocProvider<SubredditBloc>(create: (context) {
              var bloc = SubredditBloc();
              bloc.setRedditClientCubit(
                  BlocProvider.of<RedditClientCubit>(context));
              return bloc;
            }),
          ],
          child: ListingsPage(title: 'Tenmoku Coin Trader'),
        ),
      );
    }
  }
}
