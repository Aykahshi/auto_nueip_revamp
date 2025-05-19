import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:gap/gap.dart';
import 'package:joker_state/cue_gate.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/login_status_enum.dart';
import '../presenters/login_presenter.dart';

@RoutePage()
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key for FormBuilder
  late final GlobalKey<FormBuilderState> _formKey;
  // Instantiate Presenter, passing repository
  late final LoginPresenter _presenter;

  @override
  void initState() {
    _formKey = GlobalKey<FormBuilderState>();

    _presenter = Circus.find<LoginPresenter>();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Function to show snackbar messages
  void showErrorMessage(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Joker for password visibility state
    final passwordVisibleJoker = Joker<bool>(false);

    // Get theme colors for the icon
    final iconColor = context.colorScheme.primary;

    return _presenter.effect(
      effect: (context, state) {
        // Check current state status
        if (state.isSuccess) {
          context.pushRoute(const HomeRoute());
        } else if (state.isError) {
          // Use error message from LoginState if available
          showErrorMessage('登入失敗，請稍後再試');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(context.i(16)),
              // Perform UI updates based on presenter's state
              child: _presenter.perform(
                builder: (context, loginState) {
                  return IgnorePointer(
                    ignoring: loginState.isLoading,
                    child: FormBuilder(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Circus.find<Joker<AppThemeMode>>('themeMode').perform(
                            builder: (context, themeMode) {
                              final isDarkMode = themeMode == AppThemeMode.dark;

                              return Image.asset(
                                    isDarkMode
                                        ? 'assets/images/logo_dark.png'
                                        : 'assets/images/logo.png',
                                  )
                                  .animate()
                                  .scaleXY(
                                    begin: 0,
                                    end: 1,
                                    duration: 500.ms,
                                    curve: Curves.easeOutBack,
                                  )
                                  .fadeIn();
                            },
                          ),
                          Gap(context.h(16)),
                          FormBuilderTextField(
                                name: 'companyCode',
                                decoration: const InputDecoration(
                                  labelText: '公司代碼',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(
                                    errorText: '請輸入公司代碼',
                                  ),
                                  FormBuilderValidators.numeric(
                                    errorText: '公司代碼只能包含數字',
                                  ),
                                ]),
                                onTapOutside:
                                    (e) => FocusScope.of(context).unfocus(),
                              )
                              .animate()
                              .slideX(
                                begin: -1,
                                end: 0,
                                duration: 400.ms,
                                curve: Curves.easeOutCubic,
                              )
                              .fadeIn(duration: 400.ms, delay: 100.ms),
                          Gap(context.h(16)),
                          FormBuilderTextField(
                                name: 'employeeId',
                                decoration: const InputDecoration(
                                  labelText: '員工編號',
                                  border: OutlineInputBorder(),
                                ),
                                validator: FormBuilderValidators.required(
                                  errorText: '請輸入員工編號',
                                ),
                                onTapOutside:
                                    (e) => FocusScope.of(context).unfocus(),
                              )
                              .animate()
                              .slideX(
                                begin: -1,
                                end: 0,
                                duration: 400.ms,
                                curve: Curves.easeOutCubic,
                                delay: 200.ms,
                              )
                              .fadeIn(duration: 400.ms, delay: 200.ms),
                          Gap(context.h(16)),
                          passwordVisibleJoker.perform(
                            builder: (context, isPasswordVisible) {
                              return FormBuilderTextField(
                                    name: 'password',
                                    decoration: InputDecoration(
                                      labelText: '密碼',
                                      border: const OutlineInputBorder(),
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
                                    ),
                                    obscureText: !isPasswordVisible,
                                    keyboardType: TextInputType.visiblePassword,
                                    validator: FormBuilderValidators.required(
                                      errorText: '請輸入密碼',
                                    ),
                                    onTapOutside:
                                        (e) => FocusScope.of(context).unfocus(),
                                  )
                                  .animate()
                                  .slideX(
                                    begin: -1,
                                    end: 0,
                                    duration: 400.ms,
                                    curve: Curves.easeOutCubic,
                                    delay: 300.ms,
                                  )
                                  .fadeIn(duration: 400.ms, delay: 300.ms);
                            },
                          ),
                          Gap(context.h(24)),
                          ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(
                                    double.infinity,
                                    context.h(48),
                                  ),
                                ),
                                // Use status from LoginState for onPressed
                                onPressed: () async {
                                  if (loginState.isLoading) return;

                                  FocusScope.of(context).unfocus();
                                  // Use saveAndValidate with FormBuilder
                                  if (_formKey.currentState
                                          ?.saveAndValidate() ??
                                      false) {
                                    // Access values from FormBuilder's state
                                    final companyCode =
                                        _formKey
                                            .currentState
                                            ?.value['companyCode'];
                                    final employeeId =
                                        _formKey
                                            .currentState
                                            ?.value['employeeId'];
                                    final password =
                                        _formKey
                                            .currentState
                                            ?.value['password'];

                                    // Ensure values are not null before proceeding
                                    if (companyCode != null &&
                                        employeeId != null &&
                                        password != null) {
                                      CueGate.debounce(
                                        delay: const Duration(
                                          microseconds: 200,
                                        ),
                                      ).trigger(() async {
                                        await _presenter.login(
                                          companyCode: companyCode,
                                          employeeId: employeeId,
                                          password: password,
                                        );
                                      });
                                    }
                                  } else {
                                    showErrorMessage('請檢查輸入欄位');
                                  }
                                },
                                child:
                                    loginState.isLoading
                                        ? SizedBox(
                                          width: context.w(24),
                                          height: context.h(24),
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: context.w(3),
                                          ),
                                        )
                                        : Text(
                                          '登入',
                                          style: TextStyle(
                                            fontSize: context.sp(16),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                              )
                              .animate()
                              .slideX(
                                begin: -1,
                                end: 0,
                                duration: 400.ms,
                                curve: Curves.easeOutCubic,
                                delay: 400.ms,
                              )
                              .fadeIn(duration: 400.ms, delay: 400.ms),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
