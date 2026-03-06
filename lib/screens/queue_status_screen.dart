import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import '../models/queue_entry.dart';
import '../providers/queue_provider.dart';
import '../services/biometric_service.dart';
import 'package:city_flow_app/l10n/app_localizations.dart';

class QueueStatusScreen extends StatefulWidget {
  final QueueEntry queueEntry;
  final String providerName;
  final int avgServiceTime;

  const QueueStatusScreen({
    required this.queueEntry,
    required this.providerName,
    this.avgServiceTime = 10,
    super.key,
  });

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  final BiometricService _biometricService = BiometricService();
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  int _elapsedMinutes = 0;
  DateTime? _screenOpenedAt;
  bool _wasBeingServed = false; // Track if user was in "Called" state

  @override
  void initState() {
    super.initState();
    _screenOpenedAt = DateTime.now();
    
    // Start auto-refresh timer every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        final queueProvider = Provider.of<QueueProvider>(context, listen: false);
        queueProvider.fetchQueueStatus(widget.queueEntry.providerId);
        
        // Check if user has been served and auto-navigate away
        _checkIfServed(queueProvider);
      }
    });
    
    // Start a timer that ticks every minute to update the countdown
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedMinutes = DateTime.now().difference(_screenOpenedAt!).inMinutes;
        });
      }
    });
  }

  void _checkIfServed(QueueProvider queueProvider) {
    final status = queueProvider.queueStatus;
    if (status == null) return;
    
    final waitingList = status['waitingList'] as List<dynamic>? ?? [];
    final servingNumber = status['servingNumber'];
    final currentServing = status['currentServing'];
    
    // Check current states
    final inWaitingList = waitingList.any((e) => e['queueNumber'] == widget.queueEntry.queueNumber);
    final isBeingServed = servingNumber == widget.queueEntry.queueNumber || 
                          (currentServing != null && currentServing['queueNumber'] == widget.queueEntry.queueNumber);
    
    // If currently being served, mark it
    if (isBeingServed) {
      _wasBeingServed = true;
      return; // Don't check for served while being served
    }
    
    // If WAS being served but no longer (not in waiting, not being served) -> they're done
    if (_wasBeingServed && !inWaitingList && !isBeingServed) {
      // User has been served - clear queue and navigate back
      queueProvider.clearCurrentQueue();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thank you for visiting! You have been served.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
        title: Text(
          widget.providerName,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.white : Colors.black),
            onPressed: () {
               Provider.of<QueueProvider>(context, listen: false).fetchQueueStatus(widget.queueEntry.providerId);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                    ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                    : [const Color(0xFFF5F7FA), const Color(0xFFE8ECF2)],
              ),
            ),
          ),
          
          Consumer<QueueProvider>(
            builder: (context, queueProvider, child) {
              final status = queueProvider.queueStatus;
              
              int position = 0;
              String currentStatus = widget.queueEntry.status;
              int peopleAhead = 0;
              int estWaitMinutes = 0;
              
              if (status != null && status['providerId'] == widget.queueEntry.providerId) {
                 final waitingList = status['waitingList'] as List<dynamic>?;
                 if (waitingList != null) {
                   final index = waitingList.indexWhere((e) => e['queueNumber'] == widget.queueEntry.queueNumber);
                   if (index != -1) {
                     position = index + 1;
                     currentStatus = 'Waiting';
                     peopleAhead = index; // people strictly ahead
                     // Get avgServiceTime from status response (dynamically updated)
                     final dynamicAvgTime = status['avgServiceTime'] ?? widget.avgServiceTime;
                     // Calculate estimated wait with countdown offset
                     final baseWait = peopleAhead * dynamicAvgTime;
                     estWaitMinutes = (baseWait - _elapsedMinutes).clamp(0, 999).toInt();  
                   } else if (status['servingNumber'] == widget.queueEntry.queueNumber) {
                     currentStatus = 'Called';
                     position = 0;
                   }
                 }
              }

              final isServed = currentStatus == 'Served';
              final isCalled = currentStatus == 'Called';
              final primaryColor = theme.primaryColor;

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCalled ? Colors.green.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCalled ? Colors.green : primaryColor.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isCalled ? Colors.green : primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
                            const SizedBox(width: 8),
                            Text(
                              isCalled ? l10n.statusYourTurn.toUpperCase() : (isServed ? l10n.statusServed.toUpperCase() : l10n.statusWaiting.toUpperCase()),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCalled ? Colors.green : primaryColor,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ).animate().slideY(begin: -0.5, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 40),
                      
                      // MAIN TICKET CARD
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Decorative Arc
                              Positioned(
                                top: -50,
                                left: -50,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n.yourTicketNumber.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ).animate().fadeIn(delay: 400.ms),
                                    const SizedBox(height: 24),
                                    
                                    // HUGE NUMBER
                                    Hero(
                                      tag: 'queue_number',
                                      child: Text(
                                        widget.queueEntry.queueNumber,
                                        style: GoogleFonts.outfit(
                                          fontSize: 80,
                                          fontWeight: FontWeight.bold,
                                          color: isCalled ? Colors.green : theme.textTheme.bodyLarge?.color,
                                          height: 1,
                                        ),
                                      ).animate(target: isCalled ? 1 : 0)
                                       .shake(delay: 500.ms)
                                       .shimmer(duration: 1000.ms, color: Colors.greenAccent),
                                    ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),
                                    
                                    const SizedBox(height: 40),
                                    const Divider(),
                                    const SizedBox(height: 40),
                                    
                                    // METRICS GRID
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildMetric(
                                          context,
                                          l10n.nowServing,
                                          status?['servingNumber']?.toString() ?? '-',
                                          Icons.campaign,
                                          delay: 200,
                                        ),
                                        _buildMetric(
                                          context,
                                          l10n.peopleAhead,
                                          isCalled || isServed ? '0' : peopleAhead.toString(),
                                          Icons.groups,
                                          delay: 300,
                                        ),
                                        _buildMetric(
                                          context,
                                          l10n.estimatedWait,
                                          isCalled || isServed ? '0 ${l10n.mins}' : '$estWaitMinutes ${l10n.mins}',
                                          Icons.timer,
                                          delay: 400,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutBack)
                        .fadeIn(duration: 400.ms)
                        .shimmer(delay: 800.ms, duration: 1200.ms, color: Colors.white.withOpacity(0.2)),
                      ),

                      const SizedBox(height: 30),

                      // Exit Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _handleLeaveQueue(context, isServed),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.dividerColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: theme.cardColor.withOpacity(0.5),
                          ),
                          child: Text(
                            isServed ? 'Close' : l10n.leaveQueue,
                            style: GoogleFonts.inter(
                              color: isServed ? theme.textTheme.bodyMedium?.color : theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 1000.ms).slideY(begin: 1, end: 0),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleLeaveQueue(BuildContext context, bool isServed) async {
    final theme = Theme.of(context);
    final provider = Provider.of<QueueProvider>(context, listen: false);

    if (!isServed) {
      // Show confirmation dialog before security check
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Leave Queue?'),
          content: const Text('You will lose your spot.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx); // Close confirmation dialog
                
                // --- SECURITY CHECK LAYER ---
                if (provider.isBiometricsEnabled) {
                  bool authenticated = await _biometricService.authenticate(
                    localizedReason: 'Authenticate to leave the queue',
                  );
                  
                  if (!authenticated) {
                    // Fallback to password
                    if (context.mounted) {
                       authenticated = await _showPasswordDialog(context);
                    }
                  }
                  
                  if (!authenticated) return; // Abort if auth fails
                }
                // -----------------------------

                if (context.mounted) {
                  provider.leaveQueue();
                  Navigator.pop(context); // Close Status Screen
                }
              },
              child: Text('Leave', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        ),
      );
    } else {
      provider.leaveQueue();
      Navigator.pop(context);
    }
  }

  Future<bool> _showPasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter your password to confirm.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
               final queueProvider = Provider.of<QueueProvider>(context, listen: false);
               final isValid = await queueProvider.verifyPassword(passwordController.text);
               if (isValid) {
                 Navigator.of(context).pop(true);
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Invalid Password')),
                 );
               }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildMetric(BuildContext context, String label, String value, IconData icon, {int delay = 0}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0);
  }
}
