import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:dragginator/dimens.dart';
import 'package:dragginator/service/dragginator_service.dart';
import 'package:dragginator/ui/dragginator/my_dragginator_detail.dart';
import 'package:dragginator/ui/dragginator/my_dragginator_merging.dart';
import 'package:dragginator/ui/send/send_confirm_sheet.dart';
import 'package:dragginator/ui/util/ui_util.dart';
import 'package:dragginator/ui/widgets/buttons.dart';
import 'package:dragginator/ui/widgets/sheet_util.dart';
import 'package:flare_flutter/base/animation/actor_animation.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/material.dart';
import 'package:dragginator/appstate_container.dart';
import 'package:dragginator/localization.dart';
import 'package:dragginator/service_locator.dart';
import 'package:dragginator/styles.dart';
import 'package:dragginator/ui/widgets/reactive_refresh.dart';
import 'package:dragginator/util/sharedprefsutil.dart';
import 'package:dragginator/util/hapticutil.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/typicons_icons.dart';

class FirstPage extends StatefulWidget {
  final List<List> dragginatorList;

  FirstPage(this.dragginatorList) : super();

  _FirstPageStateState createState() => _FirstPageStateState();
}

class _FirstPageStateState extends State<FirstPage>
    with
        WidgetsBindingObserver,
        SingleTickerProviderStateMixin,
        FlareController {
  // Controller for placeholder card animations
  AnimationController? _placeholderCardAnimationController;
  Animation<double>? _opacityAnimation;

  bool _isRefreshing = false;
  bool _lockDisabled = false; // whether we should avoid locking the app

  // Main card height
  double? mainCardHeight;
  double settingsIconMarginTop = 5;

  // Animation for swiping to send
  ActorAnimation? _sendSlideAnimation;
  ActorAnimation? _sendSlideReleaseAnimation;
  double? _fanimationPosition;
  bool? releaseAnimation = false;

  void initialize(FlutterActorArtboard actor) {
    _fanimationPosition = 0.0;
    _sendSlideAnimation = actor.getAnimation("pull");
    _sendSlideReleaseAnimation = actor.getAnimation("release");
  }

  void setViewTransform(Mat2D viewTransform) {}

  bool advance(FlutterActorArtboard artboard, double elapsed) {
    if (releaseAnimation!) {
      _sendSlideReleaseAnimation!.apply(
          _sendSlideReleaseAnimation!.duration * (1 - _fanimationPosition!),
          artboard,
          1.0);
    } else {
      _sendSlideAnimation!.apply(
          _sendSlideAnimation!.duration * _fanimationPosition!, artboard, 1.0);
    }
    return true;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addObserver(this);

    // Main Card Size
    mainCardHeight = 120;
    settingsIconMarginTop = 7;

    // Setup placeholder animation and start
    _placeholderCardAnimationController = new AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _placeholderCardAnimationController!
        .addListener(_animationControllerListener);
    _opacityAnimation = new Tween(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(
        parent: _placeholderCardAnimationController!,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
      ),
    );
    _opacityAnimation!.addStatusListener(_animationStatusListener);
    _placeholderCardAnimationController!.forward();
  }

  void _animationStatusListener(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        _placeholderCardAnimationController!.forward();
        break;
      case AnimationStatus.completed:
        _placeholderCardAnimationController!.reverse();
        break;
      default:
        return null;
    }
  }

  void _animationControllerListener() {
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    _placeholderCardAnimationController!.dispose();
    super.dispose();
  }

  // To lock and unlock the app
  StreamSubscription<dynamic>? lockStreamListener;

  Future<void> setAppLockEvent() async {
    if (((await sl.get<SharedPrefsUtil>().getLock()) ||
            StateContainer.of(context).encryptedSecret != null) &&
        !_lockDisabled) {
      if (lockStreamListener != null) {
        lockStreamListener!.cancel();
      }
      Future<dynamic> delayed = new Future.delayed(
          (await sl.get<SharedPrefsUtil>().getLockTimeout()).getDuration());
      delayed.then((_) {
        return true;
      });
      lockStreamListener = delayed.asStream().listen((_) {
        try {
          StateContainer.of(context).resetEncryptedSecret();
        } catch (e) {} finally {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
        }
      });
    }
  }

  Future<void> cancelLockEvent() async {
    if (lockStreamListener != null) {
      lockStreamListener!.cancel();
    }
  }

  // Return widget for list
  Widget _getListWidget(BuildContext context) {
    return ReactiveRefreshIndicator(
      child: GridView.count(
        crossAxisCount: 3,
        children: List.generate(widget.dragginatorList.length, (index) {
          return Center(
              child: Stack(children: <Widget>[
            InkWell(
              onTap: () {
                Sheets.showAppHeightNineSheet(
                    context: context,
                    widget: MyDragginatorDetail(
                        StateContainer.of(context).selectedAccount.address,
                        StateContainer.of(context)
                            .wallet
                            .dragginatorList[index]));
              },
              child: CircularProfileAvatar(
                UIUtil.getDragginatorURL(widget.dragginatorList[index][1].dna,
                    widget.dragginatorList[index][1].status),
                elevation: 25,
                radius: 50.0,
                backgroundColor: Colors.transparent,
              ),
            ),
          ]));
        }),
      ),
      onRefresh: _refresh,
      isRefreshing: _isRefreshing,
    );
  }

  // Refresh list
  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
    });
    sl.get<HapticUtil>().success();
    StateContainer.of(context).requestUpdateDragginatorList();

    // Hide refresh indicator after 3 seconds if no server response
    Future.delayed(new Duration(seconds: 3), () {
      setState(() {
        _isRefreshing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: SafeArea(
            minimum: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.035),
            child: StateContainer.of(context).wallet != null &&
                    StateContainer.of(context).wallet.address != null
                ? Column(
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(bottom: 10.0, top: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                // Header Text
                                Text(
                                  AppLocalization.of(context).dragginatorHeader,
                                  style: AppStyles.textStyleSettingsHeader(
                                      context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: <Widget>[
                            //Everything else
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                //Transactions List
                                Expanded(
                                  child: Stack(
                                    children: <Widget>[
                                      _getListWidget(context),
                                    ],
                                  ),
                                ), //Transactions List End
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          widget.dragginatorList.length > 0
                              ? Container(
                                  margin: EdgeInsets.symmetric(horizontal: 6.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: FlatButton(
                                      onPressed: () {
                                        Sheets.showAppHeightNineSheet(
                                            context: context,
                                            widget: MyDragginatorMerging(
                                                StateContainer.of(context)
                                                    .selectedAccount
                                                    .address,
                                                widget.dragginatorList));
                                      },
                                      padding: EdgeInsets.all(0.0),
                                      shape: CircleBorder(),
                                      splashColor: StateContainer.of(context)
                                          .curTheme
                                          .text30,
                                      highlightColor: StateContainer.of(context)
                                          .curTheme
                                          .text15,
                                      child: Column(
                                        children: [
                                          Icon(Typicons.flow_merge,
                                              size: 26,
                                              color: StateContainer.of(context)
                                                  .curTheme
                                                  .icon),
                                          Text(
                                            AppLocalization.of(context)
                                                .dragginatorMergingHeader,
                                            style: AppStyles.textStyleTiny(
                                                context),
                                          )
                                        ],
                                      )),
                                )
                              : SizedBox(width: 0),
                          sl.get<DragginatorService>().isEggOwner(
                                      StateContainer.of(context)
                                          .wallet
                                          .tokens) ==
                                  false
                              ? SizedBox(width: 0)
                              : Container(
                                  margin: EdgeInsets.symmetric(horizontal: 6.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: FlatButton(
                                      onPressed: () {
                                        Sheets.showAppHeightNineSheet(
                                            context: context,
                                            widget: SendConfirmSheet(
                                                title: AppLocalization.of(
                                                        context)
                                                    .dragginatorGetEggWithEggHeader,
                                                amountRaw: "0",
                                                operation: "token:transfer",
                                                openfield: "egg:1",
                                                comment: "",
                                                destination:
                                                    AppLocalization.of(context)
                                                        .dragginatorAddress,
                                                contactName: ""));
                                      },
                                      padding: EdgeInsets.all(0.0),
                                      shape: CircleBorder(),
                                      splashColor: StateContainer.of(context)
                                          .curTheme
                                          .text30,
                                      highlightColor: StateContainer.of(context)
                                          .curTheme
                                          .text15,
                                      child: Column(
                                        children: [
                                          Icon(FontAwesome5.egg,
                                              size: 26,
                                              color: StateContainer.of(context)
                                                  .curTheme
                                                  .icon),
                                          Text(
                                            AppLocalization.of(context)
                                                .dragginatorGetEggWithEggHeader,
                                            style: AppStyles.textStyleTiny(
                                                context),
                                          )
                                        ],
                                      )),
                                ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 6.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: FlatButton(
                                onPressed: () {
                                  Sheets.showAppHeightNineSheet(
                                      context: context,
                                      widget: SendConfirmSheet(
                                          title: AppLocalization.of(context)
                                              .dragginatorGetEggWithBisHeader,
                                          amountRaw: "3",
                                          operation: "",
                                          openfield: "",
                                          comment: "",
                                          destination:
                                              AppLocalization.of(context)
                                                  .dragginatorAddress,
                                          contactName: ""));
                                },
                                padding: EdgeInsets.all(0.0),
                                shape: CircleBorder(),
                                splashColor:
                                    StateContainer.of(context).curTheme.text30,
                                highlightColor:
                                    StateContainer.of(context).curTheme.text15,
                                child: Column(
                                  children: [
                                    Icon(FontAwesome5.money_bill_wave,
                                        size: 26,
                                        color: StateContainer.of(context)
                                            .curTheme
                                            .icon),
                                    Text(
                                      AppLocalization.of(context)
                                          .dragginatorGetEggWithBisHeader,
                                      style: AppStyles.textStyleTiny(context),
                                    )
                                  ],
                                )),
                          ),
                        ],
                      )
                    ],
                  )
                : getIntro(context)));
  }

  Widget getIntro(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalization.of(context).dragginatorHeader,
                style: AppStyles.textStyleSettingsHeader(context),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: smallScreen(context) ? 30 : 40, vertical: 20),
            child: AutoSizeText(
              AppLocalization.of(context).welcomeText,
              style: AppStyles.textStyleParagraphBold(context),
              maxLines: 4,
              stepGranularity: 0.5,
            ),
          ),
          SizedBox(height: 180),
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  // New Wallet Button
                  AppButton.buildAppButton(
                      context,
                      AppButtonType.PRIMARY,
                      AppLocalization.of(context).newWallet,
                      Dimens.BUTTON_TOP_DIMENS, onPressed: () {
                    Navigator.of(context)
                        .pushNamed('/intro_password_on_launch');
                  }),
                ],
              ),
              Row(
                children: <Widget>[
                  // Import Wallet Button
                  AppButton.buildAppButton(
                      context,
                      AppButtonType.PRIMARY,
                      AppLocalization.of(context).importWallet,
                      Dimens.BUTTON_BOTTOM_DIMENS, onPressed: () {
                    Navigator.of(context).pushNamed('/intro_import');
                  }),
                ],
              ),
            ],
          ),
        ]);
  }
}
