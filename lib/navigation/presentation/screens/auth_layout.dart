import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/sportify_theme.dart';
import '../../../features/auth/presentation/viewmodels/auth_view_model.dart';

enum _AuthMode { signin, signup }

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScreen();
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.signin;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isSignUp => _mode == _AuthMode.signup;

  Future<void> _submit(BuildContext context) async {
    final vm = context.read<AuthViewModel>();
    vm.clearError();

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      await vm.signup(fullName: fullName, email: email, password: password);
      return;
    }

    await vm.signin(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SportifySpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(SportifySpacing.md),
                  child: Consumer<AuthViewModel>(
                    builder: (context, vm, _) {
                      final state = vm.state;

                      return Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              _isSignUp ? 'Create account' : 'Sign in',
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: SportifySpacing.sm),
                            Text(
                              _isSignUp
                                  ? 'Join Sportify to save playlists and favorites.'
                                  : 'Welcome back to Sportify.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: SportifySpacing.lg),
                            if (_isSignUp) ...<Widget>[
                              TextFormField(
                                controller: _fullNameController,
                                textInputAction: TextInputAction.next,
                                enabled: !state.isSubmitting,
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                ),
                                validator: (value) {
                                  if (!_isSignUp) return null;
                                  final text = (value ?? '').trim();
                                  if (text.length < 2) {
                                    return 'Full name must be at least 2 characters.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: SportifySpacing.md),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !state.isSubmitting,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                              validator: (value) {
                                final text = (value ?? '').trim();
                                if (!text.contains('@') ||
                                    !text.contains('.')) {
                                  return 'Enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: SportifySpacing.md),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              enabled: !state.isSubmitting,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                              ),
                              onFieldSubmitted: (_) => _submit(context),
                              validator: (value) {
                                final text = value ?? '';
                                if (_isSignUp && text.length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                if (!_isSignUp && text.isEmpty) {
                                  return 'Password is required.';
                                }
                                return null;
                              },
                            ),
                            if (state.errorMessage != null) ...<Widget>[
                              const SizedBox(height: SportifySpacing.md),
                              Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  color: SportifyColors.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: SportifySpacing.lg),
                            FilledButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => _submit(context),
                              child: state.isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isSignUp ? 'Create account' : 'Sign in',
                                    ),
                            ),
                            const SizedBox(height: SportifySpacing.sm),
                            TextButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _mode = _isSignUp
                                            ? _AuthMode.signin
                                            : _AuthMode.signup;
                                      });
                                    },
                              child: Text(
                                _isSignUp
                                    ? 'Have an account? Sign in'
                                    : 'No account? Sign up',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
