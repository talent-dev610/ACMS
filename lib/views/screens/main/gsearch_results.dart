/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/domain.models.dart';
import 'package:acms/views/components/bars.dart';
import 'package:acms/views/theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GSearchResultsScreen extends StatefulWidget {
  final Contact contact;

  const GSearchResultsScreen(this.contact);

  @override
  _GSearchResultsScreenState createState() {
    return new _GSearchResultsScreenState();
  }
}

class _GSearchResultsScreenState extends State<GSearchResultsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.lightBg,
        appBar: _buildAppBar(context),
        body: _buildList(context));
  }

  _buildAppBar(BuildContext context) {
    return TopBar(
      title: I18N.gsresults_title,
      leftAction: TopBarAction.cancel(() => Navigator.of(context).pop()),
    );
  }

  _buildList(BuildContext context) {
    final data = List<dynamic>();
    widget.contact.phones.forEach((phone) {
      if (phone.gsresults != null && phone.gsresults.isNotEmpty) {
        data.add(phone);
        phone.gsresults.forEach((gsr) {
          data.add(gsr);
        });
      }
    });

    return Material(
      color: AppColors.lightBg,
      child: Padding(
        padding: EdgeInsets.all(5.0),
        child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, index) {
              final item = data[index];
              if (item is ContactPhone) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(3.0),
                  margin: EdgeInsets.symmetric(vertical: 5.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color(0xFF84a4bb),
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  child: Text(item.value, style: _Styles.header),
                );
              } else {
                final gsr = item as GSearchResult;
                return InkWell(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 2.0, bottom: 5.0),
                            child: Text(
                              '${gsr.rank}) ${gsr.title}',
                              style: _Styles.title,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                          Text(gsr.description, style: _Styles.desc),
                          SizedBox(height: 3.0),
                          Text(
                            gsr.uri,
                            style: _Styles.uri,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                          ),
                        ]),
                  ),
                  onTap: () => launch(gsr.uri),
                );
              }
            }),
      ),
    );
  }
}

class _Styles {
  static const header = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 15.0,
    color: Colors.white,
  );
  static const title = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 15.0,
    color: Color(0xFF4183c4),
  );
  static const desc = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Color(0xFF565656),
  );
  static const uri = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 12.0,
    color: Color(0xFF008000),
  );
}
