// バックアップ設定 — FastAPI バックエンド（../../backend）への接続。
//
// つないでいなくてもアプリは全機能そのまま動く。つなぐと、
// 端末が壊れても思い出が残り、家族の複数端末で同じハコニワを見られる。
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_store.dart';
import '../theme.dart';
import '../widgets/icons.dart';
import '../widgets/tap_scale.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const BackupScreen());

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _url = TextEditingController(text: 'http://localhost:8000');
  final _token = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppStore>().connectBackup(
        baseUrl: _url.text.trim(),
        token: _token.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('サーバーに つながりました')));
    } on Object catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _message(Object e) {
    final text = e.toString();
    return text.contains('ApiException') ? text.split(': ').last : 'サーバーに つながりませんでした';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final insets = screenInsets(context);
    final creds = store.credentials;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(kScreenPadding, insets.top, kScreenPadding, 10),
            child: Row(
              children: [
                TapScale(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.chipBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: BackIcon()),
                  ),
                ),
                const Spacer(),
                Text('バックアップ', style: AppFonts.maru(16)),
                const Spacer(),
                const SizedBox(width: 38),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 6, kScreenPadding, 24),
              children: [
                Text(
                  'ハコニワを サーバーに 保管すると、端末が こわれても 思い出が のこります。'
                  '家族の べつの端末からも 同じハコニワを 見られます。',
                  style: AppFonts.kaku(12.5, color: AppColors.textFaint, height: 1.8),
                ),
                const SizedBox(height: 20),

                if (creds != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.greenPale,
                      borderRadius: AppRadii.mid,
                      border: Border.all(color: AppColors.greenBorder, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'つながっています',
                          style: AppFonts.maru(14, color: AppColors.greenDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          creds.baseUrl,
                          style: AppFonts.kaku(11, color: AppColors.textMid2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '家族トークン（別の端末から参加するときに使います）',
                          style: AppFonts.kaku(10.5, color: AppColors.textFaint2),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadii.small,
                          ),
                          child: SelectableText(
                            creds.token,
                            style: AppFonts.kaku(10.5, color: AppColors.textMid),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TapScale(
                              onTap: () async {
                                await Clipboard.setData(ClipboardData(text: creds.token));
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('トークンを コピーしました')),
                                );
                              },
                              child: Text(
                                'コピーする',
                                style: AppFonts.maru(12, color: AppColors.greenDark),
                              ),
                            ),
                            const SizedBox(width: 18),
                            TapScale(
                              onTap: _busy ? null : () => store.syncNow(silent: true),
                              child: Text(
                                'いま同期する',
                                style: AppFonts.maru(12, color: AppColors.greenDark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusLine(store),
                    style: AppFonts.kaku(11, color: AppColors.textFaint2),
                  ),
                  const SizedBox(height: 20),
                  TapScale(
                    onTap: () => store.disconnectBackup(),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadii.button,
                        border: Border.all(color: AppColors.border(0.16), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          'サーバーとの 接続をやめる',
                          style: AppFonts.maru(14, color: AppColors.accentRec),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  _Label('サーバーの ばしょ'),
                  _Input(controller: _url, hint: 'http://localhost:8000'),
                  const SizedBox(height: 16),
                  _Label('家族トークン（べつの端末から参加するとき）'),
                  _Input(controller: _token, hint: 'からのままで あたらしく つくります'),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: AppFonts.kaku(11.5, color: AppColors.accentRec)),
                  ],
                  const SizedBox(height: 20),
                  Opacity(
                    opacity: _busy ? 0.6 : 1,
                    child: TapScale(
                      onTap: _busy ? null : _connect,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: AppRadii.button,
                          boxShadow: AppShadows.button,
                        ),
                        child: Center(
                          child: Text(
                            _busy ? 'つないでいます…' : 'サーバーに つなぐ',
                            style: AppFonts.maru(16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'サーバーは ../backend の FastAPI です。'
                    'つながなくても、ハコニワは この端末の中だけで ぜんぶ動きます。',
                    style: AppFonts.kaku(11, color: AppColors.textFaint2, height: 1.7),
                  ),
                ],
                SizedBox(height: math.max(0, insets.bottom - 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLine(AppStore store) => switch (store.syncState) {
    SyncState.syncing => '同期中…',
    SyncState.ok => '最後の同期: 成功',
    SyncState.failed => '最後の同期: ${store.syncError ?? '失敗'}',
    SyncState.idle => 'まだ同期していません',
  };
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: AppFonts.kaku(11, weight: FontWeight.w600, color: AppColors.textFaint2),
    ),
  );
}

class _Input extends StatelessWidget {
  const _Input({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    cursorColor: AppColors.accent,
    style: AppFonts.kaku(13, color: AppColors.textStrong),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: AppFonts.kaku(13, color: AppColors.textFaint4),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: AppRadii.small,
        borderSide: BorderSide(color: AppColors.border(0.14), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.small,
        borderSide: BorderSide(color: AppColors.border(0.14), width: 1.5),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadii.small,
        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
  );
}
