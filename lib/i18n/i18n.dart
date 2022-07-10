// ignore_for_file: non_constant_identifier_names
/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/models/async.models.dart';

class I18N {
  static String ok = 'OK';
  static String quit = '退出程序';
  static String close = '关';
  static String save = '保存';

  static String invalidPhoneNumber = '电话或手机号码不对';
  static String tooLongName = '名字太长';
  static String tooShortName = '名字太短';

  static String tryAgain = '请再试一下';

  static String phoneRequired = '请输入（+国家代码）开头的手机号码';
  static String codeRequired = '短信验证码';
  static String nameRequired = '您真实姓名';

  static String phoneCaption = '请输入（+国家代码）开头的手机号码';
  static String codeCaption = '短信验证码';
  static String nameCaption = '真实姓名';

  static String loginCaption = '进地质关系网';
  static String sendSmsCodeCaption = '发送短信验证码';
  static String signUpCaption = '注册地质关系网';

  static String dontHaveAccout = '还没有关系网账户？';
  static String alreadyHaveAccout = '开户成功后可直接进地质关系网';
  static String smsCodeSend = '正在接收验证码...';

  static final welcomeText = (String username) => '$username, 欢迎您。';
  static String getLocationFailed = '请允许软件使用位置...';

  static String syncFailedError(String cause) =>
      '无法为您建立地质关系网，请允许软件读取通讯录... $cause';
  static String loadContactsFailedError(String cause) =>
      '没有地质关系网可用，请再试一次. $cause';

  // Sync Progress Page
  static String sync_checkingPermissions = 'Checking permissions...';
  static String sync_grantContactsPermission = 'Granted contacts permission';
  static String sync_deniedContactsPermission = 'Denied contacts permission';
  static String sync_grantLocationPermission = 'Granted location permission';
  static String sync_deniedLocationPermission = 'Denied location permission';
  static String sync_grantSmsPermission = 'Granted sms permission';
  static String sync_deniedSmsPermission = 'Denied sms permission';

  static String sync_checkingNetworkType = 'Checking network type...';
  static String sync_getNetworkType(String network) =>
      'Current network type: $network';

  static String sync_readingServerContacts = 'Reading contacts from server...';
  static String sync_localContactsCount(int count) =>
      'Reading $count contacts from your phone';
  static String sync_readinglocalContacts =
      'Reading contacts from your phone...';
  static String sync_serverContactsCount(int count) =>
      'Reading $count contacts from server';
  static String sync_serverContactsCountError(int retryCount) =>
      'Reading contacts from server failed with $retryCount times';
  static String sync_permissionRequestTips = 'Go to settings';

  // Map tab
  static String map_tabText = '地图';
  static String map_title = '地质关系网';
  static String map_syncContactsText = '正在建立地质关系网...';
  static String map_deniedContactsPermissionDialogContent =
      '请打开手机设置中的通讯录读取功能...';

  static String map_syncCompleteDialogTitle = '对方大体位置已被确定.';
  static String map_syncCompleteDialogContent(
          int syncedNumber, int untranslatedPhonesNumber) =>
      '$syncedNumber 个号码被记录' +
      (untranslatedPhonesNumber > 0
          ? '\n$untranslatedPhonesNumber 个号码需要您手动确定对方位置,'
          : '');
  static String map_syncCompleteDialogSet = '手动';

  static String map_findLocationPermissionDialogContent = '地质关系网正在监控您的位置变化.';
  static String map_findLocationPermissionDialogMyLocation = '我的位置';
  static String map_readContactsPermissionDialogContent = '地质关系网正在监控您的通讯录变化.';
  static String map_readContactsPermissionDialog_syncContent(int count) =>
      '$count 个号码的大体位置已被确定';
  static String map_readContactsPermissionDialog_untranslatedContent(
          int count) =>
      '$count 个号码需要手动确定对方位置';

  static String map_readContactsPermissionDialogSet = map_syncCompleteDialogSet;

  // Black list tab
  static String blackList_title = '失信人员名单';
  static String blackList_empty = '榜上无名';
  static String blackList_filterPlaceholder = '关键词...';

