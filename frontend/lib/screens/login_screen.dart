import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ratip/theme/app_theme.dart';
import 'package:ratip/widgets/glass_container.dart';
import 'package:ratip/widgets/glass_text_field.dart';
import 'package:ratip/screens/signup_screen.dart';
import 'package:ratip/screens/main_map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    if (_nicknameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('닉네임과 비밀번호를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Get the user profile by nickname to find their email
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('nickname', _nicknameController.text.trim())
          .maybeSingle();

      if (profile == null) {
        throw '닉네임을 찾을 수 없습니다.';
      }

      // 2. Sign in using email and password
      await Supabase.instance.client.auth.signInWithPassword(
        email: profile['email'],
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainMapScreen()),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          
          return Stack(
            children: [
              // Background Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.etherealGradient,
                ),
              ),
              
              if (isDesktop)
                // Desktop Layout
                Row(
                  children: [
                    // Left Side: Branding
                    Expanded(
                      flex: 6,
                      child: FadeInLeft(
                        duration: const Duration(milliseconds: 1000),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Hero(
                                  tag: 'logo',
                                  child: Icon(
                                    Icons.bubble_chart,
                                    size: 120,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'RATIP',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.onSurface,
                                      letterSpacing: 8,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Precision Journey\nElevate your digital presence',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w300,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Right Side: Login Panel
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: _buildLoginForm(isDesktop),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Mobile Layout
                Column(
                  children: [
                    // Top Area: Small Branding
                    Expanded(
                      flex: 4,
                      child: FadeInDown(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bubble_chart,
                                size: 80,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'RATIP',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.onSurface,
                                      letterSpacing: 4,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Bottom Area: Login Form (Rising Up)
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: _buildLoginForm(isDesktop),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoginForm(bool isDesktop) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Login',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please sign in to continue',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 40),
        
        GlassTextField(
          controller: _nicknameController,
          label: 'Nickname',
          hintText: 'Enter your nickname',
          icon: Icons.person_outline,
          onSubmitted: (_) => _signIn(),
        ),
        const SizedBox(height: 20),
        GlassTextField(
          controller: _passwordController,
          label: 'Password',
          hintText: '••••••••',
          icon: Icons.lock_outline,
          isPassword: _obscurePassword,
          onSubmitted: (_) => _signIn(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: AppTheme.outline,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 40),
        
        // Sign In Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Sign Up Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
              child: const Text(
                'Join Ratip',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
