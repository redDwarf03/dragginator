// @dart=2.9

import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:dragginator/network/model/response/dragginator_list_from_address_response.dart';
import 'package:dragginator/ui/dragginator/my_dragginator_merging.dart';
import 'package:dragginator/ui/send/send_confirm_sheet.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:dragginator/dimens.dart';
import 'package:dragginator/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dragginator/model/address.dart';
import 'package:dragginator/network/model/response/dragginator_infos_from_dna_response.dart';
import 'package:dragginator/service/dragginator_service.dart';
import 'package:dragginator/service_locator.dart';
import 'package:dragginator/styles.dart';
import 'package:dragginator/appstate_container.dart';
import 'package:dragginator/ui/send/send_sheet.dart';
import 'package:dragginator/ui/util/ui_util.dart';
import 'package:dragginator/ui/widgets/buttons.dart';
import 'package:dragginator/ui/widgets/sheet_util.dart';
import 'package:fluttericon/typicons_icons.dart';
import 'package:scrolling_page_indicator/scrolling_page_indicator.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';
import 'package:flip_card/flip_card.dart';

class BreedingList extends StatefulWidget {
  final String address;
  final List<DragginatorListFromAddressResponse> dragginatorList;

  BreedingList(this.address, this.dragginatorList) : super();

  _BreedingListStateState createState() => _BreedingListStateState();
}

class _BreedingListStateState extends State<BreedingList> {
  bool loaded;
  List<List> dragginatorInfosList;
  PageController _controller;

  double numberOfFeatures = 8;
  var data = [
    [0, 0, 0, 0, 0, 0, 0, 0]
  ];
  var ticks = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

  var features = [
    "strategy",
    "bravery",
    "strength",
    "agility",
    "power",
    "stamina",
    "speed",
    "health"
  ];

  get action => null;

