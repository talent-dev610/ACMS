/*
 * @author Oleg Khalidov (brooth@gmail.com).
 * -----------------------------------------------
 * Software Development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/views/components/base.dart';
import 'package:acms/views/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget titleWidget;
  final Widget leftAction;
  final Widget rightAction;
  final List<Widget> rightActions;
  final bool progress;
  final double lineHeight;
  final Brightness brightness;

  const TopBar({
    Key key,
    this.title,
    this.titleWidget,
    this.leftAction,
    this.rightAction,
    this.rightActions,
    this.progress = false,
    this.lineHeight = AppDimensions.topBarLineHeight,
    this.brightness = Brightness.dark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        AppBar(
          elevation: .0,
          backgroundColor: AppColors.topBarBg,
          brightness: brightness,
          automaticallyImplyLeading: false,
          title: titleWidget ??
              Padding(
                padding: AppDimensions.topBarContentPadding,
                child: Text(title, style: AppStyles.topBarTitle),
              ),
          centerTitle: true,
          leading: leftAction,
          actions: rightActions != null
              ? rightActions
                  .map(
                    (action) => Padding(
                        padding: AppDimensions.topBarContentPadding,
                        child: action),
                  )
                  .toList()
              : <Widget>[
                  Padding(
                      padding: AppDimensions.topBarContentPadding,
                      child: rightAction),
                ],
        ),
        progress
            ? LinearActivityIndicator(height: lineHeight)
            : Separator(color: AppPalette.secondaryColor, height: lineHeight),
      ],
    );
  }

  @override
  Size get preferredSize => Size(double.infinity, 58.0);
}

class TopBarAction extends StatelessWidget {
  final IconData icon;
  final Icon iconWidget;
  final GestureTapCallback onPress;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final bool progress;
  final bool disabled;

  const TopBarAction({
    Key key,
    this.icon,
    this.iconWidget,
    @required this.onPress,
    this.iconSize = 22.0,
    this.padding = AppDimensions.topBarActionPadding,
    this.progress = false,
    this.disabled = false,
  }) : super(key: key);

  const TopBarAction.back(GestureTapCallback onPress)
      : this(
          icon: Icons.arrow_back,
          padding: const EdgeInsets.fromLTRB(6.0, 4.0, 12.0, 0.0),
          onPress: onPress,
        );

  const TopBarAction.cancel(GestureTapCallback onPress)
      : this(icon: Icons.close, onPress: onPress);

  const TopBarAction.save(GestureTapCallback onPress, {bool progress = false})
      : this(icon: Icons.check, onPress: onPress, progress: progress);

  const TopBarAction.delete(GestureTapCallback onPress)
      : this(
            icon: Icons.delete,
            iconSize: 18.0,
            padding: const EdgeInsets.fromLTRB(12.0, .0, 12.0, 2.0),
            onPress: onPress);

  const TopBarAction.settings(GestureTapCallback onPress)
      : this(icon: Icons.settings, iconSize: 20.0, onPress: onPress);

  const TopBarAction.add(GestureTapCallback onPress)
      : this(
            icon: Icons.add,
            iconSize: 25.0,
            padding: const EdgeInsets.fromLTRB(12.0, .0, 12.0, 2.0),
            onPress: onPress);

  const TopBarAction.edit(GestureTapCallback onPress)
      : this(icon: Icons.edit, iconSize: 20.0, onPress: onPress);

  const TopBarAction.search(GestureTapCallback onPress, {bool progress = false})
      : this(icon: Icons.search, onPress: onPress, progress: progress);

  const TopBarAction.refresh(GestureTapCallback onPress,
      {bool progress = false})
      : this(icon: Icons.refresh, onPress: onPress, progress: progress);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: progress
          ? CircularActivityIndicator(
              size: iconSize * .7, color: AppColors.topBarIcon)
          : InkResponse(
              child: iconWidget ??
                  Icon(
                    icon,
                    color: disabled
                        ? AppColors.topBarIconDisabled
                        : AppColors.topBarIcon,
                    size: iconSize,
                  ),
              radius: 23.0,
              highlightColor: Colors.transparent,
              onTap: disabled || progress ? null : onPress,
            ),
    );
  }
}
