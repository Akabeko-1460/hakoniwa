// PCブラウザ（やデスクトップ）で開いたときの見え方をととのえる枠。
//
// このアプリのデザインは「画面の内寸 402×874」を前提にしている
// （design_handoff_hakoniwa/README.md セクション3「デバイス枠」）。
// そのまま全幅に広げるとカードも3Dルームも間のびしてしまうので、
// 画面が広いときだけ電話サイズの中央カラムに収め、まわりは
// 指示書どおり「デバイス外」の背景でうめる。
//
// スマホ（および狭いウィンドウ）では何もせず、これまでどおり全画面で表示する。
import 'package:flutter/material.dart';

import '../theme.dart';

/// デザイン基準の画面内寸
const double kDeviceWidth = 402;
const double kDeviceHeight = 874;

/// これより広いときだけ枠に収める（横向きスマホやタブレットは全画面のまま）
const double kWideBreakpoint = 520;

class DeviceFrame extends StatelessWidget {
  const DeviceFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < kWideBreakpoint) return child;

    // 縦にも余裕があるときだけ角丸の枠にする（低い画面では上下いっぱい使う）
    final framed = media.size.height > kDeviceHeight + 40;
    final height = framed ? kDeviceHeight : media.size.height;
    final width = kDeviceWidth;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          radius: 0.9,
          colors: [AppColors.outsideTop, AppColors.outsideBottom],
        ),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: framed
              ? const BorderRadius.all(Radius.circular(30))
              : BorderRadius.zero,
          child: SizedBox(
            width: width,
            height: height,
            // 枠の中を1台のスマホとして扱う。中の画面が画面サイズを見ても
            // ブラウザの全幅ではなく、この枠のサイズが返るようにする。
            child: MediaQuery(
              data: media.copyWith(size: Size(width, height)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