  @override
  void initState() {
    loaded = false;

    _controller = PageController();
    loadEggsAndDragonsList();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void loadEggsAndDragonsList() async {
    features = features.sublist(0, numberOfFeatures.floor());
    data = data
        .map((graph) => graph.sublist(0, numberOfFeatures.floor()))
        .toList();

    dragginatorInfosList =
        new List.filled( widget.dragginatorList.length, null);
    for (int i = 0; i < widget.dragginatorList.length; i++) {
      dragginatorInfosList[i] = new List.filled(2, null);
      dragginatorInfosList[i][0] = widget.dragginatorList[i];
      dragginatorInfosList[i][1] = await sl
          .get<DragginatorService>()
          .getInfosFromDna(widget.dragginatorList[i].dna);
    }

    setState(() {
      if (mounted) {
        loaded = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        minimum:
            EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.035),
        child: Column(
          children: <Widget>[
            // A row for the address text and close button

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalization.of(context).dragginatorBreedingListHeader,
                  style: AppStyles.textStyleSettingsHeader(context),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Stack(children: <Widget>[
                  Container(
                      height: 600,
                      child: SafeArea(
                        minimum: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height * 0.035,
                          top: 10,
                        ),
                        child: Column(
                          children: <Widget>[
                            // list
                            Expanded(
                              child: Stack(
                                children: <Widget>[
                                  loaded == true
                                      ? PageView.builder(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          controller: _controller,
                                          itemCount:
                                              dragginatorInfosList.length,
                                          itemBuilder: (context, index) {
                                            // Build
                                            return buildSingle(context,
                                                dragginatorInfosList[index]);
                                          },
                                        )
                                      : Center(
                                          child: CircularProgressIndicator()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ]),
              ),
            ),

            widget.dragginatorList != null &&
                    widget.dragginatorList.length > 0
                ? ScrollingPageIndicator(
                    dotColor: StateContainer.of(context).curTheme.text,
                    dotSelectedColor:
                        StateContainer.of(context).curTheme.primary,
                    dotSize: 6,
                    dotSelectedSize: 8,
                    dotSpacing: 12,
                    controller: _controller,
                    itemCount: widget.dragginatorList.length,
                    orientation: Axis.horizontal,
                  )
                : SizedBox(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                widget.dragginatorList != null &&
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
                                          .address));
                            },
                            padding: EdgeInsets.all(0.0),
                            shape: CircleBorder(),
                            splashColor:
                                StateContainer.of(context).curTheme.text30,
                            highlightColor:
                                StateContainer.of(context).curTheme.text15,
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
                                  style: AppStyles.textStyleTiny(context),
                                )
                              ],
                            )),
                      )
                    : SizedBox(width: 0),
                sl.get<DragginatorService>().isEggOwner(
                            StateContainer.of(context).wallet.tokens) ==
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
                                      title: AppLocalization.of(context)
                                          .dragginatorGetEggWithEggHeader,
                                      amountRaw: "0",
                                      operation: "token:transfer",
                                      openfield: "egg:1",
                                      comment: "",
                                      destination: AppLocalization.of(context)
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
                                Icon(FontAwesome5.egg,
                                    size: 26,
                                    color: StateContainer.of(context)
                                        .curTheme
                                        .icon),
                                Text(
                                  AppLocalization.of(context)
                                      .dragginatorGetEggWithEggHeader,
                                  style: AppStyles.textStyleTiny(context),
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
                                destination: AppLocalization.of(context)
                                    .dragginatorAddress,
                                contactName: ""));
                      },
                      padding: EdgeInsets.all(0.0),
                      shape: CircleBorder(),
                      splashColor: StateContainer.of(context).curTheme.text30,
                      highlightColor:
                          StateContainer.of(context).curTheme.text15,
                      child: Column(
                        children: [
                          Icon(FontAwesome5.money_bill_wave,
                              size: 26,
                              color: StateContainer.of(context).curTheme.icon),
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
        ));
  }

  Widget buildSingle(BuildContext context, List dragginatorInfosList) {
    DragginatorInfosFromDnaResponse dragginatorInfosFromDnaResponse =
        dragginatorInfosList[1];
    data = [
      [
        double.tryParse(
                dragginatorInfosFromDnaResponse.abilities[0][0].toString())
            .toInt(),
        double.tryParse(
                dragginatorInfosFromDnaResponse.abilities[0][1].toString())
            .toInt(),
        double.tryParse(
                dragginatorInfosFromDnaResponse.abilities[0][2].toString())
            .toInt(),
        double.tryParse(
                dragginatorInfosFromDnaResponse.abilities[0][3].toString())
            .toInt(),
        double.tryParse(
                dragginatorInfosFromDnaResponse.abilities[0][4].toString())
            .toInt(),
        double.tryParse(
                dragginatorInfosFromDnaResponse.abilities[0][5].toString())
            .toInt(),
        double.tryParse(
                dragginatorInfosFromDnaResponse.abilities[0][6].toString())
            .toInt(),
        double.tryParse(
                dragginatorInfosFromDnaResponse.abilities[0][7].toString())
            .toInt(),
      ]
    ];

    return Container(
        padding: EdgeInsets.all(0.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // Main Container
              Container(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                margin: new EdgeInsetsDirectional.only(start: 12.0, end: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                          margin: EdgeInsetsDirectional.only(start: 2.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    FontAwesome5.dna,
                                    size: AppFontSizes.small,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  SelectableText(dragginatorInfosList[0].dna,
                                      style: AppStyles.textStyleParagraphSmall(
                                          context)),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Row(
                                children: [
                                  Text("Capacities: ",
                                      style: AppStyles.textStyleParagraphSmall(
                                          context)),
                                  Text(
                                      dragginatorInfosFromDnaResponse
                                          .capacities,
                                      style: AppStyles.textStyleParagraphSmall(
                                          context)),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                      "Creator: " +
                                          Address(dragginatorInfosFromDnaResponse
                                                  .creator)
                                              .getShortString2(),
                                      style: AppStyles.textStyleParagraphSmall(
                                          context)),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                      "Owner: " +
                                          Address(dragginatorInfosFromDnaResponse
                                                  .owner)
                                              .getShortString2(),
                                      style: AppStyles.textStyleParagraphSmall(
                                          context)),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: [
                                          Icon(
                                            dragginatorInfosList[0].status ==
                                                    "egg"
                                                ? FontAwesome5.egg
                                                : FontAwesome5.dragon,
                                            size: AppFontSizes.small,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(dragginatorInfosList[0].status,
                                              style: AppStyles
                                                  .textStyleParagraphSmall(
                                                      context)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          dragginatorInfosList[0]
                                                      .type
                                                      .toLowerCase() ==
                                                  "water"
                                              ? Icon(
                                                  FontAwesome5.water,
                                                  size: AppFontSizes.small,
                                                )
                                              : dragginatorInfosList[0]
                                                          .type
                                                          .toLowerCase() ==
                                                      "air"
                                                  ? Icon(
                                                      FontAwesome5.wind,
                                                      size: AppFontSizes.small,
                                                    )
                                                  : dragginatorInfosList[0]
                                                              .type
                                                              .toLowerCase() ==
                                                          "earth"
                                                      ? Icon(
                                                          FontAwesome5.globe,
                                                          size: AppFontSizes
                                                              .small,
                                                        )
                                                      : dragginatorInfosList[0]
                                                                  .type
                                                                  .toLowerCase() ==
                                                              "fire"
                                                          ? Icon(
                                                              FontAwesome5
                                                                  .fire_alt,
                                                              size: AppFontSizes
                                                                  .small,
                                                            )
                                                          : dragginatorInfosList[0]
                                                                      .type
                                                                      .toLowerCase() ==
                                                                  "gold"
                                                              ? Icon(FontAwesome5.circle,
                                                                  size:
                                                                      AppFontSizes
                                                                          .small,
                                                                  color: Color(
                                                                      0xffaf9500))
                                                              : dragginatorInfosList[0]
                                                                          .type
                                                                          .toLowerCase() ==
                                                                      "silver"
                                                                  ? Icon(FontAwesome5.circle,
                                                                      size: AppFontSizes
                                                                          .small,
                                                                      color: Color(0xffB4B4B4))
                                                                  : dragginatorInfosList[0].type.toLowerCase() == "bronze"
                                                                      ? Icon(FontAwesome5.circle, size: AppFontSizes.small, color: Color(0xff6A3805))
                                                                      : Icon(
                                                                          FontAwesome
                                                                              .globe,
                                                                          size:
                                                                              AppFontSizes.small,
                                                                        ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(dragginatorInfosList[0].type,
                                              style: AppStyles
                                                  .textStyleParagraphSmall(
                                                      context)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            FontAwesome5.fingerprint,
                                            size: AppFontSizes.small,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(dragginatorInfosList[0].species,
                                              style: AppStyles
                                                  .textStyleParagraphSmall(
                                                      context)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            FontAwesome5.gift,
                                            size: AppFontSizes.small,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            dragginatorInfosFromDnaResponse.age,
                                            style: AppStyles
                                                .textStyleParagraphSmall(
                                                    context),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: [
                                          Text("Generation: ",
                                              style: AppStyles
                                                  .textStyleParagraphSmall(
                                                      context)),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                              dragginatorInfosFromDnaResponse
                                                  .gen,
                                              style: AppStyles
                                                  .textStyleParagraphSmall(
                                                      context)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text("Rarity: ",
                                              style: AppStyles
                                                  .textStyleParagraphSmall(
                                                      context)),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                              dragginatorInfosFromDnaResponse
                                                  .rarity
                                                  .toString(),
                                              style: AppStyles
                                                  .textStyleParagraphSmall(
                                                      context)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text("Global Id: ",
                                              style: AppStyles
                                                  .textStyleParagraphSmall(
                                                      context)),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                              dragginatorInfosFromDnaResponse
                                                  .globId,
                                              style: AppStyles
                                                  .textStyleParagraphSmall(
                                                      context)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text("Generation Id: ",
                                              style: AppStyles
                                                  .textStyleParagraphSmall(
                                                      context)),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                              dragginatorInfosFromDnaResponse
                                                  .genId,
                                              style: AppStyles
                                                  .textStyleParagraphSmall(
                                                      context)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Center(
                                child: FlipCard(
                                  flipOnTouch: true,
                                  direction: FlipDirection.HORIZONTAL,
                                  front: Container(
                                    width: 250.0,
                                    height: 250.0,
                                    child: CircularProfileAvatar(
                                      UIUtil.getDragginatorURL(
                                          dragginatorInfosList[0].dna,
                                          dragginatorInfosList[0].status),
                                      elevation: 25,
                                      backgroundColor:
                                          StateContainer.of(context)
                                              .curTheme
                                              .text05,
                                      radius: 250.0,
                                    ),
                                  ),
                                  back: Container(
                                    width: 250.0,
                                    height: 250.0,
                                    child: RadarChart.dark(
                                      ticks: ticks,
                                      features: features,
                                      data: data,
                                      reverseAxis: false,
                                      useSides: false,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )),
                    ),
                  ],
                ),
              ),
              Container(
                  margin:
                      new EdgeInsetsDirectional.only(start: 12.0, end: 12.0),
                  child: Column(children: <Widget>[
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                        "Send the " +
                            dragginatorInfosFromDnaResponse.status +
                            " to another address",
                        style: AppStyles.textStyleParagraphSmall(context)),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: <Widget>[
                        AppButton.buildAppButton(
                            context,
                            AppButtonType.PRIMARY,
                            AppLocalization.of(context)
                                .dragginatorSendEgg
                                .replaceAll("%1",
                                    dragginatorInfosFromDnaResponse.status),
                            Dimens.BUTTON_TOP_DIMENS, onPressed: () {
                          Sheets.showAppHeightNineSheet(
                              context: context,
                              widget: SendSheet(
                                sendATokenActive: false,
                                title: AppLocalization.of(context)
                                    .dragginatorSendEgg
                                    .replaceAll("%1",
                                        dragginatorInfosFromDnaResponse.status),
                                actionButtonTitle: AppLocalization.of(context)
                                    .dragginatorSendEgg
                                    .replaceAll("%1",
                                        dragginatorInfosFromDnaResponse.status),
                                quickSendAmount: "0",
                                operation: "dragg:transfer",
                                openfield: dragginatorInfosFromDnaResponse.dna,
                                localCurrency:
                                    StateContainer.of(context).curCurrency,
                              ));
                        }),
                      ],
                    ),
                  ])),

              Container(
                  margin:
                      new EdgeInsetsDirectional.only(start: 12.0, end: 12.0),
                  child: Column(children: <Widget>[
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                        "Allow someone to transfer the " +
                            dragginatorInfosFromDnaResponse.status,
                        style: AppStyles.textStyleParagraphSmall(context)),
                    Text(
                        "This transaction will allow the recipient address to transfer the dna given in the data field. After using this command, the " +
                            dragginatorInfosFromDnaResponse.status +
                            " owner still can transfer the " +
                            dragginatorInfosFromDnaResponse.status +
                            ". The owner can at anytime revert this action",
                        style:
                            AppStyles.textStyleSettingItemSubheader(context)),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: <Widget>[
                        // Send Button
                        AppButton.buildAppButton(
                            context,
                            AppButtonType.PRIMARY,
                            AppLocalization.of(context)
                                .dragginatorAllowTransfer,
                            Dimens.BUTTON_TOP_DIMENS, onPressed: () {
                          Sheets.showAppHeightNineSheet(
                              context: context,
                              widget: SendSheet(
                                sendATokenActive: false,
                                title: AppLocalization.of(context)
                                    .dragginatorAllowTransfer,
                                actionButtonTitle: AppLocalization.of(context)
                                    .dragginatorAllowTransfer,
                                quickSendAmount: "0",
                                operation: "dragg:sell",
                                openfield: dragginatorInfosFromDnaResponse.dna,
                                localCurrency:
                                    StateContainer.of(context).curCurrency,
                              ));
                        }),
                      ],
                    ),
                  ])),
              Container(
                  margin:
                      new EdgeInsetsDirectional.only(start: 12.0, end: 12.0),
                  child: Column(children: <Widget>[
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text("Revert the sell",
                        style: AppStyles.textStyleParagraphSmall(context)),
                    Text(
                        "If the " +
                            dragginatorInfosFromDnaResponse.status +
                            " is transfered by the owner or the seller, only the new owner will be able to transfer it.",
                        style:
                            AppStyles.textStyleSettingItemSubheader(context)),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: <Widget>[
                        // Send Button
                        AppButton.buildAppButton(
                            context,
                            AppButtonType.PRIMARY,
                            AppLocalization.of(context).dragginatorRevert,
                            Dimens.BUTTON_TOP_DIMENS, onPressed: () {
                          Sheets.showAppHeightNineSheet(
                              context: context,
                              widget: SendSheet(
                                sendATokenActive: false,
                                title: AppLocalization.of(context)
                                    .dragginatorRevert,
                                actionButtonTitle: AppLocalization.of(context)
                                    .dragginatorRevert,
                                quickSendAmount: "0",
                                operation: "dragg:unsell",
                                openfield: dragginatorInfosFromDnaResponse.dna,
                                localCurrency:
                                    StateContainer.of(context).curCurrency,
                              ));
                        }),
                      ],
                    ),
                  ])),
              dragginatorInfosFromDnaResponse.status.toLowerCase() == "egg"
                  ? Container(
                      margin: new EdgeInsetsDirectional.only(
                          start: 12.0, end: 12.0),
                      child: Column(children: <Widget>[
                        Divider(
                          height: 2,
                          color: StateContainer.of(context).curTheme.text15,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text("Register the egg to the hunt",
                            style: AppStyles.textStyleParagraphSmall(context)),
                        Text(
                            "This is the first step for your egg to become a draggon. You can only use this command if the choosen egg is at least 30 days old. This will allow your egg to be searched on the island.",
                            style: AppStyles.textStyleSettingItemSubheader(
                                context)),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: <Widget>[
                            // Send Button
                            AppButton.buildAppButton(
                                context,
                                AppButtonType.PRIMARY,
                                AppLocalization.of(context)
                                    .dragginatorRegisterAnEggToTheHunt,
                                Dimens.BUTTON_TOP_DIMENS, onPressed: () {
                              Sheets.showAppHeightNineSheet(
                                  context: context,
                                  widget: SendSheet(
                                    sendATokenActive: false,
                                    title: AppLocalization.of(context)
                                        .dragginatorRegisterAnEggToTheHunt,
                                    actionButtonTitle:
                                        AppLocalization.of(context)
                                            .dragginatorRegisterAnEggToTheHunt,
                                    quickSendAmount: "0",
                                    address: AppLocalization.of(context)
                                        .dragginatorAddress,
                                    operation: "dragg:hunt",
                                    openfield:
                                        dragginatorInfosFromDnaResponse.dna,
                                    localCurrency:
                                        StateContainer.of(context).curCurrency,
                                  ));
                            }),
                          ],
                        ),
                      ]))
                  : SizedBox(),
              dragginatorInfosFromDnaResponse.status.toLowerCase() == "egg"
                  ? Container(
                      margin: new EdgeInsetsDirectional.only(
                          start: 12.0, end: 12.0),
                      child: Column(children: <Widget>[
                        Divider(
                          height: 2,
                          color: StateContainer.of(context).curTheme.text15,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text("Hatch the egg",
                            style: AppStyles.textStyleParagraphSmall(context)),
                        Text(
                            "To use this command, your need to have sent the dragg:hunt command and then:\n- wait one day or\n- find it on the island\nOnce this is done, you can send the transaction, and your egg will hatch!",
                            style: AppStyles.textStyleSettingItemSubheader(
                                context)),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: <Widget>[
                            // Send Button
                            AppButton.buildAppButton(
                                context,
                                AppButtonType.PRIMARY,
                                AppLocalization.of(context)
                                    .dragginatorHatchAnEgg,
                                Dimens.BUTTON_TOP_DIMENS, onPressed: () {
                              Sheets.showAppHeightNineSheet(
                                  context: context,
                                  widget: SendSheet(
                                    sendATokenActive: false,
                                    title: AppLocalization.of(context)
                                        .dragginatorHatchAnEgg,
                                    actionButtonTitle:
                                        AppLocalization.of(context)
                                            .dragginatorHatchAnEgg,
                                    quickSendAmount: "0",
                                    address: AppLocalization.of(context)
                                        .dragginatorAddress,
                                    operation: "dragg:hatch",
                                    openfield:
                                        dragginatorInfosFromDnaResponse.dna,
                                    localCurrency:
                                        StateContainer.of(context).curCurrency,
                                  ));
                            }),
                          ],
                        ),
                      ]))
                  : SizedBox(),
            ],
          ),
        ));
  }
}
