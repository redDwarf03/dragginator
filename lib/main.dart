// @dart=2.9

// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';
import 'package:oktoast/oktoast.dart';

// Project imports:
import 'package:dragginator/appstate_container.dart';
import 'package:dragginator/localization.dart';
import 'package:dragginator/model/available_language.dart';
import 'package:dragginator/model/bis_url.dart';
import 'package:dragginator/model/vault.dart';
import 'package:dragginator/service_locator.dart';
import 'package:dragginator/styles.dart';
import 'package:dragginator/ui/before_scan_screen.dart';
import 'package:dragginator/ui/home/start_game.dart';
import 'package:dragginator/ui/home_page.dart';
import 'package:dragginator/ui/intro/intro_backup_confirm.dart';
import 'package:dragginator/ui/intro/intro_backup_safety.dart';
import 'package:dragginator/ui/intro/intro_backup_seed.dart';
import 'package:dragginator/ui/intro/intro_import_seed.dart';
import 'package:dragginator/ui/intro/intro_password.dart';
import 'package:dragginator/ui/intro/intro_password_on_launch.dart';
import 'package:dragginator/ui/lock_screen.dart';
import 'package:dragginator/ui/password_lock_screen.dart';
import 'package:dragginator/ui/send/send_confirm_sheet.dart';
import 'package:dragginator/ui/util/routes.dart';
import 'package:dragginator/ui/widgets/sheet_util.dart';
import 'package:dragginator/util/app_ffi/apputil.dart';
import 'package:dragginator/util/helpers.dart';
import 'package:dragginator/util/sharedprefsutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Setup Service Provide
  setupServiceLocator();
  // Setup logger, only show warning and higher in release mode.
  if (kReleaseMode) {
    Logger.level = Level.warning;
  } else {
    Logger.level = Level.debug;
  }
  // Run app
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(new StateContainer(child: new App()));
  });
}

