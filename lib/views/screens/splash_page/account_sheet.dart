import 'package:flutter/material.dart';

import '../../../theme/potatuhs.dart';
import '../../../user_profile.dart';
import '../../../vipotato.dart';
import 'vipotato_avatar.dart';
import 'vipotato_builder.dart';

/// Opens the hot-potato-games account sheet: email + anonymous sign-in when
/// signed out, profile editing when signed in.
Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AccountSheet(),
  );
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    // Tap anywhere outside a field to dismiss the keyboard.
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Cap the height so the body scrolls instead of overflowing.
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: Potatuhs.inkPanel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ValueListenableBuilder<HpgUser?>(
              valueListenable: AuthService.current,
              builder: (context, user, _) {
                final signedInWithEmail = user != null && !user.isAnonymous;
                return SingleChildScrollView(
                  // Keyboard inset lives INSIDE the scroll padding so the
                  // focused field/buttons scroll above the keyboard rather than
                  // overflowing the sheet.
                  padding: EdgeInsets.fromLTRB(22, 14, 22, 22 + insets),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Grabber(),
                      const SizedBox(height: 14),
                      if (signedInWithEmail)
                        _ProfileEditor(user: user)
                      else
                        _SignInForm(isAnonymous: user?.isAnonymous ?? false),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

/// Signed-out (or anonymous) view: email/password + guest entry. When the
/// visitor is already anonymous, "Create account" links and keeps their uid.
class _SignInForm extends StatefulWidget {
  final bool isAnonymous;
  const _SignInForm({required this.isAnonymous});
  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object e) {
    final s = e.toString();
    final i = s.indexOf(']');
    return i >= 0 && i < s.length - 1 ? s.substring(i + 1).trim() : s;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.isAnonymous ? 'SAVE YOUR PROGRESS' : 'SIGN IN',
          textAlign: TextAlign.center,
          style: Potatuhs.display(size: 22, spacing: 2),
        ),
        const SizedBox(height: 6),
        Text(
          widget.isAnonymous
              ? 'Playing as a guest. Create an account to keep your stuff.'
              : 'Sign in to hot-potato-games.',
          textAlign: TextAlign.center,
          style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary),
        ),
        const SizedBox(height: 18),
        _Field(controller: _email, hint: 'Email', keyboard: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _Field(controller: _password, hint: 'Password', obscure: true),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: Potatuhs.body(size: 12.5, color: Potatuhs.orange)),
        ],
        const SizedBox(height: 18),
        PotatuhsButton(
          label: widget.isAnonymous ? 'CREATE ACCOUNT' : 'SIGN IN',
          onTap: _busy
              ? () {}
              : () => _run(() => widget.isAnonymous
                  ? AuthService.registerWithEmail(_email.text, _password.text)
                  : AuthService.signInWithEmail(_email.text, _password.text)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _busy
              ? null
              : () => _run(() => widget.isAnonymous
                  ? AuthService.signInWithEmail(_email.text, _password.text)
                  : AuthService.registerWithEmail(_email.text, _password.text)),
          child: Text(
            widget.isAnonymous ? 'I already have an account' : 'Create an account',
            style: Potatuhs.body(size: 13, color: Potatuhs.gold),
          ),
        ),
        if (!widget.isAnonymous)
          TextButton(
            onPressed:
                _busy ? null : () => _run(AuthService.signInAnonymously),
            child: Text('Continue as guest',
                style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary)),
          ),
        if (_busy) ...[
          const SizedBox(height: 8),
          const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ],
    );
  }
}

/// Signed-in view: edit displayName / phone / theme / notifications, sign out.
class _ProfileEditor extends StatefulWidget {
  final HpgUser user;
  const _ProfileEditor({required this.user});
  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.user.displayName ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.user.phoneNumber ?? '');
  bool _busy = false;
  String? _status;

  VIPotatoConfig? _avatar;
  bool _avatarLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final equipped = await VIPotatoService.loadEquipped();
    if (!mounted) return;
    setState(() {
      _avatar = equipped;
      _avatarLoading = false;
    });
  }

  Future<void> _openBuilder() async {
    final saved = await openVIPotatoBuilder(context, initial: _avatar);
    if (saved != null && mounted) setState(() => _avatar = saved);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await AuthService.updateProfile(
        displayName: _name.text.trim(),
        phoneNumber: _phone.text.trim(),
      );
      if (mounted) setState(() => _status = 'Saved.');
    } catch (_) {
      if (mounted) setState(() => _status = 'Could not save — try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: GestureDetector(
            onTap: _openBuilder,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    _avatarLoading
                        ? const SizedBox(
                            width: 84,
                            height: 84,
                            child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : VIPotatoAvatar(
                            config: _avatar,
                            size: 84,
                            fallbackInitial: u.displayName ?? u.email,
                          ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Potatuhs.gold,
                      ),
                      child: const Icon(Icons.edit,
                          size: 14, color: Potatuhs.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Tap to build your VIPotato',
                    style: Potatuhs.body(
                        size: 11.5, color: Potatuhs.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(u.email ?? 'Account',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary)),
        const SizedBox(height: 18),
        _Label('DISPLAY NAME'),
        const SizedBox(height: 6),
        _Field(controller: _name, hint: 'Display name'),
        const SizedBox(height: 14),
        _Label('PHONE'),
        const SizedBox(height: 6),
        _Field(
          controller: _phone,
          hint: 'Phone number',
          keyboard: TextInputType.phone,
          // The numeric pad has no return key — give an explicit Done button.
          showDoneButton: true,
        ),
        if (_status != null) ...[
          const SizedBox(height: 12),
          Text(_status!,
              textAlign: TextAlign.center,
              style: Potatuhs.body(size: 12.5, color: Potatuhs.gold)),
        ],
        const SizedBox(height: 18),
        PotatuhsButton(
          label: _busy ? 'SAVING…' : 'SAVE',
          onTap: _busy ? () {} : _save,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy
              ? null
              : () async {
                  await AuthService.signOut();
                  if (context.mounted) Navigator.of(context).pop();
                },
          child: Text('Sign out',
              style: Potatuhs.body(size: 13, color: Potatuhs.orange)),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboard;

  /// Show a trailing "done" check that dismisses the keyboard — for numeric
  /// inputs (e.g. phone) whose keypad has no return key.
  final bool showDoneButton;

  const _Field({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboard,
    this.showDoneButton = false,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      style: Potatuhs.body(size: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Potatuhs.body(size: 15, color: Potatuhs.textFaint),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: showDoneButton
            ? IconButton(
                icon: const Icon(Icons.check_circle, color: Potatuhs.gold),
                tooltip: 'Done',
                onPressed: () => FocusScope.of(context).unfocus(),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Potatuhs.gold, width: 1.5),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Potatuhs.label(size: 11));
}

