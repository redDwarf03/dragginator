// @dart=2.9


import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flare_flutter/base/animation/actor_animation.dart';

import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/font_awesome_icons.dart';

import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:dragginator/network/model/response/address_txs_response.dart';
import 'package:dragginator/appstate_container.dart';
import 'package:dragginator/dimens.dart';
import 'package:dragginator/localization.dart';
import 'package:dragginator/service_locator.dart';

import 'package:dragginator/model/db/contact.dart';
import 'package:dragginator/model/db/appdb.dart';
import 'package:dragginator/network/model/block_types.dart';
import 'package:dragginator/styles.dart';
import 'package:dragginator/app_icons.dart';
import 'package:dragginator/ui/contacts/add_contact.dart';
import 'package:dragginator/ui/send/send_sheet.dart';
import 'package:dragginator/ui/receive/receive_sheet.dart';
import 'package:dragginator/ui/widgets/buttons.dart';
import 'package:dragginator/ui/widgets/sheet_util.dart';
import 'package:dragginator/ui/widgets/list_slidable.dart';
import 'package:dragginator/ui/widgets/reactive_refresh.dart';
import 'package:dragginator/util/sharedprefsutil.dart';
import 'package:dragginator/util/hapticutil.dart';
import 'package:dragginator/util/caseconverter.dart';

class MyHistory extends StatefulWidget {
  final String address;
  final AnimationController myHistoryController;
  bool myHistoryOpen;

  MyHistory(this.myHistoryController, this.myHistoryOpen, this.address) : super();

  _MyHistoryStateState createState() => _MyHistoryStateState();
}

