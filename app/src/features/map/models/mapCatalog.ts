import type { MapMode } from "./map.types";

export type OwnedMap = {
  description: string;
  id: MapMode;
  name: string;
};

export type StoreMapProduct = {
  countryCode: string;
  description: string;
  id: string;
  name: string;
  priceLabel: string;
  status: "coming-soon";
};

export const OWNED_MAPS: readonly OwnedMap[] = [
  {
    description: "시·군·구별 여행 기록",
    id: "korea",
    name: "대한민국 지도",
  },
  {
    description: "국가별 여행 기록",
    id: "world",
    name: "세계 지도",
  },
];

export const STORE_MAP_PRODUCTS: readonly StoreMapProduct[] = [
  {
    countryCode: "JP",
    description: "도도부현별로 사진을 기록해요",
    id: "country-japan",
    name: "일본 지도",
    priceLabel: "₩2,000",
    status: "coming-soon",
  },
  {
    countryCode: "US",
    description: "주별로 여행 사진을 기록해요",
    id: "country-united-states",
    name: "미국 지도",
    priceLabel: "₩2,000",
    status: "coming-soon",
  },
  {
    countryCode: "FR",
    description: "지역별로 여행 사진을 기록해요",
    id: "country-france",
    name: "프랑스 지도",
    priceLabel: "₩2,000",
    status: "coming-soon",
  },
  {
    countryCode: "IT",
    description: "주별로 여행 사진을 기록해요",
    id: "country-italy",
    name: "이탈리아 지도",
    priceLabel: "₩2,000",
    status: "coming-soon",
  },
  {
    countryCode: "TH",
    description: "주별로 여행 사진을 기록해요",
    id: "country-thailand",
    name: "태국 지도",
    priceLabel: "₩2,000",
    status: "coming-soon",
  },
  {
    countryCode: "VN",
    description: "성·시별로 여행 사진을 기록해요",
    id: "country-vietnam",
    name: "베트남 지도",
    priceLabel: "₩2,000",
    status: "coming-soon",
  },
];

export function getOwnedMap(mode: MapMode) {
  return OWNED_MAPS.find((map) => map.id === mode) ?? OWNED_MAPS[0];
}
