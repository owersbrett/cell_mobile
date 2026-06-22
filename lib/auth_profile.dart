/// The signed-in player's identity, handed down from hotpotatogames.com via the
/// SSO bridge (see `auth_bridge_web.dart`). When present, an authenticated
/// player plays as their **custom VIPotato avatar** ([avatarUrl] = the equipped
/// composite image); otherwise the game falls back to the sticker roster.
///
/// Static + in-memory: set once during the auth handshake, read by the party
/// setup / board when rendering the local player.
class AuthProfile {
  AuthProfile._();

  static String? name;
  static String? avatarUrl;

  /// True when we have a custom avatar to show for the signed-in player.
  static bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  static void set({String? name, String? avatarUrl}) {
    AuthProfile.name = name;
    AuthProfile.avatarUrl = avatarUrl;
  }
}
