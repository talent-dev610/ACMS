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
import 'package:acms/views/screens/main/make_public.screen.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:redux/redux.dart';

final _dtf = DateFormat('yy-MM-dd');

class ContactOptionsScreen extends StatefulWidget {
  final Contact contact;
  final String keyword;

  ContactOptionsScreen(this.contact, {this.keyword});

  @override
  _ContactOptionsScreenState createState() {
    return new _ContactOptionsScreenState();
  }
}

class _ContactOptionsScreenState extends State<ContactOptionsScreen>
    with WidgetStateUtilsMixin {
  final _noteTextFieldController = TextEditingController();
  final _notesScrollController = ScrollController();
  final _suggestionsRegExp =
      RegExp(r'(-?\d+(?:(?:\.|,)\d+)?)\*(-?\d+(?:(?:\.|,)\d+)?)$');
  MapEntry<String, String> _suggestions;
  GlobalKey _lastKeywordItemKey;
  AlertData _notification;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500),
        () => _scrollNotesToBottom(toLastKeyword: true));
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
        if (model.hasAddContactNoteFailed() ||
            model.hasChangeLikeFailed() ||
            model.hasChangePublicFailed()) {
          setState(() => _notification = AlertData.fromAsyncError(
              model.saveContactNoteState.error ??
                  model.changeLikeState.error ??
                  model.changePublicState.error));
        }
        if (model.hasAddContactNoteSucceed()) {
          setState(() => _noteTextFieldController.text = '');
          _scrollNotesToBottom();
        }
      },
    );
  }

  _buildBody(_ViewModel model) {
    final isUserContact = widget.contact is UserContact;
    return Stack(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(12.0, 10.0, 10.0, 3.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildLikeControl(model),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Separator(),
              ),
              isUserContact ? _buildPublicControl(model) : SizedBox(),
              isUserContact
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 13.0),
                      child: Separator(),
                    )
                  : SizedBox(),
              Padding(
                padding: const EdgeInsets.only(top: 5.0, bottom: 8.0),
                child: Text(I18N.contactOptions_notesHeader,
                    style: _Styles.header),
              ),
              Expanded(
                child: _buildNoteList(model),
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

  Widget _buildLikeControl(_ViewModel model) {
    final contact = widget.contact;
    final content = List<Widget>();

    if (contact is UserContact) {
      content.addAll([
        RaisedButton(
          child: Row(
            children: <Widget>[
              Icon(
                Icons.thumb_down,
                size: 16.0,
                color: contact.liked == false
                    ? AppPalette.secondaryColor
                    : Colors.black26,
              ),
              SizedBox(width: 5.0),
              Text(I18N.contactOptions_dislike,
                  style: _Styles.reputationButtonText, softWrap: false),
            ],
          ),
          onPressed: () => _changeLike(
              model, contact, contact.liked == false ? null : false),
        ),
        SizedBox(width: 10.0),
        RaisedButton(
          child: Row(
            children: <Widget>[
              Icon(
                Icons.thumb_up,
                size: 16.0,
                color: contact.liked == true
                    ? AppPalette.secondaryColor
                    : Colors.black26,
              ),
              SizedBox(width: 5.0),
              Text(I18N.contactOptions_like,
                  style: _Styles.reputationButtonText, softWrap: false),
            ],
          ),
          onPressed: () =>
              _changeLike(model, contact, contact.liked == true ? null : true),
        ),
      ]);
    } else {
      if (contact.liked == true) {
        content.add(
          Row(
            children: <Widget>[
              Icon(Icons.thumb_up,
                  size: 16.0, color: AppPalette.secondaryColor),
              SizedBox(width: 10.0, height: 35.0),
              Text(I18N.contactOptions_like,
                  style: _Styles.reputationButtonText, softWrap: false),
            ],
          ),
        );
      } else if (contact.liked == false) {
        content.add(
          Row(
            children: <Widget>[
              Icon(
                Icons.thumb_down,
                size: 16.0,
                color: contact.liked == false
                    ? AppPalette.secondaryColor
                    : Colors.black26,
              ),
              SizedBox(width: 10.0, height: 35.0),
              Text(I18N.contactOptions_dislike,
                  style: _Styles.reputationButtonText, softWrap: false),
            ],
          ),
        );
      }
    }
    if (content.length == 0) return SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(I18N.contactOptions_reputation, style: _Styles.header),
        Row(
          children: content,
        )
      ],
    );
  }

  Row _buildPublicControl(_ViewModel model) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(I18N.contactOptions_publicHeader, style: _Styles.header),
        SizedBox(height: 60.0),
        Switch(
          value: widget.contact.public,
          onChanged: (value) {
            if (value) {
              Navigator.push(
                  context,
                  AppRouteTransitions.none(
                      (_) => MakePublicScreen(widget.contact)));
            } else {
              model.changePublic(widget.contact, value);
            }
          },
        )
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Flexible(
                  child: InkResponse(
                    child: Text(
                      _suggestions.value,
                      style: TextStyle(color: Color(0xffa25e31)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => setState(() {
                          _noteTextFieldController.text =
                              _noteTextFieldController.text.substring(
                                      0,
                                      _noteTextFieldController.text.length -
                                          _suggestions.key.length) +
                                  _suggestions.value;
                          _suggestions = null;
                        }),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  Row _buildSendControl(_ViewModel model) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _noteTextFieldController,
            maxLength: 300,
            maxLines: 1,
            style: AppStyles.textField,
            decoration: InputDecoration(
              enabled: true,
              hintText: I18N.contactOptions_notesTint,
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
          child: model.saveContactNoteState.isInProgress()
              ? CircularActivityIndicator(
                  color: AppPalette.secondaryColor, size: 19.0)
              : InkResponse(
                  child: Icon(
                    Icons.send,
                    color: AppPalette.secondaryColor,
                    size: 25.0,
                  ),
                  onTap: () => _noteTextFieldController.text.isNotEmpty
                      ? model.saveContactNote(
                          widget.contact, _noteTextFieldController.text)
                      : setState(() => _notification =
                          AlertData.error(I18N.contactOptions_emptyNoteError))),
        )
      ],
    );
  }

  ListView _buildNoteList(_ViewModel model) {
    return ListView(
        controller: _notesScrollController,
        shrinkWrap: true,
        children: widget.contact.notes.map((note) {
          final isAuthorCurrentUser = note.author == null ||
              note.author.id == model.currentUser?.contacId;
          final isAuthorContactHolder = widget.contact is PublicContact &&
              (widget.contact as PublicContact).holder.id == note.author?.id;
          final textNodes = _highlightKeyword(note);
          Key key;
          if (textNodes.length > 1) {
            key = _lastKeywordItemKey = new GlobalKey();
          }
          return Padding(
              key: key,
              padding: const EdgeInsets.fromLTRB(.0, 5.0, .0, 5.0),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    isAuthorContactHolder && !isAuthorCurrentUser
                        ? Image.asset(
                            'assets/images/ic__vip.png',
                            alignment: Alignment.bottomRight,
                            width: 15.0,
                            height: 17.0,
                          )
                        : SizedBox(),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2.0),
                        child: RichText(
                          text: TextSpan(
                              children: [
                                    TextSpan(
                                        text: isAuthorCurrentUser
                                            ? I18N.contactOptions_selfAuthor
                                            : note.author.name,
                                        style: _Styles.noteAuthorName),
                                    TextSpan(
                                        text: ' ' +
                                            _dtf.format(note.createdAt) +
                                            ': ',
                                        style: _Styles.noteCreatedAt),
                                  ] +
                                  textNodes),
                        ),
                      ),
                    )
                  ]));
        }).toList());
  }

  List<TextSpan> _highlightKeyword(ContactNote note) {
    final nodes = List<TextSpan>();
    if (widget.keyword != null && widget.keyword.isNotEmpty) {
      final re =
          new RegExp(RegExp.escape(widget.keyword), caseSensitive: false);
      final matches = re.allMatches(note.text);
      int start = 0;
      matches.forEach((match) {
        nodes.add(TextSpan(
            text: match.input.substring(start, match.start),
            style: _Styles.noteText));
        nodes.add(TextSpan(
            text: match.input.substring(match.start, match.end),
            style: _Styles.noteHightlight));
        start = match.end;
      });
      if (start < note.text.length)
        nodes.add(TextSpan(
            text: note.text.substring(start), style: _Styles.noteText));
    }
    if (nodes.length == 0)
      nodes.add(TextSpan(text: note.text, style: _Styles.noteText));
    return nodes;
  }

  _buldTopbar(_ViewModel model) {
    final contact = widget.contact;
    return TopBar(
      title: contact.name,
      leftAction: TopBarAction.cancel(() => Navigator.of(context).pop()),
    );
  }

  void _scrollNotesToBottom({bool toLastKeyword = false}) {
    if (toLastKeyword && _lastKeywordItemKey?.currentContext != null) {
      Scrollable.ensureVisible(_lastKeywordItemKey.currentContext);
      return;
    }
    final offset = _notesScrollController.position.maxScrollExtent;
    _notesScrollController.animateTo(
      offset,
      curve: Curves.easeOut,
      duration: Duration(milliseconds: offset.toInt() * 2),
    );
  }

  _changeLike(_ViewModel model, Contact contact, bool value) {
    if (value == false) {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                content: Text(I18N.contactOptions_dislikeConfirm,
                    style: AppStyles.dialogContentText),
                actions: <Widget>[
                  FlatButton(
                    child: Text(I18N.contactOptions_dislikeConfirmNo,
                        style: AppStyles.dialogMinorActionText),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  FlatButton(
                    child: Text(I18N.contactOptions_dislikeConfirmYes,
                        style: AppStyles.dialogActionText),
                    onPressed: () {
                      Navigator.pop(context);
                      model.changeLike(contact, value);
                    },
                  ),
                ],
              ));
      return;
    }
    model.changeLike(contact, value);
  }
}

