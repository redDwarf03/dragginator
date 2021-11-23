// @dart=2.9

import 'dart:async';

import 'package:event_taxi/event_taxi.dart';
import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
import 'package:dragginator/appstate_container.dart';
import 'package:dragginator/bus/events.dart';
import 'package:dragginator/dimens.dart';
import 'package:dragginator/model/db/appdb.dart';
import 'package:dragginator/model/db/contact.dart';
import 'package:dragginator/network/model/response/address_txs_response.dart';
import 'package:dragginator/service/app_service.dart';
import 'package:dragginator/styles.dart';
import 'package:dragginator/localization.dart';
import 'package:dragginator/service_locator.dart';
import 'package:dragginator/ui/send/send_complete_sheet.dart';
import 'package:dragginator/ui/util/routes.dart';
import 'package:dragginator/ui/widgets/buttons.dart';
import 'package:dragginator/ui/widgets/dialog.dart';
import 'package:dragginator/ui/util/ui_util.dart';
import 'package:dragginator/ui/widgets/sheet_util.dart';
import 'package:dragginator/util/app_ffi/apputil.dart';
import 'package:dragginator/util/numberutil.dart';
import 'package:dragginator/util/sharedprefsutil.dart';
import 'package:dragginator/util/biometrics.dart';
import 'package:dragginator/util/hapticutil.dart';
import 'package:dragginator/util/caseconverter.dart';
import 'package:dragginator/model/authentication_method.dart';
import 'package:dragginator/model/vault.dart';
import 'package:dragginator/ui/widgets/security.dart';

class SendConfirmSheet extends StatefulWidget {
  final String amountRaw;
  final String destination;
  final String contactName;
  final bool maxSend;
  final String openfield;
  final String operation;
  final String comment;
  final String title;
  final bool displayTo;

  SendConfirmSheet(
      {this.amountRaw,
      this.destination,
      this.contactName,
      this.openfield,
      this.operation,
      this.comment,
      this.maxSend = false,
      this.title,
      this.displayTo})
      : super();

  _SendConfirmSheetState createState() => _SendConfirmSheetState();
}

class _SendConfirmSheetState extends State<SendConfirmSheet> {
  String amount;
  String destinationAltered;
  bool animationOpen;

  StreamSubscription<AuthenticatedEvent> _authSub;
  StreamSubscription<TransactionSendEvent> _sendTxSub;

  void _registerBus() {
    _authSub = EventTaxiImpl.singleton()
        .registerTo<AuthenticatedEvent>()
        .listen((event) {
      if (event.authType == AUTH_EVENT_TYPE.SEND) {
        _doSend();
      }
    });

    _sendTxSub = EventTaxiImpl.singleton()
        .registerTo<TransactionSendEvent>()
        .listen((event) {
      //print("listen TransactionSendEvent");
      //print("result : " + event.response);
      if (event.response != "Success") {
        // Send failed
        if (animationOpen) {
          Navigator.of(context).pop();
        }
        UIUtil.showSnackbar(
            AppLocalization.of(context).sendError + " (" + event.response + ")",
            context);
        Navigator.of(context).pop();
      } else {
        StateContainer.of(context).wallet.accountBalance -=
            double.parse(widget.amountRaw);

        // Show complete
        Contact contact;
        sl
            .get<DBHelper>()
            .getContactWithAddress(widget.destination)
            .then((value) => contact);
        String contactName = contact == null ? null : contact.name;
        Navigator.of(context).popUntil(RouteUtils.withNameLike('/home'));
        StateContainer.of(context).requestUpdateHistory();
        Sheets.showAppHeightNineSheet(
            context: context,
            closeOnTap: true,
            removeUntilHome: true,
            widget: SendCompleteSheet(
              title: widget.title,
              amountRaw: widget.amountRaw,
              destination: destinationAltered,
              contactName: contactName,
            ));
      }
    });
  }

