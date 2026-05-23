import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (_user != null) {
        await _user.updateDisplayName(_nameController.text.trim());
        await _user.reload(); // Làm mới thông tin user cục bộ
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                  SizedBox(width: 8),
                  Text('Đã cập nhật thông tin hồ sơ thành công!'),
                ],
              ),
              backgroundColor: Color(0xFF1E1A3C),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true); // Trả về true để màn hình trước cập nhật
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(child: Text('Lỗi cập nhật hồ sơ: $e')),
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
          _isSaving = false;
        });
      }
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Không rõ';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final String initialChar = (_user?.displayName != null && _user!.displayName!.isNotEmpty)
        ? _user.displayName![0].toUpperCase()
        : (_user?.email != null && _user!.email!.isNotEmpty)
            ? _user.email![0].toUpperCase()
            : 'U';

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
            top: -50,
            right: -50,
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
            bottom: 100,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
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
                          'Thông Tin Hồ Sơ',
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
                        children: [
                          const SizedBox(height: 24),

                          // Avatar phát sáng nổi bật
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.amber, width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 42,
                                    backgroundColor: const Color(0xFF1E1A3C),
                                    child: Text(
                                      initialChar,
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Hộp thông tin tài khoản (Kính mờ)
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
                                // Tên hiển thị input
                                const Text(
                                  'TÊN HIỂN THỊ',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Vui lòng nhập tên hiển thị';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Nhập tên hiển thị mới',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
                                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.white30, size: 18),
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
                                const SizedBox(height: 20),

                                // Email (Read-only)
                                const Text(
                                  'ĐỊA CHỈ EMAIL',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F0C20).withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.email_outlined, color: Colors.white30, size: 18),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _user?.email ?? 'Không có email',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.65),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.lock_rounded, color: Colors.white24, size: 14),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Ngày tham gia (Read-only)
                                const Text(
                                  'NGÀY THAM GIA',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F0C20).withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, color: Colors.white30, size: 18),
                                      const SizedBox(width: 12),
                                      Text(
                                        _formatDate(_user?.metadata.creationTime),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.65),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
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
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Color(0xFF0F0C20), strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save_rounded, size: 20),
                              label: Text(
                                _isSaving ? 'ĐANG LƯU...' : 'LƯU THAY ĐỔI',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                              ),
                              onPressed: _isSaving ? null : _updateProfile,
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
}
