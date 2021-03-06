// @dart=2.9

// Dart imports:
import 'dart:ui' as ui;

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dragginator/appstate_container.dart';

class AppStyles {
  // Text style for paragraph text.
  static TextStyle textStyleParagraph(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.medium,
        fontWeight: FontWeight.w300,
        color: StateContainer.of(context).curTheme.text);
  }

  static TextStyle textStyleParagraphBold(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.medium,
        fontWeight: FontWeight.w700,
        color: StateContainer.of(context).curTheme.text);
  }

  // Text style for paragraph text with primary color.
  static TextStyle textStyleParagraphPrimary(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.medium,
        fontWeight: FontWeight.w700,
        color: StateContainer.of(context).curTheme.primary);
  }

  static TextStyle textStyleParagraphSmall(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w300,
        color: StateContainer.of(context).curTheme.text);
  }

  // Text style for thin paragraph text with primary color.
  static TextStyle textStyleParagraphThinPrimary(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w600,
        color: StateContainer.of(context).curTheme.primary);
  }

  // Text style for paragraph text with primary color.
  static TextStyle textStyleParagraphSuccess(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w700,
        color: StateContainer.of(context).curTheme.success);
  }

  // For snackbar/Toast text
  static TextStyle textStyleSnackbar(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w700,
        color: StateContainer.of(context).curTheme.background);
  }

  // Text style for primary button
  static TextStyle textStyleButtonPrimary(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes._large,
        fontWeight: FontWeight.w700,
        color: StateContainer.of(context).curTheme.text);
  }

  // Green primary button
  static TextStyle textStyleButtonPrimaryGreen(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes._large,
        fontWeight: FontWeight.w700,
        color: StateContainer.of(context).curTheme.successDark);
  }

  // Text style for outline button
  static TextStyle textStyleButtonPrimaryOutline(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes._large,
        fontWeight: FontWeight.w700,
        color: StateContainer.of(context).curTheme.primary);
  }

  // Text style for small outline button
  static TextStyle textStyleButtonPrimarySmallOutline(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w700,
        color: StateContainer.of(context).curTheme.primary);
  }

  // Text style for small success outline button
  static TextStyle textStyleButtonSuccessSmallOutline(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w700,
        color: StateContainer.of(context).curTheme.success);
  }

  static TextStyle textStyleButtonPrimaryOutlineDisabled(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes._large,
        fontWeight: FontWeight.w700,
        color: StateContainer.of(context).curTheme.primary60);
  }

  // Text style for success outline button
  static TextStyle textStyleButtonSuccessOutline(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes._large,
        fontWeight: FontWeight.w700,
        color: StateContainer.of(context).curTheme.success);
  }

  // Text style for text outline button
  static TextStyle textStyleButtonTextOutline(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes._large,
        fontWeight: FontWeight.w700,
        color: StateContainer.of(context).curTheme.text);
  }

  static TextStyle textStyleAddressSuccess(BuildContext context) {
    return TextStyle(
      color: StateContainer.of(context).curTheme.success,
      fontSize: AppFontSizes.small,
      height: 1.5,
      fontWeight: FontWeight.w400,
      fontFamily: 'Lato',
    );
  }

  static TextStyle textStyleAddressText60(BuildContext context) {
    return TextStyle(
      color: StateContainer.of(context).curTheme.text60,
      fontSize: AppFontSizes.small,
      height: 1.5,
      fontWeight: FontWeight.w400,
      fontFamily: 'Lato',
    );
  }

  static TextStyle textStyleAddressText90(BuildContext context) {
    return TextStyle(
      color: StateContainer.of(context).curTheme.text,
      fontSize: AppFontSizes.small,
      height: 1.5,
      fontWeight: FontWeight.w400,
      fontFamily: 'Lato',
    );
  }

  // Text style for alternate currencies on home page
  static TextStyle textStyleCurrencyAlt(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w600,
        color: StateContainer.of(context).curTheme.text60);
  }

  static TextStyle textStyleCurrencyAltHidden(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w600,
        color: Colors.transparent);
  }

  // Text style for primary currency on home page
  static TextStyle textStyleCurrency(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes._largest,
        fontWeight: FontWeight.w900,
        color: StateContainer.of(context).curTheme.primary);
  }

  // Text style for primary currency on home page
  static TextStyle textStyleCurrencySmaller(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: StateContainer.of(context).curTheme.primary);
  }

  /* Transaction cards */
  // Text style for transaction card "Received"/"Sent" text
  static TextStyle textStyleTransactionType(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w600,
        color: StateContainer.of(context).curTheme.text);
  }

  static TextStyle textStyleTransactionTypeGreen(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w600,
        foreground: Paint()
          ..shader = ui.Gradient.linear(Offset.zero, Offset(0, 60),
              [Colors.green[200], Colors.green[800]]));
  }

  static TextStyle textStyleTransactionTypeBlue(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w600,
        foreground: Paint()
          ..shader = ui.Gradient.linear(Offset.zero, Offset(0, 60),
              [Colors.blue[200], Colors.blue[800]]));
  }

  static TextStyle textStyleTransactionTypeRed(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w600,
        foreground: Paint()
          ..shader = ui.Gradient.linear(
              Offset.zero, Offset(0, 60), [Colors.red[200], Colors.red[800]]));
  }

  // Amount
  static TextStyle textStyleTransactionAmount(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        color: StateContainer.of(context).curTheme.primary60,
        fontSize: AppFontSizes.smallest,
        fontWeight: FontWeight.w600);
  }

  // Unit (e.g. BAN)
  static TextStyle textStyleTransactionUnit(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      color: StateContainer.of(context).curTheme.primary60,
      fontSize: AppFontSizes.smallest,
      fontWeight: FontWeight.w300,
    );
  }

  static TextStyle textStyleTiny(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      color: StateContainer.of(context).curTheme.primary60,
      fontSize: AppFontSizes.tiny,
      fontWeight: FontWeight.w300,
    );
  }

  // Address
  static TextStyle textStyleTransactionAddress(BuildContext context) {
    return TextStyle(
      fontSize: AppFontSizes.smallest,
      fontFamily: 'Lato',
      fontWeight: FontWeight.w300,
      color: StateContainer.of(context).curTheme.text60,
    );
  }

  // Transaction Welcome
  static TextStyle textStyleTransactionWelcome(BuildContext context) {
    return TextStyle(
      fontSize: AppFontSizes.small,
      fontWeight: FontWeight.w300,
      color: StateContainer.of(context).curTheme.text,
      fontFamily: 'Lato',
    );
  }

  // Transaction Welcome Text
  static TextStyle textStyleTransactionWelcomeBold(BuildContext context) {
    return TextStyle(
      fontSize: AppFontSizes.small,
      fontWeight: FontWeight.w500,
      color: StateContainer.of(context).curTheme.text,
      fontFamily: 'Lato',
    );
  }

  // Version info in settings
  static TextStyle textStyleVersion(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w400,
        color: StateContainer.of(context).curTheme.text60);
  }

  static TextStyle textStyleVersionUnderline(BuildContext context) {
    return TextStyle(
        fontFamily: "Lato",
        fontSize: AppFontSizes.small,
        fontWeight: FontWeight.w400,
        color: StateContainer.of(context).curTheme.text60,
        decoration: TextDecoration.underline);
  }

  // Text style for alert dialog header
  static TextStyle textStyleDialogHeader(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes._large,
      fontWeight: FontWeight.w700,
      color: StateContainer.of(context).curTheme.primary,
    );
  }

  // Text style for dialog options
  static TextStyle textStyleDialogOptions(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes.medium,
      fontWeight: FontWeight.w600,
      color: StateContainer.of(context).curTheme.text,
    );
  }

  // Text style for dialog button text
  static TextStyle textStyleDialogButtonText(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes.smallest,
      fontWeight: FontWeight.w600,
      color: StateContainer.of(context).curTheme.primary,
    );
  }

  // Text style for seed text
  static TextStyle textStyleSeed(BuildContext context) {
    return TextStyle(
      fontSize: AppFontSizes.small,
      fontWeight: FontWeight.w400,
      fontFamily: 'Lato',
      color: StateContainer.of(context).curTheme.primary,
      height: 1.5,
      letterSpacing: 1,
    );
  }

  static TextStyle textStyleSeedGray(BuildContext context) {
    return TextStyle(
      fontSize: AppFontSizes.small,
      fontWeight: FontWeight.w400,
      fontFamily: 'Lato',
      color: StateContainer.of(context).curTheme.text60,
      height: 1.5,
      letterSpacing: 1,
    );
  }

  // Text style for mnemonic text
  static TextStyle textStyleMnemonicText(BuildContext context) {
    return TextStyle(
      fontSize: AppFontSizes.smallText(context),
      fontWeight: FontWeight.w400,
      fontFamily: 'Lato',
      color: StateContainer.of(context).curTheme.primary,
      height: 1,
      letterSpacing: 1,
    );
  }

  static TextStyle textStyleMnemonicTextGray(BuildContext context) {
    return TextStyle(
      fontSize: AppFontSizes.smallText(context),
      fontWeight: FontWeight.w400,
      fontFamily: 'Lato',
      color: StateContainer.of(context).curTheme.text60,
      height: 1,
      letterSpacing: 1,
    );
  }

  static TextStyle textStyleSeedGreen(BuildContext context) {
    return TextStyle(
      fontSize: AppFontSizes.small,
      fontWeight: FontWeight.w400,
      fontFamily: 'Lato',
      color: StateContainer.of(context).curTheme.success,
      height: 1.5,
      letterSpacing: 1,
    );
  }

  // Text style for general headers like sheet headers
  static TextStyle textStyleHeader(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes.largest(context),
      fontWeight: FontWeight.w700,
      color: StateContainer.of(context).curTheme.text,
    );
  }

  // Text style for settings headers
  static TextStyle textStyleSettingsHeader(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes._largest,
      fontWeight: FontWeight.w700,
      color: StateContainer.of(context).curTheme.text,
    );
  }

  // Text style for primary color header
  static TextStyle textStyleHeaderColored(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes._largest,
      fontWeight: FontWeight.w700,
      color: StateContainer.of(context).curTheme.primary,
    );
  }

  // Text style for primary color header
  static TextStyle textStyleHeader2Colored(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes.larger,
      fontWeight: FontWeight.w700,
      color: StateContainer.of(context).curTheme.primary,
    );
  }

  static TextStyle textStylePinScreenHeaderColored(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes._large,
      fontWeight: FontWeight.w700,
      color: StateContainer.of(context).curTheme.primary,
    );
  }

  static TextStyle textStyleLogoutButton(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes.small,
      fontWeight: FontWeight.w600,
      color: StateContainer.of(context).curTheme.text,
    );
  }

  // Text style for setting item header
  static TextStyle textStyleSettingItemHeader(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes.medium,
      fontWeight: FontWeight.w600,
      color: StateContainer.of(context).curTheme.text,
    );
  }

  static TextStyle textStyleDiscordAccess(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes.medium,
      fontWeight: FontWeight.w600,
      color: StateContainer.of(context).curTheme.text,
    );
  }

  static TextStyle textStyleSettingItemHeader60(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes.medium,
      fontWeight: FontWeight.w600,
      color: StateContainer.of(context).curTheme.text60,
    );
  }

  static TextStyle textStyleSettingItemHeader45(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes.medium,
      fontWeight: FontWeight.w600,
      color: StateContainer.of(context).curTheme.text45,
    );
  }

  // Text style for setting item subheader
  static TextStyle textStyleSettingItemSubheader(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes.smallest,
      fontWeight: FontWeight.w300,
      color: StateContainer.of(context).curTheme.text60,
    );
  }

  static TextStyle textStyleSettingItemSubheader30(BuildContext context) {
    return TextStyle(
      fontFamily: "Lato",
      fontSize: AppFontSizes.smallest,
      fontWeight: FontWeight.w400,
      color: StateContainer.of(context).curTheme.text30,
    );
  }

  // Text style for lock screen error
  static TextStyle textStyleErrorMedium(BuildContext context) {
    return TextStyle(
      fontSize: AppFontSizes.small,
      color: StateContainer.of(context).curTheme.primary,
      fontFamily: 'Lato',
      fontWeight: FontWeight.w600,
    );
  }

  // Text style for mnemonic
  static TextStyle textStyleMnemonic(BuildContext context) {
    return TextStyle(
      fontSize: AppFontSizes.smallText(context),
      color: StateContainer.of(context).curTheme.primary,
      fontFamily: 'Lato',
      fontWeight: FontWeight.w400,
    );
  }

  // Text style for mnemonic success
  static TextStyle textStyleMnemonicSuccess(BuildContext context) {
    return TextStyle(
      fontSize: AppFontSizes.smallText(context),
      color: StateContainer.of(context).curTheme.success,
      fontFamily: 'Lato',
      fontWeight: FontWeight.w400,
    );
  }

  // Text style for numbers of mnemonic
  static TextStyle textStyleNumbersOfMnemonic(BuildContext context) {
    return TextStyle(
      fontSize: AppFontSizes.smallText(context),
      color: StateContainer.of(context).curTheme.text30,
      fontFamily: 'Lato',
      fontWeight: FontWeight.w400,
    );
  }

  // Text style for numbers of mnemonic
  static TextStyle headerPrimary(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      color: StateContainer.of(context).curTheme.primary,
      fontFamily: 'Lato',
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle headerSuccess(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      color: StateContainer.of(context).curTheme.success,
      fontFamily: 'Lato',
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle addressText(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      color: StateContainer.of(context).curTheme.text,
      fontFamily: 'Lato',
      fontWeight: FontWeight.w400,
    );
  }
}

class AppFontSizes {
  static const tiny = 10.0;
  static const smallest = 12.0;
  static const small = 14.0;
  static const medium = 16.0;
  static const _large = 20.0;
  static const larger = 24.0;
  static const _largest = 28.0;
  static const largestc = 28.0;
  static const _sslarge = 18.0;
  static const _sslargest = 22.0;
  static double largest(context) {
    if (smallScreen(context)) {
      return _sslargest;
    }
    return _largest;
  }

  static double large(context) {
    if (smallScreen(context)) {
      return _sslarge;
    }
    return _large;
  }

  static double smallText(context) {
    if (smallScreen(context)) {
      return smallest;
    }
    return small;
  }
}

bool smallScreen(BuildContext context) {
  if (MediaQuery.of(context).size.height < 667)
    return true;
  else
    return false;
}