class _MyHistoryStateState extends State<MyHistory>
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

  // Receive card instance
  ReceiveSheet receive;

  // A separate unfortunate instance of this list, is a little unfortunate
  // but seems the only way to handle the animations
  final Map<String, GlobalKey<AnimatedListState>> _listKeyMap = Map();

  // List of contacts (Store it so we only have to query the DB once for transaction cards)
  List<Contact> _contacts = new List<Contact>.empty(growable: true);

  bool _isRefreshing = false;
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

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);

    // Main Card Size
    mainCardHeight = 120;
    settingsIconMarginTop = 7;

    _updateContacts();
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

  void _disposeAnimation() {
    if (!_animationDisposed) {
      _animationDisposed = true;
      _opacityAnimation.removeStatusListener(_animationStatusListener);
      _placeholderCardAnimationController
          .removeListener(_animationControllerListener);
      _placeholderCardAnimationController.stop();
    }
  }
  void _updateContacts() {
    sl.get<DBHelper>().getContacts().then((contacts) {
      setState(() {
        _contacts = contacts;
      });
    });
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _placeholderCardAnimationController.dispose();
    super.dispose();
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

  // Used to build list items that haven't been removed.
  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    String displayName = smallScreen(context)
        ? StateContainer.of(context).wallet.history[index].getShorterString()
        : StateContainer.of(context).wallet.history[index].getShortString();
    _contacts.forEach((contact) {
      if (StateContainer.of(context).wallet.history[index].type ==
          BlockTypes.RECEIVE) {
        if (contact.address ==
            StateContainer.of(context).wallet.history[index].from) {
          displayName = contact.name;
        }
      } else {
        if (contact.address ==
            StateContainer.of(context).wallet.history[index].recipient) {
          displayName = contact.name;
        }
      }
    });
    return _buildTransactionCard(
        StateContainer.of(context).wallet.history[index],
        animation,
        displayName,
        context);
  }

  // Return widget for list
  Widget _getListWidget(BuildContext context) {
   if (StateContainer.of(context).wallet.history.length == 0) {
      _disposeAnimation();
      return ReactiveRefreshIndicator(
        backgroundColor: StateContainer.of(context).curTheme.backgroundDark,
        child: ListView(
          padding: EdgeInsetsDirectional.fromSTEB(0, 5.0, 0, 15.0),
          children: <Widget>[
            _buildWelcomeTransactionCard(context),
            _buildDummyTransactionCard(
              AppLocalization.of(context).sent,
              AppLocalization.of(context).exampleCardLittle,
              AppLocalization.of(context).exampleCardTo,
              context,
            ),
            _buildDummyTransactionCard(
              AppLocalization.of(context).received,
              AppLocalization.of(context).exampleCardLot,
              AppLocalization.of(context).exampleCardFrom,
              context,
            ),
          ],
        ),
        onRefresh: _refresh,
        isRefreshing: _isRefreshing,
      );
    } else {
      _disposeAnimation();
    }
    return ReactiveRefreshIndicator(
      backgroundColor: StateContainer.of(context).curTheme.backgroundDark,
      child: AnimatedList(
        key: _listKeyMap[StateContainer.of(context).wallet.address],
        padding: EdgeInsetsDirectional.fromSTEB(0, 5.0, 0, 15.0),
        initialItemCount: StateContainer.of(context).wallet.history.length,
        itemBuilder: _buildItem,
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
    StateContainer.of(context).requestUpdateHistory();

    // Hide refresh indicator after 3 seconds if no server response
    Future.delayed(new Duration(seconds: 3), () {
      setState(() {
        _isRefreshing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawerEdgeDragWidth: 200,
      resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      backgroundColor: StateContainer.of(context).curTheme.background,
      body: SafeArea(
        minimum: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.045,
            bottom: MediaQuery.of(context).size.height * 0.035),
        child: Column(
          children: <Widget>[
            Container(
                margin: EdgeInsets.only(bottom: 10.0, top: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        //Back button
                        Container(
                          height: 40,
                          width: 40,
                          margin: EdgeInsets.only(right: 10, left: 10),
                          child: FlatButton(
                              highlightColor:
                                  StateContainer.of(context).curTheme.text15,
                              splashColor:
                                  StateContainer.of(context).curTheme.text15,
                              onPressed: () {
                                setState(() {
                                  widget.myHistoryOpen = false;
                                });
                                widget.myHistoryController.reverse();
                              },
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50.0)),
                              padding: EdgeInsets.all(8.0),
                              child: Icon(FontAwesome.cancel,
                                  color:
                                      StateContainer.of(context).curTheme.text,
                                  size: 24)),
                        ),
                        // Header Text
                        Text(
                          AppLocalization.of(context).historyHeader,
                          style: AppStyles.textStyleSettingsHeader(context),
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
                            //List Top Gradient End
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                height: 10.0,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      StateContainer.of(context)
                                          .curTheme
                                          .background00,
                                      StateContainer.of(context)
                                          .curTheme
                                          .background
                                    ],
                                    begin: AlignmentDirectional(0.5, 1.0),
                                    end: AlignmentDirectional(0.5, -1.0),
                                  ),
                                ),
                              ),
                            ), // List Top Gradient End

                            //List Bottom Gradient
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 30.0,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      StateContainer.of(context)
                                          .curTheme
                                          .background00,
                                      StateContainer.of(context)
                                          .curTheme
                                          .background
                                    ],
                                    begin: AlignmentDirectional(0.5, -1),
                                    end: AlignmentDirectional(0.5, 0.5),
                                  ),
                                ),
                              ),
                            ), //List Bottom Gradient End
                          ],
                        ),
                      ), //Transactions List End
                      ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Transaction Card/List Item
  Widget _buildTransactionCard(AddressTxsResponseResult item,
      Animation<double> animation, String displayName, BuildContext context) {
    String text;
    if (item.type == BlockTypes.SEND) {
      text = AppLocalization.of(context).sent;
    } else {
      text = AppLocalization.of(context).received;
    }
    return Slidable(
      delegate: SlidableScrollDelegate(),
      actionExtentRatio: 0.35,
      movementDuration: Duration(milliseconds: 300),
      enabled: StateContainer.of(context).wallet != null &&
          StateContainer.of(context).wallet.accountBalance > 0,
      onTriggered: (preempt) {
        if (preempt) {
          setState(() {
            releaseAnimation = true;
          });
        } else {
          // See if a contact
          sl.get<DBHelper>().getContactWithAddress(item.from).then((contact) {
            // Go to send with address
            Sheets.showAppHeightNineSheet(
                context: context,
                widget: SendSheet(
                  sendATokenActive: true,
                  contact: contact,
                  address: item.from,
                  quickSendAmount: item.amount,
                ));
          });
        }
      },
      onAnimationChanged: (animation) {
        if (animation != null) {
          _fanimationPosition = animation.value;
          if (animation.value == 0.0 && releaseAnimation) {
            setState(() {
              releaseAnimation = false;
            });
          }
        }
      },
      secondaryActions: <Widget>[
        SlideAction(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
            margin: EdgeInsetsDirectional.only(
                end: MediaQuery.of(context).size.width * 0.15,
                top: 4,
                bottom: 4),
            child: Container(
              alignment: AlignmentDirectional(-0.5, 0),
              constraints: BoxConstraints.expand(),
              child: FlareActor("assets/pulltosend_animation.flr",
                  animation: "pull",
                  fit: BoxFit.contain,
                  controller: this,
                  color: StateContainer.of(context).curTheme.primary),
            ),
          ),
        ),
      ],
      child: _SizeTransitionNoClip(
        sizeFactor: animation,
        child: Container(
          margin: EdgeInsetsDirectional.fromSTEB(14.0, 4.0, 14.0, 4.0),
          decoration: BoxDecoration(
            color: StateContainer.of(context).curTheme.backgroundDark,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [StateContainer.of(context).curTheme.boxShadow],
          ),
          child: FlatButton(
            highlightColor: StateContainer.of(context).curTheme.text15,
            splashColor: StateContainer.of(context).curTheme.text15,
            color: StateContainer.of(context).curTheme.backgroundDark,
            padding: EdgeInsets.all(0.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            onPressed: () {
              Sheets.showAppHeightEightSheet(
                  context: context,
                  widget: TransactionDetailsSheet(
                      item: item,
                      address: item.type == BlockTypes.SEND
                          ? item.recipient
                          : item.from,
                      displayName: displayName),
                  animationDurationMs: 175);
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 14.0, horizontal: 20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: MediaQuery.of(context).size.width / 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              item.isAliasRegister()
                                  ? Text(
                                      "Alias",
                                      textAlign: TextAlign.start,
                                      style: AppStyles.textStyleTransactionType(
                                          context),
                                    )
                                  : Text(
                                      item.blockHeight == -1
                                          ? text +
                                              " - " +
                                              AppLocalization.of(context)
                                                  .mempool
                                          : text,
                                      textAlign: TextAlign.start,
                                      style: AppStyles.textStyleTransactionType(
                                          context),
                                    ),
                              Text(
                                DateFormat.yMd(Localizations.localeOf(context)
                                        .languageCode)
                                    .add_Hms()
                                    .format(item.timestamp)
                                    .toString(),
                                style:
                                    AppStyles.textStyleTransactionUnit(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                            width: MediaQuery.of(context).size.width / 2.4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                double.tryParse(item
                                            .getFormattedAmount()
                                            .replaceAll(",", "")) >
                                        0
                                    ? Container(
                                        child: RichText(
                                          textAlign: TextAlign.start,
                                          text: TextSpan(
                                            text: '',
                                            children: [
                                              TextSpan(
                                                text: item.type ==
                                                        BlockTypes.SEND
                                                    ? "- " +
                                                        item
                                                            .getFormattedAmount() +
                                                        " BIS"
                                                    : "+ " +
                                                        item.getFormattedAmount() +
                                                        " BIS",
                                                style: item.type ==
                                                        BlockTypes.SEND
                                                    ? AppStyles
                                                        .textStyleTransactionTypeRed(
                                                            context)
                                                    : AppStyles
                                                        .textStyleTransactionTypeGreen(
                                                            context),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : SizedBox(),
                                item.isTokenTransfer() == true
                                    ? Container(
                                        child: RichText(
                                          textAlign: TextAlign.start,
                                          text: TextSpan(
                                            text: '',
                                            children: [
                                              TextSpan(
                                                text:
                                                    item.type == BlockTypes.SEND
                                                        ? "- " +
                                                            item
                                                                .getBisToken()
                                                                .tokensQuantity
                                                                .toString() +
                                                            " " +
                                                            item
                                                                .getBisToken()
                                                                .tokenName
                                                        : "+ " +
                                                            item
                                                                .getBisToken()
                                                                .tokensQuantity
                                                                .toString() +
                                                            " " +
                                                            item
                                                                .getBisToken()
                                                                .tokenName,
                                                style: item.type ==
                                                        BlockTypes.SEND
                                                    ? AppStyles
                                                        .textStyleTransactionTypeRed(
                                                            context)
                                                    : AppStyles
                                                        .textStyleTransactionTypeGreen(
                                                            context),
                                              ),
                                              item.getBisToken().tokenName ==
                                                      "egg"
                                                  ? TextSpan(text: " ")
                                                  : TextSpan(text: ""),
                                              item.getBisToken().tokenName ==
                                                      "egg"
                                                  ? WidgetSpan(
                                                      child: Icon(
                                                          FontAwesome5.egg,
                                                          size: AppFontSizes
                                                              .small,
                                                          color: item.type ==
                                                                  BlockTypes
                                                                      .SEND
                                                              ? Colors.red[400]
                                                              : Colors
                                                                  .green[400]),
                                                      style: item.type ==
                                                              BlockTypes.SEND
                                                          ? AppStyles
                                                              .textStyleTransactionTypeRed(
                                                                  context)
                                                          : AppStyles
                                                              .textStyleTransactionTypeGreen(
                                                                  context),
                                                    )
                                                  : TextSpan(text: "")
                                            ],
                                          ),
                                        ),
                                      )
                                    : item.isAliasRegister()
                                        ? Container(
                                            child: RichText(
                                              textAlign: TextAlign.start,
                                              text: TextSpan(
                                                text: '',
                                                children: [
                                                  TextSpan(
                                                    text: item.openfield
                                                        .replaceAll(
                                                            "alias=", ""),
                                                    style: AppStyles
                                                        .textStyleTransactionTypeBlue(
                                                            context),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : item.isDragginatorNew()
                                            ? Container(
                                                child: RichText(
                                                  textAlign: TextAlign.start,
                                                  text: TextSpan(
                                                    text: '',
                                                    children: [
                                                      WidgetSpan(
                                                        child: Icon(
                                                            FontAwesome5.dragon,
                                                            size: AppFontSizes
                                                                .small,
                                                            color: Colors
                                                                .blue[400]),
                                                      ),
                                                      TextSpan(
                                                        text: "   new egg",
                                                        style: AppStyles
                                                            .textStyleTransactionTypeBlue(
                                                                context),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : item.isDragginatorMerge()
                                                ? Container(
                                                    child: RichText(
                                                      textAlign:
                                                          TextAlign.start,
                                                      text: TextSpan(
                                                        text: '',
                                                        children: [
                                                          WidgetSpan(
                                                            child: Icon(
                                                                FontAwesome5
                                                                    .dragon,
                                                                size:
                                                                    AppFontSizes
                                                                        .small,
                                                                color: Colors
                                                                    .blue[400]),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                "   eggs merge",
                                                            style: AppStyles
                                                                .textStyleTransactionTypeBlue(
                                                                    context),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : item.isDragginator()
                                                    ? Container(
                                                        child: RichText(
                                                          textAlign:
                                                              TextAlign.start,
                                                          text: TextSpan(
                                                            text: '',
                                                            children: [
                                                              WidgetSpan(
                                                                child: Icon(
                                                                    FontAwesome5
                                                                        .dragon,
                                                                    size: AppFontSizes
                                                                        .small,
                                                                    color: Colors
                                                                            .blue[
                                                                        400]),
                                                              ),
                                                              TextSpan(
                                                                text: "   " +
                                                                    item.operation
                                                                        .split(
                                                                            ":")[1],
                                                                style: AppStyles
                                                                    .textStyleTransactionTypeBlue(
                                                                        context),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                    : item.isHNRegister()
                                                        ? Container(
                                                            child: RichText(
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              text: TextSpan(
                                                                text: '',
                                                                children: [
                                                                  WidgetSpan(
                                                                    child: Icon(
                                                                        FontAwesome5
                                                                            .linode,
                                                                        size: AppFontSizes
                                                                            .small,
                                                                        color: Colors
                                                                            .blue[400]),
                                                                  ),
                                                                  TextSpan(
                                                                    text:
                                                                        "  HN register",
                                                                    style: AppStyles
                                                                        .textStyleTransactionTypeBlue(
                                                                            context),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          )
                                                        : SizedBox(),
                               
                                Text(
                                  displayName,
                                  textAlign: TextAlign.end,
                                  style: AppStyles.textStyleTransactionAddress(
                                      context),
                                ),
                              ],
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  } //Transaction Card End

  // Dummy Transaction Card
  Widget _buildDummyTransactionCard(
      String type, String amount, String address, BuildContext context) {
    String text;
    IconData icon;
    Color iconColor;
    if (type == AppLocalization.of(context).sent) {
      text = AppLocalization.of(context).sent;
      icon = AppIcons.sent;
      iconColor = StateContainer.of(context).curTheme.text60;
    } else {
      text = AppLocalization.of(context).received;
      icon = AppIcons.received;
      iconColor = StateContainer.of(context).curTheme.primary60;
    }
    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(14.0, 4.0, 14.0, 4.0),
      decoration: BoxDecoration(
        color: StateContainer.of(context).curTheme.backgroundDark,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [StateContainer.of(context).curTheme.boxShadow],
      ),
      child: FlatButton(
        onPressed: () {
          return null;
        },
        highlightColor: StateContainer.of(context).curTheme.text15,
        splashColor: StateContainer.of(context).curTheme.text15,
        color: StateContainer.of(context).curTheme.backgroundDark,
        padding: EdgeInsets.all(0.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsetsDirectional.only(end: 16.0),
                      child: Icon(icon, color: iconColor, size: 15),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            text,
                            textAlign: TextAlign.start,
                            style: AppStyles.textStyleTransactionType(context),
                          ),
                          RichText(
                            textAlign: TextAlign.start,
                            text: TextSpan(
                              text: '',
                              children: [
                                TextSpan(
                                  text: amount,
                                  style: AppStyles.textStyleTransactionAmount(
                                      context),
                                ),
                                TextSpan(
                                  text: " BIS",
                                  style: AppStyles.textStyleTransactionUnit(
                                      context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  width: MediaQuery.of(context).size.width / 2.4,
                  child: Text(
                    address,
                    textAlign: TextAlign.end,
                    style: AppStyles.textStyleTransactionAddress(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } //Dummy Transaction Card End

  // Welcome Card
  TextSpan _getExampleHeaderSpan(BuildContext context) {
    String workingStr;
    if (StateContainer.of(context).selectedAccount == null ||
        StateContainer.of(context).selectedAccount.index == 0) {
      workingStr = AppLocalization.of(context).exampleCardIntro;
    } else {
      workingStr = AppLocalization.of(context).newAccountIntro;
    }
    if (!workingStr.contains("BIS")) {
      return TextSpan(
        text: workingStr,
        style: AppStyles.textStyleTransactionWelcome(context),
      );
    }
    // Colorize cryptocurrency
    List<String> splitStr = workingStr.split("BIS");
    if (splitStr.length != 2) {
      return TextSpan(
        text: workingStr,
        style: AppStyles.textStyleTransactionWelcome(context),
      );
    }
    return TextSpan(
      text: '',
      children: [
        TextSpan(
          text: splitStr[0],
          style: AppStyles.textStyleTransactionWelcome(context),
        ),
        TextSpan(
          text: "BIS",
          style: AppStyles.textStyleTransactionWelcomePrimary(context),
        ),
        TextSpan(
          text: splitStr[1],
          style: AppStyles.textStyleTransactionWelcome(context),
        ),
      ],
    );
  }

  Widget _buildWelcomeTransactionCard(BuildContext context) {
    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(14.0, 4.0, 14.0, 4.0),
      decoration: BoxDecoration(
        color: StateContainer.of(context).curTheme.backgroundDark,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [StateContainer.of(context).curTheme.boxShadow],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: 7.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    bottomLeft: Radius.circular(10.0)),
                color: StateContainer.of(context).curTheme.primary,
                boxShadow: [StateContainer.of(context).curTheme.boxShadow],
              ),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 14.0, horizontal: 15.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: _getExampleHeaderSpan(context),
                ),
              ),
            ),
            Container(
              width: 7.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0)),
                color: StateContainer.of(context).curTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  } // Welcome Card End

  // Loading Transaction Card
  Widget _buildLoadingTransactionCard(
      String type, String amount, String address, BuildContext context) {
    String text;
    IconData icon;
    Color iconColor;
    if (type == "Sent") {
      text = "Senttt";
      icon = AppIcons.dotfilled;
      iconColor = StateContainer.of(context).curTheme.text20;
    } else {
      text = "Receiveddd";
      icon = AppIcons.dotfilled;
      iconColor = StateContainer.of(context).curTheme.primary20;
    }
    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(14.0, 4.0, 14.0, 4.0),
      decoration: BoxDecoration(
        color: StateContainer.of(context).curTheme.backgroundDark,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [StateContainer.of(context).curTheme.boxShadow],
      ),
      child: FlatButton(
        onPressed: () {
          return null;
        },
        highlightColor: StateContainer.of(context).curTheme.text15,
        splashColor: StateContainer.of(context).curTheme.text15,
        color: StateContainer.of(context).curTheme.backgroundDark,
        padding: EdgeInsets.all(0.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    // Transaction Icon
                    Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                          margin: EdgeInsetsDirectional.only(end: 16.0),
                          child: Icon(icon, color: iconColor, size: 20)),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Transaction Type Text
                          Container(
                            child: Stack(
                              alignment: AlignmentDirectional(-1, 0),
                              children: <Widget>[
                                Text(
                                  text,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontFamily: "Lato",
                                    fontSize: AppFontSizes.small,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.transparent,
                                  ),
                                ),
                                Opacity(
                                  opacity: _opacityAnimation.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: StateContainer.of(context)
                                          .curTheme
                                          .text45,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      text,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontFamily: "Lato",
                                        fontSize: AppFontSizes.small - 4,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Amount Text
                          Container(
                            child: Stack(
                              alignment: AlignmentDirectional(-1, 0),
                              children: <Widget>[
                                Text(
                                  amount,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      fontFamily: "Lato",
                                      color: Colors.transparent,
                                      fontSize: AppFontSizes.smallest,
                                      fontWeight: FontWeight.w600),
                                ),
                                Opacity(
                                  opacity: _opacityAnimation.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: StateContainer.of(context)
                                          .curTheme
                                          .primary20,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      amount,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          fontFamily: "Lato",
                                          color: Colors.transparent,
                                          fontSize: AppFontSizes.smallest - 3,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Address Text
                Container(
                  width: MediaQuery.of(context).size.width / 2.4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        child: Stack(
                          alignment: AlignmentDirectional(1, 0),
                          children: <Widget>[
                            Text(
                              address,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: AppFontSizes.smallest,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w300,
                                color: Colors.transparent,
                              ),
                            ),
                            Opacity(
                              opacity: _opacityAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: StateContainer.of(context)
                                      .curTheme
                                      .text20,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  address,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontSize: AppFontSizes.smallest - 3,
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w300,
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } // Loading Transaction Card End
}

class TransactionDetailsSheet extends StatefulWidget {
  final AddressTxsResponseResult item;
  final String address;
  final String displayName;

  TransactionDetailsSheet({this.item, this.address, this.displayName})
      : super();

  _TransactionDetailsSheetState createState() =>
      _TransactionDetailsSheetState();
}

class _TransactionDetailsSheetState extends State<TransactionDetailsSheet> {
  // Current state references
  bool _addressCopied = false;
  // Timer reference so we can cancel repeated events
  Timer _addressCopiedTimer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        minimum:
            EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.035),
        child: Column(
          children: <Widget>[
            // A row for the address text and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                //Empty SizedBox
                SizedBox(
                  width: 60,
                  height: 60,
                ),
                Column(
                  children: <Widget>[
                    // Sheet handle
                    Container(
                      margin: EdgeInsets.only(top: 10),
                      height: 5,
                      width: MediaQuery.of(context).size.width * 0.15,
                      decoration: BoxDecoration(
                        color: StateContainer.of(context).curTheme.text10,
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 15.0),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 140),
                      child: Column(
                        children: <Widget>[
                          // Header
                          AutoSizeText(
                            CaseChange.toUpperCase(
                                AppLocalization.of(context).transactionHeader,
                                context),
                            style: AppStyles.textStyleHeader(context),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            stepGranularity: 0.1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                //Empty SizedBox
                SizedBox(
                  width: 60,
                  height: 60,
                ),
              ],
            ),

            Expanded(
              child: Container(
                margin: EdgeInsets.only(top: 0, bottom: 10),
                child: Center(
                  child: Stack(children: <Widget>[
                    SingleChildScrollView(
                        child: Padding(
                      padding: EdgeInsets.only(
                          top: 30, bottom: 80, left: 10, right: 10),
                      child: Column(
                        children: <Widget>[
                          // list
                          Stack(
                            children: <Widget>[
                              Column(
                                children: [
                                  SizedBox(height: 20),
                                  Text(AppLocalization.of(context)
                                      .transactionDetailBlock),
                                  widget.item.blockHeight == -1
                                      ? SizedBox()
                                      : SelectableText(widget.item.blockHash,
                                          style: AppStyles
                                              .textStyleTransactionUnit(
                                                  context),
                                          textAlign: TextAlign.center),
                                  widget.item.blockHeight == -1
                                      ? Text(
                                          "(" +
                                              AppLocalization.of(context)
                                                  .mempool +
                                              ")",
                                          style: AppStyles
                                              .textStyleTransactionUnit(
                                                  context))
                                      : Text(
                                          "(" +
                                              widget.item.blockHeight
                                                  .toString() +
                                              ")",
                                          style: AppStyles
                                              .textStyleTransactionUnit(
                                                  context)),
                                  SizedBox(height: 10),
                                  Text(AppLocalization.of(context)
                                      .transactionDetailDate),
                                  Text(
                                      DateFormat.yMd(
                                              Localizations.localeOf(context)
                                                  .languageCode)
                                          .add_Hms()
                                          .format(widget.item.timestamp)
                                          .toString(),
                                      style: AppStyles.textStyleTransactionUnit(
                                          context)),
                                  SizedBox(height: 10),
                                  Text(AppLocalization.of(context)
                                      .transactionDetailFrom),
                                  SelectableText(widget.item.from,
                                      style: AppStyles.textStyleTransactionUnit(
                                          context)),
                                  SizedBox(height: 10),
                                  Text(AppLocalization.of(context)
                                      .transactionDetailTo),
                                  SelectableText(widget.item.recipient,
                                      style: AppStyles.textStyleTransactionUnit(
                                          context)),
                                  SizedBox(height: 10),
                                  Text(AppLocalization.of(context)
                                      .transactionDetailTxId),
                                  SelectableText(widget.item.hash,
                                      style: AppStyles.textStyleTransactionUnit(
                                          context),
                                      textAlign: TextAlign.center),
                                  SizedBox(height: 10),
                                  Text(AppLocalization.of(context)
                                      .transactionDetailAmount),
                                  Text(
                                      widget.item.type == BlockTypes.SEND
                                          ? "- " +
                                              widget.item.getFormattedAmount() +
                                              " BIS"
                                          : "+ " +
                                              widget.item.getFormattedAmount() +
                                              " BIS",
                                      style: AppStyles.textStyleTransactionUnit(
                                          context)),
                                  SizedBox(height: 10),
                                  Text(AppLocalization.of(context)
                                      .transactionDetailFee),
                                  Text(
                                      "- " +
                                          widget.item.fee.toString() +
                                          " BIS",
                                      style: AppStyles.textStyleTransactionUnit(
                                          context)),
                                  SizedBox(height: 10),
                                  Text(AppLocalization.of(context)
                                      .transactionDetailReward),
                                  Text(widget.item.reward.toString() + " BIS",
                                      style: AppStyles.textStyleTransactionUnit(
                                          context)),
                                  SizedBox(height: 10),
                                  Text(AppLocalization.of(context)
                                      .transactionDetailSignature),
                                  SelectableText(widget.item.signature,
                                      style: AppStyles.textStyleTransactionUnit(
                                          context)),
                                  SizedBox(height: 10),
                                  Text(AppLocalization.of(context)
                                      .transactionDetailOperation),
                                  SelectableText(widget.item.operation,
                                      style: AppStyles.textStyleTransactionUnit(
                                          context)),
                                  SizedBox(height: 10),
                                  Text(AppLocalization.of(context)
                                      .transactionDetailOpenfield),
                                  SelectableText(widget.item.openfield,
                                      style: AppStyles.textStyleTransactionUnit(
                                          context),
                                      textAlign: TextAlign.center),
                                  SizedBox(height: 20),
                                  Text(
                                      "* " +
                                          AppLocalization.of(context)
                                              .transactionDetailCopyPaste,
                                      style: AppStyles.textStyleTransactionUnit(
                                          context),
                                      textAlign: TextAlign.left),
                                  Column(
                                    children: <Widget>[
                                      // A stack for Copy Address and Add Contact buttons
                                      Stack(
                                        children: <Widget>[
                                          // A row for Copy Address Button
                                          Row(
                                            children: <Widget>[
                                              AppButton.buildAppButton(
                                                  context,
                                                  // Share Address Button
                                                  _addressCopied
                                                      ? AppButtonType.SUCCESS
                                                      : AppButtonType.PRIMARY,
                                                  _addressCopied
                                                      ? AppLocalization.of(
                                                              context)
                                                          .addressCopied
                                                      : AppLocalization.of(
                                                              context)
                                                          .copyAddress,
                                                  Dimens
                                                      .BUTTON_TOP_EXCEPTION_DIMENS,
                                                  onPressed: () {
                                                Clipboard.setData(
                                                    new ClipboardData(
                                                        text: widget.address));
                                                if (mounted) {
                                                  setState(() {
                                                    // Set copied style
                                                    _addressCopied = true;
                                                  });
                                                }
                                                if (_addressCopiedTimer !=
                                                    null) {
                                                  _addressCopiedTimer.cancel();
                                                }
                                                _addressCopiedTimer = new Timer(
                                                    const Duration(
                                                        milliseconds: 800), () {
                                                  if (mounted) {
                                                    setState(() {
                                                      _addressCopied = false;
                                                    });
                                                  }
                                                });
                                              }),
                                            ],
                                          ),
                                          // A row for Add Contact Button
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: <Widget>[
                                              Container(
                                                margin: EdgeInsetsDirectional.only(
                                                    top: Dimens
                                                            .BUTTON_TOP_EXCEPTION_DIMENS[
                                                        1],
                                                    end: Dimens
                                                        .BUTTON_TOP_EXCEPTION_DIMENS[2]),
                                                child: Container(
                                                  height: 55,
                                                  width: 55,
                                                  // Add Contact Button
                                                  child: !widget.displayName
                                                          .startsWith("@")
                                                      ? FlatButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            Sheets.showAppHeightNineSheet(
                                                                context:
                                                                    context,
                                                                widget: AddContactSheet(
                                                                    address: widget
                                                                        .address));
                                                          },
                                                          splashColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          100.0)),
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical:
                                                                      10.0,
                                                                  horizontal:
                                                                      10),
                                                          child: Icon(
                                                              AppIcons
                                                                  .addcontact,
                                                              size: 35,
                                                              color: _addressCopied
                                                                  ? StateContainer.of(
                                                                          context)
                                                                      .curTheme
                                                                      .successDark
                                                                  : StateContainer.of(
                                                                          context)
                                                                      .curTheme
                                                                      .backgroundDark),
                                                        )
                                                      : SizedBox(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ]),
                ),
              ),
            ),
          ],
        ));
  }
}

/// This is used so that the elevation of the container is kept and the
/// drop shadow is not clipped.
///
class _SizeTransitionNoClip extends AnimatedWidget {
  final Widget child;

  const _SizeTransitionNoClip(
      {@required Animation<double> sizeFactor, this.child})
      : super(listenable: sizeFactor);

  @override
  Widget build(BuildContext context) {
    return new Align(
      alignment: const AlignmentDirectional(-1.0, -1.0),
      widthFactor: null,
      heightFactor: (this.listenable as Animation<double>).value,
      child: child,
    );
  }
}
