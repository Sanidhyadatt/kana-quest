class SeedKanaCard {
  final String character;
  final String romaji;
  final String mnemonic;
  final int row;
  final int script; // 0: Hiragana, 1: Katakana, 2: Kanji
  final String? relatedWords;

  const SeedKanaCard({
    required this.character,
    required this.romaji,
    required this.mnemonic,
    required this.row,
    this.script = 0,
    this.relatedWords,
  });
}

const seedKanaCards = <SeedKanaCard>[
  // Row 0: vowels
  SeedKanaCard(character: 'あ', romaji: 'a', mnemonic: 'A red apple opens wide for ah.', row: 0, relatedWords: 'あひる|A-hi-ru (Duck);あおい|A-o-i (Blue)'),
  SeedKanaCard(character: 'い', romaji: 'i', mnemonic: 'Two eels stand like ee teeth.', row: 0, relatedWords: 'いち|I-chi (One);いぬ|I-nu (Dog)'),
  SeedKanaCard(character: 'う', romaji: 'u', mnemonic: 'A tiny u-shaped bird says oo.', row: 0, relatedWords: 'うし|U-shi (Cow);うみ|U-mi (Sea)'),
  SeedKanaCard(character: 'え', romaji: 'e', mnemonic: 'An energetic extra says eh!', row: 0, relatedWords: 'えき|E-ki (Station)'),
  SeedKanaCard(character: 'お', romaji: 'o', mnemonic: 'An old man with a cane says oh.', row: 0, relatedWords: 'おに|O-ni (Ogre);おんがく|On-ga-ku (Music)'),

  // Row 1: ka row
  SeedKanaCard(character: 'か', romaji: 'ka', mnemonic: 'A kite with a hook says ka.', row: 1, relatedWords: 'かさ|Ka-sa (Umbrella);かめ|Ka-me (Turtle)'),
  SeedKanaCard(character: 'き', romaji: 'ki', mnemonic: 'A key with two teeth says ki.', row: 1, relatedWords: 'きつね|Ki-tsu-ne (Fox);き|Ki (Tree)'),
  SeedKanaCard(character: 'く', romaji: 'ku', mnemonic: 'A cuckoo beak bends for ku.', row: 1, relatedWords: 'くるま|Ku-ru-ma (Car);くつ|Ku-tsu (Shoes)'),
  SeedKanaCard(character: 'け', romaji: 'ke', mnemonic: 'A keg with an open lid says ke.', row: 1, relatedWords: 'けしごむ|Ke-shi-go-mu (Eraser)'),
  SeedKanaCard(character: 'こ', romaji: 'ko', mnemonic: 'Two coin strokes make ko.', row: 1, relatedWords: 'こころ|Ko-ko-ro (Heart);こども|Ko-do-mo (Child)'),

  // Row 2: sa row
  SeedKanaCard(character: 'さ', romaji: 'sa', mnemonic: 'A saw blade shape whispers sa.', row: 2, relatedWords: 'さかな|Sa-ka-na (Fish)'),
  SeedKanaCard(character: 'し', romaji: 'shi', mnemonic: 'A smiling fishhook says shi.', row: 2, relatedWords: 'しお|Shi-o (Salt)'),
  SeedKanaCard(character: 'す', romaji: 'su', mnemonic: 'A super needle loop says su.', row: 2, relatedWords: 'すいか|Su-i-ka (Watermelon)'),
  SeedKanaCard(character: 'せ', romaji: 'se', mnemonic: 'A set of shelves says se.', row: 2, relatedWords: 'せなか|Se-na-ka (Back)'),
  SeedKanaCard(character: 'そ', romaji: 'so', mnemonic: 'A sewing thread swirl says so.', row: 2, relatedWords: 'そら|So-ra (Sky)'),

  // Row 3: ta row
  SeedKanaCard(character: 'た', romaji: 'ta', mnemonic: 'A tall tower shape says ta.', row: 3, relatedWords: 'たまご|Ta-ma-go (Egg)'),
  SeedKanaCard(character: 'ち', romaji: 'chi', mnemonic: 'A cheerleader with a curl says chi.', row: 3, relatedWords: 'ちず|Chi-zu (Map)'),
  SeedKanaCard(character: 'つ', romaji: 'tsu', mnemonic: 'A tsunami wave crest says tsu.', row: 3, relatedWords: 'つくえ|Tsu-ku-e (Desk)'),
  SeedKanaCard(character: 'て', romaji: 'te', mnemonic: 'A hand with fingers says te.', row: 3, relatedWords: 'てがみ|Te-ga-mi (Letter)'),
  SeedKanaCard(character: 'と', romaji: 'to', mnemonic: 'A toe and a step line say to.', row: 3, relatedWords: 'とり|To-ri (Bird)'),

  // Row 4: na row
  SeedKanaCard(character: 'な', romaji: 'na', mnemonic: 'A knot with a tail says na.', row: 4, relatedWords: 'なつ|Na-tsu (Summer)'),
  SeedKanaCard(character: 'に', romaji: 'ni', mnemonic: 'Knee-level lines say ni.', row: 4, relatedWords: 'にく|Ni-ku (Meat)'),
  SeedKanaCard(character: 'ぬ', romaji: 'nu', mnemonic: 'A noodle knot loop says nu.', row: 4, relatedWords: 'ぬりえ|Nu-ri-e (Coloring book)'),
  SeedKanaCard(character: 'ね', romaji: 'ne', mnemonic: 'A net with a loop says ne.', row: 4, relatedWords: 'ねこ|Ne-ko (Cat)'),
  SeedKanaCard(character: 'の', romaji: 'no', mnemonic: 'A no-entry spiral says no.', row: 4, relatedWords: 'のり|No-ri (Seaweed)'),

  // Row 5: ha row
  SeedKanaCard(character: 'は', romaji: 'ha', mnemonic: 'A hat on a post says ha.', row: 5, relatedWords: 'はな|Ha-na (Flower)'),
  SeedKanaCard(character: 'ひ', romaji: 'hi', mnemonic: 'A hill with a fold says hi.', row: 5, relatedWords: 'ひつじ|Hi-tsu-ji (Sheep)'),
  SeedKanaCard(character: 'ふ', romaji: 'fu', mnemonic: 'A floating feather says fu.', row: 5, relatedWords: 'ふね|Fu-ne (Boat)'),
  SeedKanaCard(character: 'へ', romaji: 'he', mnemonic: 'A mountain peak says he.', row: 5, relatedWords: 'へび|He-bi (Snake)'),
  SeedKanaCard(character: 'ほ', romaji: 'ho', mnemonic: 'A hoop with a pole says ho.', row: 5, relatedWords: 'ほし|Ho-shi (Star)'),

  // Row 6: ma row
  SeedKanaCard(character: 'ま', romaji: 'ma', mnemonic: 'A map fold says ma.', row: 6, relatedWords: 'まつ|Ma-tsu (Pine tree)'),
  SeedKanaCard(character: 'み', romaji: 'mi', mnemonic: 'A musical curl says mi.', row: 6, relatedWords: 'みみ|Mi-mi (Ear)'),
  SeedKanaCard(character: 'む', romaji: 'mu', mnemonic: 'A mooing cow face loop says mu.', row: 6, relatedWords: 'むし|Mu-shi (Insect)'),
  SeedKanaCard(character: 'め', romaji: 'me', mnemonic: 'A messy knot says me.', row: 6, relatedWords: 'め|Me (Eye)'),
  SeedKanaCard(character: 'も', romaji: 'mo', mnemonic: 'More lines and a hook say mo.', row: 6, relatedWords: 'もり|Mo-ri (Forest)'),

  // Row 7: ya row
  SeedKanaCard(character: 'や', romaji: 'ya', mnemonic: 'A yacht mast shape says ya.', row: 7, relatedWords: 'やま|Ya-ma (Mountain)'),
  SeedKanaCard(character: 'ゆ', romaji: 'yu', mnemonic: 'A curved youth path says yu.', row: 7, relatedWords: 'ゆき|Yu-ki (Snow)'),
  SeedKanaCard(character: 'よ', romaji: 'yo', mnemonic: 'A yo-yo string with bars says yo.', row: 7, relatedWords: 'よる|Yo-ru (Night)'),

  // Row 8: ra row
  SeedKanaCard(character: 'ら', romaji: 'ra', mnemonic: 'A rabbit ear curve says ra.', row: 8, relatedWords: 'らくだ|Ra-ku-da (Camel)'),
  SeedKanaCard(character: 'り', romaji: 'ri', mnemonic: 'Two reeds standing say ri.', row: 8, relatedWords: 'りんご|Rin-go (Apple)'),
  SeedKanaCard(character: 'る', romaji: 'ru', mnemonic: 'A looped road says ru.', row: 8, relatedWords: 'るす|Ru-su (Away from home)'),
  SeedKanaCard(character: 'れ', romaji: 're', mnemonic: 'A red ribbon stroke says re.', row: 8, relatedWords: 'れいぞうこ|Re-i-zo-u-ko (Refrigerator)'),
  SeedKanaCard(character: 'ろ', romaji: 'ro', mnemonic: 'A road corner says ro.', row: 8, relatedWords: 'ろけっと|Ro-ke-tto (Rocket)'),

  // Row 9: wa row
  SeedKanaCard(character: 'わ', romaji: 'wa', mnemonic: 'A winding path says wa.', row: 9, relatedWords: 'わに|Wa-ni (Crocodile)'),
  SeedKanaCard(character: 'を', romaji: 'wo', mnemonic: 'A swooping stroke says wo.', row: 9, relatedWords: 'ほんをよむ|Hon-o-yo-mu (Read a book)'),

  // Row 10: n
  SeedKanaCard(character: 'ん', romaji: 'n', mnemonic: 'A final nasal curve says n.', row: 10, relatedWords: 'みかん|Mi-ka-n (Mandarin orange)'),
];

