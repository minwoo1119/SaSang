import 'package:flutter/material.dart';

import '../core/theme/sasang_theme.dart';

class _Product {
  const _Product(this.code, this.name, this.description, this.price);
  final String code;
  final String name;
  final String description;
  final String price;
}

const _products = [
  _Product('JP', '일본 지도', '도도부현별로 사진을 기록해요', '₩2,000'),
  _Product('US', '미국 지도', '주별로 여행 사진을 기록해요', '₩2,000'),
  _Product('FR', '프랑스 지도', '지역별로 여행 사진을 기록해요', '₩2,000'),
  _Product('IT', '이탈리아 지도', '주별로 여행 사진을 기록해요', '₩2,000'),
  _Product('TH', '태국 지도', '주별로 여행 사진을 기록해요', '₩2,000'),
  _Product('VN', '베트남 지도', '성·시별로 여행 사진을 기록해요', '₩2,000'),
];

class MapStoreScreen extends StatelessWidget {
  const MapStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('지도 상점', style: TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        const Text(
          '여행을 더 자세하게 기록하세요',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          '국가 지도를 열면 도시와 지역 단위로 사진을 남길 수 있어요.',
          style: TextStyle(color: SasangColors.secondary),
        ),
        const SizedBox(height: 24),
        const Text(
          '국가별 지도',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: .82,
          ),
          itemBuilder: (context, index) {
            final product = _products[index];
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showProduct(context, product),
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SasangColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            product.code,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: SasangColors.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SasangColors.secondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.price,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                '출시 예정',
                                style: TextStyle(
                                  color: SasangColors.secondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );

  void _showProduct(BuildContext context, _Product product) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '국가별 상세 지도',
                  style: TextStyle(
                    color: SasangColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 150,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    product.code,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: SasangColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(product.description),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('지도 가격'),
                    Text(
                      product.price,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: null, child: Text('출시 예정')),
                ),
              ],
            ),
          ),
        ),
      );
}
