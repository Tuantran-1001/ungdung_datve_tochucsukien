import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isProcessing = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_user != null && _user!.email != null) {
        // 1. Xác thực lại tài khoản (Re-authenticate) để tránh lỗi 'requires-recent-login' của Firebase
        final AuthCredential credential = EmailAuthProvider.credential(
          email: _user!.email!,
          password: _currentPasswordController.text.trim(),
        );

        await _user!.reauthenticateWithCredential(credential);

        // 2. Cập nhật mật khẩu mới
        await _user!.updatePassword(_newPasswordController.text.trim());

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: const Color(0xFF1E1A3C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 40),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Đổi Mật Khẩu Thành Công!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Mật khẩu của bạn đã được thay đổi an toàn. Vui lòng ghi nhớ mật khẩu mới cho lần đăng nhập sau.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: const Color(0xFF0F0C20),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('ĐỒNG Ý', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.pop(context); // Tắt Dialog
                            Navigator.pop(context); // Quay lại màn hình chính
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Có lỗi xảy ra, vui lòng thử lại';
      if (e.code == 'wrong-password') {
        errorMessage = 'Mật khẩu hiện tại không chính xác';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Mật khẩu mới quá yếu';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: const Color(0xFF1E1A3C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(child: Text('Lỗi: $e')),
              ],
            ),
            backgroundColor: const Color(0xFF1E1A3C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Nền Gradient cao cấp
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F0C20), // Xanh đen sâu thẳm
                  Color(0xFF15102A), // Chàm đậm
                  Color(0xFF090615), // Đen vũ trụ
                ],
              ),
            ),
          ),

          // 2. Đốm sáng Ambient Glow
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.amber.withOpacity(0.12),
                    Colors.amber.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.deepOrange.withOpacity(0.08),
                    Colors.deepOrange.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          // 3. Nội dung chính
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Đổi Mật Khẩu',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 48), // Cân bằng nút Back
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Hộp biểu mẫu thay đổi mật khẩu (Kính mờ)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1A3C).withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Mật khẩu hiện tại
                                _buildPasswordField(
                                  controller: _currentPasswordController,
                                  label: 'MẬT KHẨU HIỆN TẠI',
                                  hint: 'Nhập mật khẩu hiện tại',
                                  obscureText: _obscureCurrent,
                                  onToggleObscure: () {
                                    setState(() {
                                      _obscureCurrent = !_obscureCurrent;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu hiện tại';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Mật khẩu mới
                                _buildPasswordField(
                                  controller: _newPasswordController,
                                  label: 'MẬT KHẨU MỚI',
                                  hint: 'Tối thiểu 6 ký tự',
                                  obscureText: _obscureNew,
                                  onToggleObscure: () {
                                    setState(() {
                                      _obscureNew = !_obscureNew;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu mới';
                                    }
                                    if (value.length < 6) {
                                      return 'Mật khẩu phải dài tối thiểu 6 ký tự';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Xác nhận mật khẩu mới
                                _buildPasswordField(
                                  controller: _confirmPasswordController,
                                  label: 'XÁC NHẬN MẬT KHẨU MỚI',
                                  hint: 'Nhập lại mật khẩu mới',
                                  obscureText: _obscureConfirm,
                                  onToggleObscure: () {
                                    setState(() {
                                      _obscureConfirm = !_obscureConfirm;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng xác nhận mật khẩu mới';
                                    }
                                    if (value != _newPasswordController.text) {
                                      return 'Mật khẩu xác nhận không trùng khớp';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Nút Lưu thay đổi
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: const Color(0xFF0F0C20),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                                shadowColor: Colors.amber.withOpacity(0.2),
                              ),
                              icon: _isProcessing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Color(0xFF0F0C20), strokeWidth: 2),
                                    )
                                  : const Icon(Icons.security_rounded, size: 20),
                              label: Text(
                                _isProcessing ? 'ĐANG CẬP NHẬT...' : 'XÁC NHẬN ĐỔI MẬT KHẨU',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                              ),
                              onPressed: _isProcessing ? null : _changePassword,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white30, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white30,
                size: 18,
              ),
              onPressed: onToggleObscure,
            ),
            fillColor: const Color(0xFF0F0C20),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.amber, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
