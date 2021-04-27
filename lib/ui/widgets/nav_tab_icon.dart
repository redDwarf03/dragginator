
// @dart=2.9
import 'package:flutter/material.dart';

class NavTabIcon extends StatefulWidget {

	const NavTabIcon({
		Key key,
		@required Icon icon,
	}) : _icon = icon, super(key: key);

	final Icon _icon;

	@override
	NavTabIconState createState() =>  new NavTabIconState();
}

class NavTabIconState extends State<NavTabIcon> {

	@override
	Widget build(BuildContext context) {
		return widget._icon;
	}
}