import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/settings_service.dart';
import '../services/db_helper.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (_transactions.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    List<Map<String, dynamic>> transactionsList = [];

    try {
      final localData = await DbHelper.instance.queryAllTransactions(userId ?? 'anonymous');
      transactionsList = List<Map<String, dynamic>>.from(localData);
    } catch (e) {
      debugPrint('Error loading local transactions: $e');
    }

    if (mounted) {
      setState(() {
        _transactions = List.from(transactionsList);
        if (userId == null) _isLoading = false;
      });
    }

    if (userId != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .get();

        final List<Map<String, dynamic>> cloudTransactions = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': data['id'] ?? doc.id,
            'userId': userId,
            'eventTitle': data['eventTitle'] ?? '',
            'bookingTime': data['bookingTime'] ?? '',
            'paymentMethod': data['paymentMethod'] ?? '',
            'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
            'seatNumber': data['seatNumber'] ?? '',
            'ticketCount': (data['ticketCount'] as num?)?.toInt() ?? 0,
          };
        }).toList();

        bool hasChanges = false;
        for (var cloudTx in cloudTransactions) {
          final exists = transactionsList.any((t) => t['id'] == cloudTx['id']);
          if (!exists) {
            transactionsList.add(cloudTx);
            hasChanges = true;
            try {
              await DbHelper.instance.insertTransaction(cloudTx);
            } catch (e) {
              debugPrint('Error sync-saving cloud transaction to local: $e');
            }
          }
        }

        if (hasChanges && mounted) {
          transactionsList.sort((a, b) => (b['bookingTime'] ?? '').toString().compareTo((a['bookingTime'] ?? '').toString()));
          setState(() {
            _transactions = transactionsList;
          });
        }
      } catch (e) {
        debugPrint('Error syncing transactions from Firestore: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  AppSettings.translate('transaction_history'),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
              ),
              body: SafeArea(
                child: RefreshIndicator(
                  color: Colors.blue,
                  backgroundColor: isDark ? Colors.grey[850] : Colors.white,
                  onRefresh: _loadTransactions,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.blue),
                        )
                      : _transactions.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long_rounded,
                                          color: Colors.purple,
                                          size: 64,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                        child: Text(
                                          AppSettings.translate('no_transactions'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final tx = _transactions[index];
                                return _buildTransactionCard(tx, isDark, isEn);
                              },
                            ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, bool isDark, bool isEn) {
    final bookingTime = tx['bookingTime'] ?? '';
    final DateTime? parsedTime = DateTime.tryParse(bookingTime);
    final String displayTime = parsedTime != null
        ? "${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')} - ${parsedTime.day.toString().padLeft(2, '0')}/${parsedTime.month.toString().padLeft(2, '0')}/${parsedTime.year}"
        : bookingTime;

    final amountStr = '${(tx['amount'] as num?)?.toStringAsFixed(0) ?? '0'} VND';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['eventTitle'] ?? '',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppSettings.translate('transaction_id')}: ${tx['id']}',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.event_seat_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 16),
              const SizedBox(width: 8),
              Text(
                '${AppSettings.translate('seats_booked')}: ',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: Text(
                  tx['seatNumber'] ?? '',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '(${tx['ticketCount']} ${isEn ? 'tickets' : 'vé'})',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 16),
              const SizedBox(width: 8),
              Text(
                '${AppSettings.translate('payment_time')}: ',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: Text(
                  displayTime,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.payment_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 16),
              const SizedBox(width: 8),
              Text(
                '${AppSettings.translate('payment_method')}: ',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: Text(
                  tx['paymentMethod'] ?? '',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppSettings.translate('total_payment'),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                amountStr,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
