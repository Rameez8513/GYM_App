import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/gym_settings_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/premium_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _changePhoto(BuildContext context) async {
    final provider = context.read<SettingsProvider>();
    final hasPhoto = provider.ownerPhotoBytes != null;

    final choice = await showAppBottomSheet<String>(
      context,
      builder: (ctx) => _SheetShell(
        title: 'Owner Photo',
        icon: PhosphorIconsFill.camera,
        gradient: const [AppColors.primaryGlow, AppColors.primaryDark],
        children: [
          _SheetOption(
              icon: PhosphorIconsBold.camera,
              label: 'Take a Photo',
              onTap: () => Navigator.pop(ctx, 'camera')),
          const SizedBox(height: AppSpacing.sm),
          _SheetOption(
              icon: PhosphorIconsBold.image,
              label: 'Choose from Gallery',
              onTap: () => Navigator.pop(ctx, 'gallery')),
          if (hasPhoto) ...[
            const SizedBox(height: AppSpacing.sm),
            _SheetOption(
                icon: PhosphorIconsBold.trash,
                label: 'Remove Photo',
                isDestructive: true,
                onTap: () => Navigator.pop(ctx, 'remove')),
          ],
        ],
      ),
    );

    if (choice == null || !context.mounted) return;

    try {
      if (choice == 'remove') {
        await provider.removeOwnerPhoto();
        return;
      }
      final picked = await ImagePicker().pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 400,
          maxHeight: 400,
          imageQuality: 60);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      await provider.saveOwnerPhoto(bytes);
    } catch (_) {
      if (context.mounted)
        showAppSnackBar(
            context, 'Could not update the photo. Try a smaller image.',
            backgroundColor: AppColors.danger);
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AppAuthProvider>();
    final confirmed = await showAppBottomSheet<bool>(
      context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
        decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4))),
            Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.14),
                    shape: BoxShape.circle),
                child: const Icon(PhosphorIconsBold.signOut,
                    color: AppColors.danger, size: 30)),
            const SizedBox(height: AppSpacing.md),
            Text('Log Out?', style: AppTextStyles.title.copyWith(fontSize: 20)),
            const SizedBox(height: AppSpacing.xs),
            Text('You will need to sign in again to access the admin panel.',
                style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'))),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger),
                        child: const Text('Log Out'))),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) await auth.logout();
  }

  Future<void> _openHelpline(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/923111443400');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWideScreen(context);
    final email = context.read<AppAuthProvider>().user?.email ?? '';
    final settings = context.watch<SettingsProvider>();
    final photo = settings.ownerPhotoBytes;
    final gymSettings = settings.settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: wide ? null : const PremiumAppBar(title: 'Settings'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: wide ? AppSpacing.xl : AppSpacing.md,
              vertical: AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 760 : 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (wide) ...[
                    Text('Settings', style: AppTextStyles.headline),
                    const SizedBox(height: AppSpacing.xl)
                  ],
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        AppColors.primaryGlow,
                        AppColors.primaryDark
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: settings.isSavingPhoto
                              ? null
                              : () => _changePhoto(context),
                          child: Stack(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.15),
                                    border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.4),
                                        width: 2)),
                                padding: const EdgeInsets.all(2.5),
                                child: ClipOval(
                                  child: settings.isSavingPhoto
                                      ? const Center(
                                          child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2.2,
                                                  color: Colors.white)))
                                      : photo != null
                                          ? Image.memory(photo,
                                              fit: BoxFit.cover,
                                              gaplessPlayback: true)
                                          : const Icon(PhosphorIconsFill.user,
                                              size: 38, color: Colors.white70),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.primaryDark,
                                            width: 2)),
                                    child: const Icon(PhosphorIconsBold.camera,
                                        size: 13,
                                        color: AppColors.primaryDark)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(gymSettings.gymName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              if (gymSettings.location.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(children: [
                                  const Icon(PhosphorIconsFill.mapPin,
                                      size: 13, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Expanded(
                                      child: Text(gymSettings.location,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis))
                                ]),
                              ],
                              const SizedBox(height: 3),
                              Text(email,
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 12.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeader('GYM MANAGEMENT'),
                  const SizedBox(height: AppSpacing.sm),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: wide ? 2 : 1,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: wide ? 2.6 : 3.4,
                    children: [
                      _SettingsCard(
                        icon: PhosphorIconsFill.storefront,
                        gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        title: 'Gym Profile',
                        subtitle: gymSettings.facilities.isEmpty
                            ? 'Name, location, facilities'
                            : '${gymSettings.facilities.length} facilities listed',
                        onTap: () => showAppBottomSheet(context,
                            scrollControlled: true,
                            builder: (_) => const _GymProfileSheet()),
                      ),
                      _SettingsCard(
                        icon: PhosphorIconsFill.chatCircleText,
                        gradient: const [Color(0xFF30D158), Color(0xFF1B8A3B)],
                        title: 'Reminder Message',
                        subtitle: 'WhatsApp template for dues',
                        onTap: () => showAppBottomSheet(context,
                            scrollControlled: true,
                            builder: (_) => const _ReminderMessageSheet()),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeader('SUPPORT'),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: AppColors.border)),
                    child: InkWell(
                      onTap: () => _openHelpline(context),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFF30D158),
                                    Color(0xFF1B8A3B)
                                  ]),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm)),
                              child: const Icon(PhosphorIconsBold.whatsappLogo,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Helpline',
                                      style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w700)),
                                  Text('Rameez Mehmood · Software Developer',
                                      style: AppTextStyles.label
                                          .copyWith(fontSize: 12)),
                                  Text('+92 311 1443400',
                                      style: AppTextStyles.bodyMuted
                                          .copyWith(fontSize: 12.5)),
                                ],
                              ),
                            ),
                            const Icon(PhosphorIconsBold.whatsappLogo,
                                color: AppColors.success, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeader('ACCOUNT'),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: AppColors.border)),
                    child: InkWell(
                      onTap: () => _confirmLogout(context),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                    color: AppColors.danger
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm)),
                                child: const Icon(PhosphorIconsRegular.signOut,
                                    size: 22, color: AppColors.danger)),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                                child: Text('Log Out',
                                    style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.danger))),
                            const Icon(PhosphorIconsRegular.caretRight,
                                size: 18, color: AppColors.textDisabled),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Column(
                      children: [
                        Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  AppColors.primaryGlow,
                                  AppColors.primaryDark
                                ]),
                                borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: const Text('JG',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16))),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Joji Gym Admin',
                            style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('Version 1.1.0',
                            style:
                                AppTextStyles.label.copyWith(fontSize: 11.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.label
          .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700));
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsCard(
      {required this.icon,
      required this.gradient,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      boxShadow: [
                        BoxShadow(
                            color: gradient.first.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
                  child: Icon(icon, color: Colors.white, size: 22)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(subtitle,
                        style: AppTextStyles.label.copyWith(fontSize: 11.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(PhosphorIconsRegular.caretRight,
                  size: 16, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final List<Widget> children;

  const _SheetShell(
      {required this.title,
      required this.icon,
      required this.gradient,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4)))),
          Text(title, style: AppTextStyles.title.copyWith(fontSize: 20)),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;
  const _SheetOption(
      {required this.icon,
      required this.label,
      this.isDestructive = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.danger : AppColors.textPrimary;
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.md),
              Text(label,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600, color: color))
            ])),
      ),
    );
  }
}

