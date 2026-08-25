export type InfoType = "privacy" | "terms" | "app";

export const INFO_ITEMS: readonly {
  body: readonly string[];
  id: InfoType;
  label: string;
  title: string;
}[] = [
  {
    body: [
      "프로필 이름과 이미지는 앱에서 사용자 식별 및 개인화된 화면 표시를 위해 사용됩니다.",
      "선택한 여행 사진은 사용자가 지정한 지역의 지도 표현과 장소 피드에 표시됩니다.",
      "정식 개인정보 처리방침은 계정, 백엔드, 저장소 연동 시점에 맞춰 별도 고지됩니다.",
    ],
    id: "privacy",
    label: "개인정보",
    title: "개인정보 처리방침",
  },
  {
    body: [
      "사용자는 본인이 권리를 가진 사진을 등록해야 합니다.",
      "지도 경계와 지역 정보는 행정구역 데이터 변경에 따라 업데이트될 수 있습니다.",
      "정식 이용약관은 서비스 배포 전에 세부 조항을 확정해 제공합니다.",
    ],
    id: "terms",
    label: "이용약관",
    title: "이용약관",
  },
  {
    body: [
      "Sasang은 방문한 지역을 사진으로 채우는 개인 여행 지도 앱입니다.",
      "현재 버전은 지도 선택, 지역 사진 등록, 장소 피드 확인을 중심으로 구성되어 있습니다.",
      "오픈소스 라이선스와 세부 앱 정보는 정식 배포 단계에서 별도 문서로 연결됩니다.",
    ],
    id: "app",
    label: "앱 정보",
    title: "앱 정보",
  },
];

export const findInfoItem = (id: string | string[] | undefined) => {
  const normalizedId = Array.isArray(id) ? id[0] : id;
  return INFO_ITEMS.find((item) => item.id === normalizedId) ?? INFO_ITEMS[0];
};