class _Styles {
  static final header = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 15.0,
    color: Colors.black54,
  );
  static final noteAuthorName = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 13.0,
    color: AppColors.darkBg,
    fontWeight: FontWeight.w500,
  );
  static final noteCreatedAt = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Colors.black38,
  );
  static final noteText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Color(0xff666666),
  );
  static final noteHightlight = noteText.copyWith(
    background: Paint()..color = Colors.yellow,
  );
  static final reputationButtonText = header;
}

class _ViewModel {
  final AppState _state;
  final Function _dispatch;

  _ViewModel(Store<AppState> store)
      : _state = store.state,
        _dispatch = store.dispatch;

  User get currentUser => _state.authState.loginState.value?.user;
  AsyncState<String> get saveContactNoteState =>
      _state.domainState.saveContactNoteState;
  AsyncState<bool> get changeLikeState => _state.domainState.changeLikeState;
  AsyncState<bool> get changePublicState =>
      _state.domainState.changePublicState;

  void saveContactNote(Contact contact, String text) {
    _dispatch(new SaveContactNoteAction(contact, text));
  }

  void changeLike(Contact contact, bool value) {
    _dispatch(new ChangeLikeAction(contact, value));
  }

  void changePublic(UserContact contact, bool value) =>
      _dispatch(ChangePublicAction(contact, value));

  bool hasAddContactNoteFailed() {
    final prev = _state.prevState?.domainState?.saveContactNoteState;
    return prev != _state.domainState.saveContactNoteState &&
        _state.domainState.saveContactNoteState.isFailed();
  }

  bool hasAddContactNoteSucceed() {
    final prev = _state.prevState?.domainState?.saveContactNoteState;
    return prev != _state.domainState.saveContactNoteState &&
        _state.domainState.saveContactNoteState.isSuccessful();
  }

  bool hasChangeLikeFailed() {
    final prev = _state.prevState?.domainState?.changeLikeState;
    return prev != _state.domainState.changeLikeState &&
        _state.domainState.changeLikeState.isFailed();
  }

  bool hasChangePublicFailed() {
    final prev = _state.prevState?.domainState?.changePublicState;
    return prev != _state.domainState.changePublicState &&
        _state.domainState.changePublicState.isFailed();
  }

  operator ==(o) {
    return o is _ViewModel &&
        this.changePublicState == o.changePublicState &&
        this.saveContactNoteState == o.saveContactNoteState &&
        this.changeLikeState == o.changeLikeState;
  }

  @override
  int get hashCode => 0;
}
