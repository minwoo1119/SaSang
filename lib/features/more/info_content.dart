enum InfoContentType { privacy, terms, app }

class InfoSection {
  const InfoSection({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;
}

class InfoContent {
  const InfoContent({
    required this.id,
    required this.label,
    required this.title,
    required this.type,
    required this.sections,
    this.effectiveDate,
  });

  final String id;
  final String label;
  final String title;
  final InfoContentType type;
  final String? effectiveDate;
  final List<InfoSection> sections;

  bool get isAppInfo => type == InfoContentType.app;

  static const items = [
    InfoContent(
      id: 'privacy',
      label: '개인정보',
      title: '개인정보 처리방침',
      type: InfoContentType.privacy,
      sections: [
        InfoSection(
          title: '기기 저장',
          paragraphs: [
            '기존 버전에서 저장된 프로필 이름과 이미지는 업데이트 호환성을 위해 기기에 유지되며 현재 화면에는 표시되지 않습니다.',
            '여행 기록과 선택한 사진은 앱 전용 기기 저장소에서 처리되며 앱 코드에는 해당 정보를 서버로 업로드하는 경로가 없습니다.',
          ],
        ),
        InfoSection(
          title: '여행 사진',
          paragraphs: ['선택한 여행 사진은 사용자가 지정한 지역의 지도 표현과 장소 피드에 표시됩니다.'],
        ),
        InfoSection(
          title: '외부 서비스',
          paragraphs: [
            '앱은 Google Mobile Ads SDK를 사용하며 광고 요청은 비개인 맞춤 광고로 설정되어 있습니다. 비개인 맞춤 광고도 빈도 제한과 집계 보고 등을 위해 모바일 식별자나 네트워크 정보를 사용할 수 있습니다.',
            'iOS에서는 광고 SDK를 초기화하기 전에 시스템의 추적 권한 요청 절차를 실행합니다.',
          ],
        ),
        InfoSection(
          title: '정보 삭제',
          paragraphs: ['더보기의 계정 및 데이터 메뉴에서 기기에 저장된 여행 기록과 프로필 정보를 삭제할 수 있습니다.'],
        ),
      ],
    ),
    InfoContent(
      id: 'terms',
      label: '이용약관',
      title: '이용약관',
      type: InfoContentType.terms,
      sections: [
        InfoSection(
          title: '사진 사용',
          paragraphs: ['사용자는 본인이 권리를 가진 사진을 등록해야 합니다.'],
        ),
        InfoSection(
          title: '지도 정보',
          paragraphs: ['지도 경계와 지역 정보는 행정구역 데이터 변경에 따라 업데이트될 수 있습니다.'],
        ),
      ],
    ),
    InfoContent(
      id: 'app',
      label: '앱 정보',
      title: '앱 정보',
      type: InfoContentType.app,
      sections: [
        InfoSection(
          title: '사상 소개',
          paragraphs: [
            'Sasang은 방문한 지역을 사진으로 채우는 개인 여행 지도 앱입니다.',
            '대한민국과 세계 지도를 선택하고, 지역별 여행 사진과 기록을 한눈에 돌아볼 수 있습니다.',
          ],
        ),
      ],
    ),
  ];

  static InfoContent? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
