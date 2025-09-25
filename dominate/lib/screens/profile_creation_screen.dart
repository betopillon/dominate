import 'package:flutter/material.dart';
import '../models/player_profile.dart';
import '../services/profile_service.dart';

class ProfileCreationScreen extends StatefulWidget {
  final bool isEditing;
  final PlayerProfile? existingProfile;

  const ProfileCreationScreen({
    super.key,
    this.isEditing = false,
    this.existingProfile,
  });

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AvatarOption? _selectedAvatarOption = AvatarOption.astronaut;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _emailError;
  String? _nicknameError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingProfile != null) {
      _loadExistingProfile();
    } else {
      _generateNicknameSuggestion();
    }
  }

  void _loadExistingProfile() {
    final profile = widget.existingProfile!;
    _emailController.text = profile.email;
    _nicknameController.text = profile.nickname;
    _selectedAvatarOption = profile.avatarOption ?? AvatarOption.astronaut;
  }

  void _generateNicknameSuggestion() {
    if (_nicknameController.text.isEmpty) {
      final suggestion = ProfileService.instance.generateNicknameSuggestion();
      _nicknameController.text = suggestion;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profileService = ProfileService.instance;

      // Validate email uniqueness for new profiles
      if (!widget.isEditing) {
        final emailExists = await profileService.emailExists(_emailController.text);
        if (emailExists) {
          setState(() {
            _emailError = 'Email already exists';
            _isLoading = false;
          });
          return;
        }
      }

      if (widget.isEditing) {
        // Only update password if it's provided
        final password = _passwordController.text.isNotEmpty ? _passwordController.text : null;
        await profileService.updateProfile(
          email: _emailController.text,
          nickname: _nicknameController.text,
          password: password,
          avatarType: AvatarType.avatar,
          avatarOption: _selectedAvatarOption,
        );
      } else {
        await profileService.createProfile(
          email: _emailController.text,
          nickname: _nicknameController.text,
          password: _passwordController.text,
          avatarType: AvatarType.avatar,
          avatarOption: _selectedAvatarOption,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? 'Profile updated successfully!' : 'Profile created successfully!',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green.withValues(alpha: 0.8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${widget.isEditing ? 'updating' : 'creating'} profile: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.withValues(alpha: 0.8),
          ),
        );
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF00D4FF),
              Color(0xFF5A67D8),
            ],
          ).createShader(bounds),
          child: Text(
            widget.isEditing ? 'EDIT PROFILE' : 'CREATE PROFILE',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileHeader(),
                const SizedBox(height: 32),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildNicknameField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 16),
                _buildConfirmPasswordField(),
                const SizedBox(height: 24),
                _buildAvatarSelection(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5A67D8).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A67D8).withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAvatarPreview(),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF00D4FF),
                Color(0xFF5A67D8),
              ],
            ).createShader(bounds),
            child: Text(
              widget.isEditing ? 'Update Your Profile' : 'Create Your Space Identity',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPreview() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF00D4FF),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 38,
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        child: _selectedAvatarOption != null
            ? Text(
                _selectedAvatarOption!.emoji,
                style: const TextStyle(fontSize: 32),
              )
            : const Icon(Icons.person_add, size: 32, color: Colors.white70),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _emailError != null
              ? Colors.red.withValues(alpha: 0.6)
              : const Color(0xFF5A67D8).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Email Address',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'your.email@example.com',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.email,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            validator: (value) {
              final error = ProfileService.instance.validateEmail(value ?? '');
              return error;
            },
            onChanged: (value) {
              if (_emailError != null) {
                setState(() => _emailError = null);
              }
            },
          ),
          if (_emailError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _emailError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNicknameField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _nicknameError != null
              ? Colors.red.withValues(alpha: 0.6)
              : const Color(0xFF5A67D8).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nickname',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: _generateNicknameSuggestion,
                child: const Text(
                  'Suggest',
                  style: TextStyle(
                    color: Color(0xFF00D4FF),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nicknameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter nickname (3-10 characters)',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.person,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              counterText: '${_nicknameController.text.length}/10',
              counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
            validator: (value) {
              final error = ProfileService.instance.validateNickname(value ?? '');
              return error;
            },
            onChanged: (value) {
              setState(() {
                if (_nicknameError != null) {
                  _nicknameError = null;
                }
              });
            },
          ),
          if (_nicknameError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _nicknameError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5A67D8).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Avatar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildAvatarGrid(),
        ],
      ),
    );
  }

  Widget _buildAvatarGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: AvatarOption.values.length,
      itemBuilder: (context, index) {
        final option = AvatarOption.values[index];
        final isSelected = _selectedAvatarOption == option;

        return GestureDetector(
          onTap: () => setState(() => _selectedAvatarOption = option),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFF00D4FF).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00D4FF)
                    : Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                option.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A67D8),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Text(
                    widget.isEditing ? 'Update' : 'Create',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _passwordError != null
              ? Colors.red.withValues(alpha: 0.6)
              : const Color(0xFF5A67D8).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEditing ? 'New Password (leave empty to keep current)' : 'Password',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter password (min 6 characters)',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.lock,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (widget.isEditing && (value == null || value.isEmpty)) {
                return null; // Allow empty password when editing (keeps current)
              }
              return ProfileService.instance.validatePassword(value ?? '');
            },
            onChanged: (value) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
          ),
          if (_passwordError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _passwordError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5A67D8).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEditing ? 'Confirm New Password' : 'Confirm Password',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Confirm your password',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            validator: (value) {
              if (widget.isEditing && _passwordController.text.isEmpty) {
                return null; // Skip validation if not changing password
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}