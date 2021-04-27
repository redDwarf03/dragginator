// @dart=2.9

import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dragginator/appstate_container.dart';
import 'package:dragginator/bus/navigation_event.dart';
import 'package:dragginator/model/wallet.dart';
import 'package:dragginator/styles.dart';
import 'package:dragginator/ui/home/breeding_list.dart';
import 'package:dragginator/ui/home/main_page.dart';
import 'package:dragginator/ui/home/settings_drawer.dart';
import 'package:dragginator/ui/widgets/nav_route_view.dart';
import 'package:dragginator/ui/widgets/nav_tab_icon.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/linearicons_free_icons.dart';
import 'package:fluttericon/typicons_icons.dart';

class NavContainer extends StatefulWidget {
  NavContainer(this.appWallet, {Key key}) : super( key: key);

  final AppWallet appWallet;

  @override
  _NavContainerState createState() => _NavContainerState();
}

class _NavContainerState extends State<NavContainer>
    with SingleTickerProviderStateMixin {
  TabController _controller;

  List<Icon> children;
  Animation _animation;

  List<Tab> get _tabs {
    Iterable<Tab> _map = children.map<Tab>((Icon icon) {
      Tab _tab = Tab(
        icon: new NavTabIcon(icon: icon),
      );
      return _tab;
    });
    return _map.toList();
  }

  List<NavRouteView> get _routes {
    int _index = 0;
    Iterable<NavRouteView> _map = children.map<NavRouteView>((name) {
      NavRouteView _view = NavRouteView(
          index: _index,
          child: Container(
              constraints: BoxConstraints.expand(),
              child: name.icon == LineariconsFree.earth
                  ? MainPage(StateContainer.of(context)
                              .wallet != null && StateContainer.of(context).wallet.dragginatorList != null ? StateContainer.of(context)
                              .wallet
                              .dragginatorList : null)
                  : name.icon == Typicons.menu_outline
                      ? SettingsSheet()
                      : name.icon == FontAwesome5.dragon
                          ? BreedingList(StateContainer.of(context)
                              .selectedAccount
                              .address,
                              StateContainer.of(context)
                              .wallet
                              .dragginatorList)
                          : MainPage(StateContainer.of(context)
                              .wallet
                              .dragginatorList)),
          animation: _animation);

      _index++;
      return _view;
    });

    return _map.toList();
  }

  @override
  void initState() {
    super.initState();

    try {
      widget.appWallet != null &&
              widget.appWallet.address != null
          ? children = [
              Icon(LineariconsFree.earth),
              Icon(FontAwesome5.dragon),
              Icon(Typicons.menu_outline)
            ]
          : children = [
              Icon(LineariconsFree.earth),
            ];
    } catch (e) {
      children = [
        Icon(LineariconsFree.earth),
      ];
      print(e);
    }

    _controller = new TabController(vsync: this, length: children.length);
    _animation = _controller.animation;
    NavigationBus.registerTabController(_controller);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Container(
        padding: Platform.isAndroid
            ? EdgeInsets.only(bottom: 48)
            : EdgeInsets.only(bottom: 80),
        constraints: BoxConstraints.expand(),
        child: TabBarView(
          controller: _controller,
          children: _routes,
        ),
      ),
      Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _getBalanceWidget(),
            StateContainer.of(context).wallet != null &&
                    StateContainer.of(context).wallet.address != null
                ? (Platform.isAndroid)
                    ? TabBar(
                        indicatorPadding: EdgeInsets.all(1),
                        labelPadding: EdgeInsets.zero,
                        controller: _controller,
                        indicatorWeight: 4,
                        tabs: _tabs)
                    : Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                              const Color.fromARGB(8, 16, 32, 16),
                              const Color.fromARGB(192, 32, 16, 32)
                            ])),
                        child: TabBar(
                            indicator: BoxDecoration(),
                            labelPadding: EdgeInsets.only(bottom: 6, top: 4),
                            indicatorPadding:
                                EdgeInsets.only(top: 6, bottom: 12),
                            controller: _controller,
                            tabs: _tabs))
                : SizedBox(),
          ]),
    ]);
  }

  // Get balance display
  Widget _getBalanceWidget() {
    // Balance texts
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width - 190,
      color: Colors.transparent,
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsetsDirectional.only(bottom: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 205),
                    child: AutoSizeText.rich(
                      TextSpan(
                        children: [
                          // Main balance text
                          StateContainer.of(context).wallet != null &&
                                  StateContainer.of(context)
                                          .wallet
                                          .getAccountBalanceDisplay() !=
                                      null &&
                                  StateContainer.of(context)
                                          .wallet
                                          .getAccountBalanceDisplay() !=
                                      "0"
                              ? TextSpan(
                                  text: "Coins : " +
                                      StateContainer.of(context)
                                          .wallet
                                          .getAccountBalanceDisplay() +
                                      " BIS",
                                  style: AppStyles.textStyleCurrencySmaller(
                                      context),
                                )
                              : TextSpan(text: ""),
                        ],
                      ),
                      maxLines: 1,
                      style: TextStyle(fontSize: 22),
                      stepGranularity: 0.1,
                      minFontSize: 1,
                      maxFontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
