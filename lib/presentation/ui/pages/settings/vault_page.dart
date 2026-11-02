import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/banned_song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/vault_controller.dart';

/// Gün 17 (Kasa): yasaklı şarkıların yönetim ekranı.
///
/// Üç durumu vardır ve [VaultController] üzerindeki gözlemlenebilir alanlar
/// durum geçişlerini otomatik yapar:
/// 1. **Kurulum** — PIN yoksa; kullanıcı 4-6 haneli PIN'i iki kez girer.
/// 2. **Kilit** — PIN var ama oturum kapalı; doğrulama + deneme kilidi
///    geri sayımı.
/// 3. **Liste** — oturum açık; yasaklı şarkılar ve «kasadan çıkar» eylemi.
///
/// Kasadaki dosyalara ASLA dokunulmaz; bu sayfa yalnızca Resonance'ın
/// hangi dosyaları göstermeyeceğine/çalmayacağına ilişkin kaydı yönetir.
/// Ayarlar iki bölmeli düzenine bilinçli olarak gömülmez: hassas içerik
/// yalnız tam ekran kendi rotasında gösterilir (/vault).
///
/// Bulgu 4: PIN doğrulaması artık «oturum boyunca bir kez» değil «her
/// girişte bir kez» sorulur. Sayfadan çıkış (route pop) ve uygulamanın
/// arka plana düşmesi (paused/hidden) anında denetleyici kilitlenir;
/// kullanıcı kasaya HER dönüşünde kilit ekranını görür.
class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Sayfadan her çıkışta yeniden kilitle: bir sonraki girişte PIN sorulur.
    if (Get.isRegistered<VaultController>()) {
      Get.find<VaultController>().lock();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plana inerken (veya ekran kapanırken) de kilitle —
    // kasa açıkken uygulamayı simgeye küçülten kullanıcıya karşı da aynı
    // koruma geçerlidir.
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        Get.isRegistered<VaultController>()) {
      Get.find<VaultController>().lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vault = Get.find<VaultController>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vaultTitle)),
      body: Obx(() {
        if (!vault.hasPin.value) return _SetupView(vault: vault);
        if (!vault.isUnlocked.value) return _LockView(vault: vault);
        return const _VaultListView();
      }),
    );
  }
}

// ---------- 1. Kurulum ----------

class _SetupView extends StatefulWidget {
  const _SetupView({required this.vault});
  final VaultController vault;

  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;

  static final RegExp _pinRe = RegExp(r'^\d{4,6}$');

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final pin = _pinCtrl.text.trim();
    if (!_pinRe.hasMatch(pin)) {
      setState(() => _error = l10n.pinInvalid);
      return;
    }
    if (pin != _confirmCtrl.text.trim()) {
      setState(() => _error = l10n.pinMismatch);
      return;
    }
    await widget.vault.setPin(pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_outline,
                size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              l10n.vaultSetupTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.vaultSetupDesc,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinCtrl,
              decoration:
                  InputDecoration(labelText: l10n.vaultCreatePin, counterText: ''),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              decoration:
                  InputDecoration(labelText: l10n.vaultConfirmPin, counterText: ''),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.lock),
              label: Text(l10n.vaultSetupTitle),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.vaultPinNote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- 2. Kilit ----------

class _LockView extends StatefulWidget {
  const _LockView({required this.vault});
  final VaultController vault;

  @override
  State<_LockView> createState() => _LockViewState();
}

class _LockViewState extends State<_LockView> {
  final _pinCtrl = TextEditingController();
  String? _error;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Deneme kilidi geri sayımı: saniyede bir yeniden çiz.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _unlock() {
    final l10n = AppLocalizations.of(context);
    final vault = widget.vault;
    final ok = vault.verifyPin(_pinCtrl.text.trim());
    if (ok) return; // Obx listeye geçirir.
    setState(() {
      _error = vault.isLockedOut
          ? l10n.pinLocked(vault.lockoutSecondsLeft)
          : l10n.pinWrong;
      _pinCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vault = widget.vault;
    final lockedOut = vault.isLockedOut;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock,
                size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              l10n.vaultEnterPin,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinCtrl,
              decoration: const InputDecoration(counterText: ''),
              enabled: !lockedOut,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _unlock(),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: lockedOut ? null : _unlock,
              icon: const Icon(Icons.lock_open),
              label: Text(l10n.vaultEnterPin),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- 3. Liste ----------

class _VaultListView extends StatelessWidget {
  const _VaultListView();

  Future<void> _confirmUnban(BuildContext context, BannedSongModel entry) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unbanConfirmTitle),
        content: Text(l10n.unbanConfirmBody(entry.title)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.unbanAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Get.find<VaultController>().unban(entry);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vault = Get.find<VaultController>();
    return Obx(() {
      final entries = vault.entries;
      if (entries.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(l10n.vaultEmptyTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  l10n.vaultEmptyDesc,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      }
      return Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final e = entries[index];
                return ListTile(
                  leading: const Icon(Icons.music_off),
                  title: Text(e.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    e.artist ?? e.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: l10n.unbanAction,
                    onPressed: () => _confirmUnban(context, e),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                l10n.vaultPinNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant, height: 1.4),
              ),
            ),
          ),
        ],
      );
    });
  }
}