const seedKatakanaCards = <SeedKanaCard>[
  // Row 0
  SeedKanaCard(character: 'ア', romaji: 'a', mnemonic: 'Looks like an axe.', row: 0, script: 1, relatedWords: 'アイス|Ai-su (Ice cream)'),
  SeedKanaCard(character: 'イ', romaji: 'i', mnemonic: 'In-clined person.', row: 0, script: 1, relatedWords: 'イカ|I-ka (Squid)'),
  SeedKanaCard(character: 'ウ', romaji: 'u', mnemonic: 'Un-iversity cap.', row: 0, script: 1, relatedWords: 'ウニ|U-ni (Sea urchin)'),
  SeedKanaCard(character: 'エ', romaji: 'e', mnemonic: 'E-levator structure.', row: 0, script: 1, relatedWords: 'エンジニア|En-ji-ni-a (Engineer)'),
  SeedKanaCard(character: 'オ', romaji: 'o', mnemonic: 'O-n a surfboard.', row: 0, script: 1, relatedWords: 'オレンジ|O-ren-ji (Orange)'),
  
  // Row 1
  SeedKanaCard(character: 'カ', romaji: 'ka', mnemonic: 'Sharp Ka.', row: 1, script: 1, relatedWords: 'カメラ|Ka-me-ra (Camera)'),
  SeedKanaCard(character: 'キ', romaji: 'ki', mnemonic: 'Sharp Ki.', row: 1, script: 1, relatedWords: 'ギター|Gi-taa (Guitar)'),
  SeedKanaCard(character: 'ク', romaji: 'ku', mnemonic: 'Cook hat.', row: 1, script: 1, relatedWords: 'クリスマス|Ku-ri-su-ma-su (Christmas)'),
  SeedKanaCard(character: 'ケ', romaji: 'ke', mnemonic: 'K-like shape.', row: 1, script: 1, relatedWords: 'ケーキ|Kee-ki (Cake)'),
  SeedKanaCard(character: 'コ', romaji: 'ko', mnemonic: 'Corner.', row: 1, script: 1, relatedWords: 'コーヒー|Koo-hii (Coffee)'),

  // Row 2
  SeedKanaCard(character: 'サ', romaji: 'sa', mnemonic: 'Sharp Sa.', row: 2, script: 1, relatedWords: 'サラダ|Sa-ra-da (Salad)'),
  SeedKanaCard(character: 'シ', romaji: 'shi', mnemonic: 'Looking up.', row: 2, script: 1, relatedWords: 'シャツ|Sha-tsu (Shirt)'),
  SeedKanaCard(character: 'ス', romaji: 'su', mnemonic: 'Swimmer.', row: 2, script: 1, relatedWords: 'スキー|Su-kii (Skiing)'),
  SeedKanaCard(character: 'セ', romaji: 'se', mnemonic: 'Shelf parts.', row: 2, script: 1, relatedWords: 'センター|Sen-taa (Center)'),
  SeedKanaCard(character: 'ソ', romaji: 'so', mnemonic: 'Sewing needle.', row: 2, script: 1, relatedWords: 'ソフト|So-fu-to (Software)'),

  // Row 3
  SeedKanaCard(character: 'タ', romaji: 'ta', mnemonic: 'Tall tower.', row: 3, script: 1, relatedWords: 'タクシー|Ta-ku-shii (Taxi)'),
  SeedKanaCard(character: 'チ', romaji: 'chi', mnemonic: 'Cheerleader.', row: 3, script: 1, relatedWords: 'チーム|Chii-mu (Team)'),
  SeedKanaCard(character: 'ツ', romaji: 'tsu', mnemonic: 'Tsunami.', row: 3, script: 1, relatedWords: 'ツアー|Tsu-aa (Tour)'),
  SeedKanaCard(character: 'テ', romaji: 'te', mnemonic: 'Telephone poles.', row: 3, script: 1, relatedWords: 'テスト|Te-su-to (Test)'),
  SeedKanaCard(character: 'ト', romaji: 'to', mnemonic: 'Toe.', row: 3, script: 1, relatedWords: 'トイレ|To-i-re (Toilet)'),

  // Row 4
  SeedKanaCard(character: 'ナ', romaji: 'na', mnemonic: 'Number cross.', row: 4, script: 1, relatedWords: 'ナイフ|Na-i-fu (Knife)'),
  SeedKanaCard(character: 'ニ', romaji: 'ni', mnemonic: 'Two needles.', row: 4, script: 1, relatedWords: 'ニュース|Nyuu-su (News)'),
  SeedKanaCard(character: 'ヌ', romaji: 'nu', mnemonic: 'Noodle hook.', row: 4, script: 1, relatedWords: 'ヌイグルミ|Nu-i-gu-ru-mi (Plush)'),
  SeedKanaCard(character: 'ネ', romaji: 'ne', mnemonic: 'Next post.', row: 4, script: 1, relatedWords: 'ネクタイ|Ne-ku-ta-i (Necktie)'),
  SeedKanaCard(character: 'ノ', romaji: 'no', mnemonic: 'No entry line.', row: 4, script: 1, relatedWords: 'ノート|Noo-to (Notebook)'),

  // Row 5
  SeedKanaCard(character: 'ハ', romaji: 'ha', mnemonic: 'Hat legs.', row: 5, script: 1, relatedWords: 'パン|Pan (Bread)'),
  SeedKanaCard(character: 'ヒ', romaji: 'hi', mnemonic: 'Heeled shoe.', row: 5, script: 1, relatedWords: 'ヒーター|Hii-taa (Heater)'),
  SeedKanaCard(character: 'フ', romaji: 'fu', mnemonic: 'Flag pole.', row: 5, script: 1, relatedWords: 'フランス|Fu-ran-su (France)'),
  SeedKanaCard(character: 'へ', romaji: 'he', mnemonic: 'Mountain peak.', row: 5, script: 1, relatedWords: 'ヘルメット|He-ru-me-tto (Helmet)'),
  SeedKanaCard(character: 'ホ', romaji: 'ho', mnemonic: 'Holy cross.', row: 5, script: 1, relatedWords: 'ホテル|Ho-te-ru (Hotel)'),

  // Row 6
  SeedKanaCard(character: 'マ', romaji: 'ma', mnemonic: 'Mama\'s face.', row: 6, script: 1, relatedWords: 'マスカラ|Ma-su-ka-ra (Mascara)'),
  SeedKanaCard(character: 'ミ', romaji: 'mi', mnemonic: 'Three missiles.', row: 6, script: 1, relatedWords: 'ミルク|Mi-ru-ku (Milk)'),
  SeedKanaCard(character: 'ム', romaji: 'mu', mnemonic: 'Mooing cow.', row: 6, script: 1, relatedWords: 'ムード|Muu-do (Mood)'),
  SeedKanaCard(character: 'メ', romaji: 'me', mnemonic: 'Metal bars.', row: 6, script: 1, relatedWords: 'メニュー|Me-nyuu (Menu)'),
  SeedKanaCard(character: 'モ', romaji: 'mo', mnemonic: 'Moose antlers.', row: 6, script: 1, relatedWords: 'モデル|Mo-de-ru (Model)'),

  // Row 7
  SeedKanaCard(character: 'ヤ', romaji: 'ya', mnemonic: 'Yacht.', row: 7, script: 1, relatedWords: 'ヤンキー|Yan-kii (Delinquent)'),
  SeedKanaCard(character: 'ユ', romaji: 'yu', mnemonic: 'Unit.', row: 7, script: 1, relatedWords: 'ユニフォーム|Yu-ni-foo-mu (Uniform)'),
  SeedKanaCard(character: 'ヨ', romaji: 'yo', mnemonic: 'Yo-yo.', row: 7, script: 1, relatedWords: 'ヨーロッパ|Yo-ro-ppa (Europe)'),

  // Row 8
  SeedKanaCard(character: 'ラ', romaji: 'ra', mnemonic: 'Radio.', row: 8, script: 1, relatedWords: 'ラジオ|Ra-ji-o (Radio)'),
  SeedKanaCard(character: 'リ', romaji: 'ri', mnemonic: 'Reeds.', row: 8, script: 1, relatedWords: 'リーグ|Rii-gu (League)'),
  SeedKanaCard(character: 'ル', romaji: 'ru', mnemonic: 'Roots.', row: 8, script: 1, relatedWords: 'ルーム|Ruu-mu (Room)'),
  SeedKanaCard(character: 'レ', romaji: 're', mnemonic: 'Red line.', row: 8, script: 1, relatedWords: 'レタス|Re-ta-su (Lettuce)'),
  SeedKanaCard(character: 'ロ', romaji: 'ro', mnemonic: 'Road square.', row: 8, script: 1, relatedWords: 'ロボット|Ro-bo-tto (Robot)'),

  // Row 9
  SeedKanaCard(character: 'ワ', romaji: 'wa', mnemonic: 'Waist.', row: 9, script: 1, relatedWords: 'ワイン|Wa-i-n (Wine)'),
  SeedKanaCard(character: 'ヲ', romaji: 'wo', mnemonic: 'Warp.', row: 9, script: 1, relatedWords: 'ウォークマン|Woo-ku-man (Walkman)'),

  // Row 10
  SeedKanaCard(character: 'ン', romaji: 'n', mnemonic: 'Nasal curve.', row: 10, script: 1, relatedWords: 'パン|Pan (Bread)'),
];

