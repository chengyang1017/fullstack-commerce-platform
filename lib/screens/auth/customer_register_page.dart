import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/customer_auth_cubit.dart';
import '../../services/customer_auth_service.dart';

class CustomerRegisterPage
    extends StatefulWidget {
  const CustomerRegisterPage({
    super.key,
  });

  @override
  State<CustomerRegisterPage>
      createState() {
    return _CustomerRegisterPageState();
  }
}

class _CustomerRegisterPageState
    extends State<CustomerRegisterPage> {
  final _formKey =
      GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController
        .dispose();

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
      ).register(
        name:
            _nameController.text,
        email:
            _emailController.text,
        password:
            _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
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
            '注册失败，请稍后重试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('创建账号'),
      ),
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
                      Text(
                        '注册客户账号',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),

                      TextFormField(
                        controller:
                            _nameController,
                        textInputAction:
                            TextInputAction
                                .next,
                        autofillHints:
                            const [
                          AutofillHints
                              .name,
                        ],
                        decoration:
                            const InputDecoration(
                          labelText:
                              '用户名',
                          prefixIcon:
                              Icon(
                            Icons.person,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        validator:
                            (value) {
                          final name =
                              value?.trim() ??
                                  '';

                          if (name.length <
                                  2 ||
                              name.length >
                                  60) {
                            return '用户名长度必须为 2 至 60 个字符';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
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
                                  .isEmpty ||
                              !email
                                  .contains(
                                '@',
                              )) {
                            return '请输入有效邮箱';
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
                                .next,
                        autofillHints:
                            const [
                          AutofillHints
                              .newPassword,
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
                              value.length <
                                  8) {
                            return '密码至少需要 8 个字符';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextFormField(
                        controller:
                            _confirmPasswordController,
                        obscureText:
                            _obscurePassword,
                        textInputAction:
                            TextInputAction
                                .done,
                        decoration:
                            const InputDecoration(
                          labelText:
                              '确认密码',
                          prefixIcon:
                              Icon(
                            Icons
                                .lock_outline,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        validator:
                            (value) {
                          if (value !=
                              _passwordController
                                  .text) {
                            return '两次输入的密码不一致';
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
                        Text(
                          _errorMessage!,
                          style:
                              TextStyle(
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .error,
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
                                      '注册并登录',
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
      ),
    );
  }
}