class _GymProfileSheet extends StatefulWidget {
  const _GymProfileSheet();

  @override
  State<_GymProfileSheet> createState() => _GymProfileSheetState();
}

class _GymProfileSheetState extends State<_GymProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  final TextEditingController _customController = TextEditingController();
  late Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _nameController = TextEditingController(text: settings.gymName);
    _locationController = TextEditingController(text: settings.location);
    _selected = Set<String>.from(settings.facilities);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _customController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<SettingsProvider>().saveProfile(
        gymName: _nameController.text.trim().isEmpty
            ? 'Joji Gym'
            : _nameController.text.trim(),
        location: _locationController.text.trim(),
        facilities: _selected.toList());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(
                    top: AppSpacing.md, bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4))),
            Container(
              margin: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              child: Row(children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm)),
                    child: const Icon(PhosphorIconsFill.storefront,
                        color: Colors.white, size: 22)),
                const SizedBox(width: AppSpacing.md),
                const Text('Gym Profile',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800))
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                children: [
                  Text('GYM NAME',
                      style: AppTextStyles.label.copyWith(letterSpacing: 1)),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                      controller: _nameController,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                          hintText: 'e.g. Joji Gym',
                          prefixIcon:
                              Icon(PhosphorIconsRegular.storefront, size: 19))),
                  const SizedBox(height: AppSpacing.lg),
                  Text('LOCATION',
                      style: AppTextStyles.label.copyWith(letterSpacing: 1)),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                      controller: _locationController,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                          hintText: 'e.g. Jandanwala, Kharian',
                          prefixIcon:
                              Icon(PhosphorIconsRegular.mapPin, size: 19))),
                  const SizedBox(height: AppSpacing.lg),
                  Text('FACILITIES AVAILABLE',
                      style: AppTextStyles.label.copyWith(letterSpacing: 1)),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md - 2),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd)),
                    child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final f in {
                            ...AppConstants.facilityOptions,
                            ..._selected
                          })
                            _FacilityChip(
                                label: f,
                                selected: _selected.contains(f),
                                onTap: () => setState(() =>
                                    _selected.contains(f)
                                        ? _selected.remove(f)
                                        : _selected.add(f)))
                        ]),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: _customController,
                              style: AppTextStyles.body,
                              decoration: const InputDecoration(
                                  hintText: 'Add another facility'))),
                      const SizedBox(width: AppSpacing.sm),
                      Material(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                              onTap: () {
                                final v = _customController.text.trim();
                                if (v.isEmpty) return;
                                setState(() {
                                  _selected.add(v);
                                  _customController.clear();
                                });
                              },
                              child: const SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: Icon(PhosphorIconsBold.plus,
                                      color: Colors.white, size: 20)))),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border))),
              child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50)),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white)))
                          : const Text('Save Profile'))),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderMessageSheet extends StatefulWidget {
  const _ReminderMessageSheet();

  @override
  State<_ReminderMessageSheet> createState() => _ReminderMessageSheetState();
}