const seedKanjiCards = <SeedKanaCard>[
  // Row 0: Basic 1
  SeedKanaCard(character: '一', romaji: 'ichi', mnemonic: 'One line.', row: 0, script: 2, relatedWords: '一つ|Hi-to-tsu (One);一日|I-chi-ni-chi (One day)'),
  SeedKanaCard(character: '二', romaji: 'ni', mnemonic: 'Two lines.', row: 0, script: 2, relatedWords: '二つ|Fu-ta-tsu (Two)'),
  SeedKanaCard(character: '三', romaji: 'san', mnemonic: 'Three lines.', row: 0, script: 2, relatedWords: '三つ|Mi-ttsu (Three)'),
  SeedKanaCard(character: '四', romaji: 'yon', mnemonic: 'A window with four panes.', row: 0, script: 2, relatedWords: '四つ|Yotsu (Four)'),
  SeedKanaCard(character: '五', romaji: 'go', mnemonic: 'A structural shape.', row: 0, script: 2, relatedWords: '五つ|I-tsu-tsu (Five)'),

  // Row 1: Basic 2
  SeedKanaCard(character: '六', romaji: 'roku', mnemonic: 'A hat on top.', row: 1, script: 2, relatedWords: '六つ|Mu-ttsu (Six)'),
  SeedKanaCard(character: '七', romaji: 'nana', mnemonic: 'Seven lines upside down.', row: 1, script: 2, relatedWords: '七つ|Na-na-tsu (Seven)'),
  SeedKanaCard(character: '八', romaji: 'hachi', mnemonic: 'Two sides opening.', row: 1, script: 2, relatedWords: '八つ|Ya-ttsu (Eight)'),
  SeedKanaCard(character: '九', romaji: 'kyuu', mnemonic: 'Nine curve.', row: 1, script: 2, relatedWords: '九つ|Ko-ko-no-tsu (Nine)'),
  SeedKanaCard(character: '十', romaji: 'juu', mnemonic: 'A cross.', row: 1, script: 2, relatedWords: '十|Too (Ten)'),

  // Row 2: Nature
  SeedKanaCard(character: '日', romaji: 'hi', mnemonic: 'The sun.', row: 2, script: 2, relatedWords: '日本|Ni-hon (Japan)'),
  SeedKanaCard(character: '月', romaji: 'tsuki', mnemonic: 'The moon.', row: 2, script: 2, relatedWords: '月曜日|Ge-tsu-yo-bi (Monday)'),
  SeedKanaCard(character: '火', romaji: 'hi', mnemonic: 'Fire.', row: 2, script: 2, relatedWords: '火曜日|Ka-yo-bi (Tuesday)'),
  SeedKanaCard(character: '水', romaji: 'mizu', mnemonic: 'Water.', row: 2, script: 2, relatedWords: '水曜日|Su-i-yo-bi (Wednesday)'),
  SeedKanaCard(character: '木', romaji: 'ki', mnemonic: 'Tree.', row: 2, script: 2, relatedWords: '木曜日|Mo-ku-yo-bi (Thursday)'),
  SeedKanaCard(character: '金', romaji: 'kane', mnemonic: 'Gold/Money.', row: 2, script: 2, relatedWords: '金曜日|Kin-yo-bi (Friday)'),
  SeedKanaCard(character: '土', romaji: 'tsuchi', mnemonic: 'Soil.', row: 2, script: 2, relatedWords: '土曜日|Do-yo-bi (Saturday)'),

  // Row 3: Directions
  SeedKanaCard(character: '上', romaji: 'ue', mnemonic: 'Above the line.', row: 3, script: 2, relatedWords: '上手|Jou-zu (Skilled)'),
  SeedKanaCard(character: '下', romaji: 'shita', mnemonic: 'Below the line.', row: 3, script: 2, relatedWords: '下手|He-ta (Unskilled)'),
  SeedKanaCard(character: '左', romaji: 'hidari', mnemonic: 'Left side.', row: 3, script: 2, relatedWords: '左側|Hi-da-ri-ga-wa (Left side)'),
  SeedKanaCard(character: '右', romaji: 'migi', mnemonic: 'Right side.', row: 3, script: 2, relatedWords: '右側|Mi-gi-ga-wa (Right side)'),
  SeedKanaCard(character: '中', romaji: 'naka', mnemonic: 'Middle.', row: 3, script: 2, relatedWords: '中国|Chu-u-go-ku (China)'),
];
