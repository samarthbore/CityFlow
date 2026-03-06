import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../providers/queue_provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'package:city_flow_app/l10n/app_localizations.dart';
import 'analytics_dashboard_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _currentIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final queueProvider = Provider.of<QueueProvider>(context, listen: false);
      if (queueProvider.managedProviderName != null) {
        queueProvider.fetchQueueStatus(queueProvider.queueStatus?['providerId'] ?? '');
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queueProvider = Provider.of<QueueProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final providerName = queueProvider.managedProviderName ?? l10n.businessDashboard;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> _tabs = [
      _QueueTab(queueProvider: queueProvider),
      _SettingsTab(queueProvider: queueProvider),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(providerName, style: Theme.of(context).textTheme.titleLarge),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final providerId = queueProvider.queueStatus?['providerId'];
              if (providerId != null) {
                queueProvider.fetchQueueStatus(providerId);
              }
            },
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        selectedItemColor: isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack,
        unselectedItemColor: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: l10n.queueTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settingsTab,
          ),
        ],
      ),
    );
  }
}

class _QueueTab extends StatelessWidget {
  final QueueProvider queueProvider;
  const _QueueTab({required this.queueProvider});

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name *',
                prefixIcon: Icon(Icons.person),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (Optional)',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter customer name')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await queueProvider.addManualCustomer(
                  name,
                  phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name added to queue')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add to Queue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queueStatus = queueProvider.queueStatus;
    final currentServing = queueStatus?['currentServing'];
    final waitingList = queueStatus?['waitingList'] as List? ?? [];
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
        backgroundColor: AppTheme.accentGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Serving Card - Fixed coloring
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentGreen,
                  AppTheme.accentGreen.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGreen.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  l10n.nowServing,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  currentServing != null
                      ? '#${currentServing['queueNumber']}'
                      : '---',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentServing != null
                      ? currentServing['userName']
                      : l10n.noActiveCustomer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (currentServing != null) ...[
                  const SizedBox(height: 24),
                  // Row of action buttons: Undo | Mark Served | Not Present
                  Row(
                    children: [
                      // Undo Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              await queueProvider.undoCallNext();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Call undone. Customer returned to queue.')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.undo, size: 18),
                          label: const Text('Undo', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mark Served Button (Primary)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            queueProvider.markAsServed(currentServing['_id']);
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 20),
                          label: Text(l10n.markAsServed, style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.accentGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Not Present Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Mark Not Present?'),
                                content: Text(
                                  'This will move ${currentServing['userName']} back 5 positions in the queue and call the next customer.'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await queueProvider.markNotPresent(currentServing['_id']);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Customer moved back. Calling next...')),
                                  );
                                  // Automatically call next
                                  queueProvider.callNextUser();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.person_off, size: 16),
                          label: const Text('Absent', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Waiting List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.waitingListHeader} (${waitingList.length})',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  queueProvider.callNextUser();
                },
                icon: const Icon(Icons.notifications_active),
                label: Text(l10n.callNext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Waiting List
          Expanded(
            child: waitingList.isEmpty
                ? Center(
                    child: Text(
                      l10n.queueEmpty,
                      style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: waitingList.length,
                    itemBuilder: (context, index) {
                      final user = waitingList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark ? AppTheme.primaryWhite.withOpacity(0.1) : AppTheme.primaryBlack.withOpacity(0.1),
                            child: Text(
                              '${user['queueNumber']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                          ),
                          title: Text(user['userName'], style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['userPhone'] ?? '', style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted, fontSize: 12)),
                              if (user['joinedAt'] != null)
                                Text(
                                  'Joined: ${DateFormat('h:mm a').format(DateTime.parse(user['joinedAt']).toLocal())}',
                                  style: TextStyle(color: AppTheme.accentGreen, fontSize: 11),
                                ),
                            ],
                          ),
                          trailing: Icon(Icons.hourglass_empty, size: 16, color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }
}

class _SettingsTab extends StatefulWidget {
  final QueueProvider queueProvider;
  const _SettingsTab({required this.queueProvider});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late bool _isOpen;
  late double _avgTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.queueProvider.isManagedProviderOpen;
    _avgTime = widget.queueProvider.managedProviderAvgTime.toDouble();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await widget.queueProvider.updateSettings(_isOpen, _avgTime.toInt());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings updated successfully!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qrCode = widget.queueProvider.managedProviderQRCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR Code Section
          _buildSectionHeader('QR Code for Customers'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            ),
            child: Column(
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: qrCode != null && qrCode.isNotEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2, size: 100, color: AppTheme.primaryBlack),
                              const SizedBox(height: 8),
                              Text(
                                qrCode,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlack,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2, size: 80, color: AppTheme.primaryBlack.withOpacity(0.3)),
                              const SizedBox(height: 8),
                              Text('No QR Code', style: TextStyle(color: AppTheme.primaryBlack.withOpacity(0.5))),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Customers can scan this to join your queue',
                  style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Queue Status Section
          _buildSectionHeader(l10n.businessStatus),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            ),
            child: SwitchListTile(
              title: Text(l10n.queueOpen, style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
              subtitle: Text(_isOpen ? l10n.customersCanJoin : l10n.queueClosed, style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted)),
              value: _isOpen,
              onChanged: (val) => setState(() => _isOpen = val),
              activeColor: AppTheme.accentGreen,
              secondary: Icon(
                _isOpen ? Icons.check_circle : Icons.remove_circle,
                color: _isOpen ? AppTheme.accentGreen : AppTheme.errorRed,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Average Time Section
          _buildSectionHeader(l10n.waitTimeEstimation),
          const SizedBox(height: 8),
          Text(
            '${l10n.avgTimePerCustomer}: ${_avgTime.toInt()} ${l10n.mins}',
            style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
          ),
          Slider(
            value: _avgTime,
            min: 1,
            max: 60,
            divisions: 59,
            label: '${_avgTime.toInt()} ${l10n.mins}',
            activeColor: AppTheme.accentGreen,
            onChanged: (val) => setState(() => _avgTime = val),
          ),
          
          const SizedBox(height: 16),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack,
                foregroundColor: isDark ? AppTheme.primaryBlack : AppTheme.primaryWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: _isSaving
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppTheme.primaryBlack : AppTheme.primaryWhite))
                  : Text(l10n.saveChanges, style: const TextStyle(fontSize: 16)),
            ),
          ),
          
          const SizedBox(height: 28),
          
          // Theme Section
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 12),
          _buildThemeSelector(themeProvider),
          
          const SizedBox(height: 24),
          
          // Language Section
          _buildSectionHeader(l10n.language),
          const SizedBox(height: 12),
          _buildLanguageSelector(languageProvider),
          
          const SizedBox(height: 24),
          
          // Analytics Button
          _buildSectionHeader('Business Insights'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final token = widget.queueProvider.staffToken;
                final providerId = widget.queueProvider.queueStatus?['providerId'];
                if (token != null && providerId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnalyticsDashboardScreen(
                        providerId: providerId,
                        token: token,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.bar_chart),
              label: const Text('View Analytics', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                side: BorderSide(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Logout Button - at bottom with confirmation
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutConfirmation(context),
              icon: Icon(Icons.logout, color: AppTheme.errorRed),
              label: Text('Log Out', style: TextStyle(color: AppTheme.errorRed, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.errorRed.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        title: Text('Log Out', style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
        content: Text('Are you sure you want to log out?', style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              widget.queueProvider.logout();
              Navigator.of(context).pop(); // Go back to login
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
    );
  }

  Widget _buildThemeSelector(ThemeProvider themeProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themes = [
      ('Light', ThemeMode.light, Icons.light_mode_outlined),
      ('Dark', ThemeMode.dark, Icons.dark_mode_outlined),
      ('System', ThemeMode.system, Icons.phone_android_outlined),
    ];
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
      ),
      child: Column(
        children: themes.asMap().entries.map((entry) {
          final index = entry.key;
          final (label, mode, icon) = entry.value;
          final isSelected = themeProvider.themeMode == mode;
          return Column(
            children: [
              ListTile(
                leading: Icon(icon, color: isSelected ? AppTheme.accentGreen : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted)),
                title: Text(label, style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
                trailing: isSelected ? Icon(Icons.check_circle, color: AppTheme.accentGreen) : null,
                onTap: () => themeProvider.setTheme(mode),
              ),
              if (index < themes.length - 1)
                Divider(height: 1, color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageSelector(LanguageProvider languageProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languages = [
      ('🇺🇸', 'English', 'en'),
      ('🇮🇳', 'हिंदी', 'hi'),
      ('🇮🇳', 'मराठी', 'mr'),
    ];
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
      ),
      child: Column(
        children: languages.asMap().entries.map((entry) {
          final index = entry.key;
          final (flag, label, code) = entry.value;
          final isSelected = languageProvider.currentLocale.languageCode == code;
          return Column(
            children: [
              ListTile(
                leading: Text(flag, style: const TextStyle(fontSize: 24)),
                title: Text(label, style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
                trailing: isSelected ? Icon(Icons.check_circle, color: AppTheme.accentGreen) : null,
                onTap: () => languageProvider.changeLanguage(Locale(code)),
              ),
              if (index < languages.length - 1)
                Divider(height: 1, color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            ],
          );
        }).toList(),
      ),
    );
  }
}
