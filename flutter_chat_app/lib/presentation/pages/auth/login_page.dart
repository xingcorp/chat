import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Login page
class LoginPage extends StatelessWidget {
  /// Constructor
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.login),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo or app name
            const Icon(
              Icons.chat,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.appTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            
            // Email field
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            // Password field
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            
            // Login button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                context.l10n.login.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Forgot password
            TextButton(
              onPressed: () {},
              child: Text(context.l10n.forgotPassword),
            ),
            
            // Register link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(context.l10n.dontHaveAccount),
                TextButton(
                  onPressed: () {},
                  child: Text(context.l10n.register),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 