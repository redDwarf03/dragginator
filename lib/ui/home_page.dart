// @dart=2.9

// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:event_taxi/event_taxi.dart';
import 'package:flare_flutter/base/animation/actor_animation.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Project imports:
import 'package:dragginator/appstate_container.dart';
import 'package:dragginator/bus/events.dart';
import 'package:dragginator/bus/navigation_event.dart';
import 'package:dragginator/localization.dart';
import 'package:dragginator/service/dragginator_service.dart';
import 'package:dragginator/service_locator.dart';
import 'package:dragginator/ui/navigate/background.dart';
import 'package:dragginator/ui/navigate/nav_container.dart';
import 'package:dragginator/ui/widgets/dialog.dart';
import 'package:dragginator/util/caseconverter.dart';
import 'package:dragginator/util/sharedprefsutil.dart';

class AppHomePage extends StatefulWidget {
  AppHomePage() : super();

  @override
  _AppHomePageState createState() => _AppHomePageState();
}

class _AppHomePageState extends State<AppHomePage>
    with
        WidgetsBindingObserver,
        SingleTickerProviderStateMixin,
        FlareController {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final Logger log = sl.get<Logger>();

  // Controller for placeholder card animations
  AnimationController _placeholderCardAnimationController;
  Animation<double> _opacityAnimation;
  bool _animationDisposed;

  bool _displayReleaseNote;

  int _eggPrice = 0;

  bool _lockDisabled = false; // whether we should avoid locking the app

  // Main card height
  double mainCardHeight;
  double settingsIconMarginTop = 5;

  // Animation for swiping to send
  ActorAnimation _sendSlideAnimation;
  ActorAnimation _sendSlideReleaseAnimation;
  double _fanimationPosition;
  bool releaseAnimation = false;

  void initialize(FlutterActorArtboard actor) {
    _fanimationPosition = 0.0;
    _sendSlideAnimation = actor.getAnimation("pull");
    _sendSlideReleaseAnimation = actor.getAnimation("release");
  }

  void setViewTransform(Mat2D viewTransform) {}

  bool advance(FlutterActorArtboard artboard, double elapsed) {
    if (releaseAnimation) {
      _sendSlideReleaseAnimation.apply(
          _sendSlideReleaseAnimation.duration * (1 - _fanimationPosition),
          artboard,
          1.0);
    } else {
      _sendSlideAnimation.apply(
          _sendSlideAnimation.duration * _fanimationPosition, artboard, 1.0);
    }
    return true;
  }

  _checkVersionApp() async {
    String versionAppCached = await sl.get<SharedPrefsUtil>().getVersionApp();
    PackageInfo.fromPlatform().then((packageInfo) async {
      if (versionAppCached != packageInfo.version) {
        _displayReleaseNote = true;
      } else {
        _displayReleaseNote = false;
      }
    });
  }

  _getEggPrice() async {
    _eggPrice = await sl.get<DragginatorService>().getEggPrice();
    StateContainer.of(context).eggPrice = _eggPrice;
  }

  @override
  void initState() {
    super.initState();

    _displayReleaseNote = false;
    _checkVersionApp();
    _getEggPrice();
    _registerBus();
    WidgetsBinding.instance.addObserver(this);

    // Main Card Size
    mainCardHeight = 120;
    settingsIconMarginTop = 7;

    // Setup placeholder animation and start
    _animationDisposed = false;
    _placeholderCardAnimationController = new AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _placeholderCardAnimationController
        .addListener(_animationControllerListener);
    _opacityAnimation = new Tween(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(
        parent: _placeholderCardAnimationController,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
      ),
    );
    _opacityAnimation.addStatusListener(_animationStatusListener);
    _placeholderCardAnimationController.forward();
  }

  void _animationStatusListener(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        _placeholderCardAnimationController.forward();
        break;
      case AnimationStatus.completed:
        _placeholderCardAnimationController.reverse();
        break;
      default:
        return null;
    }
  }

  void _animationControllerListener() {
    setState(() {});
  }

  void _startAnimation() {
    if (_animationDisposed) {
      _animationDisposed = false;
      _placeholderCardAnimationController
          .addListener(_animationControllerListener);
      _opacityAnimation.addStatusListener(_animationStatusListener);
      _placeholderCardAnimationController.forward();
    }
  }

  StreamSubscription<DisableLockTimeoutEvent> _disableLockSub;
  StreamSubscription<AccountChangedEvent> _switchAccountSub;

  void _registerBus() {
    // Hackish event to block auto-lock functionality
    _disableLockSub = EventTaxiImpl.singleton()
        .registerTo<DisableLockTimeoutEvent>()
        .listen((event) {
      if (event.disable) {
        cancelLockEvent();
      }
      _lockDisabled = event.disable;
    });
    // User changed account
    _switchAccountSub = EventTaxiImpl.singleton()
        .registerTo<AccountChangedEvent>()
        .listen((event) {
      setState(() {
        StateContainer.of(context).wallet.loading = true;
        StateContainer.of(context).wallet.historyLoading = true;

        _startAnimation();
        StateContainer.of(context).updateWallet(account: event.account);

        StateContainer.of(context).wallet.loading = false;
        StateContainer.of(context).wallet.historyLoading = false;
        if (event.delayPop) {
          Future.delayed(Duration(milliseconds: 300), () {
            TabController _tabController = NavigationBus.tabController;
            _tabController.animateTo(0);
          });
        } else if (!event.noPop) {
          TabController _tabController = NavigationBus.tabController;
          _tabController.animateTo(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _destroyBus();
    WidgetsBinding.instance.removeObserver(this);
    _placeholderCardAnimationController.dispose();
    super.dispose();
  }

  void _destroyBus() {
    if (_disableLockSub != null) {
      _disableLockSub.cancel();
    }
    if (_switchAccountSub != null) {
      _switchAccountSub.cancel();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle websocket connection when app is in background
    // terminate it to be eco-friendly
    switch (state) {
      case AppLifecycleState.paused:
        setAppLockEvent();
        super.didChangeAppLifecycleState(state);
        break;
      case AppLifecycleState.resumed:
        cancelLockEvent();
        super.didChangeAppLifecycleState(state);
        break;
      default:
        super.didChangeAppLifecycleState(state);
        break;
    }
  }

  // To lock and unlock the app
  StreamSubscription<dynamic> lockStreamListener;

  Future<void> setAppLockEvent() async {
    if (((await sl.get<SharedPrefsUtil>().getLock()) ||
            StateContainer.of(context).encryptedSecret != null) &&
        !_lockDisabled) {
      if (lockStreamListener != null) {
        lockStreamListener.cancel();
      }
      Future<dynamic> delayed = new Future.delayed(
          (await sl.get<SharedPrefsUtil>().getLockTimeout()).getDuration());
      delayed.then((_) {
        return true;
      });
      lockStreamListener = delayed.asStream().listen((_) {
        try {
          StateContainer.of(context).resetEncryptedSecret();
        } catch (e) {
          log.w(
              "Failed to reset encrypted secret when locking ${e.toString()}");
        } finally {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
        }
      });
    }
  }

  Future<void> cancelLockEvent() async {
    if (lockStreamListener != null) {
      lockStreamListener.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    /*_displayReleaseNote
        ? WidgetsBinding.instance
            .addPostFrameCallback((_) => displayReleaseNote())
        : null;
  */
    return WillPopScope(
        onWillPop: () {
          NavigationBus.tryPop();
        },
        child: Scaffold(
            drawerEdgeDragWidth: 200,
            resizeToAvoidBottomInset: false,
            key: _scaffoldKey,
            body: Stack(
              children: [
                Background(
                  assetName: 'assets/dragginator_background.png',
                ),
                NavContainer(StateContainer.of(context).wallet)
              ],
            )));
  }

  void displayReleaseNote() {
    _displayReleaseNote = false;
    PackageInfo.fromPlatform().then((packageInfo) {
      AppDialogs.showConfirmDialog(
          context,
          AppLocalization.of(context).releaseNoteHeader +
              " " +
              packageInfo.version,
          "- Add Dragginator features",
          CaseChange.toUpperCase(AppLocalization.of(context).ok, context),
          () async {
        await sl.get<SharedPrefsUtil>().setVersionApp(packageInfo.version);
      });
    });
  }
}
