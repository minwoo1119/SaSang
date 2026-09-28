import 'dart:math' as math;

const sasangBottomBarHeight = 66.0;
const sasangBottomBarMinimumInset = 14.0;
const sasangMapOverlayOverlap = 36.0;
const sasangZoomControlsSafeAreaOffset = 136.0;

double sasangBottomBarTopOffset(double safeBottom) =>
    math.max(safeBottom, sasangBottomBarMinimumInset) + sasangBottomBarHeight;

double sasangMapOverlayBottomOffset(double safeBottom) =>
    sasangBottomBarTopOffset(safeBottom) - sasangMapOverlayOverlap;

double sasangZoomControlsBottomOffset(double safeBottom) =>
    safeBottom + sasangZoomControlsSafeAreaOffset;
