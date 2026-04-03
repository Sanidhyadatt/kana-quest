/// Stroke count and pronunciation hint for each Japanese character.
class KanaCharacterInfo {
  const KanaCharacterInfo({
    required this.strokeCount,
    required this.soundsLike,
    this.reading, // Optional hiragana/katakana reading used for TTS (Kanji)
  });

  final int strokeCount;
  final String soundsLike;
  /// For Kanji: the hiragana reading to pass to TTS instead of the raw character.
  /// For Kana: null (the character itself is spoken correctly).
  final String? reading;
}

const Map<String, KanaCharacterInfo> kanaCharacterInfo = {
  // ── Hiragana Vowels (A-row) ────────────────────────────────
  'あ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "ah" in father'),
  'い': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ee" in see'),
  'う': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "oo" in moon'),
  'え': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "eh" in bed'),
  'お': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "oh" in open'),
  // ── Hiragana Ka-row ────────────────────────────────────────
  'か': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "ka" in car'),
  'き': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Sounds like "ki" in key'),
  'く': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "ku" in cool'),
  'け': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "ke" in keg'),
  'こ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ko" in copy'),
  // ── Hiragana Sa-row ────────────────────────────────────────
  'さ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "sa" in saw'),
  'し': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "shi" in she'),
  'す': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "su" in sue'),
  'せ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "se" in set'),
  'そ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "so" in so!'),
  // ── Hiragana Ta-row ────────────────────────────────────────
  'た': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Sounds like "ta" in task'),
  'ち': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "chi" in cheese'),
  'つ': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "tsu" in tsunami'),
  'て': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "te" in ten'),
  'と': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "to" in tone'),
  // ── Hiragana Na-row ────────────────────────────────────────
  'な': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Sounds like "na" in nap'),
  'に': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "ni" in knee'),
  'ぬ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "nu" in new'),
  'ね': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ne" in net'),
  'の': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "no" in note'),
  // ── Hiragana Ha-row ────────────────────────────────────────
  'は': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "ha" in ha!'),
  'ひ': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "hi" in he'),
  'ふ': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Sounds like "fu" in food'),
  'へ': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "he" in hey'),
  'ほ': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Sounds like "ho" in hope'),
  // ── Hiragana Ma-row ────────────────────────────────────────
  'ま': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "ma" in mom'),
  'み': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "mi" in me'),
  'む': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "mu" in moo'),
  'め': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "me" in met'),
  'も': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "mo" in more'),
  // ── Hiragana Ya-row ────────────────────────────────────────
  'や': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "ya" in yard'),
  'ゆ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "yu" in youth'),
  'よ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "yo" in yoga'),
  // ── Hiragana Ra-row ────────────────────────────────────────
  'ら': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ra" in rock'),
  'り': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ri" in reef'),
  'る': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "ru" in root'),
  'れ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "re" in red'),
  'ろ': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "ro" in road'),
  // ── Hiragana Wa-row & N ────────────────────────────────────
  'わ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "wa" in water'),
  'を': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "wo" in won'),
  'ん': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "n" in pan'),

  // ── Katakana Vowels (A-row) ────────────────────────────────
  'ア': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ah" in father'),
  'イ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ee" in see'),
  'ウ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "oo" in moon'),
  'エ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "eh" in bed'),
  'オ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "oh" in open'),
  // ── Katakana Ka-row ────────────────────────────────────────
  'カ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ka" in car'),
  'キ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "ki" in key'),
  'ク': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ku" in cool'),
  'ケ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "ke" in keg'),
  'コ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ko" in copy'),
  // ── Katakana Sa-row ────────────────────────────────────────
  'サ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "sa" in saw'),
  'シ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "shi" in she'),
  'ス': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "su" in sue'),
  'セ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "se" in set'),
  'ソ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "so" in so!'),
  // ── Katakana Ta-row ────────────────────────────────────────
  'タ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "ta" in task'),
  'チ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "chi" in cheese'),
  'ツ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "tsu" in tsunami'),
  'テ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "te" in ten'),
  'ト': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "to" in tone'),
  // ── Katakana Na-row ────────────────────────────────────────
  'ナ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "na" in nap'),
  'ニ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ni" in knee'),
  'ヌ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "nu" in new'),
  'ネ': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Sounds like "ne" in net'),
  'ノ': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "no" in note'),
  // ── Katakana Ha-row ────────────────────────────────────────
  'ハ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ha" in ha!'),
  'ヒ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "hi" in he'),
  'フ': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "fu" in food'),
  'ヘ': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "he" in hey'),
  'ホ': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Sounds like "ho" in hope'),
  // ── Katakana Ma-row ────────────────────────────────────────
  'マ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ma" in mom'),
  'ミ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "mi" in me'),
  'ム': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "mu" in moo'),
  'メ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "me" in met'),
  'モ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "mo" in more'),
  // ── Katakana Ya-row ────────────────────────────────────────
  'ヤ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ya" in yard'),
  'ユ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "yu" in youth'),
  'ヨ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "yo" in yoga'),
  // ── Katakana Ra-row ────────────────────────────────────────
  'ラ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ra" in rock'),
  'リ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ri" in reef'),
  'ル': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "ru" in root'),
  'レ': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Sounds like "re" in red'),
  'ロ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "ro" in road'),
  // ── Katakana Wa-row & N ────────────────────────────────────
  'ワ': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "wa" in water'),
  'ヲ': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Sounds like "wo" in won'),
  'ン': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Sounds like "n" in pan'),

  // ── Kanji (with hiragana reading for TTS) ──────────────────
  '一': KanaCharacterInfo(strokeCount: 1, soundsLike: 'Ichi — One', reading: 'いち'),
  '二': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Ni — Two', reading: 'に'),
  '三': KanaCharacterInfo(strokeCount: 3, soundsLike: 'San — Three', reading: 'さん'),
  '四': KanaCharacterInfo(strokeCount: 5, soundsLike: 'Yon/Shi — Four', reading: 'よん'),
  '五': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Go — Five', reading: 'ご'),
  '六': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Roku — Six', reading: 'ろく'),
  '七': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Nana/Shichi — Seven', reading: 'なな'),
  '八': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Hachi — Eight', reading: 'はち'),
  '九': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Kyuu/Ku — Nine', reading: 'きゅう'),
  '十': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Juu — Ten', reading: 'じゅう'),
  '日': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Nichi/Hi — Sun, Day', reading: 'にち'),
  '月': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Getsu/Tsuki — Moon, Month', reading: 'つき'),
  '火': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Ka/Hi — Fire', reading: 'ひ'),
  '水': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Sui/Mizu — Water', reading: 'みず'),
  '木': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Moku/Ki — Tree, Wood', reading: 'き'),
  '金': KanaCharacterInfo(strokeCount: 8, soundsLike: 'Kin/Kane — Gold, Money', reading: 'かね'),
  '土': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Do/Tsuchi — Soil, Earth', reading: 'つち'),
  '上': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Ue/Jou — Above', reading: 'うえ'),
  '下': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Shita/Ka — Below', reading: 'した'),
  '左': KanaCharacterInfo(strokeCount: 5, soundsLike: 'Hidari — Left', reading: 'ひだり'),
  '右': KanaCharacterInfo(strokeCount: 5, soundsLike: 'Migi — Right', reading: 'みぎ'),
  '中': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Naka/Chuu — Middle', reading: 'なか'),
  '山': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Yama/San — Mountain', reading: 'やま'),
  '川': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Kawa/Sen — River', reading: 'かわ'),
  '大': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Oo/Dai — Big, Large', reading: 'おおきい'),
  '小': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Ko/Shoo — Small', reading: 'ちいさい'),
  '人': KanaCharacterInfo(strokeCount: 2, soundsLike: 'Hito/Jin — Person', reading: 'ひと'),
  '口': KanaCharacterInfo(strokeCount: 3, soundsLike: 'Kuchi/Kou — Mouth', reading: 'くち'),
  '目': KanaCharacterInfo(strokeCount: 5, soundsLike: 'Me/Moku — Eye', reading: 'め'),
  '耳': KanaCharacterInfo(strokeCount: 6, soundsLike: 'Mimi/Ji — Ear', reading: 'みみ'),
  '手': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Te/Shu — Hand', reading: 'て'),
  '足': KanaCharacterInfo(strokeCount: 7, soundsLike: 'Ashi/Soku — Foot, Leg', reading: 'あし'),
  '犬': KanaCharacterInfo(strokeCount: 4, soundsLike: 'Inu/Ken — Dog', reading: 'いぬ'),
  '猫': KanaCharacterInfo(strokeCount: 11, soundsLike: 'Neko — Cat', reading: 'ねこ'),
  '魚': KanaCharacterInfo(strokeCount: 11, soundsLike: 'Sakana/Gyo — Fish', reading: 'さかな'),
};