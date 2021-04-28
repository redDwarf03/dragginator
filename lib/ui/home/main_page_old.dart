import 'package:auto_size_text/auto_size_text.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:dragginator/appstate_container.dart';
import 'package:dragginator/dimens.dart';
import 'package:dragginator/localization.dart';
import 'package:dragginator/styles.dart';
import 'package:dragginator/ui/util/ui_util.dart';
import 'package:dragginator/ui/widgets/buttons.dart';
import 'package:flare_flutter/base/animation/actor_animation.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  final List<List> dragginatorList;

  MainPage(this.dragginatorList) : super();

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Scene _scene;
  Object? _egg;

  bool notNull(Object o) => o != null;

  bool isLoggedIn = false;

  // Main card height
  double? mainCardHeight;
  double settingsIconMarginTop = 5;

  // Animation for swiping to send
  ActorAnimation? _sendSlideAnimation;
  ActorAnimation? _sendSlideReleaseAnimation;
  double? _fanimationPosition;
  bool releaseAnimation = false;

  void initialize(FlutterActorArtboard actor) {
    _fanimationPosition = 0.0;
    _sendSlideAnimation = actor.getAnimation("pull");
    _sendSlideReleaseAnimation = actor.getAnimation("release");
  }

  void setViewTransform(Mat2D viewTransform) {}

  bool advance(FlutterActorArtboard artboard, double elapsed) {
    if (releaseAnimation) {
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

    if (_egg != null) {
      _egg!.updateTransform();
      _scene.update();
    }
    // Main Card Size
    mainCardHeight = 120;
    settingsIconMarginTop = 7;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SafeArea(
          child: StateContainer.of(context).wallet != null &&
                  StateContainer.of(context).wallet.address != null
              ? getDragginatorList(context)
              : getIntro(context)),
    );
  }

  Widget getDragginatorList(BuildContext context) {
    return Column(
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
        new Container(
          height: 200,
          child: Cube(onSceneCreated: _onSceneCreated),
        ),
        Expanded(
            child: Center(
                child: Stack(children: <Widget>[
          GridView.count(
            crossAxisCount: 3,
            children: List.generate(widget.dragginatorList.length, (index) {
              return Center(
                  child: Stack(children: <Widget>[
                CircularProfileAvatar(
                  UIUtil.getDragginatorURL(widget.dragginatorList[index][1].dna,
                      widget.dragginatorList[index][1].status),
                  elevation: 25,
                  radius: 50.0,
                  backgroundColor: Colors.transparent,
                ),
              ]));
            }),
          )
        ])))
      ],
    );
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

  void _onSceneCreated(Scene scene) {
    _scene = scene;
    _egg = Object(
        name: 'egg',
        scale: Vector3(10.0, 10.0, 10.0),
        backfaceCulling: true,
        fileName: 'assets/egg/test.obj');
    _scene.world.add(_egg!);
    _scene.updateTexture();
  }
}
