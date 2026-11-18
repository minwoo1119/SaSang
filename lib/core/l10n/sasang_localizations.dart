import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum SasangLanguage {
  korean('ko', '한국어'),
  english('en', 'English'),
  japanese('ja', '日本語'),
  simplifiedChinese('zh', '简体中文');

  const SasangLanguage(this.code, this.displayName);

  final String code;
  final String displayName;

  Locale get locale => code == 'zh'
      ? const Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN')
      : Locale(code);

  static SasangLanguage fromCode(String? code) => values.firstWhere(
    (language) => language.code == code,
    orElse: () => korean,
  );

  static SasangLanguage fromDeviceLocale(Locale locale) =>
      switch (locale.languageCode) {
        'en' => english,
        'ja' => japanese,
        'zh' => simplifiedChinese,
        _ => korean,
      };
}

class SasangLocalizations {
  const SasangLocalizations(this.locale);

  final Locale locale;

  static const delegate = _SasangLocalizationsDelegate();
  static const supportedLocales = [
    Locale('ko'),
    Locale('en'),
    Locale('ja'),
    Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
  ];

  static SasangLanguage _currentLanguage = SasangLanguage.korean;

  static SasangLanguage get currentLanguage => _currentLanguage;

  static SasangLocalizations of(BuildContext context) =>
      Localizations.of<SasangLocalizations>(context, SasangLocalizations) ??
      SasangLocalizations(_currentLanguage.locale);

  static void use(SasangLanguage language) => _currentLanguage = language;

  SasangLanguage get language => SasangLanguage.fromCode(locale.languageCode);

  String text(String korean) => _translate(korean, language);
}

class _SasangLocalizationsDelegate
    extends LocalizationsDelegate<SasangLocalizations> {
  const _SasangLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => SasangLanguage.values.any(
    (language) => language.code == locale.languageCode,
  );

  @override
  Future<SasangLocalizations> load(Locale locale) =>
      SynchronousFuture(SasangLocalizations(locale));

  @override
  bool shouldReload(_SasangLocalizationsDelegate old) => false;
}

String tr(String korean) =>
    _translate(korean, SasangLocalizations._currentLanguage);

String _translate(String source, SasangLanguage language) {
  if (language == SasangLanguage.korean) return source;
  final translated = _translations[source];
  if (translated != null) {
    return switch (language) {
      SasangLanguage.english => translated.$1,
      SasangLanguage.japanese => translated.$2,
      SasangLanguage.simplifiedChinese => translated.$3,
      SasangLanguage.korean => source,
    };
  }
  return _translatePattern(source, language) ?? source;
}

