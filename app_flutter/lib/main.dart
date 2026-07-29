import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'features/voice.dart';
import 'screens/main_shell.dart';
import 'screens/onboard_screen.dart';
import 'state/app_store.dart';
import 'widgets/device_frame.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const HakoniwaApp());
}

class HakoniwaApp extends StatelessWidget {
  const HakoniwaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStore()..init()),
        // こえメモの再生はアプリ全体で1つ（同時に鳴らさない）
        ChangeNotifierProvider(create: (_) => VoicePlayer()),
      ],
      child: MaterialApp(
        title: 'ハコニワ',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // ダイアログやボトムシートも枠の中に出したいので、
        // Navigator ごと包む builder を使う
        builder: (context, child) => DeviceFrame(child: child!),
        home: const AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    if (!store.ready) {
      return const ColoredBox(color: AppColors.cream, child: SizedBox.expand());
    }
    // 画面切替は fade 0.28s（デザイン指示）
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: store.onboarded
          ? const MainShell(key: ValueKey('main'))
          : const OnboardScreen(key: ValueKey('onboard')),
    );
  }
}
