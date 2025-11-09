
import 'package:flutter/material.dart';
import '../services/email_verification_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String userName;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.userName,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  final EmailVerificationController _controller = EmailVerificationController();
  final TextEditingController _tokenController = TextEditingController();

  bool _isVerified = false;
  bool _isLoading = false;
  bool _emailSent = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();

    // Send email on load
    _controller.handleSendEmail(
      context: context,
      email: widget.email,
      userName: widget.userName,
      setLoading: (value) => setState(() => _isLoading = value),
      setEmailSent: (value) => setState(() => _emailSent = value),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryBlue, AppTheme.backgroundColor],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildEmailIcon(),
                  const SizedBox(height: 32),
                  _buildTitle(),
                  const SizedBox(height: 16),
                  _buildContentCard(),
                  const SizedBox(height: 32),
                  _buildBackButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailIcon() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          _isVerified ? Icons.mark_email_read : Icons.email_outlined,
          size: 60,
          color: _isVerified ? Colors.green : AppTheme.accentBlue,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      _isVerified ? 'Email Verified!' : 'Verify Your Email',
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildContentCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDescription(),
          const SizedBox(height: 12),
          _buildEmailText(),
          const SizedBox(height: 24),

          if (!_isVerified && _emailSent) ...[
            _buildInstructions(),
            const SizedBox(height: 16),
            _buildTokenInput(),
            const SizedBox(height: 24),
            _buildVerifyButton(),
            const SizedBox(height: 16),
            _buildResendButton(),
          ],

          if (_isLoading && !_emailSent)
            const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      _isVerified
          ? 'Your account has been successfully verified!'
          : _emailSent
          ? 'We\'ve sent a verification code to:'
          : 'Sending verification email...',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 16,
        color: AppTheme.textGrey,
      ),
    );
  }

  Widget _buildEmailText() {
    return Text(
      widget.email,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildInstructions() {
    return const Text(
      'Enter the verification code from your email:',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: AppTheme.textGrey,
      ),
    );
  }

  Widget _buildTokenInput() {
    return TextField(
      controller: _tokenController,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
      decoration: InputDecoration(
        hintText: 'Enter code',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.accentBlue,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
          _controller.handleVerifyToken(
            context: context,
            enteredToken: _tokenController.text,
            email: widget.email,
            setLoading: (value) => setState(() => _isLoading = value),
            setVerified: (value) => setState(() => _isVerified = value),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentBlue,
        ),
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text('Verify Email'),
      ),
    );
  }

  Widget _buildResendButton() {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () {
        _controller.handleResendEmail(
          context: context,
          email: widget.email,
          userName: widget.userName,
          setLoading: (value) => setState(() => _isLoading = value),
        );
      },
      child: const Text('Resend Code'),
    );
  }

  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      },
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      label: const Text(
        'Back to Login',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}