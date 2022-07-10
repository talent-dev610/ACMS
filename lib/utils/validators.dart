/*
 * Developed in 2018 by Oleg Khalidov (brooth@gmail.com).
 *
 * Freelance Mobile Development:
 * UpWork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/i18n/i18n.dart';

String validateName(String val) => val.length < 2
    ? I18N.tooShortName
    : val.length > 200 ? I18N.tooLongName : null;

String validatePhone(String val) =>
    val.length < 10 ? I18N.invalidPhoneNumber : null;
