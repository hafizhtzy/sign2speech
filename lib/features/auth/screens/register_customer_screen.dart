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

/// Self-registration screen strictly for `CUSTOMER` accounts.
/// Does not expose any role selection for CASHIER or ADMIN.
class RegisterCustomerScreen extends StatefulWidget {
  const RegisterCustomerScreen({super.key});

  @override
  State<RegisterCustomerScreen> createState() => _RegisterCustomerScreenState();
}

class _RegisterCustomerScreenState extends State<RegisterCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _communicationMode = 'deaf';
  final String _preferredSignSystem = 'BISINDO';

  AuthController get _authController => Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final ok = await _authController.registerCustomer(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      communicationMode: _communicationMode,
      preferredSignSystem: _preferredSignSystem,
    );

    if (!mounted) return;
    if (ok) {
      Get.offAllNamed(AppRoutes.mainShell);
    } else if (_authController.errorMessage.value.isNotEmpty) {
      AppSnackbar.error(
        title: AppStrings.authRegisterCustomerTitle.tr,
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.ink,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          AppStrings.authRegisterCustomerTitle.tr,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ResponsiveContentWrapper(
              maxWidth: ResponsiveBreakpoints.maxFormWidth,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.authRegisterCustomerSubtitle.tr,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppStrings.authFullNameLabel.tr,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('register_name_field'),
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: AppStrings.authFullNameHint.tr,
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
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
                              if ((val?.trim() ?? '').isEmpty) {
                                return AppStrings.authValidationRequired.tr;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.authEmailLabel.tr,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('register_email_field'),
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
                            AppStrings.authPhoneLabel.tr,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('register_phone_field'),
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: AppStrings.authPhoneHint.tr,
                              prefixIcon: Icon(
                                Icons.phone_outlined,
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
                            key: const Key('register_password_field'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
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
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _ChoiceChipButton(
                                  label: AppStrings.roleDeaf.tr,
                                  selected: _communicationMode == 'deaf',
                                  onTap: () => setState(
                                    () => _communicationMode = 'deaf',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ChoiceChipButton(
                                  label: AppStrings.roleHearing.tr,
                                  selected: _communicationMode == 'hearing',
                                  onTap: () => setState(
                                    () => _communicationMode = 'hearing',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Obx(
                            () => AppPrimaryButton(
                              key: const Key('register_submit_button'),
                              label: AppStrings.authRegisterBtn.tr,
                              isLoading: auth.isSubmitting.value,
                              onPressed: auth.isSubmitting.value
                                  ? null
                                  : _submitRegister,
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
                            AppStrings.authHaveAccountPrompt.tr,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Get.back(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            child: Text(
                              AppStrings.authGoToLogin.tr,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _ChoiceChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          alignment: .center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(
              color: selected ? AppColors.textOnDark : AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
