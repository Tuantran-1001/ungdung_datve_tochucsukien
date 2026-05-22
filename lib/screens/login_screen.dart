import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart'; // Mở sang trang đăng ký
import '../main.dart'; // Để gọi MainNavigation sau khi đăng nhập xong

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Gửi yêu cầu đăng nhập lên Firebase
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công!'), backgroundColor: Colors.green),
        );

        // Đăng nhập thành công -> Nhảy vào màn hình chính và xóa lịch sử Back
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
              (route) => false,
        );

      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Đăng nhập thất bại. Vui lòng kiểm tra lại.';
        // Bắt các lỗi phổ biến từ Firebase
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
          errorMessage = 'Tài khoản hoặc mật khẩu không chính xác.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Định dạng email không hợp lệ.';
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đăng Nhập', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.event_available, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              const Text('Chào mừng trở lại\nEvent Pro!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Ô nhập Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ô nhập Mật khẩu
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                validator: (value) => value != null && value.length < 6 ? 'Mật khẩu phải từ 6 ký tự' : null,
              ),
              const SizedBox(height: 32),

              // Nút Đăng nhập
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  onPressed: _isLoading ? null : _loginUser,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
              const SizedBox(height: 20),

              // Nút chuyển sang trang Đăng ký
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text('Chưa có tài khoản? Đăng ký ngay', style: TextStyle(color: Colors.blue, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}