class App extends StatefulWidget {
  @override
  _AppState createState() => new _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
  }

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        StateContainer.of(context).curTheme.statusBar);
    return OKToast(
      textStyle: AppStyles.textStyleSnackbar(context),
      backgroundColor: StateContainer.of(context).curTheme.backgroundDark,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dragginator',
        theme: ThemeData(
          dialogBackgroundColor:
              StateContainer.of(context).curTheme.backgroundDark,
          primaryColor: StateContainer.of(context).curTheme.primary,
          accentColor: StateContainer.of(context).curTheme.primary10,
          backgroundColor: StateContainer.of(context).curTheme.backgroundDark,
          fontFamily: 'Lato',
          brightness: Brightness.dark,
        ),
        localizationsDelegates: [
          AppLocalizationsDelegate(StateContainer.of(context).curLanguage),
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate
        ],
        locale: StateContainer.of(context).curLanguage == null ||
                StateContainer.of(context).curLanguage.language ==
                    AvailableLanguage.DEFAULT
            ? null
            : StateContainer.of(context).curLanguage.getLocale(),
        supportedLocales: [
          const Locale('en', 'US'), // English
        ],
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case '/':
              return NoTransitionRoute(
                builder: (_) => Splash(),
                settings: settings,
              );
            case '/start_game':
              return NoTransitionRoute(
                builder: (_) => StartGame(),
                settings: settings,
              );
            case '/home':
              return NoTransitionRoute(
                builder: (_) => AppHomePage(),
                settings: settings,
              );
            case '/home_transition':
              return NoPopTransitionRoute(
                builder: (_) => AppHomePage(),
                settings: settings,
              );
            case '/intro_password_on_launch':
              return MaterialPageRoute(
                builder: (_) => IntroPasswordOnLaunch(seed: settings.arguments),
                settings: settings,
              );
            case '/intro_password':
              return MaterialPageRoute(
                builder: (_) => IntroPassword(seed: settings.arguments),
                settings: settings,
              );
            case '/intro_backup':
              return MaterialPageRoute(
                builder: (_) =>
                    IntroBackupSeedPage(encryptedSeed: settings.arguments),
                settings: settings,
              );
            case '/intro_backup_safety':
              return MaterialPageRoute(
                builder: (_) => IntroBackupSafetyPage(),
                settings: settings,
              );
            case '/intro_backup_confirm':
              return MaterialPageRoute(
                builder: (_) => IntroBackupConfirm(),
                settings: settings,
              );
            case '/intro_import':
              return MaterialPageRoute(
                builder: (_) => IntroImportSeedPage(),
                settings: settings,
              );
            case '/lock_screen':
              return NoTransitionRoute(
                builder: (_) => AppLockScreen(),
                settings: settings,
              );
            case '/lock_screen_transition':
              return MaterialPageRoute(
                builder: (_) => AppLockScreen(),
                settings: settings,
              );
            case '/password_lock_screen':
              return NoTransitionRoute(
                builder: (_) => AppPasswordLockScreen(),
                settings: settings,
              );
            case '/before_scan_screen':
              return NoTransitionRoute(
                builder: (_) => BeforeScanScreen(),
                settings: settings,
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}

/// Splash
/// Default page route that determines if user is logged in and routes them appropriately.
class Splash extends StatefulWidget {
  @override
  SplashState createState() => new SplashState();
}

class SplashState extends State<Splash> with WidgetsBindingObserver {
  bool _hasCheckedLoggedIn;
  bool _retried;

  bool seedIsEncrypted(String seed) {
    if (seed == null) {
      return false;
    }
    try {
      String salted = AppHelpers.bytesToUtf8String(
          AppHelpers.hexToBytes(seed.substring(0, 16)));
      if (salted == "Salted__") {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future checkLoggedIn() async {
    // Update session key
    await sl.get<Vault>().updateSessionKey();
    // Check if device is rooted or jailbroken, show user a warning informing them of the risks if so
    /*if (!(await sl.get<SharedPrefsUtil>().getHasSeenRootWarning()) &&
        (await RootChecker.isDeviceRooted)) {
      AppDialogs.showConfirmDialog(
          context,
          CaseChange.toUpperCase(AppLocalization.of(context).warning, context),
          AppLocalization.of(context).rootWarning,
          AppLocalization.of(context).iUnderstandTheRisks.toUpperCase(),
          () async {
            await sl.get<SharedPrefsUtil>().setHasSeenRootWarning();
            checkLoggedIn();
          },
          cancelText: AppLocalization.of(context).exit.toUpperCase(),
          cancelAction: () {
            if (Platform.isIOS) {
              exit(0);
            } else {
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            }
          });
      return;
    }*/
    if (!_hasCheckedLoggedIn) {
      _hasCheckedLoggedIn = true;
    } else {
      return;
    }
    try {
      // iOS key store is persistent, so if this is first launch then we will clear the keystore
      bool firstLaunch = await sl.get<SharedPrefsUtil>().getFirstLaunch();
      if (firstLaunch) {
        await sl.get<Vault>().deleteAll();
      }
      await sl.get<SharedPrefsUtil>().setFirstLaunch();
      // See if logged in already
      bool isLoggedIn = false;
      bool isEncrypted = false;
      var seed = await sl.get<Vault>().getSeed();
      var pin = await sl.get<Vault>().getPin();
      // If we have a seed set, but not a pin - or vice versa
      // Then delete the seed and pin from device and start over.
      // This would mean user did not complete the intro screen completely.
      if (seed != null && pin != null) {
        isLoggedIn = true;
        isEncrypted = seedIsEncrypted(seed);
      } else if (seed != null && pin == null) {
        await sl.get<Vault>().deleteSeed();
      } else if (pin != null && seed == null) {
        await sl.get<Vault>().deletePin();
      }

      if (isLoggedIn) {
        if (isEncrypted) {
          Navigator.of(context).pushReplacementNamed('/password_lock_screen');
        } else if (await sl.get<SharedPrefsUtil>().getLock() ||
            await sl.get<SharedPrefsUtil>().shouldLock()) {
          Navigator.of(context).pushReplacementNamed('/lock_screen');
        } else {
          await AppUtil().loginAccount(seed, context);
          StateContainer.of(context).requestUpdateHistory();
          StateContainer.of(context).requestUpdateDragginatorList();
          if (StateContainer.of(context).initialDeepLink != null) {
            handleDeepLink(StateContainer.of(context).initialDeepLink);
            StateContainer.of(context).initialDeepLink = null;
          }
          Navigator.of(context).pushReplacementNamed('/start_game');
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/start_game');
      }
    } catch (e) {
      /// Fallback secure storage
      /// A very small percentage of users are encountering issues writing to the
      /// Android keyStore using the flutter_secure_storage plugin.
      ///
      /// Instead of telling them they are out of luck, this is an automatic "fallback"
      /// It will generate a 64-byte secret using the native android "bottlerocketstudios" Vault
      /// This secret is used to encrypt sensitive data and save it in SharedPreferences
      if (Platform.isAndroid && e.toString().contains("flutter_secure")) {
        if (!(await sl.get<SharedPrefsUtil>().useLegacyStorage())) {
          await sl.get<SharedPrefsUtil>().setUseLegacyStorage();
          checkLoggedIn();
        }
      } else {
        await sl.get<Vault>().deleteAll();
        await sl.get<SharedPrefsUtil>().deleteAll();
        if (!_retried) {
          _retried = true;
          _hasCheckedLoggedIn = false;
          checkLoggedIn();
        }
      }
    }
  }

  Future<void> handleDeepLink(String link) async {
    BisUrl bisUrl = await new BisUrl().getInfo(Uri.decodeFull(link));

    // Remove any other screens from stack
    Navigator.of(context).popUntil(RouteUtils.withNameLike('/home'));

    // Go to send confirm with amount
    Sheets.showAppHeightNineSheet(
        context: context,
        widget: SendConfirmSheet(
            displayTo: true,
            amountRaw: bisUrl.amount,
            operation: bisUrl.operation,
            openfield: bisUrl.openfield,
            comment: bisUrl.comment,
            destination: bisUrl.address,
            contactName: bisUrl.contactName));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hasCheckedLoggedIn = false;
    _retried = false;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => checkLoggedIn());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Account for user changing locale when leaving the app
    switch (state) {
      case AppLifecycleState.paused:
        super.didChangeAppLifecycleState(state);
        break;
      case AppLifecycleState.resumed:
        setLanguage();
        super.didChangeAppLifecycleState(state);
        break;
      default:
        super.didChangeAppLifecycleState(state);
        break;
    }
  }

  void setLanguage() {
    setState(() {
      StateContainer.of(context).deviceLocale = Localizations.localeOf(context);
    });
    sl.get<SharedPrefsUtil>().getLanguage().then((setting) {
      setState(() {
        StateContainer.of(context).curLanguage = setting;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // This seems to be the earliest place we can retrieve the device Locale
    setLanguage();
    return new Scaffold(
      backgroundColor: StateContainer.of(context).curTheme.background,
    );
  }
}