String? _translatePattern(String source, SasangLanguage language) {
  String pick(String en, String ja, String zh) => switch (language) {
    SasangLanguage.english => en,
    SasangLanguage.japanese => ja,
    SasangLanguage.simplifiedChinese => zh,
    SasangLanguage.korean => source,
  };

  RegExpMatch? match;
  match = RegExp(r'^(\d+)장$').firstMatch(source);
  if (match != null) {
    final count = match.group(1)!;
    return pick('$count photos', '$count枚', '$count张');
  }
  match = RegExp(r'^사진 (\d+)장$').firstMatch(source);
  if (match != null) {
    final count = match.group(1)!;
    return pick('$count photos', '写真$count枚', '$count张照片');
  }
  match = RegExp(r'^(\d+)장의 여행 사진$').firstMatch(source);
  if (match != null) {
    final count = match.group(1)!;
    return pick('$count travel photos', '旅の写真$count枚', '$count张旅行照片');
  }
  match = RegExp(r'^보유한 지도 (\d+)개$').firstMatch(source);
  if (match != null) {
    final count = match.group(1)!;
    return pick('$count owned maps', '所有マップ$count件', '已拥有$count张地图');
  }
  match = RegExp(r'^(\d+)개$').firstMatch(source);
  if (match != null) {
    final count = match.group(1)!;
    return pick(count, '$count件', '$count个');
  }
  match = RegExp(r'^(\d{4})년 (\d{1,2})월 (\d{1,2})일$').firstMatch(source);
  if (match != null) {
    final year = match.group(1)!;
    final month = match.group(2)!;
    final day = match.group(3)!;
    return pick(
      '$month/$day/$year',
      '$year年$month月$day日',
      '$year年$month月$day日',
    );
  }
  match = RegExp(r'^북한 방문 확인 · (\d+)/3$').firstMatch(source);
  if (match != null) {
    final attempt = match.group(1)!;
    return pick(
      'North Korea visit check · $attempt/3',
      '北朝鮮訪問の確認 · $attempt/3',
      '朝鲜访问确认 · $attempt/3',
    );
  }
  match = RegExp(r'^시행일 (.+)$').firstMatch(source);
  if (match != null) {
    final date = match.group(1)!;
    return pick('Effective $date', '施行日 $date', '生效日期 $date');
  }
  match = RegExp(r'^(.+) 지도$').firstMatch(source);
  if (match != null) {
    final name = match.group(1)!;
    return pick('$name map', '$nameのマップ', '$name地图');
  }
  match = RegExp(r'^(\d+)개 (.+)$').firstMatch(source);
  if (match != null) {
    final count = match.group(1)!;
    final unit = match.group(2)!;
    return pick('$count $unit', '$unit$count', '$count$unit');
  }
  match = RegExp(
    r'^현재 지도 (\d+)개 (.+) 중 (\d+)개 여행, (\d+)퍼센트$',
  ).firstMatch(source);
  if (match != null) {
    final total = match.group(1)!;
    final unit = match.group(2)!;
    final visited = match.group(3)!;
    final percentage = match.group(4)!;
    return pick(
      '$visited of $total $unit visited, $percentage percent',
      '現在のマップ：$total$unit中$visited、$percentageパーセント訪問済み',
      '当前地图：共$total$unit，已旅行$visited，百分之$percentage',
    );
  }
  return null;
}

