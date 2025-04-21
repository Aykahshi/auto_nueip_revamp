import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:gap/gap.dart';
import 'package:joker_state/joker_state.dart';

import '../../data/repositories/nueip_repository_impl.dart'; // Import Repository
import '../../domain/repositories/nueip_repository.dart'; // Import Repository Interface
import '../presenters/login_presenter.dart'; // Import the Presenter

@RoutePage()
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Form key for validation
    final formKey = GlobalKey<FormState>();

    // Create controllers for each text field
    final companyCodeController = TextEditingController();
    final employeeIdController = TextEditingController();
    final passwordController = TextEditingController();

    // Joker for password visibility state
    final passwordVisibleJoker = Joker<bool>(false);
    // Joker for loading state
    final isLoadingJoker = Joker<bool>(false);

    // List of controllers to be managed by trapeze
    final controllers = [
      companyCodeController,
      employeeIdController,
      passwordController,
    ];

    // Get theme colors for the icon
    final iconColor = Theme.of(context).colorScheme.primary;

    // Instantiate repository (replace with DI in real app)
    final NueipRepository nueipRepository = NueipRepositoryImpl();
    // Instantiate Presenter, passing repository
    final presenter = LoginPresenter(repository: nueipRepository);

    // Function to show snackbar messages
    void showMessage(String message, {bool isError = false}) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: controllers.trapeze(
          // Use trapeze with locally defined controllers
          KeyboardVisibilityBuilder(
            builder: (context, isKeyboardVisible) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: isKeyboardVisible ? 16.0 : 16.0,
                ),
                // Use local isLoadingJoker
                child: isLoadingJoker.perform(
                  builder: (context, isLoading) {
                    return IgnorePointer(
                      ignoring: isLoading,
                      child: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/images/logo.png'),
                              // Use local companyCodeController
                              _LoginFormField(
                                controller: companyCodeController,
                                labelText: '公司代碼',
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '請輸入公司代碼';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return '公司代碼只能包含數字';
                                  }
                                  return null;
                                },
                              ),
                              const Gap(16.0),
                              // Use local employeeIdController
                              _LoginFormField(
                                controller: employeeIdController,
                                labelText: '員工編號',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '請輸入員工編號';
                                  }
                                  return null;
                                },
                              ),
                              const Gap(16.0),
                              // Use local passwordVisibleJoker and passwordController
                              passwordVisibleJoker.perform(
                                builder: (context, isPasswordVisible) {
                                  return _LoginFormField(
                                    controller: passwordController,
                                    labelText: '密碼',
                                    obscureText: !isPasswordVisible,
                                    keyboardType: TextInputType.visiblePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '請輸入密碼';
                                      }
                                      return null;
                                    },
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: iconColor,
                                      ),
                                      // Update local passwordVisibleJoker
                                      onPressed: () {
                                        passwordVisibleJoker.trickWith(
                                          (state) => !state,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              const Gap(24.0),
                              // Login Button delegates to Presenter
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                                onPressed:
                                    isLoading
                                        ? null
                                        : () async {
                                          FocusScope.of(context).unfocus();
                                          if (formKey.currentState
                                                  ?.validate() ??
                                              false) {
                                            final companyCode =
                                                companyCodeController.text;
                                            final employeeId =
                                                employeeIdController.text;
                                            final password =
                                                passwordController.text;

                                            // Call Presenter's login method, passing the UI's loading Joker
                                            CueGate.debounce(
                                              delay: const Duration(
                                                microseconds: 200,
                                              ),
                                            ).trigger(() async {
                                              await presenter.login(
                                                companyCode: companyCode,
                                                employeeId: employeeId,
                                                password: password,
                                                loadingJoker: isLoadingJoker,
                                              );
                                            });
                                          } else {
                                            showMessage(
                                              '請檢查輸入欄位',
                                              isError: true,
                                            );
                                          }
                                        },
                                child:
                                    isLoading
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                        : const Text(
                                          '登入',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                              ),
                              if (isKeyboardVisible)
                                Gap(
                                  MediaQuery.viewInsetsOf(context).bottom > 100
                                      ? 100
                                      : MediaQuery.viewInsetsOf(context).bottom,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Reusable Form Field Widget (Moved outside LoginScreen for clarity)
class _LoginFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final AutovalidateMode autovalidateMode;

  const _LoginFormField({
    required this.controller,
    required this.labelText,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autovalidateMode: autovalidateMode,
      validator: validator,
      onTapOutside: (e) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
