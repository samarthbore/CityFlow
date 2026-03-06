import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../theme/app_theme.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final int avgServiceTime;

  const BookAppointmentScreen({
    required this.providerId,
    required this.providerName,
    this.avgServiceTime = 30,
    super.key,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  List<String> _availableSlots = [];
  List<String> _bookedSlots = [];
  bool _isLoadingSlots = false;
  bool _isBooking = false;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
    });

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await ApiService.getAvailableSlots(widget.providerId, dateString);
      
      if (mounted) {
        setState(() {
          _availableSlots = List<String>.from(response['available'] ?? []);
          _bookedSlots = List<String>.from(response['booked'] ?? []);
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load slots: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      await ApiService.bookAppointment(
        providerId: widget.providerId,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        timeSlot: _selectedSlot!,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Appointment booked successfully!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Book Appointment', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Provider Name
                  Text(
                    widget.providerName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  
                  // Date Selection
                  _buildSectionTitle('Select Date'),
                  const SizedBox(height: 12),
                  _buildDatePicker(),
                  
                  const SizedBox(height: 24),
                  
                  // Time Slots
                  _buildSectionTitle('Select Time'),
                  const SizedBox(height: 12),
                  _buildTimeSlots(),
                  
                  const SizedBox(height: 24),
                  
                  // Notes
                  _buildSectionTitle('Notes (Optional)'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                      decoration: InputDecoration(
                        hintText: 'Any special requests or notes...',
                        hintStyle: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Book Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
              border: Border(top: BorderSide(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isBooking || _selectedSlot == null) ? null : _bookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack,
                    foregroundColor: isDark ? AppTheme.primaryBlack : AppTheme.primaryWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: (isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack).withOpacity(0.5),
                  ),
                  child: _isBooking
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: isDark ? AppTheme.primaryBlack : AppTheme.primaryWhite,
                          ),
                        )
                      : Text(
                          _selectedSlot != null 
                              ? 'Book for ${DateFormat('MMM d').format(_selectedDate)} at $_selectedSlot'
                              : 'Select a time slot',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
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
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
    );
  }

  Widget _buildDatePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, // Next 2 weeks
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) == 
                            DateFormat('yyyy-MM-dd').format(_selectedDate);
          final isToday = index == 0;
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _fetchSlots();
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack)
                    : (isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? Colors.transparent 
                      : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected 
                          ? (isDark ? AppTheme.primaryBlack : AppTheme.primaryWhite)
                          : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? (isDark ? AppTheme.primaryBlack : AppTheme.primaryWhite)
                          : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlots() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_availableSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
            const SizedBox(height: 12),
            Text(
              'No slots available',
              style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _availableSlots.map((slot) {
        final isSelected = _selectedSlot == slot;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedSlot = slot),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? (isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack)
                  : (isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? Colors.transparent 
                    : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
              ),
            ),
            child: Text(
              slot,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected 
                    ? (isDark ? AppTheme.primaryBlack : AppTheme.primaryWhite)
                    : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
