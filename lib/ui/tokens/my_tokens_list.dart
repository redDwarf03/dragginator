// @dart=2.9

import 'package:dragginator/network/model/response/address_txs_response.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:dragginator/model/token_ref.dart';
import 'package:dragginator/service/http_service.dart';
import 'package:dragginator/service_locator.dart';
import 'package:dragginator/styles.dart';
import 'package:dragginator/appstate_container.dart';
import 'package:dragginator/localization.dart';

class MyTokensList extends StatefulWidget {
  final AnimationController tokensListController;
  bool tokensListOpen;
  final List<BisToken> listBisToken;

  MyTokensList(
      this.tokensListController, this.tokensListOpen, this.listBisToken);

  _MyTokensListState createState() => _MyTokensListState();
}

class _MyTokensListState extends State<MyTokensList> {
  final Logger log = sl.get<Logger>();

  List<BisToken> _myBisTokenList = new List<BisToken>();
  List<BisToken> _myBisTokenListForDisplay = new List<BisToken>();

  @override
  void initState() {
    //

    setState(() {
      _myBisTokenList.addAll(widget.listBisToken);
      _myBisTokenList.removeWhere((element) => element.tokenName == "");
      _myBisTokenListForDisplay = _myBisTokenList;
    });
    super.initState();
  }

  Future<List<TokenRef>> loadTokenRefList() async {
    return await sl.get<HttpService>().getTokensReflist();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: StateContainer.of(context).curTheme.backgroundDarkest,
          boxShadow: [
            BoxShadow(
                color: StateContainer.of(context).curTheme.overlay30,
                offset: Offset(-5, 0),
                blurRadius: 20),
          ],
        ),
        child: SafeArea(
          minimum: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.035,
            top: 60,
          ),
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
                                  widget.tokensListOpen = false;
                                });
                                widget.tokensListController.reverse();
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
                          AppLocalization.of(context).myTokensListHeader,
                          style: AppStyles.textStyleSettingsHeader(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                      hintText: AppLocalization.of(context).searchField),
                  onChanged: (text) {
                    text = text.toLowerCase();
                    setState(() {
                      _myBisTokenListForDisplay =
                          _myBisTokenList.where((token) {
                        var tokenId = token.tokenName.toLowerCase();
                        return tokenId.contains(text);
                      }).toList();
                    });
                  },
                ),
              ),
              // list + top and bottom gradients
              Expanded(
                child: Stack(
                  children: <Widget>[
                    //  list
                    ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(bottom: 15),
                      itemCount: _myBisTokenListForDisplay == null
                          ? 0
                          : _myBisTokenListForDisplay.length,
                      itemBuilder: (context, index) {
                        // Build
                        return buildSingleToken(
                            context, _myBisTokenListForDisplay[index]);
                      },
                    ),
                    //List Top Gradient End
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 20.0,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              StateContainer.of(context)
                                  .curTheme
                                  .backgroundDark,
                              StateContainer.of(context)
                                  .curTheme
                                  .backgroundDark00
                            ],
                            begin: AlignmentDirectional(0.5, -1.0),
                            end: AlignmentDirectional(0.5, 1.0),
                          ),
                        ),
                      ),
                    ),
                    //List Bottom Gradient End
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 15.0,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              StateContainer.of(context)
                                  .curTheme
                                  .backgroundDark00,
                              StateContainer.of(context)
                                  .curTheme
                                  .backgroundDark,
                            ],
                            begin: AlignmentDirectional(0.5, -1.0),
                            end: AlignmentDirectional(0.5, 1.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget buildSingleToken(BuildContext context, BisToken bisToken) {
    return Container(
      padding: EdgeInsets.all(0.0),
      child: Column(children: <Widget>[
        Divider(
          height: 2,
          color: StateContainer.of(context).curTheme.text15,
        ),
        // Main Container
        Container(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          margin: new EdgeInsetsDirectional.only(start: 12.0, end: 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Container(
                  height: 40,
                  margin: EdgeInsetsDirectional.only(start: 2.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          Text(
                              NumberFormat.compact(
                                          locale:
                                              Localizations.localeOf(context)
                                                  .languageCode)
                                      .format(bisToken.tokensQuantity) +
                                  " " +
                                  bisToken.tokenName,
                              style: AppStyles.textStyleSettingItemHeader(
                                  context)),
                          SizedBox(
                            width: 5,
                          ),
                          TokenRef().getIcon(bisToken.tokenName),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
