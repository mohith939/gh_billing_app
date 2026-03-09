import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../shop/domain/entities/shop.dart';
import '../../data/models/user_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    final email = HiveDatabase.settingsBox.get('saved_email');
    final password = HiveDatabase.settingsBox.get('saved_password');
    if (email != null && password != null) {
      _emailController.text = email;
      _passwordController.text = password;
    }
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      final userBox = HiveDatabase.userBox;
      final user = userBox.get(email);

      if (user != null && user.password == password) {
        if (_rememberMe) {
          HiveDatabase.settingsBox.put('saved_email', email);
          HiveDatabase.settingsBox.put('saved_password', password);
        } else {
          HiveDatabase.settingsBox.delete('saved_email');
          HiveDatabase.settingsBox.delete('saved_password');
        }

        if (user.isSuperAdmin) {
          context.go('/super-admin');
        } else {
          // Check subscription for regular users
          if (user.expiryDate != null && user.expiryDate!.isBefore(DateTime.now())) {
             _showExpiredDialog();
             return;
          }
          
          // Save logged in user email to settings for session
          HiveDatabase.settingsBox.put('logged_in_user', email);
          
          // Load user-specific shop details
          _onLoginSuccess(user);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Expired'),
        content: const Text(
          'Your monthly plan has expired. Please pay ₹2500 via Google Pay to 9392633211 to continue using the services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onLoginSuccess(UserModel user) {
    // Sync shop bloc with user's specific shop data
    final shop = Shop(
      name: user.shopName,
      addressLine1: user.addressLine1,
      addressLine2: user.addressLine2,
      phoneNumber: user.phoneNumber,
      upiId: user.upiId,
      footerText: user.footerText,
      qrCodePath: user.qrCodePath,
    );
    
    // This updates the local shop box which the app uses for printing and display
    context.read<ShopBloc>().add(UpdateShopEvent(shop));
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Container(
                    height: 160,
                    margin: const EdgeInsets.only(bottom: 40),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.eco_rounded, 
                        size: 100, 
                        color: theme.primaryColor
                      ),
                    ),
                  ),
                  
                  // Card for Login Form
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please login to your account',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 32),
                        
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter email' : null,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter password' : null,
                        ),

                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe, 
                              onChanged: (val) => setState(() => _rememberMe = val ?? true),
                              activeColor: theme.primaryColor,
                            ),
                            const Text('Remember Me', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Login Button
                        PrimaryButton(
                          onPressed: _login, 
                          label: 'LOGIN',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Text(
                    '© 2024 Golden Harvest Raw Powders',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
