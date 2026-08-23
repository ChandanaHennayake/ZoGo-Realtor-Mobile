import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/google_constants.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _googleSignIn.initialize(
      serverClientId: GoogleConstants.serverClientId,
    );

    _initialized = true;
  }

  Future<String?> signInAndGetIdToken() async {
    await initialize();

    final account = await _googleSignIn.authenticate();

    return account.authentication.idToken;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}