/// Simple singleton that holds the currently logged-in user's data.
/// Populated after a successful login; cleared on logout.
class UserSession {
  UserSession._();

  static final instance = UserSession._();

  String name = '';
  String email = '';
  String? photoUrl;

  bool get isLoggedIn => email.isNotEmpty;

  /// Call after a successful email / password login.
  void setFromEmail(String email) {
    this.email = email;
    // Derive a readable display name from the email username.
    // e.g. "alex.johnson@kuet.ac.bd"  →  "Alex Johnson"
    // e.g. "alam2107023@stud.kuet.ac.bd"  →  "Alam"
    final username = email.split('@').first;
    final cleaned = username
        .replaceAll(RegExp(r'[0-9]'), '')
        .replaceAll(RegExp(r'[._\-]'), ' ')
        .trim();
    name = cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
    if (name.isEmpty) name = username;
    photoUrl = null;
  }

  /// Call after a successful Google Sign-In.
  void setFromGoogle({
    required String name,
    required String email,
    String? photoUrl,
  }) {
    this.name = name;
    this.email = email;
    this.photoUrl = photoUrl;
  }

  /// Clear session on logout.
  void clear() {
    name = '';
    email = '';
    photoUrl = null;
  }
}
