import 'dart:math' as math;

const sasangBottomBarHeight = 66.0;
const sasangBottomBarMinimumInset = 14.0;

double sasangBottomBarTopOffset(double safeBottom) =>
    math.max(safeBottom, sasangBottomBarMinimumInset) + sasangBottomBarHeight;
