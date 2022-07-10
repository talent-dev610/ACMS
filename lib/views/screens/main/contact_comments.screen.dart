/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'dart:async';

import 'package:acms/actions/domain.actions.dart';
import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/models/auth.models.dart';
import 'package:acms/models/domain.models.dart';
import 'package:acms/store/app.store.dart';
import 'package:acms/views/components/alerts.dart';
import 'package:acms/views/components/bars.dart';
import 'package:acms/views/components/base.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:redux/redux.dart';

final _dtf = DateFormat('yy-MM-dd hh:mm');

class ContactCommentsScreen extends StatefulWidget {
  final Contact contact;
  final String keyword;

  ContactCommentsScreen(this.contact, {this.keyword});

  @override
  _ContactCommentsScreenState createState() {
    return new _ContactCommentsScreenState();
  }
}

class _ContactCommentsScreenState extends State<ContactCommentsScreen>
    with WidgetStateUtilsMixin {
  final _commentTextFieldController = TextEditingController();
  final _commentsScrollController = ScrollController();
  GlobalKey _lastKeywordItemKey;
  AlertData _notification;

  final _suggestionsRegExp =
      RegExp(r'(-?\d+(?:(?:\.|,)\d+)?)\*(-?\d+(?:(?:\.|,)\d+)?)$');
  MapEntry<String, String> _suggestions;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500),
        () => _scrollCommentsToBottom(toLastKeyword: true));
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      distinct: true,
      converter: (store) => _ViewModel(store),
      builder: (_, model) => Scaffold(
            backgroundColor: AppColors.lightBg,
            appBar: _buldTopbar(model),
            body: SafeArea(
              child: _buildBody(model),
            ),
          ),
      onDidChange: (model) {
        if (model.hasAddContactCommentFailed()) {
          setState(() => _notification =
              AlertData.fromAsyncError(model.saveContactCommentState.error));
        }
        if (model.hasAddContactCommentSucceed()) {
          setState(() => _commentTextFieldController.text = '');
          _scrollCommentsToBottom();
        }
      },
    );
  }

  _buildBody(_ViewModel model) {
    return Stack(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _buildCommentList(model),
              ),
              SizedBox(height: 5.0),
              _buildSuggestions(),
              _buildSendControl(model),
            ],
          ),
        ),
        buildNotification(_notification),
      ],
    );
  }

  Widget _buildSuggestions() {
    if (_suggestions == null) return SizedBox();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        color: Color(0xFFffef9b),
        border: Border.all(
          color: Color(0xffbbbbbb),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 7, 5, 7),
          child: Row(
            children: <Widget>[
              Flexible(
                child: InkResponse(
                  child: Text(
                    _suggestions.value,
                    style: TextStyle(color: Color(0xffa25e31)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => setState(() {
                        _commentTextFieldController.text =
                            _commentTextFieldController.text.substring(
                                    0,
                                    _commentTextFieldController.text.length -
                                        _suggestions.key.length) +
                                _suggestions.value;
                        _suggestions = null;
                      }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row _buildSendControl(_ViewModel model) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        SizedBox(width: 5.0),
        Expanded(
          child: TextField(
            controller: _commentTextFieldController,
            maxLength: 300,
            maxLines: 1,
            style: AppStyles.textField,
            decoration: InputDecoration(
              enabled: true,
              hintText: I18N.contactInfo_commentInputPlaceholder,
              hintStyle: AppStyles.textField.copyWith(color: Colors.black26),
              counterStyle: AppStyles.textField
                  .copyWith(color: Colors.black26, fontSize: 10.0),
              contentPadding: EdgeInsets.fromLTRB(.0, 6.0, 0.0, 4.0),
            ),
            onChanged: (text) {
              if (_suggestionsRegExp.hasMatch(text)) {
                final match = _suggestionsRegExp.firstMatch(text);
                final parts = match.group(0).split('*');
                setState(() {
                  _suggestions = MapEntry(match.group(0),
                      '【  ${match.group(0)}、${parts[0]}mm*${parts[1]}mm、${parts[0]}${parts[0].contains('.') ? '' : '.00'}mm*${parts[1]}${parts[1].contains('.') ? '' : '.00'}mm】');
                });
              } else if (_suggestions != null) {
                setState(() => _suggestions = null);
              }
            },
          ),
        ),
        Container(
          width: 40.0,
          height: 35.0,
          margin: EdgeInsets.only(bottom: 14.0),
          alignment: Alignment.centerRight,
          child: model.saveContactCommentState.isInProgress()
              ? CircularActivityIndicator(
                  color: AppPalette.secondaryColor, size: 19.0)
              : InkResponse(
                  child: Icon(
                    Icons.send,
                    color: AppPalette.secondaryColor,
                    size: 25.0,
                  ),
                  onTap: () => _commentTextFieldController.text.isNotEmpty
                      ? model.saveContactComment(
                          widget.contact, _commentTextFieldController.text)
                      : null),
        )
      ],
    );
  }

  ListView _buildCommentList(_ViewModel model) {
    return ListView(
        controller: _commentsScrollController,
        shrinkWrap: true,
        children: widget.contact.comments.map((comment) {
          final textNodes = _highlightKeyword(comment);
          Key key;
          if (textNodes.length > 1) {
            key = _lastKeywordItemKey = new GlobalKey();
          }
          return Container(
              key: key,
              margin: const EdgeInsets.only(bottom: 10.0),
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(
                    color: Color(0xff2185d0),
                    width: 3.0,
                  ),
                ),
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_dtf.format(comment.createdAt),
                        style: _Styles.commentCreatedAt),
                    SizedBox(height: 3.0),
                    Flexible(
                        child: RichText(
                      text: TextSpan(children: textNodes),
                    ))
                  ]));
        }).toList());
  }

  _buldTopbar(_ViewModel model) {
    final contact = widget.contact;
    return TopBar(
      title: contact.name,
      leftAction: TopBarAction.cancel(() => Navigator.of(context).pop()),
    );
  }

  List<TextSpan> _highlightKeyword(ContactComment comment) {
    final nodes = List<TextSpan>();
    if (widget.keyword != null && widget.keyword.isNotEmpty) {
      final re =
          new RegExp(RegExp.escape(widget.keyword), caseSensitive: false);
      final matches = re.allMatches(comment.text);
      int start = 0;
      matches.forEach((match) {
        nodes.add(TextSpan(
            text: match.input.substring(start, match.start),
            style: _Styles.commentText));
        nodes.add(TextSpan(
            text: match.input.substring(match.start, match.end),
            style: _Styles.commentHightlight));
        start = match.end;
      });
      if (start < comment.text.length)
        nodes.add(TextSpan(
            text: comment.text.substring(start), style: _Styles.commentText));
    }
    if (nodes.length == 0)
      nodes.add(TextSpan(text: comment.text, style: _Styles.commentText));
    return nodes;
  }

  void _scrollCommentsToBottom({bool toLastKeyword = false}) {
    if (toLastKeyword && _lastKeywordItemKey?.currentContext != null) {
      Scrollable.ensureVisible(_lastKeywordItemKey.currentContext);
      return;
    }
    final offset = _commentsScrollController.position.maxScrollExtent;
    _commentsScrollController.animateTo(
      offset,
      curve: Curves.easeOut,
      duration: Duration(milliseconds: offset.toInt() * 2),
    );
  }
}

