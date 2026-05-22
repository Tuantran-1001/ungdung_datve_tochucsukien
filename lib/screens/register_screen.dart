import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _registerUser() async {
    // Kiểm tra xem người dùng đã nhập đủ và đúng định dạng chưa
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Bật hiệu ứng xoay vòng chờ đợi
      });

      try {
        // 1. Gửi lệnh tạo tài khoản lên Firebase và GÁN VÀO BIẾN userCredential
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 2. LỆNH MỚI THÊM: Cập nhật "Họ và tên" vào hồ sơ Firebase
        await userCredential.user?.updateDisplayName(_nameController.text.trim());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công!'), backgroundColor: Colors.green),
        );

        // Quay lại màn hình trước đó (thường là màn hình Login)
        Navigator.pop(context);

      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Đã xảy ra lỗi.';
        if (e.code == 'weak-password') {
          errorMessage = 'Mật khẩu quá yếu (cần ít nhất 6 ký tự).';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Email này đã được sử dụng.';
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
        title: const Text('Tạo Tài Khoản', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 20),
              const Text('Tham gia Event Pro ngay!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Ô nhập Họ Tên
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 16),

              // Ô nhập Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                  if (!value.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ô nhập Mật khẩu
              TextFormField(
                controller: _passwordController,
                obscureText: true, // Ẩn ký tự mật khẩu
                decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                validator: (value) => value != null && value.length < 6 ? 'Mật khẩu phải từ 6 ký tự' : null,
              ),
              const SizedBox(height: 16),

              // Ô Xác nhận Mật khẩu
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_clock)),
                validator: (value) {
                  if (value != _passwordController.text) return 'Mật khẩu không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Nút Đăng ký
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  onPressed: _isLoading ? null : _registerUser,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ĐĂNG KÝ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                    'Đã có tài khoản? Đăng nhập ngay',
                    style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w500)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}