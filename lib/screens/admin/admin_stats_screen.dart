import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/settings_service.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  bool _isLoading = true;
  double _totalRevenue = 0;
  int _totalTickets = 0;
  int _totalEvents = 0;
  List<Map<String, dynamic>> _eventStats = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      // Fetch all events to count total & map prices
      final eventsSnap =
          await FirebaseFirestore.instance.collection('events').get();

      // Fetch all transactions
      final transSnap =
          await FirebaseFirestore.instance.collection('transactions').get();

      double totalRevenue = 0;
      int totalTickets = 0;
      Map<String, Map<String, dynamic>> eventMap = {};

      if (transSnap.docs.isNotEmpty) {
        for (var doc in transSnap.docs) {
          final data = doc.data();
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          final ticketCount = (data['ticketCount'] as num?)?.toInt() ?? 0;
          final eventTitle = (data['eventTitle'] ?? 'Unknown') as String;

          totalRevenue += amount;
          totalTickets += ticketCount;

          if (eventMap.containsKey(eventTitle)) {
            eventMap[eventTitle]!['revenue'] += amount;
            eventMap[eventTitle]!['tickets'] += ticketCount;
          } else {
            eventMap[eventTitle] = {
              'title': eventTitle,
              'revenue': amount,
              'tickets': ticketCount,
            };
          }
        }
      } else {
        // Fallback: Reconstruct statistics from tickets and events
        final ticketsSnap = await FirebaseFirestore.instance.collection('tickets').get();

        // Build price map using both document ID and field 'id'
        Map<String, double> eventPrices = {};
        for (var doc in eventsSnap.docs) {
          final data = doc.data();
          final double price = (data['price'] as num?)?.toDouble() ?? 0.0;
          final String? docId = doc.id;
          final String? fieldId = data['id'];
          if (docId != null) eventPrices[docId] = price;
          if (fieldId != null) eventPrices[fieldId] = price;
        }

        // Group tickets by (userId + bookingTime + eventId) to reconstruct transaction-like groups
        Map<String, List<Map<String, dynamic>>> groups = {};
        for (var doc in ticketsSnap.docs) {
          final data = doc.data();
          final String userId = data['userId'] ?? 'anonymous';
          final String bookingTime = data['bookingTime'] ?? '';
          final String eventId = data['eventId'] ?? '';
          final String key = '${userId}_${bookingTime}_${eventId}';

          if (!groups.containsKey(key)) {
            groups[key] = [];
          }
          groups[key]!.add(data);
        }

        for (var entry in groups.entries) {
          final list = entry.value;
          if (list.isEmpty) continue;

          final first = list.first;
          final String eventTitle = first['eventTitle'] ?? 'Unknown';
          final String eventId = first['eventId'] ?? '';
          final int ticketCount = list.length;
          final double basePrice = eventPrices[eventId] ?? 0.0;
          final double amount = (basePrice * ticketCount) + 15000.0; // ticket price + 15k fee per transaction

          totalRevenue += amount;
          totalTickets += ticketCount;

          if (eventMap.containsKey(eventTitle)) {
            eventMap[eventTitle]!['revenue'] += amount;
            eventMap[eventTitle]!['tickets'] += ticketCount;
          } else {
            eventMap[eventTitle] = {
              'title': eventTitle,
              'revenue': amount,
              'tickets': ticketCount,
            };
          }
        }
      }

      // Sort per-event stats by revenue descending
      final eventStatsList = eventMap.values.toList()
        ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      setState(() {
        _totalRevenue = totalRevenue;
        _totalTickets = totalTickets;
        _totalEvents = eventsSnap.docs.length;
        _eventStats = eventStatsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
      }
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
            final textColor = isDark ? Colors.white : Colors.black87;
            final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
            final bgColor = isDark ? Colors.grey[900] : Colors.grey[100];
            final cardColor = isDark ? Colors.grey[850] : Colors.white;
            final borderColor =
                isDark ? Colors.grey[800]! : Colors.grey[200]!;

            return Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                title: Text(
                  AppSettings.translate('revenue_stats'),
                  style: TextStyle(color: textColor),
                ),
                backgroundColor:
                    isDark ? const Color(0xFF303030) : Colors.white,
                iconTheme: IconThemeData(color: textColor),
                elevation: 0.5,
              ),
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadStats,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Summary cards
                          _buildSummaryCard(
                            icon: '💰',
                            label: AppSettings.translate('total_revenue'),
                            value:
                                '${_totalRevenue.toStringAsFixed(0)} VND',
                            isDark: isDark,
                            textColor: textColor,
                            subtitleColor: subtitleColor!,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            accentColor: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryCard(
                            icon: '🎫',
                            label:
                                AppSettings.translate('total_tickets_sold'),
                            value: '$_totalTickets',
                            isDark: isDark,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            accentColor: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryCard(
                            icon: '📅',
                            label: AppSettings.translate('total_events'),
                            value: '$_totalEvents',
                            isDark: isDark,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            accentColor: Colors.orange,
                          ),
                          const SizedBox(height: 24),
                          // Per-event section header
                          Text(
                            AppSettings.translate('revenue_by_event'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Per-event stats list
                          if (_eventStats.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  AppSettings.translate('no_transactions'),
                                  style: TextStyle(color: subtitleColor),
                                ),
                              ),
                            )
                          else
                            ..._eventStats.map((event) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event['title'] as String,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '🎫 ${event['tickets']} ${AppSettings.translate('total_tickets_sold')}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: subtitleColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${(event['revenue'] as double).toStringAsFixed(0)} VND',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String icon,
    required String label,
    required String value,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    required Color? cardColor,
    required Color borderColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
