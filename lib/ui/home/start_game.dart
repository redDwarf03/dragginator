// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dragginator/dimens.dart';
import 'package:dragginator/localization.dart';
import 'package:dragginator/styles.dart';
import 'package:dragginator/ui/util/ui_util.dart';
import 'package:dragginator/ui/widgets/buttons.dart';

class StartGame extends StatefulWidget {
  StartGame() : super();

  _StartGameStateState createState() => _StartGameStateState();
}

class _StartGameStateState extends State<StartGame> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/dragginator_background_opacity70.png'),
              fit: BoxFit.cover),
        ),
        child: SafeArea(
          minimum: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.035),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(child: SizedBox()),
              Expanded(
                child: Center(
                  child: Container(
                    child: Image.asset("assets/dragginator_logo_start.png"),
                  ),
                ),
              ),
              Container(
                child: Row(
                  children: <Widget>[
                    AppButton.buildAppButton(
                      context,
                      AppButtonType.PRIMARY,
                      AppLocalization.of(context).startGame,
                      Dimens.BUTTON_TOP_DIMENS,
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/home');
                      },
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(AppLocalization.of(context).poweredBy,
                      style: AppStyles.textStyleVersion(context)),
                  Container(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Image.asset("assets/icon.png"),
                    ),
                  ),
                  Text(" | ", style: AppStyles.textStyleVersion(context)),
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (BuildContext context) {
                          return UIUtil.showWebview(
                              context, AppLocalization.of(context).privacyUrl);
                        }));
                      },
                      child: Text(AppLocalization.of(context).privacyPolicy,
                          style: AppStyles.textStyleVersionUnderline(context))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
