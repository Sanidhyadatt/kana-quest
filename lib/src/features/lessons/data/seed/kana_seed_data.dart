class SeedKanaCard {
  const SeedKanaCard({
    required this.character,
    required this.romaji,
    required this.mnemonic,
    required this.row,
  });

  final String character;
  final String romaji;
  final String mnemonic;
  final int row;
}

const seedKanaCards = <SeedKanaCard>[
  // Row 0: vowels
  SeedKanaCard(character: 'あ', romaji: 'a', mnemonic: 'A red apple opens wide for ah.', row: 0),
  SeedKanaCard(character: 'い', romaji: 'i', mnemonic: 'Two eels stand like ee teeth.', row: 0),
  SeedKanaCard(character: 'う', romaji: 'u', mnemonic: 'A tiny u-shaped bird says oo.', row: 0),
  SeedKanaCard(character: 'え', romaji: 'e', mnemonic: 'An energetic extra says eh!', row: 0),
  SeedKanaCard(character: 'お', romaji: 'o', mnemonic: 'An old man with a cane says oh.', row: 0),

  // Row 1: ka row
  SeedKanaCard(character: 'か', romaji: 'ka', mnemonic: 'A kite with a hook says ka.', row: 1),
  SeedKanaCard(character: 'き', romaji: 'ki', mnemonic: 'A key with two teeth says ki.', row: 1),
  SeedKanaCard(character: 'く', romaji: 'ku', mnemonic: 'A cuckoo beak bends for ku.', row: 1),
  SeedKanaCard(character: 'け', romaji: 'ke', mnemonic: 'A keg with an open lid says ke.', row: 1),
  SeedKanaCard(character: 'こ', romaji: 'ko', mnemonic: 'Two coin strokes make ko.', row: 1),

  // Row 2: sa row
  SeedKanaCard(character: 'さ', romaji: 'sa', mnemonic: 'A saw blade shape whispers sa.', row: 2),
  SeedKanaCard(character: 'し', romaji: 'shi', mnemonic: 'A smiling fishhook says shi.', row: 2),
  SeedKanaCard(character: 'す', romaji: 'su', mnemonic: 'A super needle loop says su.', row: 2),
  SeedKanaCard(character: 'せ', romaji: 'se', mnemonic: 'A set of shelves says se.', row: 2),
  SeedKanaCard(character: 'そ', romaji: 'so', mnemonic: 'A sewing thread swirl says so.', row: 2),

  // Row 3: ta row
  SeedKanaCard(character: 'た', romaji: 'ta', mnemonic: 'A tall tower shape says ta.', row: 3),
  SeedKanaCard(character: 'ち', romaji: 'chi', mnemonic: 'A cheerleader with a curl says chi.', row: 3),
  SeedKanaCard(character: 'つ', romaji: 'tsu', mnemonic: 'A tsunami wave crest says tsu.', row: 3),
  SeedKanaCard(character: 'て', romaji: 'te', mnemonic: 'A hand with fingers says te.', row: 3),
  SeedKanaCard(character: 'と', romaji: 'to', mnemonic: 'A toe and a step line say to.', row: 3),

  // Row 4: na row
  SeedKanaCard(character: 'な', romaji: 'na', mnemonic: 'A knot with a tail says na.', row: 4),
  SeedKanaCard(character: 'に', romaji: 'ni', mnemonic: 'Knee-level lines say ni.', row: 4),
  SeedKanaCard(character: 'ぬ', romaji: 'nu', mnemonic: 'A noodle knot loop says nu.', row: 4),
  SeedKanaCard(character: 'ね', romaji: 'ne', mnemonic: 'A net with a loop says ne.', row: 4),
  SeedKanaCard(character: 'の', romaji: 'no', mnemonic: 'A no-entry spiral says no.', row: 4),

  // Row 5: ha row
  SeedKanaCard(character: 'は', romaji: 'ha', mnemonic: 'A hat on a post says ha.', row: 5),
  SeedKanaCard(character: 'ひ', romaji: 'hi', mnemonic: 'A hill with a fold says hi.', row: 5),
  SeedKanaCard(character: 'ふ', romaji: 'fu', mnemonic: 'A floating feather says fu.', row: 5),
  SeedKanaCard(character: 'へ', romaji: 'he', mnemonic: 'A mountain peak says he.', row: 5),
  SeedKanaCard(character: 'ほ', romaji: 'ho', mnemonic: 'A hoop with a pole says ho.', row: 5),

  // Row 6: ma row
  SeedKanaCard(character: 'ま', romaji: 'ma', mnemonic: 'A map fold says ma.', row: 6),
  SeedKanaCard(character: 'み', romaji: 'mi', mnemonic: 'A musical curl says mi.', row: 6),
  SeedKanaCard(character: 'む', romaji: 'mu', mnemonic: 'A mooing cow face loop says mu.', row: 6),
  SeedKanaCard(character: 'め', romaji: 'me', mnemonic: 'A messy knot says me.', row: 6),
  SeedKanaCard(character: 'も', romaji: 'mo', mnemonic: 'More lines and a hook say mo.', row: 6),

  // Row 7: ya row
  SeedKanaCard(character: 'や', romaji: 'ya', mnemonic: 'A yacht mast shape says ya.', row: 7),
  SeedKanaCard(character: 'ゆ', romaji: 'yu', mnemonic: 'A curved youth path says yu.', row: 7),
  SeedKanaCard(character: 'よ', romaji: 'yo', mnemonic: 'A yo-yo string with bars says yo.', row: 7),

  // Row 8: ra row
  SeedKanaCard(character: 'ら', romaji: 'ra', mnemonic: 'A rabbit ear curve says ra.', row: 8),
  SeedKanaCard(character: 'り', romaji: 'ri', mnemonic: 'Two reeds standing say ri.', row: 8),
  SeedKanaCard(character: 'る', romaji: 'ru', mnemonic: 'A looped road says ru.', row: 8),
  SeedKanaCard(character: 'れ', romaji: 're', mnemonic: 'A red ribbon stroke says re.', row: 8),
  SeedKanaCard(character: 'ろ', romaji: 'ro', mnemonic: 'A road corner says ro.', row: 8),

  // Row 9: wa row
  SeedKanaCard(character: 'わ', romaji: 'wa', mnemonic: 'A winding path says wa.', row: 9),
  SeedKanaCard(character: 'を', romaji: 'wo', mnemonic: 'A swooping stroke says wo.', row: 9),

  // Row 10: n
  SeedKanaCard(character: 'ん', romaji: 'n', mnemonic: 'A final nasal curve says n.', row: 10),
];
