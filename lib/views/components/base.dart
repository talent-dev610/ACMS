/*
 * @author Oleg Khalidov (brooth@gmail.com).
 * -----------------------------------------------
 * Software Development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/views/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class KeyboardSpace extends StatelessWidget {
  final double heightRatio;

  KeyboardSpace({this.heightRatio = 1.0});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin:
          EdgeInsets.only(bottom: mediaQuery.viewInsets.vertical * heightRatio),
    );
  }
}

class Separator extends StatelessWidget {
  final Color color;
  final double height;

  Separator({this.color, this.height = 1.3});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      color: color ?? AppColors.separator,
    );
  }
}

class LinearActivityIndicator extends StatelessWidget {
  final double height;
  final Color color;

  LinearActivityIndicator(
      {this.height = 1.5, this.color = AppPalette.secondaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: Theme(
          data: ThemeData(accentColor: color),
          child: LinearProgressIndicator(backgroundColor: Colors.transparent)),
    );
  }
}

class CircularActivityIndicator extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  CircularActivityIndicator(
      {this.size = 20.0,
      this.color = AppPalette.primaryColor,
      this.strokeWidth = 1.5});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: Theme(
          data: ThemeData(accentColor: color),
          child: CircularProgressIndicator(
            value: null,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final GestureTapCallback onPress;
  final double size;
  final double iconSize;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final bool innerMaterial;

  CircleIconButton({
    @required this.icon,
    @required this.onPress,
    this.color = Colors.white,
    this.size = 25.0,
    this.iconSize,
    this.borderWidth = 1.0,
    this.padding,
    this.innerMaterial = false,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      padding: padding,
      child: InkResponse(
        splashColor: color.withOpacity(0.5),
        highlightColor: Colors.transparent,
        radius: size,
        onTap: onPress,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: borderWidth,
              )),
          child: Icon(icon, color: color, size: iconSize ?? size - 6),
        ),
      ),
    );
    return innerMaterial
        ? Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(size),
            child: widget,
          )
        : widget;
  }
}
