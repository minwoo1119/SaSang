# 신규 UI 구현 가이드

## 1. 구현 전 결정 순서

1. 이 화면에서 지도 또는 사진이 가장 중요한 콘텐츠인지 확인한다.
2. [공통 컴포넌트 목록](09-common-components.md)에서 재사용 API를 찾는다.
3. [Variant 규칙](04-component-variants.md)과 [예외 규칙](10-screen-exceptions.md)을 확인한다.
4. Semantic Token으로 구조를 조립한다.
5. 한국어/영어/일본어/중국어와 text scale 1.0/1.3/2.0을 고려한다.
6. Widget/Golden Test와 양 플랫폼 캡처 계획을 구현 전에 정한다.

## 2. 신규 화면 예시

아래 예시는 별도 색상·간격·radius를 만들지 않고 기존 API로 정보 화면을 조립하는 최소 형태다.

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/l10n/sasang_localizations.dart';
import '../core/theme/sasang_theme.dart';
import '../widgets/sasang_ui.dart';

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SasangSemanticColors.canvasSubtle,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(SasangSemanticSpacing.pageInset),
        children: [
          Text(tr('화면 제목'), style: SasangSemanticTypography.pageTitle),
          const SizedBox(height: SasangSemanticSpacing.xLarge),
          SasangSurface(
            radius: SasangSemanticRadii.radiusContentCard,
            padding: const EdgeInsets.all(SasangSemanticSpacing.large),
            child: Text(
              tr('여행 사진을 중심으로 필요한 정보만 보여 주세요.'),
              style: SasangSemanticTypography.body,
            ),
          ),
          const SizedBox(height: SasangSemanticSpacing.xLarge),
          SasangPrimaryButton(label: tr('완료'), onPressed: () {}),
        ],
      ),
    ),
  );
}
```

실제 문자열은 네 언어 번역을 추가한다. 긴 제목을 `maxLines: 1`로 숨기지 말고 scroll/높이 증가를
우선한다. `SasangSurface`가 모든 콘텐츠에 필요한 것은 아니며, 여백과 divider만으로 계층이 충분하면
카드를 추가하지 않는다.

## 3. 새 토큰 또는 컴포넌트가 필요한 경우

PR에 다음 내용을 기록한다.

- 해결하려는 semantic 역할과 사용 화면
- 기존 토큰/Variant로 해결할 수 없는 구체적 이유
- 현재값과 제안값, 네 언어/큰 글꼴 영향
- iOS/Android 차이와 최소 44dp hit target
- 새 상태와 Widget/Golden Test
- `03-design-tokens-proposal.md`, `04-component-variants.md`, `09-common-components.md` 중
  변경되는 문서

한 화면에서만 쓰이는 geometry나 illustration 값은 공통 토큰으로 과도하게 승격하지 않는다. 반대로
같은 의미가 두 화면 이상에서 반복되면 화면별 상수로 복제하지 않는다.

## 4. 금지 패턴

- `Color(0x...)`, `Colors.*`, 숫자형 radius/spacing/font size를 새 UI에 직접 추가
- 지도 검색 pill을 일반 16dp control로 변경
- 카드 안에 카드, 큰 장식 아이콘, 배지, 강한 그림자를 동시에 사용
- 선택 상태를 배경+테두리+글자색+체크+그림자로 중복 강조
- Flutter/Cupertino 표준 접근성을 픽셀 일치를 위해 재구현
- UI 개선을 이유로 지도, 사진, 저장 데이터 로직까지 함께 변경

정당한 화면/렌더링 예외는 [화면별 예외 규칙](10-screen-exceptions.md)의 주석 형식을 사용한다.

## 5. PR 완료 조건

- `dart run tool/check_design_style.dart` 통과
- `flutter analyze`와 관련 UI/Golden Test 통과
- 320×568과 대표 화면, text scale 1.0/1.3/2.0 확인
- 네 언어의 긴 문자열 확인
- iOS/Android 실행 결과 확인
- 변경 전후 캡처를 `docs/pr-screenshots/<issue>/`에 커밋
- 토큰/Variant/예외 변경 시 공식 문서와 테스트 동시 갱신
