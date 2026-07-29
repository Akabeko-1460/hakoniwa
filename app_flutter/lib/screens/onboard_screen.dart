// 4-1. オンボーディング
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_store.dart';
import '../theme.dart';
import '../widgets/tap_scale.dart';

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> with SingleTickerProviderStateMixin {
  // hako-float 5s ease-in-out infinite（±5px 上下）
  late final _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = screenInsets(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.onboardTop, AppColors.onboardBottom],
          ),
        ),
        child: Column(
          children: [
            // 背の低い画面（横向き・小型端末）でもあふれないよう、
            // 場所があれば中央ぞろえ、足りなければスクロールさせる
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _float,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(
                                0,
                                -5 * Curves.easeInOut.transform(_float.value),
                              ),
                              child: child,
                            ),
                            child: const _HeroFrame(),
                          ),
                          const SizedBox(height: 34),
                          Text(
                            '大切なモノを、\n思い出と一緒に。',
                            textAlign: TextAlign.center,
                            style: AppFonts.maru(30, weight: FontWeight.w900, height: 1.25),
                          ),
                          const SizedBox(height: 16),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: Text(
                              '子どもの宝物を3Dスキャンして、\nちいさなハコニワにのこそう。\n写真やこえメモも いっしょに。',
                              textAlign: TextAlign.center,
                              style: AppFonts.kaku(
                                14,
                                color: AppColors.textFaint,
                                height: 1.9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(28, 0, 28, insets.bottom),
              child: Column(
                children: [
                  TapScale(
                    onTap: () => context.read<AppStore>().setOnboarded(true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: AppRadii.button,
                        boxShadow: [AppShadows.of(0.34, 22, 10, AppColors.accent)],
                      ),
                      child: Center(
                        child: Text('はじめる', style: AppFonts.maru(16, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  TapScale(
                    onTap: () => context.read<AppStore>().setOnboarded(true),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'すでに アカウントを おもちの方',
                        style: AppFonts.kaku(
                          12,
                          weight: FontWeight.w600,
                          color: AppColors.textFaint2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 木枠 210×210px・角丸34px、中にハコニワの部屋、上にピン2つ
class _HeroFrame extends StatelessWidget {
  const _HeroFrame();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(34)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment(0.1, 1),
                colors: [AppColors.woodLight, AppColors.woodDark],
              ),
              boxShadow: [AppShadows.of(0.32, 44, 24)],
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(26)),
                child: Image.asset('assets/room-sample.png', fit: BoxFit.cover),
              ),
            ),
          ),
          const Positioned(left: 67, top: 80, child: _Pin(26, AppColors.accent)),
          const Positioned(right: 55, top: 55, child: _Pin(22, AppColors.green)),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin(this.size, this.color);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 2.5),
      boxShadow: [AppShadows.of(0.30, 11, 4, AppColors.textStrong)],
    ),
  );
}
