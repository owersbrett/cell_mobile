import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../theme/potatuhs.dart';
import 'game_feedback.dart';

/// The non-blocking post-game "Did you like that game?" card
/// (spec: `docs/PARTY_CINEMATIC_SPEC.md` §7).
///
/// Self-contained and host-agnostic: embed it anywhere (party round ceremony,
/// solo results). It NEVER navigates or blocks — [onDone] tells the host the
/// player is finished (rated or skipped); the host owns dismissal.
///
/// Flow:
/// - On mount the game is queued in [GameFeedback] — so if the host tears the
///   card down without interaction, the game stays pending (badge accumulates).
/// - 👍/👎 is one-tap resolution: the rating submits immediately and [onDone]
///   fires. A short optional note field then appears; SEND attaches the note
///   to the already-submitted record.
/// - SKIP fires [onDone] and leaves the game queued for later.
class FeedbackPrompt extends StatefulWidget {
  final String gameId;
  final String gameName;

  /// `'party'` or `'solo'`.
  final String source;

  /// The player is finished with the prompt (rated or skipped). The host
  /// decides what to do — this widget never dismisses itself.
  final VoidCallback onDone;

  const FeedbackPrompt({
    super.key,
    required this.gameId,
    required this.gameName,
    required this.source,
    required this.onDone,
  });

  @override
  State<FeedbackPrompt> createState() => _FeedbackPromptState();
}

class _FeedbackPromptState extends State<FeedbackPrompt> {
  final _note = TextEditingController();
  bool? _liked; // null until a thumb is tapped
  bool _noteSent = false;
  DatabaseReference? _recordRef;

  @override
  void initState() {
    super.initState();
    // Queue on show: skipping (or the host dismissing) leaves it pending.
    GameFeedback.addPending(widget.gameId);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _rate(bool liked) async {
    if (_liked != null) return;
    setState(() => _liked = liked);
    widget.onDone();
    _recordRef = await GameFeedback.resolvePending(
      widget.gameId,
      liked: liked,
      source: widget.source,
    );
  }

  void _skip() {
    // Already queued from initState — just hand control back.
    widget.onDone();
  }

  Future<void> _sendNote() async {
    final text = _note.text.trim();
    if (text.isEmpty || _noteSent) return;
    setState(() => _noteSent = true);
    await GameFeedback.attachNote(
        gameId: widget.gameId, ref: _recordRef, note: text);
  }

  @override
  Widget build(BuildContext context) {
    final rated = _liked != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel,
        borderColor: Potatuhs.gold.withValues(alpha: 0.45),
        radius: 18,
        glowColor: Potatuhs.gold,
        glowStrength: 0.18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            rated ? 'THANKS!' : 'DID YOU LIKE THAT GAME?',
            textAlign: TextAlign.center,
            style: Potatuhs.label(size: 11, color: Potatuhs.gold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.gameName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Potatuhs.display(size: 16),
          ),
          const SizedBox(height: 10),
          if (!rated)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ThumbButton(
                  icon: Icons.thumb_up_alt_rounded,
                  color: Potatuhs.gold,
                  tooltip: 'Liked it',
                  onTap: () => _rate(true),
                ),
                const SizedBox(width: 18),
                _ThumbButton(
                  icon: Icons.thumb_down_alt_rounded,
                  color: Potatuhs.copper,
                  tooltip: 'Not for me',
                  onTap: () => _rate(false),
                ),
                const SizedBox(width: 18),
                TextButton(
                  onPressed: _skip,
                  child: Text('SKIP',
                      style: Potatuhs.body(
                          size: 13, color: Potatuhs.textSecondary)),
                ),
              ],
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _liked!
                      ? Icons.thumb_up_alt_rounded
                      : Icons.thumb_down_alt_rounded,
                  color: _liked! ? Potatuhs.gold : Potatuhs.copper,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _liked! ? 'Glad you liked it' : 'Noted — we\'ll work on it',
                  style:
                      Potatuhs.body(size: 13, color: Potatuhs.textSecondary),
                ),
              ],
            ),
            if (!_noteSent) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _note,
                      maxLength: 120,
                      style: Potatuhs.body(size: 13.5),
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        hintText: 'Add a quick note (optional)',
                        hintStyle:
                            Potatuhs.body(size: 13, color: Potatuhs.textFaint),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Potatuhs.gold, width: 1.5),
                        ),
                      ),
                      onSubmitted: (_) => _sendNote(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Send note',
                    onPressed: _sendNote,
                    icon: const Icon(Icons.send_rounded,
                        color: Potatuhs.gold, size: 22),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Note sent — thank you!',
                textAlign: TextAlign.center,
                style: Potatuhs.body(size: 12.5, color: Potatuhs.gold),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ThumbButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ThumbButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 26),
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
