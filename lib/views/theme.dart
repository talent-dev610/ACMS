/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:flutter/material.dart';

class AppPalette {
  static const primaryColor = Color(0xFF40a8c4);
  static const secondaryColor = Color(0xFFf7aa00);
}

class AppColors {
  static const action = AppPalette.primaryColor;
  static const success = Color(0xff479F4B);
  static const error = Color(0xFFE56754);

  static const separator = Color(0xFFe2e2e2);

  static const inputText = Color(0xFF5C5959);
  static const inputTextHint = Color(0x99757575);
  static const inputTextDisabled = Color(0x99414141);

  // backgrounds
  static const lightBg = Color(0xfff7f7f7);
  static const darkBg = Color(0xff235784);

  static const backLoading = AppPalette.secondaryColor;
  static final backPrintIcon = Colors.grey;
  static final backPrintText = backPrintIcon;

  // top bar
  static const topBarBg = darkBg;
  static const topBarTitle = Colors.white;
  static const topBarIcon = topBarTitle;
  static const topBarIconDisabled = Colors.grey;
  static const topBarSearchBarIcon = Color(0xFFD3D3D3);
  static const topBarSearchBarBorder = Color(0xFFE2E1DF);

  // bottom bar
  static const bottomBarBg = topBarBg;
  static const bottomBarItem = Colors.white;
  static final bottomBarItemInactive = Colors.grey;
  static const bottomBarItemBudge = Color(0xFFF34246);

  static const notificationBg = Colors.white;

  // auth
  static const authArcsBg = AppPalette.primaryColor;
  static const authInputBorder = Color(0xFFC6C1C1);
  static const authButton = AppPalette.secondaryColor;
  static const authButtonText = Colors.white;
  static const authHyperlink = Colors.white;
}

class AppDimensions {
  static const topBarLineHeight = 4.0;

  static const authFormPadding = EdgeInsets.symmetric(horizontal: 35.0);
  static const authFormTopFieldPadding =
      EdgeInsets.only(left: 30.0, right: 30.0, top: 5.0);
  static const authFormMiddleFieldPadding =
      EdgeInsets.only(left: 30.0, right: 30.0, top: 5.0);
  static const authFormMiddleButtonPadding =
      EdgeInsets.only(left: 30.0, right: 30.0, top: 5.0);
  static const authFormBottomButtonPadding =
      EdgeInsets.only(left: 30.0, right: 30.0, top: 5.0, bottom: 30.0);
  static const authFormBottomHyperlinkPadding =
      EdgeInsets.only(top: 13.0, bottom: 15.0);

  static const topBarContentPadding = EdgeInsets.only(top: 5.0);
  static const topBarActionPadding = EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 0.0);

  static const backPrintButtonRadius = 3.0;
  static const backPrintButtonPadding =
      EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0);
}

class AppStyles {
  static const actionText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: AppColors.action,
    fontWeight: FontWeight.w500,
  );
  static const actionTextMinor = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Colors.grey,
    fontWeight: FontWeight.w500,
  );
  static const notificationToastText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: AppColors.inputText,
  );

  /*
   * Dialogs
   */
  static const dialogTitleText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 17.0,
    color: AppColors.inputText,
    fontWeight: FontWeight.w500,
  );
  static const dialogContentText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: AppColors.inputText,
  );
  static const dialogInputText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: AppColors.inputText,
  );
  static final dialogInputHint = dialogInputText.copyWith(
    color: AppColors.inputTextHint,
  );
  static const dialogActionText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: AppColors.action,
    fontWeight: FontWeight.normal,
  );
  static final dialogMinorActionText = dialogActionText.copyWith(
    color: Colors.grey,
  );
  static final dialogDangerActionText = dialogActionText.copyWith(
    color: Colors.redAccent,
  );

  /*
   *   TopBar
   */
  static final topBarTitle = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 17.0,
    color: AppColors.topBarTitle,
    fontWeight: FontWeight.normal,
  );

  /*
   * Bottom Bar
   */
  static const bottomBarItemTitle = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
  );

  /*
   * Background
   */
  static final backPrintTitle = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 26.0,
    color: AppColors.backPrintText,
    fontWeight: FontWeight.bold,
  );
  static final backPrintMessage =
      backPrintTitle.copyWith(fontSize: 16.0, fontWeight: FontWeight.normal);
  static final backPrintTryAgainButton = actionText;

  /*
   * Auth
   */
  static const authTextInputCaption = TextStyle(
    fontSize: 11.0,
    fontFamily: 'NotoSans',
    color: AppColors.authInputBorder,
    fontWeight: FontWeight.w600,
  );
  static const authButtonText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: AppColors.authButtonText,
  );
  static const authHyperlink = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Colors.white,
  );

  static const textField = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 16.0,
    color: AppColors.inputText,
    fontWeight: FontWeight.normal,
  );
  static final textFieldDisabled = textField.copyWith(
    color: AppColors.inputTextDisabled,
  );
}

