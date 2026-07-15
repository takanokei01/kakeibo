import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sample/data/expense_database.dart';

import 'MainPageWidget.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _authSubscription;
  Future<void> _databaseSwitch = Future<void>.value();
  User? _user;
  Object? _error;
  bool _loading = true;
  int _authChangeId = 0;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthChanged,
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _error = error;
          _loading = false;
        });
      },
    );
  }

  Future<void> _handleAuthChanged(User? user) async {
    final authChangeId = ++_authChangeId;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      _databaseSwitch = _databaseSwitch.then(
        (_) => ExpenseDatabase.setUser(user?.uid),
        onError: (_) => ExpenseDatabase.setUser(user?.uid),
      );
      await _databaseSwitch;
      if (!mounted || authChangeId != _authChangeId) return;
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || authChangeId != _authChangeId) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text('データの読み込みに失敗しました: $_error')));
    }
    final user = _user;
    if (user != null) {
      return MainPageWidget(key: ValueKey(user.uid));
    }
    return const LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isRegister = false;
  String? _errorText;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'メールアドレスとパスワードを入力してください。';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _loading = true;
    });
    try {
      if (_isRegister) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      TextInput.finishAutofillContext();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorText = _authErrorMessage(e);
      });
    } catch (e, stackTrace) {
      // Web/desktop でプラグイン未登録の問題が発生した場合、
      // ここで例外内容を表示して診断できるようにします。
      debugPrint('Firebase Auth error: $e');
      debugPrint('$stackTrace');
      setState(() {
        _errorText = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'メールアドレスまたはパスワードが間違っています。';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'email-already-in-use':
        return 'このメールアドレスはすでに登録されています。';
      case 'weak-password':
        return 'パスワードは6文字以上で入力してください。';
      default:
        return '認証に失敗しました。時間をおいてもう一度お試しください。';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MY家計簿')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: const Color(0xFFF7F7F7),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'メールアドレス *',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailController,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(),
                      ),
                      const SizedBox(height: 34),
                      const Text(
                        'パスワード *',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.password],
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_loading) {
                            _submit();
                          }
                        },
                        decoration: _fieldDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                if (_errorText != null) ...[
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 58,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _submit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111827),
                      side: const BorderSide(
                        color: Color(0xFF374151),
                        width: 1.4,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_isRegister ? '新規登録' : 'ログイン'),
                              const SizedBox(width: 56),
                              const Icon(Icons.chevron_right, size: 28),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: _loading ? null : _sendPasswordResetEmail,
                  child: const Text(
                    'パスワードをお忘れですか？',
                    style: TextStyle(color: Color(0xFF6FA0C2), fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                          setState(() {
                            _isRegister = !_isRegister;
                            _errorText = null;
                          });
                        },
                  child: Text(
                    _isRegister ? 'すでにアカウントをお持ちですか？ログイン' : 'アカウントがない場合はこちら',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: Color(0xFF6FA0C2), width: 1.4),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorText = 'パスワード再設定にはメールアドレスを入力してください。';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _errorText = 'パスワード再設定メールを送信しました。';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorText = e.message ?? 'パスワード再設定メールを送信できませんでした。';
      });
    }
  }
}
