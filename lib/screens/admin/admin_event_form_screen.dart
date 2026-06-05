import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/settings_service.dart';

class AdminEventFormScreen extends StatefulWidget {
  final Map<String, dynamic>? event;

  const AdminEventFormScreen({super.key, this.event});

  @override
  State<AdminEventFormScreen> createState() => _AdminEventFormScreenState();
}

class _AdminEventFormScreenState extends State<AdminEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Âm nhạc';
  bool _isSaving = false;

  bool get _isEditing => widget.event != null;

  final List<String> _categories = ['Âm nhạc', 'Thể thao', 'Workshop'];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.event!;
      _titleController.text = e['title'] ?? '';
      _selectedCategory = e['category'] ?? 'Âm nhạc';
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = 'Âm nhạc';
      }
      _dateController.text = e['date'] ?? '';
      _locationController.text = e['location'] ?? '';
      _priceController.text = (e['price'] ?? '').toString();
      _imageUrlController.text = e['imageUrl'] ?? '';
      _descriptionController.text = e['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (pickedTime == null || !mounted) return;

    final year = pickedDate.year.toString().padLeft(4, '0');
    final month = pickedDate.month.toString().padLeft(2, '0');
    final day = pickedDate.day.toString().padLeft(2, '0');
    final hour = pickedTime.hour.toString().padLeft(2, '0');
    final minute = pickedTime.minute.toString().padLeft(2, '0');

    _dateController.text = '$year-$month-$day $hour:$minute';
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'title': _titleController.text.trim(),
      'category': _selectedCategory,
      'date': _dateController.text.trim(),
      'location': _locationController.text.trim(),
      'price': num.tryParse(_priceController.text.trim()) ?? 0,
      'imageUrl': _imageUrlController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    try {
      final firestore = FirebaseFirestore.instance;

      if (_isEditing) {
        final docId = widget.event!['id'] as String;
        await firestore.collection('events').doc(docId).update(data);
      } else {
        final docRef = await firestore.collection('events').add(data);
        await docRef.update({'id': docRef.id});
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppSettings.isEnglish
                ? (_isEditing ? 'Event updated successfully!' : 'Event created successfully!')
                : (_isEditing ? 'Cập nhật sự kiện thành công!' : 'Tạo sự kiện thành công!'),
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppSettings.isEnglish ? 'Error: $e' : 'Lỗi: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.languageNotifier,
      builder: (context, lang, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppSettings.themeNotifier,
          builder: (context, themeMode, _) {
            final isDark = themeMode == ThemeMode.dark;
            final isEn = lang == 'en';

            return Scaffold(
              backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
              appBar: AppBar(
                elevation: 0,
                backgroundColor: isDark ? Colors.grey[850] : Colors.white,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: isDark ? Colors.white : Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  _isEditing
                      ? AppSettings.translate('edit_event')
                      : AppSettings.translate('add_event'),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Tên sự kiện
                      _buildTextField(
                        controller: _titleController,
                        label: isEn ? 'Event Name' : 'Tên sự kiện',
                        icon: Icons.event,
                        isDark: isDark,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isEn ? 'Please enter event name' : 'Vui lòng nhập tên sự kiện';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Danh mục
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: isEn ? 'Category' : 'Danh mục',
                            labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            border: InputBorder.none,
                            icon: Icon(Icons.category, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                          dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                          items: _categories.map((cat) {
                            String displayName = cat;
                            if (isEn) {
                              if (cat == 'Âm nhạc') displayName = 'Music';
                              if (cat == 'Thể thao') displayName = 'Sports';
                              if (cat == 'Workshop') displayName = 'Workshop';
                            }
                            return DropdownMenuItem(value: cat, child: Text(displayName));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Ngày & Giờ
                      _buildTextField(
                        controller: _dateController,
                        label: isEn ? 'Date & Time' : 'Ngày & Giờ',
                        icon: Icons.calendar_today,
                        isDark: isDark,
                        readOnly: true,
                        onTap: _pickDateTime,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isEn ? 'Please select date and time' : 'Vui lòng chọn ngày và giờ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Địa điểm
                      _buildTextField(
                        controller: _locationController,
                        label: isEn ? 'Location' : 'Địa điểm',
                        icon: Icons.location_on,
                        isDark: isDark,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isEn ? 'Please enter location' : 'Vui lòng nhập địa điểm';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Giá vé
                      _buildTextField(
                        controller: _priceController,
                        label: isEn ? 'Ticket Price' : 'Giá vé',
                        icon: Icons.attach_money,
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isEn ? 'Please enter price' : 'Vui lòng nhập giá vé';
                          }
                          if (num.tryParse(val.trim()) == null) {
                            return isEn ? 'Invalid number' : 'Số không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Link ảnh
                      _buildTextField(
                        controller: _imageUrlController,
                        label: isEn ? 'Image URL' : 'Link ảnh',
                        icon: Icons.image,
                        isDark: isDark,
                        hint: 'https://images.unsplash.com/...',
                      ),
                      const SizedBox(height: 16),

                      // Mô tả
                      _buildTextField(
                        controller: _descriptionController,
                        label: isEn ? 'Description' : 'Mô tả',
                        icon: Icons.description,
                        isDark: isDark,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 28),

                      // Nút Lưu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save, size: 20),
                          label: Text(
                            _isSaving
                                ? (isEn ? 'Saving...' : 'Đang lưu...')
                                : (isEn ? 'SAVE' : 'LƯU'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveEvent,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? hint,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onTap: onTap,
        validator: validator,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
          hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}
