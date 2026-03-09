import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/config/app_identity.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_brand_logo.dart';

/// Forgot password page
class ForgotPasswordPage extends StatelessWidget {
  /// Constructor
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppBrandLogo.wordmark(
              width: 220,
              height: 62,
            ),
            const SizedBox(height: 16),
            Text(
              AppIdentity.appName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Đặt lại mật khẩu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vui lòng nhập địa chỉ email của bạn. Chúng tôi sẽ gửi hướng dẫn đặt lại mật khẩu đến email của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Email field
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),

            // Reset password button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'GỬI YÊU CẦU',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Back to login
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Trở về đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
