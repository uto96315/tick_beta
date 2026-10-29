// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Ozio';

  @override
  String get tagline => '怠惰な人のためのタイマー';

  @override
  String get home => 'ホーム';

  @override
  String get timer => 'タイマー';

  @override
  String get history => '履歴';

  @override
  String get settings => '設定';

  @override
  String get start => 'はじめる';

  @override
  String get endTimeMode => '終了時刻';

  @override
  String get durationMode => '時間で指定';

  @override
  String get interval => '区切り';

  @override
  String get custom => 'カスタム';

  @override
  String get useShift => '今日の予定を使う';

  @override
  String get remaining => '残り';

  @override
  String get chunks => '区切り';

  @override
  String get freeTitle => '自由だー！';

  @override
  String get freeBody => '今日のぶんは終わり。仕事じゃないことをしていい。';

  @override
  String get goHome => 'ホームへ';

  @override
  String get seeHistory => '履歴を見る';

  @override
  String get extend => '延長する';

  @override
  String get endEarly => '途中で終わる';

  @override
  String get earlyDone => '今日はここまで。';

  @override
  String get noSession => 'まだ始まっていない。';

  @override
  String get breaksKeepGoing => '休憩中も時間は進む。終了時刻は動かない。';

  @override
  String get noPause => '一時停止はない。終わるまで進む。';

  @override
  String get notifyTitle => '通知';

  @override
  String get notifyChunk => '区切り完了';

  @override
  String get notifyEnd => 'タイマー終了';

  @override
  String get sound => '音';

  @override
  String get vibration => '振動';

  @override
  String get vibrationHelp => 'アプリを開いているときの振動です。通知の振動はiPhoneのマナーモードに従います。';

  @override
  String get endAction => '終了したとき';

  @override
  String get actionCelebration => '解放演出';

  @override
  String get actionHome => 'ホームへ';

  @override
  String get actionHistory => '履歴を開く';

  @override
  String get visual => 'タイマーの見た目';

  @override
  String get visualHelp => 'プロトタイプです。切り替えて比べてください。';

  @override
  String get visualTiles => 'タイル';

  @override
  String get visualMap => 'ステージ';

  @override
  String get visualCharacter => 'キャラクター';

  @override
  String get visualGauge => 'ゲージ';

  @override
  String get showCharacter => 'キャラクターを表示';

  @override
  String get autoStart => '予定時刻に自動開始';

  @override
  String get autoStartHelp => '自動で始まるのは、アプリを開いているときだけ。閉じていたときは、次に開いたとき確認します。';

  @override
  String get schedule => '勤務スケジュール';

  @override
  String get account => 'アカウント';

  @override
  String get premium => 'プレミアム';

  @override
  String get camouflage => 'カモフラージュ';

  @override
  String get fakeCall => '偽着信';

  @override
  String get trigger => '戻し方';

  @override
  String get triggerCorner => '右上をタップ';

  @override
  String get triggerLong => '長押し';

  @override
  String get triggerSwipe => '下にスワイプ';

  @override
  String get camouflageHint => 'アプリ内の静かな画面に切り替わります。iPhoneのホーム画面そのものにはなりません。';

  @override
  String get backHintCorner => '右上をタップすると戻る';

  @override
  String get backHintLong => '長押しで戻る';

  @override
  String get backHintSwipe => '下にスワイプで戻る';

  @override
  String get callNow => '今すぐ';

  @override
  String get callLater => '予約';

  @override
  String get callers => '発信者';

  @override
  String get weeklyLimit => '無料は週1回';

  @override
  String get unlimited => '無制限';

  @override
  String get weekReset => '無料分は毎週月曜に戻ります。';

  @override
  String get answer => '応答';

  @override
  String get decline => '拒否';

  @override
  String get mute => 'ミュート';

  @override
  String get endCall => '終了';

  @override
  String get incoming => '着信中';

  @override
  String get mobile => 'モバイル';

  @override
  String get startPromptTitle => 'この勤務を始めますか？';

  @override
  String get startNow => '始める';

  @override
  String get notToday => '今日はしない';

  @override
  String get patterns => '勤務パターン';

  @override
  String get weekdays => '曜日';

  @override
  String get holiday => '休日';

  @override
  String get customDay => 'この日だけ変更';

  @override
  String get add => '追加';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get cancel => 'キャンセル';

  @override
  String get name => '名前';

  @override
  String get startTime => '開始';

  @override
  String get endTime => '終了';

  @override
  String get offDay => '休み';

  @override
  String get breakLabel => '休憩';

  @override
  String get addBreak => '休憩を追加';

  @override
  String get noBreaks => '休憩なし';

  @override
  String get overtime => '残業';

  @override
  String get overtimeNone => 'なし';

  @override
  String get memo => '一言メモ';

  @override
  String get memoHint => '残したければ、ひとこと';

  @override
  String get computedNote => '残業と休憩合計は、入っている時刻から計算します。';

  @override
  String get statusDone => '通常終了';

  @override
  String get statusEarly => '途中終了';

  @override
  String get extensions => '延長';

  @override
  String get originalEnd => '当初の終了';

  @override
  String get actualStart => '実際の開始';

  @override
  String get actualEnd => '実際の終了';

  @override
  String get achievement => '達成';

  @override
  String get anonymous => '匿名で利用中';

  @override
  String get registerEmail => 'メールで登録して引き継ぐ';

  @override
  String get registerGoogle => 'Googleで登録して引き継ぐ';

  @override
  String get signInEmail => 'メールでログイン';

  @override
  String get signInGoogle => 'Googleでログイン';

  @override
  String get signOut => 'ログアウト';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get deleteAccountBody => 'アカウントと、設定・履歴を削除します。';

  @override
  String get email => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get firebaseLocal => 'このiPhoneの中に保存しています。ログインにはFirebaseプロジェクトが必要です。';

  @override
  String get premiumPitch =>
      '買い切りです。偽着信が無制限になり、発信者、カモフラージュの画面、着信音、ひよこの口調が増えます。';

  @override
  String get premiumOwned => 'プレミアムは有効';

  @override
  String get buy => '購入する';

  @override
  String get restore => '購入を復元';

  @override
  String get priceFallback => '¥500';

  @override
  String get freeTier => '無料';

  @override
  String get languageFollows => '言語はiPhoneの設定に合わせます。';

  @override
  String get customMinutes => '区切りの分数';

  @override
  String get customExtend => '延長する分数';

  @override
  String get invalidMinutes => '1以上の分数を入れて';

  @override
  String get tooShort => '終了は、今から1分以上あとにして';

  @override
  String get limitReached => '今週の偽着信は使い切った';

  @override
  String get premiumRequired => 'プレミアムの機能です';

  @override
  String get encourage1 => 'もう少し。始めるところが一番むずかしい。';

  @override
  String get encourage2 => 'まだここにいる。それだけで十分えらい。';

  @override
  String get encourage3 => '未来の自分が感謝する。今は文句を言っていい。';

  @override
  String get encourage4 => 'あと一区切り。その先に出口がある。';

  @override
  String get encourage5 => '疲れていても、終わらせていい。';

  @override
  String get burstOne => '区切りクリア！';

  @override
  String get burstMany => '区切りクリア！';

  @override
  String get addCaller => '発信者を追加';

  @override
  String get callerName => '発信者の名前';

  @override
  String get photo => '写真';

  @override
  String get emptyHistory => 'まだ履歴がない。';

  @override
  String get running => '進行中';

  @override
  String get applyShift => '予定の開始時刻から進める';

  @override
  String get upcomingAuto => '予定時刻になったら、開いているあいだ自動で始まる';

  @override
  String get hours => '時間';

  @override
  String get mins => '分';

  @override
  String get mon => '月';

  @override
  String get tue => '火';

  @override
  String get wed => '水';

  @override
  String get thu => '木';

  @override
  String get fri => '金';

  @override
  String get sat => '土';

  @override
  String get sun => '日';

  @override
  String get authUnavailable => 'このログインはまだ使えない';

  @override
  String get authInvalid => 'メールアドレスを確認して';

  @override
  String get authWeak => 'パスワードは6文字以上';

  @override
  String get authExists => 'そのメールは登録済み。ログインして。';

  @override
  String get authWrong => 'メールかパスワードが違う';

  @override
  String get authRecent => '削除するには、もう一度ログインして';

  @override
  String get authCanceled => 'キャンセルした';

  @override
  String get authUnknown => '完了できなかった';

  @override
  String get purchaseUnavailable => 'App Storeの購入が使えない';

  @override
  String get offline => 'オフライン。このまま使えて、あとで同期する。';

  @override
  String get nextDay => '翌日';

  @override
  String get newPattern => 'パターンを追加';

  @override
  String get editPattern => 'パターンを編集';

  @override
  String get continueTimer => 'タイマーを開く';

  @override
  String get passwordHint => '6文字以上';

  @override
  String get linkKeeps => '登録すると、今の履歴と設定を引き継ぐ。';

  @override
  String get anonymousLoss => '匿名のまま消すと、再インストールでは戻らない。登録済みならログインで戻る。';

  @override
  String get switchHelp => '別のアカウントでログインすると、このiPhoneにはそのアカウントのデータが出る。';

  @override
  String get today => '今日';

  @override
  String get tomorrow => 'あした';

  @override
  String get stage => 'ステージ';

  @override
  String get muted => 'ミュート中';

  @override
  String get inCall => '通話中';

  @override
  String get noShiftNeeded => 'スケジュールがなくてもタイマーは使える。';

  @override
  String get intervalHelp => '最後の区切りは、残り時間に合わせて短くなる。';

  @override
  String get close => '閉じる';

  @override
  String get requiredName => '名前を入れて';

  @override
  String get scheduledCall => '着信を予約した';

  @override
  String get cancelCall => 'この予約を取り消す';

  @override
  String get googleMissing =>
      'Googleログインには、GoogleService-Info.plist の CLIENT_ID が必要です。';

  @override
  String get crossesMidnight => 'この勤務は日付をまたぐ';

  @override
  String get breakTotal => '休憩合計';

  @override
  String get status => '状態';

  @override
  String get rate => '達成率';

  @override
  String get extendTotal => '延長合計';

  @override
  String get pickEnd => '終了時刻';

  @override
  String get earlyBy => '予定より早く終了';

  @override
  String get localAccount => 'このiPhoneだけ';

  @override
  String get registered => 'ログイン中';

  @override
  String get overrides => '特別な日';

  @override
  String get addOverride => '日付を追加';

  @override
  String get deletePattern => 'パターンを削除';

  @override
  String get premiumCamouflage => '長押しとスワイプはプレミアム';

  @override
  String get premiumCallers => '発信者の追加はプレミアム';

  @override
  String get usedThisWeek => '今週の利用';

  @override
  String get ringing => '呼び出し中';

  @override
  String get notRunning => '未開始';

  @override
  String get startTimer => 'タイマーを開始';

  @override
  String get chunksAhead => 'あと';

  @override
  String get todayProgress => '本日の進捗';

  @override
  String get plannedEnd => '終了予定';

  @override
  String get extendChoose => '延長時間を選択してください';

  @override
  String get keepGoing => 'もうちょっとだけがんばろう！';

  @override
  String get historyWork => '勤務履歴';

  @override
  String get viewList => '一覧';

  @override
  String get viewCalendar => 'カレンダー';

  @override
  String get minuteChunk => '分刻み';

  @override
  String get hourChunk => '時間刻み';

  @override
  String get intervalCustom => '任意';

  @override
  String get nowChunk => 'いま';

  @override
  String get tutorialNext => '次へ';

  @override
  String get tutorialSkip => 'スキップ';

  @override
  String get tutorialStart => 'はじめる';

  @override
  String get tutorial1Title => '終わりまで、区切って進む';

  @override
  String get tutorial1Body => '終了時刻を決めると、そこまでを小さな区切りに分けます。';

  @override
  String get tutorial2Title => '区切りの長さ';

  @override
  String get tutorial2Body => 'ホームで 15分、30分、1時間、または好きな分数を選べます。';

  @override
  String get tutorial3Title => 'いま進んでいるところ';

  @override
  String get tutorial3Body => 'タイマーには「いま 16:10–16:30」のように、今の区切りの時間が出ます。';

  @override
  String get updateRequiredTitle => '更新してください';

  @override
  String get updateRequiredBody => 'このバージョンでは続けられません。';

  @override
  String get updateAvailableTitle => '新しいバージョンがあります';

  @override
  String get updateAvailableBody => '今のままでも使えます。';

  @override
  String get updateAction => '更新する';

  @override
  String get updateLater => 'あとで';

  @override
  String get chickNormal1 => '始めるところが、いちばんむずかしい。';

  @override
  String get chickNormal2 => 'だるくていい。座っていても、区切りは減る。';

  @override
  String get chickNormal3 => '定時まで、小さく刻んでいこう。';

  @override
  String get chickTired1 => 'まだ先は長い。でも、この区切りは終わる。';

  @override
  String get chickTired2 => 'やる気は出なくていい。時間のほうが先に減る。';

  @override
  String get chickTired3 => '座っているだけでも、進んではいる。';

  @override
  String get chickHappy1 => '少し進んだ。このペースでいいよ。';

  @override
  String get chickHappy2 => '悪くない。数字はちゃんと減っている。';

  @override
  String get chickHappy3 => 'この区切りが終われば、またひとつ減る。';

  @override
  String get chickCheer1 => '半分は過ぎた。景色が変わってきたね。';

  @override
  String get chickCheer2 => 'ここまで来たら、あとは時間が働く。';

  @override
  String get chickCheer3 => 'えらいよ。お世辞じゃなく、そう思う。';

  @override
  String get chickAttention1 => 'あと少し。出口が見えてきた。';

  @override
  String get chickAttention2 => 'もうほぼ終わり。力は入れなくていい。';

  @override
  String get chickAttention3 => 'この区切りを越えれば、今日はかなり終わり。';

  @override
  String get chickSurprise1 => '定時は過ぎている。まだいるんだね。';

  @override
  String get chickSurprise2 => '帰る時間は、もう来ているよ。';

  @override
  String get chickSurprise3 => '残業しているね。区切りは、まだ減る。';

  @override
  String get chickSleep1 => '休憩だよ。ここでは何もしなくていい。';

  @override
  String get chickSleep2 => '目を閉じていていい時間だよ。';

  @override
  String get chickSleep3 => '休みが終わるまで、このままでいい。';

  @override
  String get chickDone1 => '今日のぶんは、終わり。';

  @override
  String get chickDone2 => 'よく座っていた。もう仕事じゃなくていい。';

  @override
  String get chickDone3 => '自由だよ。帰っていい。';

  @override
  String get chickBack1 => 'タイマーは動いている。戻ったら続きから。';

  @override
  String get chickBack2 => '席を外しても、区切りは減っていく。';

  @override
  String get chickBack3 => 'こっちで進めておく。急いで戻らなくていい。';

  @override
  String get chickNotice1 => '区切りがひとつ終わった。次にいこう。';

  @override
  String get chickNotice2 => 'ちゃんと減っている。見てわかる。';

  @override
  String get chickNotice3 => 'ひとつ終わった。それだけでいい。';

  @override
  String get chickGoodjob1 => 'いくつも終わった。すごいとまでは言わないけど。';

  @override
  String get chickGoodjob2 => '進んでいるよ。自分で思っているより。';

  @override
  String get chickGoodjob3 => 'このまま座っていれば、また減る。';

  @override
  String get chickLove1 => '今日は、ここまででいい。';

  @override
  String get chickLove2 => 'よく終わらせた。えらいよ。';

  @override
  String get chickLove3 => 'もう、仕事の顔はしなくていい。';

  @override
  String get lookHome => 'ホーム';

  @override
  String get lookNotes => 'メモ';

  @override
  String get lookCalendar => 'カレンダー';

  @override
  String get premiumLooks => 'メモとカレンダーはプレミアム';

  @override
  String get chickVoiceTitle => 'ひよこの口調';

  @override
  String get voicePlain => 'ふつう';

  @override
  String get voiceLazy => 'もっとだるい';

  @override
  String get voiceKansai => '関西弁';

  @override
  String get voiceCustom => '自分のセリフ';

  @override
  String get premiumVoice => '口調の追加はプレミアム';

  @override
  String get customLine => 'ひよこに言わせる一言';

  @override
  String get moodHeavy => 'だるい';

  @override
  String get moodTired => '疲れた';

  @override
  String get moodSleepy => '眠い';

  @override
  String get moodCall => 'この気分で電話';

  @override
  String get premiumMoodCall => '電話まで飛ばすのはプレミアム';

  @override
  String get soundClassic => '標準';

  @override
  String get soundSoft => 'やわらか';

  @override
  String get soundBright => '高め';

  @override
  String get premiumSounds => '着信音の変更はプレミアム';

  @override
  String get callBeforeEnd => '定時の10分前';

  @override
  String get beforeEndPassed => 'その時間は過ぎています';

  @override
  String get noteMilk => '牛乳と卵';

  @override
  String get noteDentist => '歯医者、来週';

  @override
  String get noteReturn => '本、返す';

  @override
  String get noteMilkBody => '帰りに買う。忘れない。';

  @override
  String get noteDentistBody => '午後。仕事の話はしない。';

  @override
  String get noteReturnBody => '期限、そろそろ。';

  @override
  String get calLunch => '昼ごはん';

  @override
  String get voiceLazy1 => 'あー、だる。';

  @override
  String get voiceLazy2 => '動きたくない。でも時間は減る。';

  @override
  String get voiceLazy3 => '今日はこれでいい。';

  @override
  String get voiceLazy4 => 'やる気は、明日。';

  @override
  String get voiceLazy5 => '座ってる。それが仕事。';

  @override
  String get voiceLazy6 => 'もう一区切りだけ。たぶん。';

  @override
  String get voiceKansai1 => 'まだ先、長いわ。';

  @override
  String get voiceKansai2 => 'ええ感じに進んでるで。';

  @override
  String get voiceKansai3 => 'ぼちぼちいこか。';

  @override
  String get voiceKansai4 => '定時まで、もうちょい。';

  @override
  String get voiceKansai5 => 'えらいえらい。';

  @override
  String get voiceKansai6 => '帰ったらええのに。';

  @override
  String get moodHeavy1 => 'だるい。わかってる。';

  @override
  String get moodHeavy2 => 'そのままで、進んでる。';

  @override
  String get moodHeavy3 => '今日は重いでいい。';

  @override
  String get moodTired1 => '疲れたね。';

  @override
  String get moodTired2 => 'ここまで来た。';

  @override
  String get moodTired3 => '休んでいい。時間は進む。';

  @override
  String get moodSleepy1 => '眠い。';

  @override
  String get moodSleepy2 => '目、半分でいい。';

  @override
  String get moodSleepy3 => 'うとうとしてていい。';

  @override
  String get slack => 'サボる';

  @override
  String get slackIntro =>
      '席を外すためのボタンです。仕事の電話が来た画面になるか、このアプリの中身を別の画面にすり替えます。本当の電話はかかりません。';

  @override
  String get slackCall => '電話が来たことにする';

  @override
  String get slackHide => '画面を別のものにする';

  @override
  String get slackWeekly => '無料の電話は、週に1回です。';

  @override
  String get slackMore => '回数を増やす';
}
