import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../core/theme/sasang_theme.dart';
import '../features/map/map_repository.dart';
import '../models/map_models.dart';
import '../widgets/sasang_ui.dart';

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

class MapStoreScreen extends StatefulWidget {
  const MapStoreScreen({super.key});

  @override
  State<MapStoreScreen> createState() => _MapStoreScreenState();
}

class _MapStoreScreenState extends State<MapStoreScreen> {
  late final Future<RegionMapAsset> _worldMap = MapRepository().load(
    MapMode.world,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const CupertinoNavigationBar(
      border: Border(
        bottom: BorderSide(color: SasangColors.divider, width: .5),
      ),
      middle: Text(
        '지도 상점',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
    body: FutureBuilder<RegionMapAsset>(
      future: _worldMap,
      builder: (context, snapshot) {
        final regions = {
          for (final region in snapshot.data?.regions ?? const <MapRegion>[])
            region.code: region,
        };
        return ListView(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            MediaQuery.paddingOf(context).bottom + 40,
          ),
          children: [
            const Text(
              '여행을 더 자세하게 기록하세요',
              style: TextStyle(
                color: SasangColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 7),
            const SizedBox(
              width: 330,
              child: Text(
                '국가 지도를 열면 도시와 지역 단위로 사진을 남길 수 있어요.',
                style: TextStyle(
                  color: SasangColors.secondary,
                  fontSize: 14,
                  height: 1.42,
                ),
              ),
            ),
            const SizedBox(height: 26),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '국가별 지도',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  '6개',
                  style: TextStyle(
                    color: SasangColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
                childAspectRatio: .78,
              ),
              itemBuilder: (context, index) {
                final product = _products[index];
                return _ProductCard(
                  product: product,
                  region: regions[product.code],
                  onPressed: () =>
                      _showProduct(context, product, regions[product.code]),
                );
              },
            ),
          ],
        );
      },
    ),
  );

  Future<void> _showProduct(
    BuildContext context,
    _Product product,
    MapRegion? region,
  ) => showSasangSheet<void>(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '국가별 상세 지도',
                    style: TextStyle(
                      color: SasangColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF4F4F5),
              onPressed: () => Navigator.pop(context),
              child: const Icon(
                CupertinoIcons.xmark,
                size: 18,
                color: Color(0xFF52525B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: _CountryPreview(region: region, selected: true),
          ),
        ),
        const SizedBox(height: 17),
        Text(
          product.description,
          style: const TextStyle(
            color: Color(0xFF52525B),
            fontSize: 14,
            height: 1.42,
          ),
        ),
        const SizedBox(height: 17),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '지도 가격',
              style: TextStyle(
                color: SasangColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              product.price,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 17),
        const SasangPrimaryButton(onPressed: null, label: '출시 예정'),
      ],
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.region,
    required this.onPressed,
  });

  final _Product product;
  final MapRegion? region;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SasangColors.divider, width: .6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 108,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(child: _CountryPreview(region: region)),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xD118181B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.lock_fill,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SasangColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SasangColors.secondary,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.price,
                        style: const TextStyle(
                          color: SasangColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        '출시 예정',
                        style: TextStyle(
                          color: SasangColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CountryPreview extends StatelessWidget {
  const _CountryPreview({required this.region, this.selected = false});

  final MapRegion? region;
  final bool selected;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: selected ? const Color(0xFFEFF7FF) : const Color(0xFFF4F7F9),
    child: region == null
        ? const Center(child: CupertinoActivityIndicator(radius: 9))
        : CustomPaint(
            painter: _CountryPreviewPainter(
              path: parseSvgPathData(region!.pathData),
              selected: selected,
            ),
          ),
  );
}

class _CountryPreviewPainter extends CustomPainter {
  const _CountryPreviewPainter({required this.path, required this.selected});

  final Path path;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = path.getBounds();
    if (bounds.isEmpty) return;
    final padding = math.max(bounds.width, bounds.height) * .12;
    final padded = bounds.inflate(padding);
    final scale = math.min(
      size.width / padded.width,
      size.height / padded.height,
    );
    final left = (size.width - padded.width * scale) / 2;
    final top = (size.height - padded.height * scale) / 2;
    canvas
      ..save()
      ..translate(left, top)
      ..scale(scale)
      ..translate(-padded.left, -padded.top)
      ..drawPath(
        path,
        Paint()
          ..color = selected
              ? const Color(0xFFB9DAFF)
              : const Color(0xFFDCE5ED),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = .7 / scale
          ..color = selected ? SasangColors.accent : const Color(0xFF81909D),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _CountryPreviewPainter oldDelegate) =>
      oldDelegate.path != path || oldDelegate.selected != selected;
}
