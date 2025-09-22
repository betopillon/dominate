import 'package:flutter/material.dart';
import '../models/player_profile.dart';
import '../services/profile_service.dart';
import '../services/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PlayerProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    await ProfileService.instance.initialize();
    setState(() {
      _currentProfile = ProfileService.instance.currentProfile;
    });
  }

  void _showCreateAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _CreateAccountDialog(
            currentProfile: _currentProfile,
            onAccountCreated: () async {
              await _loadCurrentProfile();
            },
          ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _LoginDialog(
            onLoginSuccess: () async {
              await _loadCurrentProfile();
            },
          ),
    );
  }

  void _showUpgradeDialog() {
    if (_currentProfile == null) return;

    showDialog(
      context: context,
      builder:
          (context) => _UpgradeAccountDialog(
            currentProfile: _currentProfile!,
            onUpgradeComplete: () async {
              await _loadCurrentProfile();
            },
          ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.black.withValues(alpha: 0.9),
            title: Text('Logout', style: TextStyle(color: Colors.white)),
            content: Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.6)))), TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Logout', style: TextStyle(color: Colors.red)))],
          ),
    );

    if (confirm == true) {
      await ProfileService.instance.logout();
      await _loadCurrentProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out successfully'), backgroundColor: Colors.green));
      }
    }
  }

  void _showEditProfileDialog() {
    if (_currentProfile == null) return;

    showDialog(
      context: context,
      builder:
          (context) => _EditProfileDialog(
            currentProfile: _currentProfile!,
            onEditComplete: () async {
              await _loadCurrentProfile();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF5A67D8)]).createShader(bounds), child: const Text('SETTINGS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2))), backgroundColor: Colors.transparent, foregroundColor: Colors.white, centerTitle: true, elevation: 0),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: Column(children: [const SizedBox(height: 20), _buildProfileSection(), const SizedBox(height: 24), _buildSettingsOptions()]))),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF5A67D8).withValues(alpha: 0.5), width: 1), boxShadow: [BoxShadow(color: const Color(0xFF5A67D8).withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2)]),
      child: Column(children: [_buildProfileAvatar(), const SizedBox(height: 16), _buildProfileInfo(), const SizedBox(height: 20), _buildProfileActions()]),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00D4FF), width: 3), boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)]),
      child: CircleAvatar(radius: 38, backgroundColor: Colors.black.withValues(alpha: 0.5), child: _currentProfile?.avatarType == AvatarType.avatar && _currentProfile?.avatarOption != null ? Text(_currentProfile!.avatarOption!.emoji, style: const TextStyle(fontSize: 32)) : const Icon(Icons.person, size: 32, color: Colors.white70)),
    );
  }

  Widget _buildProfileInfo() {
    if (_currentProfile == null) {
      return Column(
        children: [
          ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF5A67D8)]).createShader(bounds), child: const Text('No Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
          const SizedBox(height: 8),
          Text('Create a profile to save your progress', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)), textAlign: TextAlign.center),
        ],
      );
    }

    return Column(
      children: [
        ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF5A67D8)]).createShader(bounds), child: Text(_currentProfile!.nickname, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
        if (_currentProfile!.isRegistered) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_currentProfile!.isEmailVerified ? Icons.verified : Icons.email, size: 16, color: _currentProfile!.isEmailVerified ? Colors.green : Colors.orange), const SizedBox(width: 4), Text(_currentProfile!.email, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)))]),
        ] else ...[
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1)), child: const Text('Temporary Profile', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500))),
        ],
      ],
    );
  }

  Widget _buildProfileActions() {
    if (_currentProfile == null) {
      return SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _showCreateAccountDialog, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A67D8), padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500))));
    }

    if (!_currentProfile!.isRegistered) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _showUpgradeDialog, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('Upgrade Account', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500)))),
          const SizedBox(height: 8),
          Text('Save your progress permanently', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)), textAlign: TextAlign.center),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: _showEditProfileDialog, style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withValues(alpha: 0.5)), padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(onPressed: _logout, style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.7), padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)))),
      ],
    );
  }

  Widget _buildSettingsOptions() {
    return Column(
      children: [
        // Audio Settings Section
        _buildAudioSettings(),
        const SizedBox(height: 24),

        // Account Settings Section
        // Show login option only if no registered user is logged in
        if (_currentProfile == null || !_currentProfile!.isRegistered) ...[_buildSettingsTile(icon: Icons.login, title: 'Login', subtitle: 'Access your saved profile', onTap: _showLoginDialog), const SizedBox(height: 12)],
        _buildSettingsTile(
          icon: Icons.info,
          title: 'About',
          subtitle: 'App version and information',
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    backgroundColor: const Color.fromARGB(255, 49, 49, 49).withValues(alpha: 0.9),
                    title: Row(children: [Icon(Icons.info, color: Color(0xFF00D4FF), size: 24), const SizedBox(width: 12), Text('About Dominate', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
                    content: Text('Dominate Beta Version by Beto Game\n\nMusic: 93 BPM Industrial Ambient Loop #5314 (WAV) by looplicator -- https://freesound.org/s/755441/ -- License: Attribution 4.0', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.5)),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: Color(0xFF00D4FF))))],
                  ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAudioSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Audio Section Title
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('Audio', style: TextStyle(fontFamily: 'Futura', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.9), letterSpacing: 1.0))),
        const SizedBox(height: 12),

        // Music Toggle
        Container(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF5A67D8).withValues(alpha: 0.3), width: 1)),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF5A67D8).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.music_note, color: Colors.white, size: 24)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Background Music', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)), Text('Play ambient background music', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)))])),
                  Switch(
                    value: AudioService.instance.isMusicEnabled,
                    onChanged: (value) async {
                      await AudioService.instance.setMusicEnabled(value);
                      setState(() {});
                    },
                    activeColor: const Color(0xFF00D4FF),
                    activeTrackColor: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Volume Control
        Container(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF5A67D8).withValues(alpha: 0.3), width: 1)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF5A67D8).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.volume_up, color: Colors.white, size: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Music Volume', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)), Text('${(AudioService.instance.musicVolume * 100).round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF00D4FF)))]),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(trackHeight: 4, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8), overlayShape: RoundSliderOverlayShape(overlayRadius: 16), activeTrackColor: const Color(0xFF00D4FF), inactiveTrackColor: Colors.white.withValues(alpha: 0.2), thumbColor: const Color(0xFF00D4FF), overlayColor: const Color(0xFF00D4FF).withValues(alpha: 0.2)),
                        child: Slider(
                          value: AudioService.instance.musicVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          onChanged: (value) async {
                            await AudioService.instance.setMusicVolume(value);
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF5A67D8).withValues(alpha: 0.3), width: 1)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF5A67D8).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 24)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)), Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)))])),
                Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.5), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Create Account Dialog