const Map<String, (String, String, String)> _translations = {
  '간직하고 싶은 형식을 선택해 주세요.': (
    'Choose how you want to keep it.',
    '残したい形式を選んでください。',
    '请选择想要保存的格式。',
  ),
  '개 국가': (' countries', 'か国', '个国家'),
  '개 지역': (' regions', '地域', '个地区'),
  '개인정보': ('Privacy', 'プライバシー', '隐私'),
  '개인정보 처리방침': ('Privacy Policy', 'プライバシーポリシー', '隐私政策'),
  '거의 다 됐어요': ('Almost done', 'もうすぐ完了です', '即将完成'),
  '검색 결과가 없어요': ('No results found', '検索結果がありません', '未找到结果'),
  '계정 및 데이터': ('Account & Data', 'アカウントとデータ', '账户与数据'),
  '공유 이미지를 만들지 못했어요.': (
    'Could not create the share image.',
    '共有画像を作成できませんでした。',
    '无法创建分享图片。',
  ),
  '공유 화면을 여는 중이에요.': ('Opening the share sheet.', '共有画面を開いています。', '正在打开分享界面。'),
  '공유할 여행 기록이 없어요': (
    'No travel records to share',
    '共有する旅行記録がありません',
    '没有可分享的旅行记录',
  ),
  '광고': ('Ad', '広告', '广告'),
  '국가': ('Country', '国', '国家'),
  '국가 이름 검색': ('Search countries', '国名を検索', '搜索国家名称'),
  '국가 지도 검색': ('Search country maps', '国別マップを検索', '搜索国家地图'),
  '국가 지도를 열면 도시와 지역 단위로 사진을 남길 수 있어요.': (
    'Open a country map to add photos by city and region.',
    '国別マップを開くと、都市や地域ごとに写真を残せます。',
    '打开国家地图后，可按城市和地区添加照片。',
  ),
  '국가별 상세 지도': ('Detailed country maps', '国別詳細マップ', '国家详细地图'),
  '국가별 여행 기록': ('Travel records by country', '国別の旅行記録', '按国家记录旅行'),
  '국가별 지도': ('Country maps', '国別マップ', '国家地图'),
  '기기 저장': ('On-device storage', '端末内保存', '设备存储'),
  '기기 저장 공간을 확인한 뒤 다시 시도해 주세요.': (
    'Check your device storage and try again.',
    '端末の空き容量を確認して、もう一度お試しください。',
    '请检查设备存储空间后重试。',
  ),
  '기기에 저장된 모든 여행 기록과 프로필 정보를 초기화합니다.': (
    'This resets all travel records and profile information stored on this device.',
    '端末に保存されたすべての旅行記録とプロフィール情報を初期化します。',
    '这将重置设备上保存的所有旅行记录和个人资料。',
  ),
  '기기에 저장된 여행 기록과 프로필은 유지됩니다.': (
    'Travel records and profile data stored on this device will remain.',
    '端末に保存された旅行記録とプロフィールは保持されます。',
    '设备中保存的旅行记录和个人资料将保留。',
  ),
  '기본 지도': ('Default maps', '基本マップ', '默认地图'),
  '나의 대한민국 여행': ('My Korea Travels', '私の韓国旅行', '我的韩国旅行'),
  '나의 세계 여행': ('My World Travels', '私の世界旅行', '我的世界旅行'),
  '나의 여행 지도': ('My Travel Map', '私の旅行マップ', '我的旅行地图'),
  '나의 여행을 지도에 남기다': (
    'Map your travels through photos',
    '旅の思い出を地図に残そう',
    '用照片记录你的旅行地图',
  ),
  '내 지도': ('My Maps', 'マイマップ', '我的地图'),
  '내보내기 완료': ('Export complete', 'エクスポート完了', '导出完成'),
  '내보내기 진행': ('Export progress', 'エクスポートの進行状況', '导出进度'),
  '내보내기 취소': ('Cancel export', 'エクスポートをキャンセル', '取消导出'),
  '내보내기를 중단했어요': ('Export stopped', 'エクスポートを中止しました', '已停止导出'),
  '눌러서 사진 추가': ('Tap to add photos', 'タップして写真を追加', '点击添加照片'),
  '다른 국가명이나 국가 코드를 입력해 보세요.': (
    'Try another country name or country code.',
    '別の国名または国コードを入力してください。',
    '请输入其他国家名称或国家代码。',
  ),
  '다른 앱으로 공유': ('Share to another app', '他のアプリで共有', '分享到其他应用'),
  '다시 시도': ('Try again', 'もう一度試す', '重试'),
  '닫기': ('Close', '閉じる', '关闭'),
  '대표 사진': ('Cover photo', '代表写真', '封面照片'),
  '대표 사진으로': ('Set as cover', '代表写真に設定', '设为封面'),
  '대한민국': ('Korea', '韓国', '韩国'),
  '대한민국 지도': ('Korea Map', '韓国マップ', '韩国地图'),
  '더보기': ('More', 'その他', '更多'),
  '데이터 백업 진행': ('Backup progress', 'バックアップの進行状況', '备份进度'),
  '데이터 백업하기': ('Back up data', 'データをバックアップ', '备份数据'),
  '데이터 지우고 로그아웃': ('Clear data and log out', 'データを削除してログアウト', '清除数据并退出登录'),
  '데이터 지우고 로그아웃하기': ('Clear data and log out', 'データを削除してログアウト', '清除数据并退出登录'),
  '데이터 지우기': ('Clear data', 'データを削除', '清除数据'),
  '동의하고 시작하기': ('Agree and start', '同意して始める', '同意并开始'),
  '로그아웃': ('Log out', 'ログアウト', '退出登录'),
  '방문한 지역을 고르고, 그 경계 안에 내 사진을 담아보세요.': (
    'Choose a place you visited and fill its borders with your photos.',
    '訪れた地域を選び、その境界の中に写真を残しましょう。',
    '选择去过的地区，用照片填满它的边界。',
  ),
  '백업 실패': ('Backup failed', 'バックアップ失敗', '备份失败'),
  '백업 파일 만드는 중…': ('Creating backup…', 'バックアップを作成中…', '正在创建备份…'),
  '백업 파일 만들기': ('Create backup', 'バックアップを作成', '创建备份'),
  '백업 파일을 만들고 있어요': ('Creating your backup', 'バックアップを作成しています', '正在创建备份'),
  '백업 파일을 만들지 못했어요. 잠시 후 다시 시도해 주세요.': (
    'Could not create the backup. Please try again later.',
    'バックアップを作成できませんでした。しばらくしてからもう一度お試しください。',
    '无法创建备份，请稍后重试。',
  ),
  '버전': ('Version', 'バージョン', '版本'),
  '본토와 섬을 포함해 지역별로 기록해요': (
    'Record each region, including the mainland and islands',
    '本土と島を含む地域ごとに記録できます',
    '按地区记录，包括大陆和岛屿',
  ),
  '사상': ('Sasang', 'Sasang', 'Sasang'),
  '사상 데이터 백업': ('Sasang data backup', 'Sasangデータバックアップ', 'Sasang数据备份'),
  '사상 소개': ('About Sasang', 'Sasangについて', '关于Sasang'),
  '사상 앱 아이콘': ('Sasang app icon', 'Sasangアプリアイコン', 'Sasang应用图标'),
  '사상 여행 지도': ('Sasang Travel Map', 'Sasang旅行マップ', 'Sasang旅行地图'),
  '사용 중': ('In use', '使用中', '使用中'),
  '사진 날짜': ('Photo date', '写真の日付', '照片日期'),
  '사진 보관함에 저장': ('Save to Photos', '写真ライブラリに保存', '保存到相册'),
  '사진 보관함에 저장하지 못했어요.': (
    'Could not save to Photos.',
    '写真ライブラリに保存できませんでした。',
    '无法保存到相册。',
  ),
  '사진 보관함에 저장했어요.': ('Saved to Photos.', '写真ライブラリに保存しました。', '已保存到相册。'),
  '사진 사용': ('Photo use', '写真の利用', '照片使用'),
  '사진 저장 안내': ('Photo storage notice', '写真保存のご案内', '照片存储说明'),
  '사진 추가': ('Add photos', '写真を追加', '添加照片'),
  '사진에 기록된 촬영일을 불러왔어요.': (
    'We found the date recorded in the photo.',
    '写真に記録された撮影日を読み込みました。',
    '已读取照片中记录的拍摄日期。',
  ),
  '사진으로 남기기': ('Save as image', '写真で残す', '保存为图片'),
  '사진으로 채우는 여행 지도': (
    'A travel map filled with your photos',
    '写真で彩る旅行マップ',
    '用照片填满的旅行地图',
  ),
  '사진을 만들지 못했어요': ('Could not create the image', '写真を作成できませんでした', '无法创建图片'),
  '사진을 삭제할까요?': ('Delete this photo?', 'この写真を削除しますか？', '要删除这张照片吗？'),
  '사진을 정리하는 중이에요.': ('Preparing your photos.', '写真を整理しています。', '正在整理照片。'),
  '사진을 추가할 수 없어요': ('Could not add the photo', '写真を追加できません', '无法添加照片'),
  '사진이 준비됐어요': ('Your image is ready', '写真の準備ができました', '图片已准备好'),
  '삭제': ('Delete', '削除', '删除'),
  '상세 정보': ('Details', '詳細情報', '详细信息'),
  '새로운 지도 둘러보기': ('Explore new maps', '新しいマップを見る', '探索新地图'),
  '선택한 날짜': ('Selected date', '選択した日付', '所选日期'),
  '세계 지도': ('World Map', '世界マップ', '世界地图'),
  '세계': ('World', '世界', '世界'),
  '시·군·구별 여행 기록': ('Travel records by region', '市・郡・区別の旅行記録', '按市、郡、区记录旅行'),
  '시작하기': ('Get started', '始める', '开始'),
  '시행일 미정': ('Effective date TBD', '施行日未定', '生效日期待定'),
  '아직 기록이 없어요': ('No records yet', 'まだ記録がありません', '还没有记录'),
  '앨범에서 선택하기': ('Choose from library', 'ライブラリから選択', '从相册选择'),
  '앱 정보': ('App information', 'アプリ情報', '应用信息'),
  '약관 및 정보': ('Terms & Information', '規約と情報', '条款与信息'),
  '여행 기록과 사진을 하나로 정리하는 중이에요.': (
    'Bundling your travel records and photos.',
    '旅行記録と写真をまとめています。',
    '正在整理旅行记录和照片。',
  ),
  '여행 비율을 담은 9:16 이미지': (
    'A 9:16 image with your travel progress',
    '旅行の達成率を入れた9:16画像',
    '包含旅行进度的9:16图片',
  ),
  '여행 사진': ('Travel photos', '旅行写真', '旅行照片'),
  '여행 영상을 만들고 있어요': ('Creating your travel video', '旅行動画を作成しています', '正在制作旅行视频'),
  '여행 지도를 만들고 있어요': ('Creating your travel map', '旅行マップを作成しています', '正在制作旅行地图'),
  '여행 지도를 어떻게 남길까요?': (
    'How would you like to keep your travel map?',
    '旅行マップをどのように残しますか？',
    '想如何保存旅行地图？',
  ),
  '여행을 더 자세하게 기록하세요': (
    'Record your travels in more detail',
    '旅をもっと詳しく記録しましょう',
    '更详细地记录旅行',
  ),
  '여행의 순간을 영상으로 담고 있어요.': (
    'Turning your travel moments into a video.',
    '旅の思い出を動画にしています。',
    '正在将旅行瞬间制作成视频。',
  ),
  '여행의 순간을 한 장에 담고 있어요.': (
    'Putting your travel moments into one image.',
    '旅の思い出を一枚にまとめています。',
    '正在将旅行瞬间汇成一张图片。',
  ),
  '여행자': ('Traveler', '旅行者', '旅行者'),
  '영상 내보내기가 취소되었습니다.': (
    'Video export was canceled.',
    '動画のエクスポートがキャンセルされました。',
    '视频导出已取消。',
  ),
  '영상으로 남기기': ('Save as video', '動画で残す', '保存为视频'),
  '영상으로 만들 여행 기록이 없어요.': (
    'There are no travel records to turn into a video.',
    '動画にする旅行記録がありません。',
    '没有可制作成视频的旅行记录。',
  ),
  '영상을 만들지 못했어요': ('Could not create the video', '動画を作成できませんでした', '无法制作视频'),
  '영상이 준비됐어요': ('Your video is ready', '動画の準備ができました', '视频已准备好'),
  '오래된순': ('Oldest first', '古い順', '最早优先'),
  '오픈소스 라이선스': ('Open-source licenses', 'オープンソースライセンス', '开源许可'),
  '완성된 사진을 저장하고 있어요.': (
    'Saving the finished image.',
    '完成した写真を保存しています。',
    '正在保存完成的图片。',
  ),
  '완성된 영상을 저장하고 있어요.': (
    'Saving the finished video.',
    '完成した動画を保存しています。',
    '正在保存完成的视频。',
  ),
  '외부 서비스': ('External services', '外部サービス', '外部服务'),
  '요청을 처리하지 못했습니다.': (
    'Could not process the request.',
    'リクエストを処理できませんでした。',
    '无法处理请求。',
  ),
  '이 기기에 한 번 저장': ('Save once on this device', 'この端末に一度保存', '在此设备上保存一次'),
  '이 날짜로 저장': ('Save this date', 'この日付で保存', '保存此日期'),
  '이 앱에서 사용한 사진은 일체 서버로 전송되지 않으며, 기기 내부에 저장됩니다.': (
    'Photos used in this app are never sent to a server and remain on your device.',
    'このアプリで使用する写真はサーバーへ送信されず、端末内に保存されます。',
    '本应用使用的照片不会发送到服务器，仅保存在设备中。',
  ),
  '이 지역의 앨범에서 사진이 제거돼요.': (
    'The photo will be removed from this region’s album.',
    'この地域のアルバムから写真が削除されます。',
    '照片将从该地区的相册中移除。',
  ),
  '이용약관': ('Terms of Service', '利用規約', '服务条款'),
  '일치하는 지역이 없어요': ('No matching places', '一致する地域がありません', '没有匹配的地区'),
  '장소': ('Places', '場所', '地点'),
  '저장하거나 다른 앱으로 바로 공유할 수 있어요.': (
    'Save it or share it directly to another app.',
    '保存したり、他のアプリにすぐ共有できます。',
    '可以保存或直接分享到其他应用。',
  ),
  '정보 삭제': ('Delete information', '情報の削除', '删除信息'),
  '지도': ('Map', 'マップ', '地图'),
  '지도 가격': ('Map price', 'マップ価格', '地图价格'),
  '지도 상점': ('Map Store', 'マップストア', '地图商店'),
  '지도 위치 초기화': ('Reset map position', 'マップ位置をリセット', '重置地图位置'),
  '지도 정보': ('Map information', '地図情報', '地图信息'),
  '지도 축소': ('Zoom out', '縮小', '缩小'),
  '지도 확대': ('Zoom in', '拡大', '放大'),
  '지도를 불러오지 못했어요.': ('Could not load the map.', 'マップを読み込めませんでした。', '无法加载地图。'),
  '지도에 사진을 먼저 추가해 주세요.': (
    'Add a photo to the map first.',
    'まずマップに写真を追加してください。',
    '请先在地图上添加照片。',
  ),
  '지도에서 시작하기': ('Start on the map', 'マップから始める', '从地图开始'),
  '지도에서 첫 사진을 추가해보세요.': (
    'Add your first photo from the map.',
    'マップから最初の写真を追加しましょう。',
    '从地图添加第一张照片吧。',
  ),
  '지도와 여행 기록은 그대로 유지돼요.': (
    'Your map and travel records are unchanged.',
    'マップと旅行記録はそのまま保持されます。',
    '地图和旅行记录将保持不变。',
  ),
  '지역': ('Region', '地域', '地区'),
  '지역 이름 검색': ('Search regions', '地域名を検索', '搜索地区名称'),
  '지역별로 여행 사진을 기록해요': (
    'Record travel photos by region',
    '地域ごとに旅行写真を記録できます',
    '按地区记录旅行照片',
  ),
  '지역을 선택해 기록을 시작하세요': (
    'Select a region to start recording',
    '地域を選んで記録を始めましょう',
    '选择地区开始记录',
  ),
  '첫 사진을 추가해 보세요': ('Add your first photo', '最初の写真を追加しましょう', '添加第一张照片'),
  '촬영일 순으로 이어지는 9:16 MP4': (
    'A 9:16 MP4 ordered by photo date',
    '撮影日順につながる9:16 MP4',
    '按拍摄日期排列的9:16 MP4',
  ),
  '촬영일 정보가 없어 오늘 날짜로 설정했어요.': (
    'No photo date was found, so we used today.',
    '撮影日情報がないため、今日の日付に設定しました。',
    '未找到拍摄日期，已设为今天。',
  ),
  '최신순': ('Newest first', '新しい順', '最新优先'),
  '추가 지도': ('Additional maps', '追加マップ', '附加地图'),
  '출시 예정': ('Coming soon', '近日公開', '即将推出'),
  '취소': ('Cancel', 'キャンセル', '取消'),
  '타임라인 영상을 만들지 못했어요.': (
    'Could not create the timeline video.',
    'タイムライン動画を作成できませんでした。',
    '无法制作时间线视频。',
  ),
  '확인': ('OK', '確認', '确认'),
  '확인 중': ('Checking', '確認中', '检查中'),
  '해외': ('International', '海外', '海外'),
  '설정': ('Settings', '設定', '设置'),
  '언어': ('Language', '言語', '语言'),
  '언어 선택': ('Choose language', '言語を選択', '选择语言'),
  '기존 버전에서 저장된 프로필 이름과 이미지는 업데이트 호환성을 위해 기기에 유지되며 현재 화면에는 표시되지 않습니다.': (
    'Profile names and images saved by earlier versions remain on the device for update compatibility but are not shown in the current app.',
    '旧バージョンで保存されたプロフィール名と画像は更新互換性のため端末に保持されますが、現在の画面には表示されません。',
    '旧版本保存的个人资料名称和图片会保留在设备中以兼容更新，但不会显示在当前界面。',
  ),
  '여행 기록과 선택한 사진은 앱 전용 기기 저장소에서 처리되며 앱 코드에는 해당 정보를 서버로 업로드하는 경로가 없습니다.': (
    'Travel records and selected photos are processed in app-only device storage, and the app has no code path that uploads them to a server.',
    '旅行記録と選択した写真はアプリ専用の端末ストレージで処理され、サーバーへアップロードする経路はありません。',
    '旅行记录和所选照片仅在应用专用设备存储中处理，应用没有将其上传到服务器的路径。',
  ),
  '앱은 Google Mobile Ads SDK를 사용하며 광고 요청은 비개인 맞춤 광고로 설정되어 있습니다. 비개인 맞춤 광고도 빈도 제한과 집계 보고 등을 위해 모바일 식별자나 네트워크 정보를 사용할 수 있습니다.': (
    'The app uses the Google Mobile Ads SDK and requests non-personalized ads. These ads may still use mobile identifiers or network information for frequency capping and aggregate reporting.',
    '本アプリはGoogle Mobile Ads SDKを使用し、非パーソナライズ広告をリクエストします。頻度制限や集計レポートのため、モバイル識別子やネットワーク情報が使用される場合があります。',
    '本应用使用Google Mobile Ads SDK并请求非个性化广告。此类广告仍可能使用移动标识符或网络信息进行频次限制和汇总报告。',
  ),
  '여행 기록과 원본 사진을 하나의 파일로 만듭니다. 백업 파일은 암호화되지 않으므로 안전한 곳에 보관해 주세요.': (
    'Your travel records and original photos will be saved in one file. The backup is not encrypted, so keep it somewhere secure.',
    '旅行記録と元の写真を一つのファイルにまとめます。バックアップは暗号化されないため、安全な場所に保管してください。',
    '旅行记录和原始照片将保存为一个文件。备份文件未加密，请妥善保管。',
  ),
  'Instagram 등 앱 선택': (
    'Choose an app such as Instagram',
    'Instagramなどのアプリを選択',
    '选择Instagram等应用',
  ),
  'Sasang은 방문한 지역을 사진으로 채우는 개인 여행 지도 앱입니다.': (
    'Sasang is a personal travel map app that fills visited places with your photos.',
    'Sasangは、訪れた地域を写真で彩る個人向け旅行マップアプリです。',
    'Sasang是一款用照片填充去过地区的个人旅行地图应用。',
  ),
  'iOS에서는 광고 SDK를 초기화하기 전에 시스템의 추적 권한 요청 절차를 실행합니다.': (
    'On iOS, the system tracking permission flow runs before the advertising SDK is initialized.',
    'iOSでは、広告SDKを初期化する前にシステムのトラッキング許可を求めます。',
    '在iOS上，初始化广告SDK前会先执行系统跟踪权限请求。',
  ),
  '대한민국과 세계 지도를 선택하고, 지역별 여행 사진과 기록을 한눈에 돌아볼 수 있습니다.': (
    'Choose Korea or World maps and review your travel photos and records by region at a glance.',
    '韓国マップと世界マップを選び、地域別の旅行写真と記録を一覧できます。',
    '选择韩国或世界地图，一览各地区的旅行照片与记录。',
  ),
  '더보기의 계정 및 데이터 메뉴에서 기기에 저장된 여행 기록과 프로필 정보를 삭제할 수 있습니다.': (
    'You can delete travel records and profile information stored on this device from Account & Data under More.',
    '「その他」の「アカウントとデータ」から、端末内の旅行記録とプロフィール情報を削除できます。',
    '可在“更多”的“账户与数据”中删除设备上的旅行记录和个人资料。',
  ),
  '진짜 방문하셨다고요 ?????': ('You really visited there?', '本当に訪れたのですか？', '你真的去过那里吗？'),
  '정말 북한에 다녀오셨다고요 ?????': (
    'You really traveled to North Korea?',
    '本当に北朝鮮へ行ったのですか？',
    '你真的去过朝鲜吗？',
  ),
  '마지막 확인이에요. 진짜 방문하신 게 맞나요 ?????': (
    'One last check. Did you really visit?',
    '最後の確認です。本当に訪れましたか？',
    '最后确认一次，你真的去过吗？',
  ),
  '사용자는 본인이 권리를 가진 사진을 등록해야 합니다.': (
    'You may only add photos you have the right to use.',
    'ご自身が権利を持つ写真のみ登録してください。',
    '只能添加您拥有使用权的照片。',
  ),
  '선택한 여행 사진은 사용자가 지정한 지역의 지도 표현과 장소 피드에 표시됩니다.': (
    'Selected travel photos appear on the chosen region and in the Places feed.',
    '選択した旅行写真は、指定した地域のマップ表示と場所フィードに表示されます。',
    '所选旅行照片会显示在指定地区的地图和地点信息流中。',
  ),
  '여행 사진 파일을 찾을 수 없어 백업을 만들지 못했어요.': (
    'A travel photo file is missing, so the backup could not be created.',
    '旅行写真ファイルが見つからないため、バックアップを作成できませんでした。',
    '找不到旅行照片文件，无法创建备份。',
  ),
  '프로필 사진 파일을 찾을 수 없어 백업을 만들지 못했어요.': (
    'The profile photo file is missing, so the backup could not be created.',
    'プロフィール写真が見つからないため、バックアップを作成できませんでした。',
    '找不到个人资料照片，无法创建备份。',
  ),
  '지도 경계와 지역 정보는 행정구역 데이터 변경에 따라 업데이트될 수 있습니다.': (
    'Map boundaries and region information may change when administrative data is updated.',
    '行政区域データの変更により、境界や地域情報が更新される場合があります。',
    '地图边界和地区信息可能会随行政区划数据更新。',
  ),
  '언어를 선택해 주세요': ('Choose your language', '言語を選択してください', '请选择语言'),
  '선택한 언어는 설정에서 언제든지 바꿀 수 있어요.': (
    'You can change your language anytime in Settings.',
    '選択した言語は設定からいつでも変更できます。',
    '您可以随时在设置中更改语言。',
  ),
  '여행할 지도를 선택하세요': ('Choose your travel map', '旅行するマップを選びましょう', '选择你的旅行地图'),
  '대한민국과 세계 지도에서 여행을 기록할 지역을 골라보세요.': (
    'Choose a place to record on the Korea or World map.',
    '韓国マップや世界マップから、旅を記録する地域を選びましょう。',
    '在韩国或世界地图中选择要记录旅行的地区。',
  ),
  '지역을 사진으로 채워보세요': (
    'Fill places with your photos',
    '地域を写真で彩りましょう',
    '用照片填满去过的地区',
  ),
  '방문한 지역을 누르고 사진을 추가하면, 지도 경계 안에 내 추억이 채워져요.': (
    'Tap a place you visited and add a photo to fill its map boundary with your memory.',
    '訪れた地域をタップして写真を追加すると、地図の境界内が思い出で彩られます。',
    '点击去过的地区并添加照片，让回忆填满地图边界。',
  ),
  '여행을 기록하고 공유하세요': (
    'Record and share your journey',
    '旅を記録してシェアしましょう',
    '记录并分享你的旅程',
  ),
  '장소별 사진과 날짜를 모아보고, 완성된 여행 지도를 이미지나 영상으로 나눠보세요.': (
    'Review photos and dates by place, then share your completed travel map as an image or video.',
    '地域ごとの写真と日付を振り返り、完成した旅行マップを画像や動画でシェアできます。',
    '按地点查看照片和日期，并将完成的旅行地图以图片或视频分享。',
  ),
  '사진은 기기에 안전하게 보관돼요': (
    'Your photos stay safely on your device',
    '写真は端末内に安全に保存されます',
    '照片安全保存在你的设备上',
  ),
  '다음': ('Next', '次へ', '下一步'),
  '이전': ('Back', '戻る', '返回'),
};