class _Styles {
  static final commentCreatedAt = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 12.0,
    color: Colors.black38,
  );
  static final commentText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Color(0xff444444),
  );
  static final commentHightlight = commentText.copyWith(
    background: Paint()..color = Colors.yellow,
  );
}

class _ViewModel {
  final AppState _state;
  final Function _dispatch;

  _ViewModel(Store<AppState> store)
      : _state = store.state,
        _dispatch = store.dispatch;

  User get currentUser => _state.authState.loginState.value?.user;
  AsyncState<String> get saveContactCommentState =>
      _state.domainState.saveContactCommentState;

  void saveContactComment(Contact contact, String text) {
    _dispatch(new SaveContactCommentAction(contact, text));
  }

  bool hasAddContactCommentFailed() {
    final prev = _state.prevState?.domainState?.saveContactCommentState;
    return prev != _state.domainState.saveContactCommentState &&
        _state.domainState.saveContactCommentState.isFailed();
  }

  bool hasAddContactCommentSucceed() {
    final prev = _state.prevState?.domainState?.saveContactCommentState;
    return prev != _state.domainState.saveContactCommentState &&
        _state.domainState.saveContactCommentState.isSuccessful();
  }

  operator ==(o) {
    return o is _ViewModel &&
        this.saveContactCommentState == o.saveContactCommentState;
  }

  @override
  int get hashCode => 0;
}
