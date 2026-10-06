import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../core/storage/sasang_storage.dart';
import '../../core/theme/sasang_theme.dart';
import '../../models/map_models.dart';
import '../../widgets/sasang_ui.dart';
import '../state/sasang_state.dart';
import 'photo_date.dart';

Future<void> showRegionPhotoAlbumSheet({
  required BuildContext context,
  required SasangState state,
  required MapMode mode,
  required MapRegion region,
  required Future<void> Function() onAdd,
}) => showSasangSheet<void>(
  context,
  RegionPhotoAlbumSheet(state: state, mode: mode, region: region, onAdd: onAdd),
);

class RegionPhotoAlbumSheet extends StatefulWidget {
  const RegionPhotoAlbumSheet({
    required this.state,
    required this.mode,
    required this.region,
    required this.onAdd,
    super.key,
  });

  final SasangState state;
  final MapMode mode;
  final MapRegion region;
  final Future<void> Function() onAdd;

  @override
  State<RegionPhotoAlbumSheet> createState() => _RegionPhotoAlbumSheetState();
}

class _RegionPhotoAlbumSheetState extends State<RegionPhotoAlbumSheet> {
  late final PageController _controller;
  int _page = 0;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: .74)
      ..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (mounted) setState(() {});
  }

  Future<void> _add() async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      await widget.onAdd();
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _delete(RegionPhoto photo) async {
    final confirmed = await showSasangConfirmDialog(
      context,
      title: '사진을 삭제할까요?',
      message: '이 지역의 앨범에서 사진이 제거돼요.',
      action: '삭제',
      destructive: true,
    );
    if (!confirmed) return;
    widget.state.removePhoto(widget.mode, widget.region.code, photo.id);
    final length =
        widget.state
            .regionAlbum(widget.mode, widget.region.code)
            ?.photos
            .length ??
        0;
    final nextPage = math.min(_page, length);
    if (!mounted) return;
    setState(() => _page = nextPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) _controller.jumpToPage(nextPage);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.state,
    builder: (context, _) {
      final album = widget.state.regionAlbum(widget.mode, widget.region.code);
      final photos = album?.photos ?? const <RegionPhoto>[];
      final itemCount = photos.length + 1;
      final safePage = _page.clamp(0, itemCount - 1);
      final current = safePage < photos.length ? photos[safePage] : null;
      return Column(
        key: const Key('region-photo-album-sheet'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD4D4D8),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.region.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SasangColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      photos.isEmpty ? '첫 사진을 추가해 보세요' : '사진 ${photos.length}장',
                      style: const TextStyle(
                        color: SasangColors.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                key: const Key('region-album-close'),
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFFF4F4F5),
                onPressed: () => Navigator.pop(context),
                child: const Icon(
                  CupertinoIcons.xmark,
                  color: SasangColors.secondary,
                  size: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 310,
            child: PageView.builder(
              key: const Key('region-photo-carousel'),
              controller: _controller,
              itemCount: itemCount,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                final page = _controller.hasClients
                    ? _controller.page ?? safePage.toDouble()
                    : safePage.toDouble();
                final distance = (index - page).clamp(-1.0, 1.0);
                final scale = 1 - distance.abs() * .065;
                final angle = distance * .045;
                return Transform.translate(
                  offset: Offset(0, distance.abs() * 9),
                  child: Transform.rotate(
                    angle: angle,
                    child: Transform.scale(
                      scale: scale,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: index == photos.length
                            ? _AddPhotoCard(loading: _adding, onPressed: _add)
                            : _AlbumPhotoCard(
                                photo: photos[index],
                                isCover:
                                    album?.coverPhoto?.id == photos[index].id,
                                storage: widget.state.storage,
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: current == null
                ? const SizedBox(key: Key('album-add-caption'), height: 44)
                : Row(
                    key: ValueKey(current.id),
                    children: [
                      Expanded(
                        child: Text(
                          koreanDate(
                            regionPhotoDate(current.takenAt, current.createdAt),
                          ),
                          style: const TextStyle(
                            color: SasangColors.secondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (album?.coverPhoto?.id != current.id)
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          onPressed: () => widget.state.setRegionCoverPhoto(
                            widget.mode,
                            widget.region.code,
                            current.id,
                          ),
                          child: const Text(
                            '대표 사진으로',
                            style: TextStyle(
                              color: SasangColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      CupertinoButton(
                        padding: const EdgeInsets.only(left: 8),
                        onPressed: () => _delete(current),
                        child: const Text(
                          '삭제',
                          style: TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );
    },
  );
}

class _AlbumPhotoCard extends StatefulWidget {
  const _AlbumPhotoCard({
    required this.photo,
    required this.isCover,
    required this.storage,
  });

  final RegionPhoto photo;
  final bool isCover;
  final SasangStorage storage;

  @override
  State<_AlbumPhotoCard> createState() => _AlbumPhotoCardState();
}

class _AlbumPhotoCardState extends State<_AlbumPhotoCard> {
  late Future<File?> _file;

  bool get _isLandscape => widget.photo.width > widget.photo.height;

  double get _landscapeAspectRatio =>
      (widget.photo.width / widget.photo.height).clamp(4 / 3, 16 / 9);

  @override
  void initState() {
    super.initState();
    _file = widget.storage.resolveImage(widget.photo.uri);
  }

  @override
  void didUpdateWidget(covariant _AlbumPhotoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.uri != widget.photo.uri ||
        oldWidget.storage != widget.storage) {
      _file = widget.storage.resolveImage(widget.photo.uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      key: Key('region-album-photo-card-${widget.photo.id}'),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2218181B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<File?>(
              future: _file,
              builder: (context, snapshot) => snapshot.data == null
                  ? const ColoredBox(color: Color(0xFFF4F4F5))
                  : Image.file(snapshot.data!, fit: BoxFit.cover),
            ),
            if (widget.isCover)
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '대표 사진',
                    style: TextStyle(
                      color: SasangColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!_isLandscape) return card;
    return Align(
      alignment: Alignment.center,
      child: AspectRatio(aspectRatio: _landscapeAspectRatio, child: card),
    );
  }
}

class _AddPhotoCard extends StatelessWidget {
  const _AddPhotoCard({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    key: const Key('region-album-add-card'),
    padding: EdgeInsets.zero,
    borderRadius: BorderRadius.circular(24),
    onPressed: loading ? null : onPressed,
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1F007AFF), width: 1.2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: SasangColors.accent,
                shape: BoxShape.circle,
              ),
              child: loading
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    )
                  : const Icon(
                      CupertinoIcons.add,
                      color: CupertinoColors.white,
                      size: 27,
                    ),
            ),
            const SizedBox(height: 14),
            const Text(
              '사진 추가',
              style: TextStyle(
                color: SasangColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              '앨범에서 선택하기',
              style: TextStyle(color: SasangColors.secondary, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