class _CreateAccountDialog extends StatefulWidget {
  final PlayerProfile? currentProfile;
  final VoidCallback onAccountCreated;

  const _CreateAccountDialog({required this.currentProfile, required this.onAccountCreated});

  @override
  State<_CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<_CreateAccountDialog> {
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _emailError;
  String? _nicknameError;
  String? _passwordError;
  String? _generalError;

  AvatarOption _selectedAvatar = AvatarOption.astronaut;

  @override
  void initState() {
    super.initState();
    if (widget.currentProfile != null) {
      _nicknameController.text = widget.currentProfile!.nickname;
      _selectedAvatar = widget.currentProfile!.avatarOption ?? AvatarOption.astronaut;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFF00D4FF).withValues(alpha: 0.5)), boxShadow: [BoxShadow(color: Color(0xFF00D4FF).withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)]),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [Icon(Icons.person_add, color: Color(0xFF00D4FF), size: 28), const SizedBox(width: 12), Expanded(child: Text('Create Account', style: TextStyle(fontFamily: 'Futura', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))), IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.6)))]),
              const SizedBox(height: 16),

              Text('Save your progress and compete globally', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
              const SizedBox(height: 20),

              if (_generalError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.5))),
                  child: Row(children: [Icon(Icons.error, color: Colors.red, size: 20), const SizedBox(width: 8), Expanded(child: Text(_generalError!, style: TextStyle(color: Colors.red, fontSize: 12)))]),
                ),
                const SizedBox(height: 16),
              ],

              // Avatar Selection
              Text('Choose Avatar', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      AvatarOption.values.take(6).map((avatar) {
                        final isSelected = avatar == _selectedAvatar;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatar = avatar),
                          child: Container(
                            width: 50,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(color: isSelected ? Color(0xFF00D4FF).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? Color(0xFF00D4FF) : Colors.white.withValues(alpha: 0.2), width: isSelected ? 2 : 1)),
                            child: Center(child: Text(avatar.emoji, style: TextStyle(fontSize: 24))),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Form Fields
              _buildCompactTextField(controller: _emailController, label: 'Email', hint: 'Enter your email', icon: Icons.email, error: _emailError, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),

              _buildCompactTextField(controller: _nicknameController, label: 'Nickname', hint: 'Choose a nickname', icon: Icons.person, error: _nicknameError, maxLength: 10),
              const SizedBox(height: 12),

              _buildCompactTextField(controller: _passwordController, label: 'Password', hint: 'At least 6 characters', icon: Icons.lock, error: _passwordError, obscureText: true),
              const SizedBox(height: 12),

              _buildCompactTextField(controller: _confirmPasswordController, label: 'Confirm Password', hint: 'Re-enter password', icon: Icons.lock_outline, obscureText: true),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))))),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleCreateAccount,
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00D4FF), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: _isLoading ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, String? error, bool obscureText = false, TextInputType? keyboardType, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8), border: Border.all(color: error != null ? Colors.red : Colors.white.withValues(alpha: 0.2))),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLength: maxLength,
            style: TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14), prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 18), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), counterText: ''),
          ),
        ),
        if (error != null) ...[const SizedBox(height: 2), Text(error, style: TextStyle(color: Colors.red, fontSize: 11))],
      ],
    );
  }

  Future<void> _handleCreateAccount() async {
    setState(() {
      _emailError = null;
      _nicknameError = null;
      _passwordError = null;
      _generalError = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final nickname = _nicknameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hasError = false;

    // Validate inputs
    final emailValidation = ProfileService.instance.validateEmail(email);
    if (emailValidation != null) {
      setState(() => _emailError = emailValidation);
      hasError = true;
    }

    final nicknameValidation = ProfileService.instance.validateNickname(nickname);
    if (nicknameValidation != null) {
      setState(() => _nicknameError = nicknameValidation);
      hasError = true;
    }

    final passwordValidation = ProfileService.instance.validatePassword(password);
    if (passwordValidation != null) {
      setState(() => _passwordError = passwordValidation);
      hasError = true;
    }

    if (password != confirmPassword) {
      setState(() => _passwordError = 'Passwords do not match');
      hasError = true;
    }

    if (hasError) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Check email and nickname availability
      final emailExists = await ProfileService.instance.emailExists(email);
      if (emailExists) {
        setState(() {
          _emailError = 'Email already registered';
          _isLoading = false;
        });
        return;
      }

      final nicknameAvailable = await ProfileService.instance.isNicknameAvailable(nickname);
      if (!nicknameAvailable) {
        setState(() {
          _nicknameError = 'Nickname not available';
          _isLoading = false;
        });
        return;
      }

      // Create account
      await ProfileService.instance.createProfile(email: email, nickname: nickname, password: password, avatarType: AvatarType.avatar, avatarOption: _selectedAvatar);

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account created successfully!'), backgroundColor: Colors.green));
        widget.onAccountCreated();
      }
    } catch (e) {
      setState(() {
        _generalError = 'Failed to create account: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}

// Login Dialog
class _LoginDialog extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const _LoginDialog({required this.onLoginSuccess});

  @override
  State<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<_LoginDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 350),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFF00D4FF).withValues(alpha: 0.5)), boxShadow: [BoxShadow(color: Color(0xFF00D4FF).withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)]),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [Icon(Icons.login, color: Color(0xFF00D4FF), size: 28), const SizedBox(width: 12), Expanded(child: Text('Welcome Back', style: TextStyle(fontFamily: 'Futura', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))), IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.6)))]),
              const SizedBox(height: 8),

              Text('Sign in to your account', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
              const SizedBox(height: 20),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.5))),
                  child: Row(children: [Icon(Icons.error, color: Colors.red, size: 20), const SizedBox(width: 8), Expanded(child: Text(_error!, style: TextStyle(color: Colors.red, fontSize: 12)))]),
                ),
                const SizedBox(height: 16),
              ],

              // Email Field
              _buildCompactTextField(controller: _emailController, label: 'Email', hint: 'Enter your email', icon: Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              // Password Field
              _buildCompactTextField(controller: _passwordController, label: 'Password', hint: 'Enter your password', icon: Icons.lock, obscureText: true),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))))),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00D4FF), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: _isLoading ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, bool obscureText = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14), prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 18), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Please enter both email and password';
        _isLoading = false;
      });
      return;
    }

    try {
      final profile = await ProfileService.instance.login(email, password);

      if (profile != null) {
        setState(() => _isLoading = false);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome back, ${profile.nickname}!'), backgroundColor: Colors.green));
          widget.onLoginSuccess();
        }
      } else {
        setState(() {
          _error = 'Invalid email or password';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Login failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}

// Upgrade Account Dialog (reuse from player_profile_screen.dart)
class _UpgradeAccountDialog extends StatefulWidget {
  final PlayerProfile currentProfile;
  final VoidCallback onUpgradeComplete;

  const _UpgradeAccountDialog({required this.currentProfile, required this.onUpgradeComplete});

  @override
  State<_UpgradeAccountDialog> createState() => _UpgradeAccountDialogState();
}

class _UpgradeAccountDialogState extends State<_UpgradeAccountDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: 500),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFF00D4FF).withValues(alpha: 0.5)), boxShadow: [BoxShadow(color: Color(0xFF00D4FF).withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)]),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [Icon(Icons.upgrade, color: Color(0xFF00D4FF), size: 28), const SizedBox(width: 12), Expanded(child: Text('Upgrade Account', style: TextStyle(fontFamily: 'Futura', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))), IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.6)))]),
              const SizedBox(height: 12),

              // Current Profile Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
                child: Row(
                  children: [
                    Text(widget.currentProfile.avatarOption?.emoji ?? '👤', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.currentProfile.nickname, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)), Text('Temporary Account', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w600))])),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_generalError != null) ...[Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.withValues(alpha: 0.5))), child: Text(_generalError!, style: TextStyle(color: Colors.red, fontSize: 11))), const SizedBox(height: 12)],

              // Form Fields
              _buildCompactTextField(controller: _emailController, label: 'Email Address', hint: 'Enter your email', icon: Icons.email, error: _emailError, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),

              _buildCompactTextField(controller: _passwordController, label: 'Password', hint: 'Create a secure password', icon: Icons.lock, error: _passwordError, obscureText: true),
              const SizedBox(height: 12),

              _buildCompactTextField(controller: _confirmPasswordController, label: 'Confirm Password', hint: 'Re-enter your password', icon: Icons.lock_outline, obscureText: true),
              const SizedBox(height: 16),

              // Benefits
              Text('Benefits:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('🏆 Global rankings  💾 Save progress  📱 Sync devices', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))))),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleUpgrade,
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00D4FF), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: _isLoading ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, String? error, bool obscureText = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8), border: Border.all(color: error != null ? Colors.red : Colors.white.withValues(alpha: 0.2))),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14), prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 18), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
          ),
        ),
        if (error != null) ...[const SizedBox(height: 2), Text(error, style: TextStyle(color: Colors.red, fontSize: 11))],
      ],
    );
  }

  Future<void> _handleUpgrade() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hasError = false;

    // Validate email
    final emailValidation = ProfileService.instance.validateEmail(email);
    if (emailValidation != null) {
      setState(() => _emailError = emailValidation);
      hasError = true;
    }

    // Validate password
    final passwordValidation = ProfileService.instance.validatePassword(password);
    if (passwordValidation != null) {
      setState(() => _passwordError = passwordValidation);
      hasError = true;
    }

    // Check password confirmation
    if (password != confirmPassword) {
      setState(() => _passwordError = 'Passwords do not match');
      hasError = true;
    }

    if (hasError) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Check if email already exists
      final emailExists = await ProfileService.instance.emailExists(email);
      if (emailExists) {
        setState(() {
          _emailError = 'Email already registered';
          _isLoading = false;
        });
        return;
      }

      // Convert temporary account to permanent
      final upgradedProfile = await ProfileService.instance.convertToPermanentAccount(email: email, nickname: widget.currentProfile.nickname, password: password, avatarType: AvatarType.avatar, avatarOption: widget.currentProfile.avatarOption ?? AvatarOption.astronaut);

      if (upgradedProfile != null) {
        setState(() => _isLoading = false);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account upgraded successfully!'), backgroundColor: Colors.green));
          widget.onUpgradeComplete();
        }
      } else {
        setState(() {
          _generalError = 'Failed to upgrade account. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _generalError = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}

class _EditProfileDialog extends StatefulWidget {
  final PlayerProfile currentProfile;
  final VoidCallback onEditComplete;

  const _EditProfileDialog({required this.currentProfile, required this.onEditComplete});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _nicknameController = TextEditingController();
  String? _nicknameError;
  bool _isLoading = false;
  AvatarOption _selectedAvatar = AvatarOption.astronaut;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.currentProfile.nickname;
    _selectedAvatar = widget.currentProfile.avatarOption ?? AvatarOption.astronaut;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      title: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF00D4FF).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit, color: Color(0xFF00D4FF), size: 20)), const SizedBox(width: 12), const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Selection
            const Text('Avatar', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      AvatarOption.values.map((avatar) {
                        final isSelected = _selectedAvatar == avatar;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatar = avatar),
                          child: Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(color: isSelected ? const Color(0xFF00D4FF).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: isSelected ? const Color(0xFF00D4FF) : Colors.white.withValues(alpha: 0.3), width: isSelected ? 2 : 1)),
                            child: Center(child: Text(avatar.emoji, style: const TextStyle(fontSize: 24))),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nickname Field
            const Text('Nickname', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your nickname',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00D4FF))),
                errorText: _nicknameError,
                errorStyle: const TextStyle(color: Colors.red),
              ),
              onChanged: (value) {
                if (_nicknameError != null) {
                  setState(() => _nicknameError = null);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.6)))),
        ElevatedButton(onPressed: _isLoading ? null : _saveProfile, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), foregroundColor: Colors.black), child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Save')),
      ],
    );
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();

    // Validate nickname
    if (nickname.isEmpty) {
      setState(() => _nicknameError = 'Nickname is required');
      return;
    }

    if (nickname.length < 2) {
      setState(() => _nicknameError = 'Nickname must be at least 2 characters');
      return;
    }

    if (nickname.length > 20) {
      setState(() => _nicknameError = 'Nickname must be 20 characters or less');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if nickname is available (if it's different from current)
      if (nickname != widget.currentProfile.nickname) {
        final isAvailable = await ProfileService.instance.isNicknameAvailable(nickname);
        if (!isAvailable) {
          setState(() {
            _nicknameError = 'Nickname is already taken';
            _isLoading = false;
          });
          return;
        }
      }

      // Update the profile
      await ProfileService.instance.updateProfile(nickname: nickname, avatarOption: _selectedAvatar);

      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
        widget.onEditComplete();
      }
    } catch (e) {
      setState(() {
        _nicknameError = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}
