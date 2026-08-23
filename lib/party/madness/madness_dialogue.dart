import '../../games/mini_game.dart';
import '../screens/party_dialogue.dart';

/// Host beats for MINIGAME MADNESS. Butter MCs — smooth, BRIEF, never winks;
/// "uhhh…" belongs to Russ ALONE (voice law, Brett 2026-07-07).

/// The opening ceremony: what madness is, in two beats.
List<DialogueBeat> madnessOpeningBeats(int spinsPerPlayer, int totalRounds) => [
      DialogueBeat(
        kCharButter,
        'No board tonight. Three wheels — category, scale, game. '
        '$totalRounds rounds. Highest total takes it.',
        CharacterMood.smug,
      ),
      const DialogueBeat(
        kCharRuss,
        'uhhh… so I just spin, and then a game happens? Any game? From '
        'anywhere in the universe? …okay yes, I love it.',
        CharacterMood.excited,
      ),
      DialogueBeat(
        kCharButter,
        '$spinsPerPlayer spin${spinsPerPlayer == 1 ? '' : 's'} each. '
        'Make them count.',
        CharacterMood.neutral,
      ),
    ];

/// Butter announces the landed game before it launches. Data-driven so all
/// ~125 games get an in-voice intro without a hand-written bank.
DialogueBeat madnessGameIntroBeat(MiniGameSpec spec) => DialogueBeat(
      kCharButter,
      '${spec.name}. ${spec.howToWin}',
      CharacterMood.neutral,
    );

/// The between-rounds ceremony line.
DialogueBeat madnessCeremonyBeat({
  required String leaderName,
  required int roundsLeft,
}) {
  if (roundsLeft <= 0) {
    return const DialogueBeat(
      kCharButter,
      "That was the last one. Let's see the damage.",
      CharacterMood.smug,
    );
  }
  return DialogueBeat(
    kCharButter,
    '$leaderName leads. $roundsLeft round${roundsLeft == 1 ? '' : 's'} left — '
    'plenty of madness to go.',
    CharacterMood.neutral,
  );
}

/// The final crown.
DialogueBeat madnessFinalBeat(String winnerName) => DialogueBeat(
      kCharButter,
      '$winnerName. That was the whole story.',
      CharacterMood.smug,
    );
