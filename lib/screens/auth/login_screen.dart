import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../services/credential_storage_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _credentials = CredentialStorageService();

  bool _obscurePassword = true;
  bool _remember = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await _credentials.read();
    if (saved == null || !mounted) return;
    setState(() {
      _emailController.text = saved.email;
      _passwordController.text = saved.password;
      _remember = true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AppAuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final success = await auth.login(email, password);
    if (!success) return;
    if (_remember) {
      await _credentials.save(email, password);
    } else {
      await _credentials.clear();
    }
    TextInput.finishAutofillContext();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final width = MediaQuery.of(context).size.width;
    final formWidth = width > 480 ? 420.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            width > 700
                ? 'assets/images/gym_bg.jpg'
                : 'assets/images/gym_bg_mobile.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: width > 700
                    ? [
                        AppColors.background.withValues(alpha: 0.55),
                        AppColors.background.withValues(alpha: 0.4),
                        AppColors.background.withValues(alpha: 0.6),
                      ]
                    : [
                        AppColors.background.withValues(alpha: 0.3),
                        AppColors.background.withValues(alpha: 0.18),
                        AppColors.background.withValues(alpha: 0.35),
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Center(
            child: Container(
              width: width > 700 ? 520 : 360,
              height: width > 700 ? 520 : 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.background
                        .withValues(alpha: width > 700 ? 0.45 : 0.3),
                    AppColors.background.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: formWidth,
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primaryGlow,
                                    AppColors.primaryDark
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.fitness_center_rounded,
                                  color: Colors.white, size: 38),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'JOJI GYM',
                            style: AppTextStyles.headline.copyWith(
                              letterSpacing: 3,
                              fontSize: 28,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Sign in to continue',
                              style: AppTextStyles.bodyMuted,
                              textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.xl),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.surface
                                  .withValues(alpha: width > 700 ? 0.78 : 0.88),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg + 4),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 30,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppTextField(
                                  label: 'Email',
                                  hint: 'owner@example.com',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: PhosphorIconsRegular.envelope,
                                  autofillHints: const [
                                    AutofillHints.username,
                                    AutofillHints.email
                                  ],
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty)
                                      return 'Email is required';
                                    if (!value.contains('@'))
                                      return 'Enter a valid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  label: 'Password',
                                  hint: 'Enter your password',
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  prefixIcon: PhosphorIconsRegular.lock,
                                  suffixIcon: _obscurePassword
                                      ? PhosphorIconsRegular.eye
                                      : PhosphorIconsRegular.eyeSlash,
                                  onSuffixTap: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _handleLogin(),
                                  validator: (value) =>
                                      (value == null || value.isEmpty)
                                          ? 'Password is required'
                                          : null,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                InkWell(
                                  onTap: () =>
                                      setState(() => _remember = !_remember),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: _remember,
                                            activeColor: AppColors.primary,
                                            side: const BorderSide(
                                                color: AppColors.textDisabled,
                                                width: 1.5),
                                            onChanged: (value) => setState(() =>
                                                _remember = value ?? false),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text('Remember me on this device',
                                            style: AppTextStyles.body
                                                .copyWith(fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                ),
                                if (auth.errorMessage != null) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  Container(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: AppColors.dangerBg,
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusSm),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            PhosphorIconsFill.warningCircle,
                                            size: 20,
                                            color: AppColors.primary),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            auth.errorMessage!,
                                            style: AppTextStyles.body.copyWith(
                                                color: AppColors.primary,
                                                fontSize: 14.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.lg),
                                AppButton(
                                    label: 'Sign In',
                                    onPressed: _handleLogin,
                                    isLoading: auth.isLoading,
                                    fullWidth: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