  void _destroyBus() {
    if (_authSub != null) {
      _authSub.cancel();
    }
    if (_sendTxSub != null) {
      _sendTxSub.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    _registerBus();
    this.animationOpen = false;
    // Derive amount from raw amount
    if (NumberUtil.getRawAsUsableString(widget.amountRaw).replaceAll(",", "") ==
        NumberUtil.getRawAsUsableDecimal(widget.amountRaw).toString()) {
      amount = NumberUtil.getRawAsUsableString(widget.amountRaw);
    } else {
      amount = NumberUtil.truncateDecimal(
                  NumberUtil.getRawAsUsableDecimal(widget.amountRaw),
                  digits: 6)
              .toStringAsFixed(6) +
          "~";
    }
    destinationAltered = widget.destination;
  }

  @override
  void dispose() {
    _destroyBus();
    super.dispose();
  }

  void _showSendingAnimation(BuildContext context) {
    animationOpen = true;
    Navigator.of(context).push(AnimationLoadingOverlay(
        AnimationType.SEND,
        StateContainer.of(context).curTheme.animationOverlayStrong,
        StateContainer.of(context).curTheme.animationOverlayMedium,
        onPoppedCallback: () => animationOpen = false));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        minimum:
            EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.035),
        child: Column(
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
            //The main widget that holds the text fields, "SENDING" and "TO" texts
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // "SENDING" TEXT
                  Container(
                    margin: EdgeInsets.only(bottom: 10.0),
                    child: Column(
                      children: <Widget>[
                        Text(
                          CaseChange.toUpperCase(
                              widget.title == null
                                  ? AppLocalization.of(context).sending
                                  : widget.title,
                              context),
                          style: AppStyles.textStyleHeader(context),
                        ),
                      ],
                    ),
                  ),
                  // Container for the amount text
                  Container(
                    margin: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width * 0.105,
                        right: MediaQuery.of(context).size.width * 0.105),
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          StateContainer.of(context).curTheme.backgroundDarkest,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    // Amount text
                    child: Column(
                      children: [
                        double.tryParse(amount.replaceAll(",", "")) > 0
                            ? RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: '',
                                  children: [
                                    TextSpan(
                                      text: "$amount",
                                      style: TextStyle(
                                        color: StateContainer.of(context)
                                            .curTheme
                                            .primary,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Lato',
                                      ),
                                    ),
                                    TextSpan(
                                      text: " BIS",
                                      style: TextStyle(
                                        color: StateContainer.of(context)
                                            .curTheme
                                            .primary,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w300,
                                        fontFamily: 'Lato',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox(),
                        widget.operation ==
                                AddressTxsResponseResult.TOKEN_TRANSFER
                            ? RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: '',
                                  children: [
                                    TextSpan(
                                      text:
                                          widget.openfield.split(":")[1] + " ",
                                      style: TextStyle(
                                        color: StateContainer.of(context)
                                            .curTheme
                                            .primary,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Lato',
                                      ),
                                    ),
                                    TextSpan(
                                      text: widget.openfield.split(":")[0],
                                      style: TextStyle(
                                        color: StateContainer.of(context)
                                            .curTheme
                                            .primary,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Lato',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox(),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            "+ " +
                                AppLocalization.of(context).fees +
                                ": " +
                                sl
                                    .get<AppService>()
                                    .getFeesEstimation(
                                        widget.openfield, widget.operation)
                                    .toStringAsFixed(5) +
                                " BIS",
                            style: TextStyle(
                              color:
                                  StateContainer.of(context).curTheme.primary60,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // "TO" text
                  widget.displayTo
                      ? Container(
                          margin: EdgeInsets.only(top: 10.0, bottom: 0),
                          child: Column(
                            children: <Widget>[
                              Text(
                                CaseChange.toUpperCase(
                                    AppLocalization.of(context).to, context),
                                style: TextStyle(
                                  color: StateContainer.of(context)
                                      .curTheme
                                      .text60,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Lato',
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(),
                  // Address text
                  widget.displayTo
                      ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 25.0,
                            vertical: 15.0,
                          ),
                          margin: EdgeInsets.only(
                              top: 10.0,
                              bottom: 10,
                              left: MediaQuery.of(context).size.width * 0.105,
                              right: MediaQuery.of(context).size.width * 0.105),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: StateContainer.of(context)
                                .curTheme
                                .backgroundDarkest,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: UIUtil.threeLineAddressText(
                              context, destinationAltered,
                              contactName: widget.contactName))
                      : const SizedBox(),

                  Expanded(
                    child: Stack(children: [
                      SingleChildScrollView(
                          padding: EdgeInsets.only(top: 30.0, bottom: 30),
                          child: Column(children: <Widget>[
                            Stack(children: <Widget>[
                              Column(
                                children: [
                                  widget.operation == "" ||
                                          widget.operation ==
                                              AddressTxsResponseResult
                                                  .TOKEN_TRANSFER
                                      ? SizedBox()
                                      : Container(
                                          margin: EdgeInsets.only(
                                              top: 10.0, bottom: 0),
                                          child: Column(
                                            children: <Widget>[
                                              Text(
                                                CaseChange.toUpperCase(
                                                    AppLocalization.of(context)
                                                        .operation,
                                                    context),
                                                style: TextStyle(
                                                  color:
                                                      StateContainer.of(context)
                                                          .curTheme
                                                          .primary60,
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w300,
                                                  fontFamily: 'Lato',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  widget.operation == "" ||
                                          widget.operation ==
                                              AddressTxsResponseResult
                                                  .TOKEN_TRANSFER
                                      ? SizedBox()
                                      : Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 25.0, vertical: 15.0),
                                          margin: EdgeInsets.only(
                                              left: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.105,
                                              right: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.105),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: StateContainer.of(context)
                                                .curTheme
                                                .backgroundDarkest,
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          child: Text(
                                            removeDiacritics(widget.operation),
                                            style: TextStyle(
                                              color: StateContainer.of(context)
                                                  .curTheme
                                                  .primary60,
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w300,
                                              fontFamily: 'Lato',
                                            ),
                                          )),
                                  widget.comment == "" || widget.openfield == ""
                                      ? SizedBox()
                                      : Container(
                                          margin: EdgeInsets.only(
                                              top: 10.0, bottom: 0),
                                          child: Column(
                                            children: <Widget>[
                                              Text(
                                                CaseChange.toUpperCase(
                                                    AppLocalization.of(context)
                                                        .openfield,
                                                    context),
                                                style: TextStyle(
                                                  color:
                                                      StateContainer.of(context)
                                                          .curTheme
                                                          .primary60,
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w300,
                                                  fontFamily: 'Lato',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  widget.comment == "" || widget.openfield == ""
                                      ? SizedBox()
                                      : Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 25.0, vertical: 15.0),
                                          margin: EdgeInsets.only(
                                              left: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.105,
                                              right: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.105),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: StateContainer.of(context)
                                                .curTheme
                                                .backgroundDarkest,
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          child: Text(
                                            removeDiacritics(widget.operation ==
                                                    AddressTxsResponseResult
                                                        .TOKEN_TRANSFER
                                                ? widget.comment
                                                : widget.openfield),
                                            style: TextStyle(
                                              color: StateContainer.of(context)
                                                  .curTheme
                                                  .primary60,
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w300,
                                              fontFamily: 'Lato',
                                            ),
                                          )),
                                ],
                              )
                            ])
                          ])),
                      //List Top Gradient End
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: 30.0,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                StateContainer.of(context)
                                    .curTheme
                                    .background00,
                                StateContainer.of(context).curTheme.background
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
                                StateContainer.of(context).curTheme.background
                              ],
                              begin: AlignmentDirectional(0.5, -1),
                              end: AlignmentDirectional(0.5, 0.5),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  )
                ],
              ),
            ),

            //A container for CONFIRM and CANCEL buttons
            Container(
              margin: EdgeInsets.only(top: 10.0, bottom: 0),
              child: Column(
                children: <Widget>[
                  // A row for CONFIRM Button
                  Row(
                    children: <Widget>[
                      // CONFIRM Button
                      AppButton.buildAppButton(
                          context,
                          AppButtonType.PRIMARY,
                          CaseChange.toUpperCase(
                              AppLocalization.of(context).confirm, context),
                          Dimens.BUTTON_TOP_DIMENS, onPressed: () async {
                        // Authenticate
                        AuthenticationMethod authMethod =
                            await sl.get<SharedPrefsUtil>().getAuthMethod();
                        bool hasBiometrics =
                            await sl.get<BiometricUtil>().hasBiometrics();
                        if (authMethod.method == AuthMethod.BIOMETRICS &&
                            hasBiometrics) {
                          try {
                            bool authenticated = await sl
                                .get<BiometricUtil>()
                                .authenticateWithBiometrics(
                                    context,
                                    AppLocalization.of(context)
                                        .sendAmountConfirm
                                        .replaceAll("%1", amount));
                            if (authenticated) {
                              sl.get<HapticUtil>().fingerprintSucess();
                              EventTaxiImpl.singleton().fire(
                                  AuthenticatedEvent(AUTH_EVENT_TYPE.SEND));
                            }
                          } catch (e) {
                            await authenticateWithPin();
                          }
                        } else {
                          await authenticateWithPin();
                        }
                      })
                    ],
                  ),
                  // A row for CANCEL Button
                  Row(
                    children: <Widget>[
                      // CANCEL Button
                      AppButton.buildAppButton(
                          context,
                          AppButtonType.PRIMARY_OUTLINE,
                          CaseChange.toUpperCase(
                              AppLocalization.of(context).cancel, context),
                          Dimens.BUTTON_BOTTOM_DIMENS, onPressed: () {
                        Navigator.of(context).pop();
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  Future<void> _doSend() async {
    try {
      _showSendingAnimation(context);

      // Send tx
      String openfield = "";
      if (widget.openfield.length > 0) {
        openfield = widget.openfield;
      }
      if (widget.comment.length > 0) {
        openfield += ':{"Message":"' + widget.comment + '"}';
      }
      String seed = await StateContainer.of(context).getSeed();
      if (seed ==
          '772AD56F4AC98FABD97DE6BAA56C055F2B249D59EE34F8FE45D770AEB4E6958A') {
            EventTaxiImpl.singleton()
          .fire(TransactionSendEvent(response: 'Demo mode'));
      } else {
        int index = StateContainer.of(context).selectedAccount.index;
        String publicKeyBase64 =
            await AppUtil().seedToPublicKeyBase64(seed, index);
        String privateKey = await AppUtil().seedToPrivateKey(seed, index);
        //print("send tx");
        sl.get<AppService>().sendTx(
            StateContainer.of(context).wallet.address,
            widget.amountRaw,
            destinationAltered,
            openfield,
            widget.operation,
            publicKeyBase64,
            privateKey);
      }
    } catch (e) {
      // Send failed
      //print("send failed" + e.toString());
      EventTaxiImpl.singleton()
          .fire(TransactionSendEvent(response: e.toString()));
    }
  }

  Future<void> authenticateWithPin() async {
    // PIN Authentication
    String expectedPin = await sl.get<Vault>().getPin();
    bool auth = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      return new PinScreen(
        PinOverlayType.ENTER_PIN,
        expectedPin: expectedPin,
        description: AppLocalization.of(context)
            .sendAmountConfirmPin
            .replaceAll("%1", amount),
      );
    }));
    //print("authenticateWithPin - auth : " + auth.toString());
    if (auth != null && auth) {
      await Future.delayed(Duration(milliseconds: 200));
      //print("authenticateWithPin - fire AuthenticatedEvent");
      EventTaxiImpl.singleton().fire(AuthenticatedEvent(AUTH_EVENT_TYPE.SEND));
    }
  }
}