class AppDecorations {
  static final borderedButton = BoxDecoration(
    borderRadius: BorderRadius.circular(4.0),
    border: Border.all(
      color: Colors.grey,
      width: 1.0,
    ),
  );
  static final notification = BoxDecoration(
    color: AppColors.notificationBg,
    borderRadius: BorderRadius.all(Radius.circular(3.0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(60),
        offset: Offset(3.0, 3.0),
        blurRadius: 2.0,
      )
    ],
  );

  static final authForm = BoxDecoration(
    color: AppColors.lightBg,
    borderRadius: BorderRadius.all(Radius.circular(30.0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(60),
        offset: Offset(1.0, 3.0),
        blurRadius: 6.0,
      )
    ],
  );

  static final authInputBox = BoxDecoration(
    border: Border.all(
      color: AppColors.authInputBorder,
      width: 1.0,
    ),
    color: Colors.white,
    boxShadow: AppShadows.authFormItem,
  );

  static final authButtonBox = BoxDecoration(
    boxShadow: AppShadows.authFormItem,
  );

  static final backPrintButton = BoxDecoration(
      borderRadius: BorderRadius.circular(AppDimensions.backPrintButtonRadius),
      border: Border.all(color: AppColors.action));

  static final underlineSeparator = BoxDecoration(
    border: Border(bottom: BorderSide(color: AppColors.separator)),
  );

  static underline(Color color) => BoxDecoration(
        border: Border(bottom: BorderSide(color: color)),
      );
}

class AppShadows {
  static final List<BoxShadow> basic = [
    BoxShadow(
      color: Colors.black.withAlpha(60),
      offset: Offset(1.0, 1.0),
      blurRadius: 6.0,
    )
  ];

  static final List<BoxShadow> minY = [
    BoxShadow(
      color: Colors.black.withAlpha(40),
      offset: Offset(.0, 1.0),
      blurRadius: 1.0,
    )
  ];

  static final List<BoxShadow> authFormItem = [
    BoxShadow(
      color: Colors.black.withAlpha(80),
      offset: Offset(.5, 1.0),
      blurRadius: 4.0,
    )
  ];
}

class AppRouteTransitions {
  static standard(WidgetBuilder builder) {
    return MaterialPageRoute(builder: builder);
  }

  static none(WidgetBuilder builder) {
    return PageRouteBuilder(
        pageBuilder: (ctx, _, __) => builder(ctx),
        transitionsBuilder: (_, ___, __, Widget child) {
          return child;
        });
  }

  static fade(WidgetBuilder builder, {int duration = 150}) {
    return PageRouteBuilder(
        pageBuilder: (ctx, _, __) => builder(ctx),
        transitionDuration: Duration(milliseconds: duration),
        transitionsBuilder: (_, animation, __, Widget child) {
          return new FadeTransition(opacity: animation, child: child);
        });
  }
}

ThemeData appTheme(BuildContext context) {
  final theme = Theme.of(context);
  return ThemeData(
    primaryColor: AppPalette.primaryColor,
    primaryColorBrightness: Brightness.dark,
    canvasColor: AppColors.darkBg,
    accentColor: AppColors.action,

    // not working for snackbar (flat button defaults)
    textTheme: theme.textTheme.copyWith(
        button: AppStyles.actionText,
        // bottom bar item title
        caption: AppStyles.bottomBarItemTitle.copyWith(
          color: AppColors.bottomBarItemInactive,
        )),
  );
}
