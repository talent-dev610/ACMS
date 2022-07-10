/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

class User {
  final String id;
  final String contacId;
  final String phone;
  final String name;
  final UserPrefs prefs;

  const User(
    this.id,
    this.contacId,
    this.phone,
    this.name,
    this.prefs,
  );

  User.fromJson(final Map<String, dynamic> json)
      : this(
          json['id'],
          json['contactId'],
          json['phone'],
          json['name'],
          UserPrefs.fromJson(json['prefs'] ?? {}),
        );

  Map<String, dynamic> toJson() => {
        "id": id,
        "contactId": contacId,
        "phone": phone,
        "name": name,
        "prefs": prefs,
      };

  User copyWith({UserPrefs prefs}) => User(
        this.id,
        this.contacId,
        this.phone,
        this.name,
        prefs ?? this.prefs,
      );
}

class UserPrefs {
  final List<String> hiddenManualLocationPhones;

  const UserPrefs(this.hiddenManualLocationPhones);

  UserPrefs.fromJson(final Map<String, dynamic> json)
      : this(
          json['hiddenManualLocationPhones'] != null
              ? json['hiddenManualLocationPhones'].split(';')
              : new List<String>(),
        );

  Map<String, dynamic> toJson() => {
        "hiddenManualLocationPhones": hiddenManualLocationPhones.join(';'),
      };
}

class Session {
  final String token;
  final User user;
  final Function expired;

  const Session(this.token, this.user, this.expired);

  Session.fromJson(Map<String, dynamic> json, Function onExpired)
      : this(json['token'], User.fromJson(json['user']), onExpired);

  Map<String, dynamic> toJson() => {
        'token': token,
        'user': user.toJson(),
      };

  Session copyWith({User user}) =>
      Session(this.token, user ?? this.user, this.expired);
}