  // Contact options
  static const contactInfo_commentInputPlaceholder = '注意...';
  static const contactOptions_publicHeader = '让所有人知道此号';
  static String contactOptions_notesHeader = '日常备注：';
  static String contactOptions_notesTint = '请键入文本...';
  static String contactOptions_emptyNoteError = '不能空白';
  static String contactOptions_selfAuthor = '本机';
  static String contactOptions_reputation = '声誉';
  static String contactOptions_like = '点赞';
  static String contactOptions_dislike = '黑名单';
  static String contactOptions_dislikeConfirm =
      '请注意：一旦您公开这个号码，别的会员就会看到，会认为这个号码是不守信用的。';
  static String contactOptions_dislikeConfirmYes = '确定';
  static String contactOptions_dislikeConfirmNo = I18N.close;

  // Manual location
  static String manualLocation_title = '需要手动确定对方位置';
  static String manualLocation_savedSuccessfuly = '手动定位成功！正在退出。。。';

  // Search
  static String searchTab_tabText = '找人';
  static String searchTab_placeholder = '关键词...';
  static String searchTab_foundContactTooltip(int count) => '$count 个相关号码';
  static String searchTab_totalContactsTooltip(int count) => '关系网号码总数：$count 个';
  static String searchTab_noContacts = '暂无号码';
  static String searchTab_noContactsFoundForQueryError(String query) =>
      '没有查到 : "$query"';
  static String searchPane_twiceSearchIconTitle = '从地图上看结果';
  static List<String> search_tips = ['厂家', '贸易商', '物流', '门市'];
  static List<String> search_tips2 = ['同行', '产品关键词'];

  static String searchMap_noLocationFoundError = '请重新捡个位置';
  static String searchMap_holderAcmsTitle(String holderName) =>
      '$holderName 地质关系网';
  static String searchMap_queryTitle(String query) => '"$query"';
  static String searchMap_contactSearchTitle(String contactName) =>
      '- $contactName -';

  // Cluster list
  static String clusterList_noContactsFoundForQueryError = '没有查到';
  static String clusterList_placeholder = I18N.blackList_filterPlaceholder;

  // Common Contacts
  static String commonContactsTitle = 'Common contacts';
  static String commonContactsNotFound = 'No matches were found';
  static String commonContactsRecord(String locality, int count) =>
      ' have $count common contacts in $locality';

  static fromAsyncError(AsyncError error) {
    switch (error.type) {
      case AsyncErrorType.PERMISSION_DENIED:
        return '权限未打开';
      case AsyncErrorType.SERVER_ERROR:
        return '服务器故障，请联系技术员：电话 13795375098';
      case AsyncErrorType.APP_ERROR:
        return '地质关系网暂时不可用，请再试一下';
      case AsyncErrorType.NETWORK_PROBLEMS:
        return '请检查手机网络太卡';
      case AsyncErrorType.NO_VERIFICATION_CODE:
      case AsyncErrorType.INVALID_VERIFICATION_CODE:
        return '验证码失效';
      case AsyncErrorType.USER_NOT_FOUND:
        return '请先开户，联系客服：电话 13788932357';
      case AsyncErrorType.PHONE_NUMBER_TAKEN:
        return '请不要重复注册，您已可直接登录';
      case AsyncErrorType.TOO_MANY_REQUESTS:
        return '地质关系网正繁忙，请等一下再试';
      case AsyncErrorType.INVALID_PHONE_NUMBER:
        return '号码格式有误';
      case AsyncErrorType.SESSION_EXPIRED:
        return '会话超时，请联系技术员：电话 13795375098';
      case AsyncErrorType.FAILED_TO_SEND_SMS:
        return '手机发不出去短信';
      case AsyncErrorType.LOCATION_NOT_FOUND:
        return '手动失败，请联系技术员：电话 13795375098';
    }
  }

  static String sharedBy(String holderName) => '来自年费会员 $holderName';
  static String contactHolderAreaHint(int numberOfContacts) =>
      ' 有 $numberOfContacts 个号码的大体位置在这一块';
  static String contactHolderSearchHint(int numberOfContacts) =>
      ' 有 $numberOfContacts 个号码被查到';

  static String holderUserSubtitle(int numberOfContacts, String locality) =>
      locality != null
          ? '年费会员, $numberOfContacts 个号码，在 $locality'
          : '年费会员, $numberOfContacts 个号码';

  // Google Search Results
  static String gsresults_title = '谷歌搜索';

  static String callLogContactName = '未知姓名';

  // Make public
  static const makePublic_title = contactOptions_publicHeader;
  static const makePublic_toEveryone = '推给所有人';
  static const makePublic_restrict = '推给他';
  static const makePublic_filterHint = '关系网会员';
}
