import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../models/player_profile.dart';
import '../models/game_stats.dart';

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  PlayerProfile? _currentProfile;
  bool _isLoading = false;

  // Registration form controllers
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Login form controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  AvatarOption _selectedAvatar = AvatarOption.astronaut;
  String? _emailError;
  String? _nicknameError;
  String? _passwordError;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    setState(() {
      _currentProfile = ProfileService.instance.currentProfile;
      if (_currentProfile != null) {
        _nicknameController.text = _currentProfile!.nickname;
        _selectedAvatar = _currentProfile!.avatarOption ?? AvatarOption.astronaut;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('Player Profile', style: TextStyle(fontFamily: 'Futura', fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      body: _currentProfile?.isRegistered == true
          ? _buildRegisteredPlayerView()
          : _buildAuthenticationView(),
    );
  }

  Widget _buildRegisteredPlayerView() {
    final profile = _currentProfile!;
    final totalStats = profile.stats.totalStats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF00D4FF).withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF00D4FF).withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF00D4FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    profile.avatarOption?.emoji ?? '👤',
                    style: TextStyle(fontSize: 48),
                  ),
                ),
                const SizedBox(height: 16),
                // Nickname
                Text(
                  profile.nickname,
                  style: TextStyle(
                    fontFamily: 'Futura',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Registered Player',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Stats
          Row(
            children: [
              Expanded(child: _buildStatCard('Matches', totalStats.matchesPlayed.toString(), Icons.sports_esports, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Win Rate', '${totalStats.winRate.toStringAsFixed(1)}%', Icons.trending_up, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Best Streak', totalStats.bestWinStreak.toString(), Icons.local_fire_department, Colors.orange)),
            ],
          ),
          const SizedBox(height: 24),

          // Detailed Stats
          _buildDetailedStats(profile.stats),
          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAuthenticationView() {
    return Column(
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Color(0xFF00D4FF),
            labelColor: Color(0xFF00D4FF),
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            labelStyle: TextStyle(fontFamily: 'Futura', fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Register'),
              Tab(text: 'Login'),
              Tab(text: 'Profile'),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRegistrationTab(),
              _buildLoginTab(),
              _buildProfileTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Account',
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save your progress and compete globally',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Avatar Selection
          Text(
            'Choose Your Avatar',
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildAvatarSelection(),
          const SizedBox(height: 24),

          // Email Field
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email address',
            icon: Icons.email,
            error: _emailError,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Nickname Field
          _buildTextField(
            controller: _nicknameController,
            label: 'Nickname',
            hint: 'Choose a unique nickname',
            icon: Icons.person,
            error: _nicknameError,
            maxLength: 10,
          ),
          const SizedBox(height: 16),

          // Password Field
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'At least 6 characters',
            icon: Icons.lock,
            error: _passwordError,
            obscureText: true,
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 32),

          // Register Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00D4FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : Text(
                      'Create Account',
                      style: TextStyle(
                        fontFamily: 'Futura',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back',
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to your account',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          if (_loginError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_loginError!, style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Email Field
          _buildTextField(
            controller: _loginEmailController,
            label: 'Email',
            hint: 'Enter your email address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Password Field
          _buildTextField(
            controller: _loginPasswordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock,
            obscureText: true,
          ),
          const SizedBox(height: 32),

          // Login Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00D4FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : Text(
                      'Sign In',
                      style: TextStyle(
                        fontFamily: 'Futura',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    if (_currentProfile == null) {
      return Center(
        child: Text(
          'No profile available',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Profile',
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          // Current Profile Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Text(
                  _currentProfile!.avatarOption?.emoji ?? '👤',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  _currentProfile!.nickname,
                  style: TextStyle(
                    fontFamily: 'Futura',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'Temporary Account',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Upgrade Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF00D4FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF00D4FF).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.upgrade, color: Color(0xFF00D4FF), size: 32),
                const SizedBox(height: 8),
                Text(
                  'Upgrade to Save Progress',
                  style: TextStyle(
                    fontFamily: 'Futura',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a permanent account to save your game progress, compete on leaderboards, and sync across devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showUpgradeDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00D4FF),
                    foregroundColor: Colors.black,
                  ),
                  child: Text('Upgrade Account'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSelection() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: AvatarOption.values.map((avatar) {
          final isSelected = avatar == _selectedAvatar;
          return GestureDetector(
            onTap: () => setState(() => _selectedAvatar = avatar),
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Color(0xFF00D4FF).withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Color(0xFF00D4FF)
                      : Colors.white.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(avatar.emoji, style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    avatar.displayName.split(' ').last,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? error,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Futura',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null
                  ? Colors.red
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLength: maxLength,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '',
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(PlayerStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Statistics',
            style: TextStyle(
              fontFamily: 'Futura',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Total Matches', stats.totalStats.matchesPlayed.toString()),
          _buildStatRow('Wins', stats.totalStats.wins.toString()),
          _buildStatRow('Losses', stats.totalStats.losses.toString()),
          _buildStatRow('Draws', stats.totalStats.draws.toString()),
          _buildStatRow('Best Win Streak', stats.totalStats.bestWinStreak.toString()),
          _buildStatRow('Comeback Wins', stats.totalStats.comebackWins.toString()),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Futura',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Edit Profile Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to edit profile
            },
            icon: Icon(Icons.edit, size: 20),
            label: Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Logout Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: Icon(Icons.logout, size: 20),
            label: Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegistration() async {
    setState(() {
      _emailError = null;
      _nicknameError = null;
      _passwordError = null;
      _isLoading = true;
    });

    // Validate inputs
    final email = _emailController.text.trim();
    final nickname = _nicknameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hasError = false;

    // Email validation
    final emailValidation = ProfileService.instance.validateEmail(email);
    if (emailValidation != null) {
      setState(() => _emailError = emailValidation);
      hasError = true;
    }

    // Nickname validation
    final nicknameValidation = ProfileService.instance.validateNickname(nickname);
    if (nicknameValidation != null) {
      setState(() => _nicknameError = nicknameValidation);
      hasError = true;
    }

    // Password validation
    final passwordValidation = ProfileService.instance.validatePassword(password);
    if (passwordValidation != null) {
      setState(() => _passwordError = passwordValidation);
      hasError = true;
    }

    // Confirm password
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

      // Check nickname availability
      final nicknameAvailable = await ProfileService.instance.isNicknameAvailable(nickname);
      if (!nicknameAvailable) {
        setState(() {
          _nicknameError = 'Nickname not available';
          _isLoading = false;
        });
        return;
      }

      // Create profile
      await ProfileService.instance.createProfile(
        email: email,
        nickname: nickname,
        password: password,
        avatarType: AvatarType.avatar,
        avatarOption: _selectedAvatar,
      );

      setState(() => _isLoading = false);

      // Show success and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _emailError = 'Registration failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _loginError = null;
      _isLoading = true;
    });

    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _loginError = 'Please enter both email and password';
        _isLoading = false;
      });
      return;
    }

    try {
      final profile = await ProfileService.instance.login(email, password);

      if (profile != null) {
        await _loadCurrentProfile();
        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${profile.nickname}!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _loginError = 'Invalid email or password';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loginError = 'Login failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        title: Text('Logout', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ProfileService.instance.logout();
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _UpgradeAccountDialog(
        currentProfile: _currentProfile!,
        onUpgradeComplete: () async {
          await _loadCurrentProfile();
          if (mounted) {
            Navigator.pop(context, true);
          }
        },
      ),
    );
  }
}

class _UpgradeAccountDialog extends StatefulWidget {
  final PlayerProfile currentProfile;
  final VoidCallback onUpgradeComplete;

  const _UpgradeAccountDialog({
    required this.currentProfile,
    required this.onUpgradeComplete,
  });

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
        constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFF00D4FF).withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF00D4FF).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.upgrade, color: Color(0xFF00D4FF), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Upgrade Account',
                      style: TextStyle(
                        fontFamily: 'Futura',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current Profile Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      widget.currentProfile.avatarOption?.emoji ?? '👤',
                      style: TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.currentProfile.nickname,
                            style: TextStyle(
                              fontFamily: 'Futura',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Temporary Account',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Create a permanent account to save your progress and compete globally.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              if (_generalError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_generalError!, style: TextStyle(color: Colors.red, fontSize: 12))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Email Field
              _buildUpgradeTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter your email',
                icon: Icons.email,
                error: _emailError,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password Field
              _buildUpgradeTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Create a secure password',
                icon: Icons.lock,
                error: _passwordError,
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              _buildUpgradeTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Re-enter your password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // Benefits List
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benefits of upgrading:',
                      style: TextStyle(
                        fontFamily: 'Futura',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBenefitItem('🏆', 'Global leaderboard rankings'),
                    _buildBenefitItem('💾', 'Save progress permanently'),
                    _buildBenefitItem('📱', 'Sync across devices'),
                    _buildBenefitItem('📊', 'Detailed statistics tracking'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00D4FF),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : Text(
                              'Upgrade Now',
                              style: TextStyle(
                                fontFamily: 'Futura',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Widget _buildUpgradeTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? error,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: error != null
                  ? Colors.red
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(color: Colors.red, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _buildBenefitItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
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
      final upgradedProfile = await ProfileService.instance.convertToPermanentAccount(
        email: email,
        nickname: widget.currentProfile.nickname,
        password: password,
        avatarType: AvatarType.avatar,
        avatarOption: widget.currentProfile.avatarOption ?? AvatarOption.astronaut,
      );

      if (upgradedProfile != null) {
        setState(() => _isLoading = false);

        if (mounted) {
          Navigator.pop(context);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account upgraded successfully! Welcome, ${upgradedProfile.nickname}!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

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