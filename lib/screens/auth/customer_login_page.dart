import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/customer_auth_cubit.dart';
import '../../services/customer_auth_service.dart';
import 'customer_register_page.dart';

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({
    super.key,
  });

  @override
  State<CustomerLoginPage> createState() {
    return _CustomerLoginPageState();
  }
}

class _CustomerLoginPageState
    extends State<CustomerLoginPage> {
  final _formKey =
      GlobalKey<FormState>();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting ||
        !_formKey.currentState!
            .validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await BlocProvider.of<
          CustomerAuthCubit>(
        context,
      ).login(
        email:
            _emailController.text,
        password:
            _passwordController.text,
      );
    } on CustomerAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            '登录失败，请稍后重试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void>
      _openRegister() async {
    await Navigator.of(context)
        .push<void>(
      MaterialPageRoute(
        builder: (_) {
          return const CustomerRegisterPage();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 420,
              ),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      const Icon(
                        Icons.shopping_bag,
                        size: 72,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        '欢迎回来',
                        textAlign:
                            TextAlign.center,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        '登录后查看购物车和订单',
                        textAlign:
                            TextAlign.center,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodyMedium,
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      TextFormField(
                        controller:
                            _emailController,
                        keyboardType:
                            TextInputType
                                .emailAddress,
                        textInputAction:
                            TextInputAction
                                .next,
                        autofillHints:
                            const [
                          AutofillHints
                              .email,
                        ],
                        decoration:
                            const InputDecoration(
                          labelText: '邮箱',
                          prefixIcon:
                              Icon(
                            Icons.email,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        validator:
                            (value) {
                          final email =
                              value?.trim() ??
                                  '';

                          if (email
                              .isEmpty) {
                            return '请输入邮箱';
                          }

                          if (!email
                              .contains(
                            '@',
                          )) {
                            return '邮箱格式无效';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      TextFormField(
                        controller:
                            _passwordController,
                        obscureText:
                            _obscurePassword,
                        textInputAction:
                            TextInputAction
                                .done,
                        autofillHints:
                            const [
                          AutofillHints
                              .password,
                        ],
                        decoration:
                            InputDecoration(
                          labelText: '密码',
                          prefixIcon:
                              const Icon(
                            Icons.lock,
                          ),
                          border:
                              const OutlineInputBorder(),
                          suffixIcon:
                              IconButton(
                            onPressed: () {
                              setState(
                                () {
                                  _obscurePassword =
                                      !_obscurePassword;
                                },
                              );
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                      .visibility
                                  : Icons
                                      .visibility_off,
                            ),
                          ),
                        ),
                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .isEmpty) {
                            return '请输入密码';
                          }

                          return null;
                        },
                        onFieldSubmitted:
                            (_) async {
                          await _submit();
                        },
                      ),
                      if (_errorMessage !=
                          null) ...[
                        const SizedBox(
                          height: 16,
                        ),
                        Container(
                          padding:
                              const EdgeInsets
                                  .all(
                            12,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .errorContainer,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style:
                                TextStyle(
                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(
                        height: 24,
                      ),
                      FilledButton(
                        onPressed:
                            _isSubmitting
                                ? null
                                : _submit,
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 14,
                          ),
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                      width:
                                          22,
                                      height:
                                          22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                      ),
                                    )
                                  : const Text(
                                      '登录',
                                    ),
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      TextButton(
                        onPressed:
                            _isSubmitting
                                ? null
                                : _openRegister,
                        child: const Text(
                          '没有账号？立即注册',
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
    );
  }
}