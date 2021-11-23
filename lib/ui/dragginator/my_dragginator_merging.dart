// @dart=2.9

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';

// Project imports:
import 'package:dragginator/appstate_container.dart';
import 'package:dragginator/dimens.dart';
import 'package:dragginator/localization.dart';
import 'package:dragginator/service/dragginator_service.dart';
import 'package:dragginator/service_locator.dart';
import 'package:dragginator/styles.dart';
import 'package:dragginator/ui/send/send_confirm_sheet.dart';
import 'package:dragginator/ui/send/send_sheet.dart';
import 'package:dragginator/ui/util/ui_util.dart';
import 'package:dragginator/ui/widgets/buttons.dart';
import 'package:dragginator/ui/widgets/sheet_util.dart';

class MyDragginatorMerging extends StatefulWidget {
  final String address;
  final List<List> dragginatorInfosList;

  MyDragginatorMerging(this.address, this.dragginatorInfosList) : super();

  _MyDragginatorMergingStateState createState() =>
      _MyDragginatorMergingStateState();
}

class _MyDragginatorMergingStateState extends State<MyDragginatorMerging> {
  String dna1selected;
  String dna2selected;
  List<String> dnaCompatible;
  bool isCompatible = false;

  double numberOfFeatures = 8;
  var data = [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
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
    dnaCompatible = null;
    features = features.sublist(0, numberOfFeatures.floor());
    data = data
        .map((graph) => graph.sublist(0, numberOfFeatures.floor()))
        .toList();
    super.initState();
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                //Empty SizedBox
                SizedBox(
                  width: 60,
                  height: 40,
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
                  ],
                ),
                //Empty SizedBox
                SizedBox(
                  width: 60,
                  height: 40,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalization.of(context).dragginatorMergingHeader,
                  style: AppStyles.textStyleSettingsHeader(context),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Stack(children: <Widget>[
                  Container(
                      height: 700,
                      child: SafeArea(
                        minimum: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height * 0.035,
                          top: 10,
                        ),
                        child: Column(
                          children: <Widget>[
                            Container(
                              width: 200.0,
                              height: 200.0,
                              child: RadarChart.dark(
                                ticks: ticks,
                                features: features,
                                data: data,
                                reverseAxis: false,
                                useSides: false,
                              ),
                            ),
                            // list
                            Expanded(
                              child: Stack(
                                children: <Widget>[
                                  GridView.count(
                                    crossAxisCount: 3,
                                    children: List.generate(
                                        widget.dragginatorInfosList.length,
                                        (index) {
                                      return Center(
                                        child: Container(
                                          width: 100.0,
                                          height: 100.0,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(100.0),
                                            border: Border.all(
                                                color: dna1selected != null &&
                                                        dna1selected ==
                                                            widget
                                                                .dragginatorInfosList[
                                                                    index][1]
                                                                .dna
                                                    ? Colors.green
                                                    : dna2selected != null &&
                                                            dna2selected ==
                                                                widget
                                                                    .dragginatorInfosList[index]
                                                                        [1]
                                                                    .dna
                                                        ? Colors.blue
                                                        : StateContainer.of(context)
                                                            .curTheme
                                                            .primary,
                                                width: dna1selected ==
                                                            widget
                                                                .dragginatorInfosList[
                                                                    index][1]
                                                                .dna ||
                                                        dna2selected ==
                                                            widget
                                                                .dragginatorInfosList[
                                                                    index][1]
                                                                .dna
                                                    ? 4
                                                    : 0),
                                          ),
                                          alignment:
                                              AlignmentDirectional(-4, 0),
                                          child: Hero(
                                            tag: "dragginator",
                                            child: InkWell(
                                              onTap: () async {
                                                if (dnaCompatible == null ||
                                                    dnaCompatible != null &&
                                                        dnaCompatible.contains(
                                                                widget
                                                                    .dragginatorInfosList[
                                                                        index]
                                                                        [1]
                                                                    .dna) ==
                                                            true) {
                                                  await selectItem(index);
                                                  setState(() {});
                                                }
                                              },
                                              child: CircularProfileAvatar(
                                                UIUtil.getDragginatorURL(
                                                    widget
                                                        .dragginatorInfosList[
                                                            index][1]
                                                        .dna,
                                                    widget
                                                        .dragginatorInfosList[
                                                            index][1]
                                                        .status),
                                                elevation: 25,
                                                foregroundColor: dnaCompatible ==
                                                        null
                                                    ? StateContainer.of(context)
                                                        .curTheme
                                                        .backgroundDark
                                                        .withOpacity(0)
                                                    : dnaCompatible != null &&
                                                            dnaCompatible.contains(widget
                                                                    .dragginatorInfosList[
                                                                        index]
                                                                        [1]
                                                                    .dna) ==
                                                                true
                                                        ? StateContainer.of(
                                                                context)
                                                            .curTheme
                                                            .backgroundDark
                                                            .withOpacity(0)
                                                        : StateContainer.of(
                                                                context)
                                                            .curTheme
                                                            .backgroundDark
                                                            .withOpacity(0.8),
                                                showInitialTextAbovePicture:
                                                    true,
                                                backgroundColor: dnaCompatible !=
                                                            null &&
                                                        dnaCompatible.contains(
                                                                widget
                                                                    .dragginatorInfosList[
                                                                        index]
                                                                        [1]
                                                                    .dna) ==
                                                            true
                                                    ? StateContainer.of(context)
                                                        .curTheme
                                                        .text05
                                                    : StateContainer.of(context)
                                                        .curTheme
                                                        .text45,
                                                radius: 50.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  )
                                ],
                              ),
                            ),
                            Container(
                                margin: new EdgeInsetsDirectional.only(
                                    start: 12.0, end: 12.0),
                                child: Column(children: <Widget>[
                                  Divider(
                                    height: 2,
                                    color: StateContainer.of(context)
                                        .curTheme
                                        .text15,
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                      "If you merge two eggs, they will be archived, but you won't be able to use them, and you'll get a new egg made from the two old ones.",
                                      style: AppStyles
                                          .textStyleSettingItemSubheader(
                                              context)),
                                  Text(
                                      "You can only merge two eggs of the same species and the same element. The cost is 0.5 BIS plus fees.",
                                      style: AppStyles
                                          .textStyleSettingItemSubheader(
                                              context)),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    children: <Widget>[
                                      dna1selected == null ||
                                              dna2selected == null ||
                                              dna1selected == dna2selected ||
                                              isCompatible == false
                                          ? AppButton.buildAppButton(
                                              context,
                                              AppButtonType.PRIMARY_OUTLINE,
                                              AppLocalization.of(context)
                                                  .dragginatorMerging2Eggs,
                                              Dimens.BUTTON_TOP_DIMENS,
                                            )
                                          :
                                          // Send Button
                                          AppButton.buildAppButton(
                                              context,
                                              AppButtonType.PRIMARY,
                                              AppLocalization.of(context)
                                                  .dragginatorMerging2Eggs,
                                              Dimens.BUTTON_TOP_DIMENS,
                                              onPressed: () {
                                              Sheets.showAppHeightNineSheet(
                                                  context: context,
                                                  widget: SendConfirmSheet(
                                                      title: AppLocalization.of(
                                                              context)
                                                          .dragginatorMerging2Eggs,
                                                      amountRaw: "0.5",
                                                      operation: "dragg:merge",
                                                      openfield: dna1selected +
                                                          ":" +
                                                          dna2selected,
                                                      displayTo: false,
                                                      comment: "",
                                                      destination:
                                                          AppLocalization.of(
                                                                  context)
                                                              .dragginatorAddress,
                                                      contactName: ""));
                                            }),
                                    ],
                                  ),
                                ]))
                          ],
                        ),
                      )),
                ]),
              ),
            ),
          ],
        ));
  }

  isDnaCompatible(String dna1, String dna2) async {
    isCompatible = false;
    List<String> _dnaCompatible;
    if (dna1 != null && dna2 != null) {
      await sl.get<DragginatorService>().getEggsCompatible(dna1).then((value) {
        _dnaCompatible = value;
        if (_dnaCompatible != null && _dnaCompatible.contains(dna2)) {
          isCompatible = true;
        }
      });
    }
  }

  getListCompatible(String dna) async {
    if (dna != null) {
      sl.get<DragginatorService>().getEggsCompatible(dna).then((value) {
        setState(() {
          dnaCompatible = value;
          dnaCompatible.add(dna);
        });
      });
    } else {
      dnaCompatible = null;
    }
  }

  selectItem(int index) async {
    // CASE : first dna selected
    if (dna1selected == null) {
      data[0] = [
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][0]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][1]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][2]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][3]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][4]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][5]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][6]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][7]
                .toString())
            .toInt(),
      ];
      dna1selected = widget.dragginatorInfosList[index][1].dna;
      await getListCompatible(dna1selected);
    } else
    // CASE : disabled dna 1 selected
    if (dna1selected != null &&
        dna1selected == widget.dragginatorInfosList[index][1].dna) {
      if (dna2selected == null) {
        dna1selected = null;
        data[0] = [0, 0, 0, 0, 0, 0, 0, 0];
        await getListCompatible(dna2selected);
      } else {
        dna1selected = dna2selected;
        dna2selected = null;
        data[0] = data[1];
        data[1] = [0, 0, 0, 0, 0, 0, 0, 0];
        await getListCompatible(dna1selected);
      }
    } else
    // CASE : second dna selected
    if (dna2selected == null) {
      data[1] = [
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][0]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][1]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][2]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][3]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][4]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][5]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][6]
                .toString())
            .toInt(),
        double.tryParse(widget.dragginatorInfosList[index][1].abilities[0][7]
                .toString())
            .toInt(),
      ];
      dna2selected = widget.dragginatorInfosList[index][1].dna;
    } else
    // CASE : disabled dna 2 selected
    if (dna2selected != null &&
        dna2selected == widget.dragginatorInfosList[index][1].dna) {
      dna2selected = null;
      data[1] = [0, 0, 0, 0, 0, 0, 0, 0];
      await getListCompatible(dna1selected);
    }
    await isDnaCompatible(dna1selected, dna2selected);
    setState(() {});
  }
}
