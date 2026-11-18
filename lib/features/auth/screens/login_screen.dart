import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/auth/controllers/auth_controller.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/responsive_layout.dart';

/// Responsive Three-Role Login Screen (`CUSTOMER`, `CASHIER`, `ADMIN`).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  AuthController get _authController => Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final ok = await _authController.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (ok) {
      Get.offAllNamed(_authController.homeRouteForCurrentRole);
    } else if (_authController.errorMessage.value.isNotEmpty) {
      AppSnackbar.error(
        title: AppStrings.authLoginTitle.tr,
        message: _authController.errorMessage.value,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = _authController;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.appTitle.tr,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ResponsiveContentWrapper(
              maxWidth: ResponsiveBreakpoints.maxFormWidth,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.coffee_rounded,
                          color: AppColors.textOnDark,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.authLoginTitle.tr,
                      textAlign: .center,
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.authLoginSubtitle.tr,
                      textAlign: .center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(() {
                      final msg = auth.errorMessage.value;
                      if (msg.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  msg,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppStrings.authEmailLabel.tr,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('login_email_field'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: AppStrings.authEmailHint.tr,
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.muted,
                              ),
                              filled: true,
                              fillColor: AppColors.bgSurface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                            ),
                            validator: (val) {
                              final text = val?.trim() ?? '';
                              if (text.isEmpty) {
                                return AppStrings.authValidationRequired.tr;
                              }
                              if (!text.contains('@') || !text.contains('.')) {
                                return AppStrings.authValidationEmail.tr;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.authPasswordLabel.tr,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('login_password_field'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submitLogin(),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: AppStrings.authPasswordHint.tr,
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.muted,
                              ),
                              suffixIcon: SizedBox(
                                width: 48,
                                height: 48,
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.bgSurface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                            ),
                            validator: (val) {
                              final text = val ?? '';
                              if (text.isEmpty) {
                                return AppStrings.authValidationRequired.tr;
                              }
                              if (text.length < 6) {
                                return AppStrings.authValidationPasswordMin.tr;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Obx(
                            () => AppPrimaryButton(
                              key: const Key('login_submit_button'),
                              label: AppStrings.authSignInBtn.tr,
                              isLoading: auth.isSubmitting.value,
                              onPressed: auth.isSubmitting.value
                                  ? null
                                  : _submitLogin,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: .center,
                      children: [
                        Flexible(
                          child: Text(
                            AppStrings.authNoAccountPrompt.tr,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          key: const Key('go_to_register_button'),
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Get.toNamed(AppRoutes.registerCustomer),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            child: Text(
                              AppStrings.authGoToRegister.tr,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: InkWell(
                        key: const Key('continue_accessibility_button'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Get.offAllNamed(AppRoutes.mainShell),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sign_language_rounded,
                                color: AppColors.ink,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  AppStrings.authContinueAccessibilityGuest.tr,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
