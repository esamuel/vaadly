import 'package:cloud_functions/cloud_functions.dart';

class UserAdminService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Returns a list of user maps with fields: name, email, role, isActive, lastLogin, createdAt, updatedAt, auth{uid,emailVerified,disabled,lastSignInTime}
  static Future<List<Map<String, dynamic>>> listUsers() async {
    final callable = _functions.httpsCallable('listUsersForOwner');
    final res = await callable.call();
    final List users = (res.data['users'] as List?) ?? [];
    return users.cast<Map<String, dynamic>>();
  }

  static Future<String> generateResetLink(String email) async {
    final callable =
        _functions.httpsCallable('generatePasswordResetLinkForOwner');
    final res = await callable.call({'email': email});
    return (res.data['resetLink'] as String?) ?? '';
  }

  // Utility: convert users to CSV content (dev use only)
  static String usersToCsv(List<Map<String, dynamic>> users) {
    const headers = [
      'name',
      'email',
      'role',
      'isActive',
      'lastLogin',
      'uid',
      'emailVerified',
      'disabled'
    ];
    final headerLine = headers.join(',');
    final lines = <String>[headerLine];

    for (final u in users) {
      final name = _csv(u['name']);
      final email = _csv((u['email'] ?? '').toString().toLowerCase());
      final role = _csv(u['role']);
      final isActive = _csv('${u['isActive'] ?? false}');
      final lastLogin = _csv(u['lastLogin'] ?? '');
      final auth = u['auth'] as Map<String, dynamic>?;
      final uid = _csv(auth?['uid'] ?? '');
      final emailVerified = _csv('${auth?['emailVerified'] ?? false}');
      final disabled = _csv('${auth?['disabled'] ?? false}');
      lines.add([
        name,
        email,
        role,
        isActive,
        lastLogin,
        uid,
        emailVerified,
        disabled
      ].join(','));
    }

    return lines.join('\n');
  }

  static String _csv(dynamic value) {
    final s = (value ?? '').toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