class _ReminderMessageSheetState extends State<_ReminderMessageSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: context.read<SettingsProvider>().settings.reminderTemplate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<SettingsProvider>().saveReminderTemplate(
        _controller.text.trim().isEmpty
            ? GymSettingsModel.defaultReminderTemplate
            : _controller.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _controller.text
        .replaceAll('{name}', 'Ali Raza')
        .replaceAll('{amount}', 'PKR 3,000');

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4)))),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF30D158), Color(0xFF1B8A3B)]),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: Row(children: [
                  Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm)),
                      child: const Icon(PhosphorIconsBold.whatsappLogo,
                          color: Colors.white, size: 22)),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                      child: Text('Reminder Message',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)))
                ]),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('MESSAGE TEMPLATE',
                  style: AppTextStyles.label.copyWith(letterSpacing: 1)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: _controller,
                  maxLines: 5,
                  style: AppTextStyles.body,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      hintText: 'Write your reminder message...')),
              const SizedBox(height: AppSpacing.sm),
              Wrap(spacing: AppSpacing.sm, children: [
                _PlaceholderChip(
                    label: '{name}',
                    onTap: () => setState(() => _controller.text += '{name}')),
                _PlaceholderChip(
                    label: '{amount}',
                    onTap: () => setState(() => _controller.text += '{amount}'))
              ]),
              const SizedBox(height: AppSpacing.lg),
              Text('PREVIEW',
                  style: AppTextStyles.label.copyWith(letterSpacing: 1)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3))),
                  child: Text(preview.isEmpty ? '—' : preview,
                      style: AppTextStyles.body.copyWith(fontSize: 14))),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: AppColors.success),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white)))
                          : const Text('Save Message'))),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacilityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FacilityChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md - 2, vertical: 8),
        decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.18)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (selected) ...[
            const Icon(PhosphorIconsBold.check,
                size: 13, color: AppColors.primary),
            const SizedBox(width: 5)
          ],
          Text(label,
              style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500))
        ]),
      ),
    );
  }
}

class _PlaceholderChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PlaceholderChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8)),
            child: Text(label,
                style: AppTextStyles.body.copyWith(
                    fontSize: 12.5,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700))));
  }
}
