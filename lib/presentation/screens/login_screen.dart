import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:gap/gap.dart';
import 'package:joker_state/joker_state.dart';

import '../../data/models/login_status_enum.dart';
import '../../data/repositories/nueip_repository_impl.dart'; // Import Repository
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

    // List of controllers to be managed by trapeze
    final controllers = [
      companyCodeController,
      employeeIdController,
      passwordController,
    ];

    // Get theme colors for the icon
    final iconColor = Theme.of(context).colorScheme.primary;

    // Instantiate repository (replace with DI in real app)
    final repository = Circus.find<NueipRepositoryImpl>();
    // Instantiate Presenter, passing repository
    // Use Circus.summon to manage presenter lifecycle if needed globally or across routes,
    // but direct instantiation is fine for a single screen context like this.
    final presenter = LoginPresenter(repository: repository);

    // Function to show snackbar messages
    // ! TOFIX: in stateless widget, it will throw error sometimes, need to find a better way to handle this
    void showMessage(String message, {bool isError = false}) {
      if (!context.mounted) return;
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

    // Listen to presenter state changes
    presenter.listen((previous, current) {
      // Check current state status
      if (current.status.isSuccess) {
        showMessage('登入成功');
        // Consider navigation or other actions upon successful login
      } else if (current.status.isError) {
        // Use error message from LoginState if available
        final errorMessage = current.errors?.message ?? '登入失敗，請稍後再試';
        showMessage(errorMessage, isError: true);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: controllers.trapeze(
          KeyboardVisibilityBuilder(
            builder: (context, isKeyboardVisible) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: isKeyboardVisible ? 16.0 : 16.0,
                ),
                // Perform UI updates based on presenter's state
                child: presenter.perform(
                  builder: (context, loginState) {
                    // Builder receives LoginState
                    return IgnorePointer(
                      // Use status from LoginState
                      ignoring: loginState.status.isLoading,
                      child: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/images/logo.png'),
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
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                                // Use status from LoginState for onPressed
                                onPressed: () async {
                                  if (loginState.status.isLoading) return;

                                  FocusScope.of(context).unfocus();
                                  if (formKey.currentState?.validate() ??
                                      false) {
                                    final companyCode =
                                        companyCodeController.text;
                                    final employeeId =
                                        employeeIdController.text;
                                    final password = passwordController.text;

                                    CueGate.debounce(
                                      delay: const Duration(microseconds: 200),
                                    ).trigger(() async {
                                      await presenter.login(
                                        companyCode: companyCode,
                                        employeeId: employeeId,
                                        password: password,
                                      );
                                    });
                                  } else {
                                    showMessage('請檢查輸入欄位', isError: true);
                                  }
                                },
                                // Use status from LoginState for button child
                                child: loginState.status.isLoading.reveal(
                                  whenTrue: const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  whenFalse: const Text(
                                    '登入',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
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
