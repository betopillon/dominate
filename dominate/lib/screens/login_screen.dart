import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _loginError;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loginError = null;
    });

    try {
      final profileService = ProfileService.instance;
      final profile = await profileService.login(_emailController.text, _passwordController.text);

      if (profile != null) {
        // Login successful
        if (mounted) {
          Navigator.of(context).pop(profile);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome back, ${profile.nickname}!', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green.withValues(alpha: 0.8)));
        }
      } else {
        // Login failed
        setState(() {
          _loginError = 'Invalid email or password';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loginError = 'Login failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF5A67D8)]).createShader(bounds), child: const Text('LOGIN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2))), backgroundColor: Colors.transparent, foregroundColor: Colors.white, centerTitle: true, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildLoginHeader(),
                const SizedBox(height: 32),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                if (_loginError != null) ...[const SizedBox(height: 16), _buildErrorMessage()],
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF5A67D8).withValues(alpha: 0.5), width: 1), boxShadow: [BoxShadow(color: const Color(0xFF5A67D8).withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2)]),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00D4FF), width: 3), boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)]),
            child: CircleAvatar(radius: 38, backgroundColor: Colors.black.withValues(alpha: 0.5), child: const Icon(Icons.login, size: 32, color: Colors.white70)),
          ),
          const SizedBox(height: 16),
          ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF5A67D8)]).createShader(bounds), child: const Text('Welcome Back, Commander', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF5A67D8).withValues(alpha: 0.3), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Email Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: 'your.email@example.com', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)), border: InputBorder.none, prefixIcon: Icon(Icons.email, color: Colors.white.withValues(alpha: 0.7))),
            validator: (value) {
              return ProfileService.instance.validateEmail(value ?? '');
            },
            onChanged: (value) {
              if (_loginError != null) {
                setState(() => _loginError = null);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF5A67D8).withValues(alpha: 0.3), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.7)),
              suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white.withValues(alpha: 0.7)), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
            onChanged: (value) {
              if (_loginError != null) {
                setState(() => _loginError = null);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1)),
      child: Row(children: [Icon(Icons.error_outline, color: Colors.red.withValues(alpha: 0.8), size: 20), const SizedBox(width: 8), Expanded(child: Text(_loginError!, style: TextStyle(color: Colors.red.withValues(alpha: 0.9), fontSize: 14)))]),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withValues(alpha: 0.5)), padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)))),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A67D8), padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
