import 'dart:async';
import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import 'ticket_view_screen.dart';
import '../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final List<String> selectedSeats;

  const PaymentScreen({
    super.key,
    required this.event,
    required this.selectedSeats,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'card'; // 'card', 'momo', 'zalopay', 'qr'
  bool _isProcessing = false;
  bool _isSuccess = false;
  String _processingText = 'Đang kết nối cổng thanh toán...';
  String _transactionId = '';

  // Credit Card Form Keys & Controllers
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  // Pricing calculations
  late double _ticketPrice;
  final double _bookingFee = 15000;
  late double _totalPrice;

  @override
  void initState() {
    super.initState();
    _ticketPrice = (widget.event['price'] as num).toDouble() * widget.selectedSeats.length;
    _totalPrice = _ticketPrice + _bookingFee;
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _holderNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _startPaymentProcess() async {
    if (_selectedMethod == 'card') {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _processingText = 'Đang kết nối cổng thanh toán...';
    });

    // Simulate different payment processing stages
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _processingText = _selectedMethod == 'card' 
          ? 'Đang xác thực thông tin thẻ...' 
          : 'Đang xác thực giao dịch ví điện tử...';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _processingText = 'Đang tiến hành trừ tiền tài khoản...';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _processingText = 'Đang khởi tạo vé điện tử...';
    });

    // Save ticket to local database and sync to Firebase Firestore
    final String timestampSuffix = '${DateTime.now().millisecondsSinceEpoch % 10000}';
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    final String formattedBookingTime = DateTime.now().toIso8601String().split('.').first;

    for (int i = 0; i < widget.selectedSeats.length; i++) {
      final String seat = widget.selectedSeats[i];
      final String ticketId = 'EP-${widget.event['id']}-$timestampSuffix-$seat';
      
      final Map<String, dynamic> ticketData = {
        'id': ticketId,
        'eventId': widget.event['id'],
        'eventTitle': widget.event['title'],
        'eventDate': widget.event['date'],
        'eventLocation': widget.event['location'],
        'seatNumber': seat,
        'status': 'Chưa sử dụng',
        'bookingTime': formattedBookingTime,
      };

      // 1. Save locally to SQLite
      await DbHelper.instance.insertTicket(ticketData);

      // 2. Sync to Firebase Firestore under collection 'tickets' (Chạy bất đồng bộ nền để tránh treo giao diện nếu mất mạng hoặc lỗi Firebase)
      FirebaseFirestore.instance.collection('tickets').doc(ticketId).set({
        ...ticketData,
        'userId': userId ?? 'anonymous',
      }).catchError((e) {
        debugPrint('Error syncing ticket $ticketId to Firestore: $e');
      });
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
      _transactionId = 'TX-${100000 + (DateTime.now().millisecondsSinceEpoch % 900000)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Nền Gradient cao cấp mang lại chiều sâu vũ trụ
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

          // 2. Các đốm sáng Ambient Glow mềm mại
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
                    Colors.amber.withOpacity(0.1),
                    Colors.amber.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
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

          // 3. Nội dung chính tùy theo trạng thái
          SafeArea(
            child: _isSuccess 
                ? _buildSuccessScreen(context)
                : _buildCheckoutForm(context),
          ),

          // 4. Màn hình xử lý giao dịch ảo phủ kính mờ
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  // =========================================================================
  // Giao diện chính của Trang thanh toán (Checkout Form)
  // =========================================================================
  Widget _buildCheckoutForm(BuildContext context) {
    return Column(
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
                  'Thanh Toán Đặt Vé',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 48), // Để cân bằng
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tóm tắt đơn hàng (Order Summary)
                _buildOrderSummaryCard(),
                const SizedBox(height: 24),

                // 2. Chọn phương thức thanh toán
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodSelector(),
                const SizedBox(height: 24),

                // 3. Biểu mẫu chi tiết theo phương thức đã chọn
                _buildSelectedPaymentDetails(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // Thanh thanh toán chân trang
        _buildBottomPaymentBar(),
      ],
    );
  }

  // =========================================================================
  // Widget: Tóm tắt đơn hàng (Order Summary Card)
  // =========================================================================
  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A3C).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_activity_rounded, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tóm tắt đơn hàng',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.event['title'] ?? 'Sự kiện',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.chair_alt_rounded, color: Colors.white.withOpacity(0.5), size: 14),
              const SizedBox(width: 6),
              Text(
                'Vị trí ghế: ',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),
              Text(
                widget.selectedSeats.join(', '),
                style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Colors.white10, height: 1),
          ),
          _buildPriceRow('Giá vé gốc', '${_ticketPrice.toStringAsFixed(0)} VND'),
          const SizedBox(height: 8),
          _buildPriceRow('Phí tiện ích (Online)', '${_bookingFee.toStringAsFixed(0)} VND'),
          const SizedBox(height: 8),
          _buildPriceRow('Số lượng', '1 vé'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Colors.white10, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                '${_totalPrice.toStringAsFixed(0)} VND',
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // =========================================================================
  // Widget: Hộp chọn phương thức thanh toán
  // =========================================================================
  Widget _buildPaymentMethodSelector() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildMethodCard('card', Icons.credit_card_rounded, 'Thẻ Quốc tế', 'Visa / Mastercard', Colors.blue),
        _buildMethodCard('momo', Icons.wallet_rounded, 'Ví MoMo', 'Khuyên dùng', Colors.pinkAccent),
        _buildMethodCard('zalopay', Icons.account_balance_wallet_rounded, 'ZaloPay', 'Tiện lợi', Colors.blueAccent),
        _buildMethodCard('qr', Icons.qr_code_scanner_rounded, 'QR Pay', 'Chuyển khoản nhanh', Colors.orange),
      ],
    );
  }

  Widget _buildMethodCard(String methodId, IconData icon, String title, String subtitle, Color activeGlowColor) {
    final bool isSelected = _selectedMethod == methodId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = methodId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF1E1A3C).withOpacity(0.8) 
              : const Color(0xFF1E1A3C).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: activeGlowColor.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeGlowColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: isSelected ? activeGlowColor : Colors.white60),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.amberAccent.withOpacity(0.8) : Colors.white30,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Widget: Hiển thị chi tiết theo phương thức thanh toán
  // =========================================================================
  Widget _buildSelectedPaymentDetails() {
    if (_selectedMethod == 'card') {
      return _buildCreditCardForm();
    } else if (_selectedMethod == 'momo') {
      return _buildEWalletInstructions('MoMo', Colors.pinkAccent);
    } else if (_selectedMethod == 'zalopay') {
      return _buildEWalletInstructions('ZaloPay', Colors.blueAccent);
    } else {
      return _buildQRCodeSimulation();
    }
  }

  // Biểu mẫu Thẻ tín dụng Quốc tế
  Widget _buildCreditCardForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A3C).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: Colors.greenAccent, size: 16),
                SizedBox(width: 6),
                Text(
                  'Cổng thanh toán bảo mật PCI-DSS',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tên chủ thẻ
            _buildTextField(
              controller: _holderNameController,
              label: 'TÊN CHỦ THẺ',
              hint: 'NGUYEN VAN A',
              icon: Icons.person_outline_rounded,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Vui lòng nhập tên chủ thẻ';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Số thẻ
            _buildTextField(
              controller: _cardNumberController,
              label: 'SỐ THẺ',
              hint: '4123 4567 8901 2345',
              icon: Icons.credit_card_rounded,
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Vui lòng nhập số thẻ';
                if (val.replaceAll(' ', '').length < 16) return 'Số thẻ không hợp lệ (đủ 16 số)';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Hạn dùng & CVV song song
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _expiryController,
                    label: 'HẠN DÙNG (MM/YY)',
                    hint: '12/29',
                    icon: Icons.calendar_today_rounded,
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Vui lòng nhập hạn dùng';
                      if (!val.contains('/')) return 'MM/YY';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _cvvController,
                    label: 'MÃ CVV',
                    hint: '123',
                    icon: Icons.security_rounded,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Nhập CVV';
                      if (val.length < 3) return '3 chữ số';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.white30, size: 18),
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

  // Ví điện tử MoMo / ZaloPay
  Widget _buildEWalletInstructions(String walletName, Color brandColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A3C).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.install_mobile_rounded, size: 30, color: brandColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Thanh toán qua ví $walletName',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Khi nhấn "Xác nhận", hệ thống sẽ tự động liên kết và mở ứng dụng $walletName trên điện thoại của bạn để tiến hành phê duyệt thanh toán an toàn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  // Quét QR Code ngân hàng (QR Pay)
  Widget _buildQRCodeSimulation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A3C).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Text(
            'Quét Mã QR Chuyển Khoản Nhanh',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'Hệ thống tự động tạo mã chuyển khoản VietQR',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 1,
                )
              ],
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 160,
              color: Color(0xFF0F0C20),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Tự động duyệt vé ngay khi nhận tiền',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Widget: Thanh thanh toán cố định ở chân trang
  // =========================================================================
  Widget _buildBottomPaymentBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131026),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TỔNG THANH TOÁN', 
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4), 
                    fontSize: 10, 
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  '${_totalPrice.toStringAsFixed(0)} VND', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: const Color(0xFF0F0C20),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                shadowColor: Colors.amber.withOpacity(0.3),
              ),
              icon: const Icon(Icons.security_rounded, size: 18),
              label: const Text(
                'XÁC NHẬN THANH TOÁN', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
              ),
              onPressed: _startPaymentProcess,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Màn hình xử lý giao dịch ảo phủ kính mờ (Processing Overlay)
  // =========================================================================
  Widget _buildProcessingOverlay() {
    return Container(
      color: const Color(0xFF0F0C20).withOpacity(0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1A3C).withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: Colors.amber,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _processingText,
                  key: ValueKey<String>(_processingText),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vui lòng không tắt ứng dụng hoặc tải lại trang.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // Màn hình Chúc mừng / Thanh toán thành công (Payment Success Screen)
  // =========================================================================
  Widget _buildSuccessScreen(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon checkmark tròn phát sáng rực rỡ
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 80,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 32),

            // Tiêu đề chúc mừng
            const Text(
              'Thanh Toán Thành Công!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tấm vé của bạn đã sẵn sàng trong kho vé.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Mẫu Vé điện tử E-Ticket cao cấp kèm QR Code ngay trên trang thành công
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A3C).withOpacity(0.65),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Phần trên: Chi tiết thông tin vé
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.withOpacity(0.2), width: 0.5),
                              ),
                              child: const Text(
                                'VÉ ĐIỆN TỬ (E-TICKET)',
                                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.greenAccent.withOpacity(0.2), width: 0.5),
                              ),
                              child: const Text(
                                'ĐÃ THANH TOÁN',
                                style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.event['title'] ?? 'Sự kiện',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.white10, height: 1),
                        ),
                        _buildReceiptRow('Thời gian', widget.event['date'] ?? ''),
                        const SizedBox(height: 10),
                        _buildReceiptRow('Địa điểm', widget.event['location'] ?? ''),
                        const SizedBox(height: 10),
                        _buildReceiptRow('Vị trí ghế', widget.selectedSeats.join(', '), isValueHighlighted: true),
                        const SizedBox(height: 10),
                        _buildReceiptRow('Mã giao dịch', _transactionId),
                        const SizedBox(height: 10),
                        _buildReceiptRow(
                          'Phương thức', 
                          _selectedMethod == 'card' 
                              ? 'Thẻ Quốc tế (Visa)' 
                              : _selectedMethod == 'momo' 
                                  ? 'Ví MoMo' 
                                  : _selectedMethod == 'zalopay' 
                                      ? 'Ví ZaloPay' 
                                      : 'Chuyển khoản VietQR'
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.white10, height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng thanh toán',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '${_totalPrice.toStringAsFixed(0)} VND',
                              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Đường cắt rách xẻ vé rạp chiếu phim nét đứt
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0C20),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              for (int i = 0; i < 24; i++)
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 2.0),
                                    child: Divider(color: Colors.white24, height: 1, thickness: 1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0C20),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
                        ),
                      ),
                    ],
                  ),

                  // Phần dưới: QR Code phát sáng bọc trong thẻ trắng cao cấp
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.12),
                                blurRadius: 15,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: QrImageView(
                            data: 'EP-${widget.event['id']}-${_transactionId}-${widget.selectedSeats.join("_")}',
                            version: QrVersions.auto,
                            size: 130.0,
                            gapless: false,
                            foregroundColor: const Color(0xFF0F0C20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'QUÉT MÃ NÀY TẠI CỬA VÀO CỔNG',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Các nút điều hướng
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
                icon: const Icon(Icons.confirmation_num_rounded, size: 20),
                label: const Text(
                  'XEM VÉ ĐIỆN TỬ NGAY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                ),
                onPressed: () {
                  final String simulatedTicketId = 'EP-${widget.event['id']}-${DateTime.now().millisecondsSinceEpoch % 10000}-${widget.selectedSeats.first}';
                  // Navigate directly to TicketViewScreen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketViewScreen(
                        ticket: {
                          'id': simulatedTicketId,
                          'eventId': widget.event['id'],
                          'eventTitle': widget.event['title'],
                          'eventDate': widget.event['date'],
                          'eventLocation': widget.event['location'],
                          'seatNumber': widget.selectedSeats.join(', '),
                          'status': 'Chưa sử dụng',
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                ),
                icon: const Icon(Icons.home_rounded, size: 20),
                label: const Text(
                  'QUAY LẠI TRANG CHỦ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainNavigation()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isValueHighlighted = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isValueHighlighted ? Colors.amberAccent : Colors.white,
              fontWeight: isValueHighlighted ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
