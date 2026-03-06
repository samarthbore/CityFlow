import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../theme/app_theme.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final String providerId;
  final String token;

  const AnalyticsDashboardScreen({
    super.key,
    required this.providerId,
    required this.token,
  });

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = 'today';
  DateTimeRange? _customRange;

  final List<Map<String, String>> _periods = [
    {'key': 'today', 'label': 'Today'},
    {'key': 'week', 'label': 'This Week'},
    {'key': 'month', 'label': 'This Month'},
    {'key': 'year', 'label': 'This Year'},
    {'key': 'custom', 'label': 'Custom'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? startDate;
      String? endDate;
      
      if (_selectedPeriod == 'custom' && _customRange != null) {
        startDate = _customRange!.start.toIso8601String().split('T')[0];
        endDate = _customRange!.end.toIso8601String().split('T')[0];
      }

      final data = await ApiService.getAnalytics(
        widget.token, 
        widget.providerId,
        period: _selectedPeriod,
        startDate: startDate,
        endDate: endDate,
      );
      setState(() {
        _analytics = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(String period) async {
    if (period == 'custom') {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _customRange ?? DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        ),
      );
      if (range != null) {
        setState(() {
          _customRange = range;
          _selectedPeriod = 'custom';
        });
        _fetchAnalytics();
      }
    } else {
      setState(() {
        _selectedPeriod = period;
      });
      _fetchAnalytics();
    }
  }

  void _showServedCustomers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServedCustomersSheet(
        providerId: widget.providerId,
        token: widget.token,
        period: _selectedPeriod,
        customRange: _customRange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Analytics', style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                      const SizedBox(height: 16),
                      Text('Failed to load analytics', style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
                      Text(_error!, style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchAnalytics, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAnalytics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPeriodSelector(),
                        const SizedBox(height: 20),
                        _buildPeriodStats(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Performance'),
                        const SizedBox(height: 12),
                        _buildPerformanceCards(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Daily Breakdown'),
                        const SizedBox(height: 12),
                        _buildDailyChart(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Peak Hours'),
                        const SizedBox(height: 12),
                        _buildPeakHoursChart(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildPeriodSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period['key'];
          String label = period['label']!;
          
          if (period['key'] == 'custom' && _customRange != null && _selectedPeriod == 'custom') {
            final start = DateFormat('MMM d').format(_customRange!.start);
            final end = DateFormat('MMM d').format(_customRange!.end);
            label = '$start - $end';
          }
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => _onPeriodChanged(period['key']!),
              selectedColor: AppTheme.accentGreen,
              backgroundColor: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodStats() {
    final period = _analytics?['period'] ?? {};
    return Row(
      children: [
        Expanded(child: _buildStatCard('Waiting', '${period['waiting'] ?? 0}', Icons.hourglass_empty, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Serving', '${period['serving'] ?? 0}', Icons.person, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _showServedCustomers,
            child: _buildStatCard('Served', '${period['served'] ?? 0}', Icons.check_circle, AppTheme.accentGreen, tappable: true),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool tappable = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: tappable ? Border.all(color: color.withOpacity(0.5), width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
              if (tappable) ...[
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 10, color: color),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
    );
  }

  Widget _buildPerformanceCards() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avgWait = _analytics?['avgWaitTime'] ?? 0;
    final ratings = _analytics?['ratings'] ?? {};
    final period = _analytics?['period'] ?? {};
    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text('Avg Wait', style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('$avgWait min', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text('Rating', style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${ratings['avgRating'] ?? 0}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text('Total', style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${period['total'] ?? 0}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daily = (_analytics?['daily'] as List?) ?? [];
    
    if (daily.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text('No data for this period', style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted))),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: daily.map((d) => (d['count'] as int).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= daily.length) return const Text('');
                  final date = daily[value.toInt()]['_id'];
                  return Text(DateFormat('d').format(DateTime.parse(date)), style: TextStyle(fontSize: 10, color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barGroups: daily.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: (entry.value['count'] as int).toDouble(),
                  color: AppTheme.accentGreen,
                  width: 16,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPeakHoursChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hourly = (_analytics?['hourly'] as List?) ?? [];
    
    if (hourly.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text('No data for this period', style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted))),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final hour = value.toInt();
                  if (hour % 4 != 0) return const Text('');
                  return Text('${hour}h', style: TextStyle(fontSize: 10, color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: hourly.map((h) => FlSpot((h['_id'] as int).toDouble(), (h['count'] as int).toDouble())).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }
}

// Served Customers Bottom Sheet
class ServedCustomersSheet extends StatefulWidget {
  final String providerId;
  final String token;
  final String period;
  final DateTimeRange? customRange;

  const ServedCustomersSheet({
    super.key,
    required this.providerId,
    required this.token,
    required this.period,
    this.customRange,
  });

  @override
  State<ServedCustomersSheet> createState() => _ServedCustomersSheetState();
}

class _ServedCustomersSheetState extends State<ServedCustomersSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _customers = [];
  bool _isLoading = true;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers({bool reset = true}) async {
    if (reset) {
      setState(() {
        _page = 1;
        _isLoading = true;
      });
    }

    try {
      String? startDate;
      String? endDate;
      
      if (widget.period == 'custom' && widget.customRange != null) {
        startDate = widget.customRange!.start.toIso8601String().split('T')[0];
        endDate = widget.customRange!.end.toIso8601String().split('T')[0];
      }

      final data = await ApiService.getServedCustomers(
        widget.token,
        widget.providerId,
        period: widget.period,
        startDate: startDate,
        endDate: endDate,
        search: _searchController.text,
        page: _page,
      );

      setState(() {
        _customers = data['customers'] ?? [];
        _totalPages = data['pagination']?['pages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Served Customers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _fetchCustomers(),
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, or ticket...',
                    hintStyle: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                    prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? Center(
                        child: Text(
                          'No customers found',
                          style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _customers.length,
                        itemBuilder: (context, index) {
                          final customer = _customers[index];
                          final joinedAt = customer['joinedAt'] != null 
                              ? DateTime.parse(customer['joinedAt']).toLocal() 
                              : null;
                          final servedAt = customer['servedAt'] != null 
                              ? DateTime.parse(customer['servedAt']).toLocal() 
                              : null;
                          
                          // Calculate wait duration
                          String waitDuration = '-';
                          if (joinedAt != null && servedAt != null) {
                            final diff = servedAt.difference(joinedAt);
                            if (diff.inHours > 0) {
                              waitDuration = '${diff.inHours}h ${diff.inMinutes % 60}m';
                            } else {
                              waitDuration = '${diff.inMinutes}m';
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row - Ticket number, Name, Status badge
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        customer['queueNumber'] ?? 'Q?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.accentGreen,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customer['userName'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.phone, size: 14, color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                                              const SizedBox(width: 6),
                                              Text(
                                                customer['userPhone'] ?? 'No phone',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, size: 14, color: AppTheme.accentGreen),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Served',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.accentGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 16),
                                
                                // Time details row
                                Row(
                                  children: [
                                    // Join Date & Time
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Joined',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (joinedAt != null) ...[
                                            Text(
                                              DateFormat('MMM d, y').format(joinedAt),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                              ),
                                            ),
                                            Text(
                                              DateFormat('h:mm a').format(joinedAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    
                                    // Wait Duration
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Wait Time',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              waitDuration,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Served Time
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Served',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (servedAt != null) ...[
                                            Text(
                                              DateFormat('MMM d, y').format(servedAt),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                              ),
                                            ),
                                            Text(
                                              DateFormat('h:mm a').format(servedAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.accentGreen,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _page > 1 ? () { setState(() => _page--); _fetchCustomers(reset: false); } : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page $_page of $_totalPages'),
                  IconButton(
                    onPressed: _page < _totalPages ? () { setState(() => _page++); _fetchCustomers(reset: false); } : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
