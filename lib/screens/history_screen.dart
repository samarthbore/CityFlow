import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/queue_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<QueueProvider>(context, listen: false).fetchHistory());
  }

  void _showQueueDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QueueDetailsSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queueProvider = Provider.of<QueueProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.historyTitle ?? 'History', style: Theme.of(context).textTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: queueProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : queueProvider.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noHistory ?? 'No history found',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: queueProvider.history.length,
                  itemBuilder: (context, index) {
                    final item = queueProvider.history[index];
                    final provider = item['providerId'];
                    final date = DateTime.parse(item['joinedAt']).toLocal();

                    return GestureDetector(
                      onTap: () => _showQueueDetails(item),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getStatusColor(item['status']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item['queueNumber'],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(item['status']),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider != null ? provider['name'] : 'Unknown Provider',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Joined: ${DateFormat('MMM d, y • h:mm a').format(date)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  if (item['servedAt'] != null && item['status'] == 'Served') ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Served: ${DateFormat('h:mm a').format(DateTime.parse(item['servedAt']).toLocal())}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(item['status']).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item['status'],
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _getStatusColor(item['status']),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Waiting':
        return Colors.orange;
      case 'Called':
        return Colors.blue;
      case 'Served':
        return Colors.green;
      case 'Canceled':
      case 'NoShow':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Queue Details Bottom Sheet
class QueueDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> item;

  const QueueDetailsSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = item['providerId'];
    final joinedAt = item['joinedAt'] != null ? DateTime.parse(item['joinedAt']).toLocal() : null;
    final servedAt = item['servedAt'] != null ? DateTime.parse(item['servedAt']).toLocal() : null;
    final calledAt = item['calledAt'] != null ? DateTime.parse(item['calledAt']).toLocal() : null;
    
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

    Color statusColor;
    IconData statusIcon;
    switch (item['status']) {
      case 'Waiting':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'Called':
        statusColor = Colors.blue;
        statusIcon = Icons.notifications_active;
        break;
      case 'Served':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Canceled':
      case 'NoShow':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['status'] ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              'Ticket ${item['queueNumber'] ?? '-'}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Provider Info
                  _buildInfoSection(context, 'Provider', provider?['name'] ?? 'Unknown', Icons.store, isDark),
                  if (provider?['city'] != null)
                    _buildInfoSection(context, 'Location', provider['city'], Icons.location_on, isDark),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  
                  // Time Details
                  Text(
                    'Timeline',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTimelineItem(context, 'Joined Queue', joinedAt, Colors.orange, isDark, true),
                  if (calledAt != null)
                    _buildTimelineItem(context, 'Called', calledAt, Colors.blue, isDark, servedAt == null),
                  if (servedAt != null)
                    _buildTimelineItem(context, 'Served', servedAt, Colors.green, isDark, true),
                  if (item['status'] == 'Canceled')
                    _buildTimelineItem(context, 'Canceled', joinedAt, Colors.red, isDark, true),
                  
                  const SizedBox(height: 24),
                  
                  // Wait Duration (only for served)
                  if (item['status'] == 'Served') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Total Wait Time',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            waitDuration,
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, String label, DateTime? time, Color color, bool isDark, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: color.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                if (time != null)
                  Text(
                    DateFormat('MMM d, y • h:mm a').format(time),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
