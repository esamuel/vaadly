import 'package:flutter/material.dart';
import '../../../core/models/resident.dart';

class ResidentCard extends StatelessWidget {
  final Resident resident;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ResidentCard({
    super.key,
    required this.resident,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  static const Map<String, String> _tagTranslations = {
    'VIP': 'VIP',
    'Special Needs': 'צרכים מיוחדים',
    'Pet Owner': 'בעל/ת חיית מחמד',
    'Senior Citizen': 'אזרח/ית ותיק/ה',
    'Student': 'סטודנט/ית',
    'Family with Children': 'משפחה עם ילדים',
    'Single': 'רווק/ה',
    'Working Professional': 'עובד/ת',
    'Retired': 'גמלאי/ת',
    'Medical Professional': 'איש/אשת רפואה',
    'Emergency Contact': 'איש קשר לחירום',
    'Building Committee Member': 'חבר/ת ועד הבית',
  };

  String _t(String key) => _tagTranslations[key] ?? key;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and basic info
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: _getAvatarColor(resident.residentType),
                    child: Text(
                      resident.firstName.isNotEmpty
                          ? resident.firstName[0]
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Basic info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resident.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resident.apartmentDisplay,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (resident.floor != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'קומה ${resident.floor}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusChip(resident.status),
                            const SizedBox(width: 8),
                            _buildTypeChip(resident.residentType),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action menu
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                        case 'call':
                          _makePhoneCall(context, resident.phoneNumber);
                          break;
                        case 'email':
                          _sendEmail(context, resident.email);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('ערוך'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'call',
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 20),
                            SizedBox(width: 8),
                            Text('התקשר'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'email',
                        child: Row(
                          children: [
                            Icon(Icons.email, size: 20),
                            SizedBox(width: 8),
                            Text('שלח אימייל'),
                          ],
                        ),
                      ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('מחק', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Contact information
              _buildInfoRow(Icons.phone, resident.phoneNumber),
              _buildInfoRow(Icons.email, resident.email),
              if (resident.residentId != null &&
                  resident.residentId!.isNotEmpty)
                _buildInfoRow(Icons.badge, 'ת.ז: ${resident.residentId}'),

              // Emergency contact if available
              if (resident.emergencyContact != null &&
                  resident.emergencyContact!.isNotEmpty)
                _buildInfoRow(
                  Icons.emergency,
                  '${resident.emergencyContact} - ${resident.emergencyPhone ?? 'אין טלפון'}',
                  isEmergency: true,
                ),

              const SizedBox(height: 12),

              // Dates and additional info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.calendar_today,
                      'נכנס: ${_formatDate(resident.moveInDate)}',
                      showIcon: false,
                    ),
                  ),
                  if (resident.moveOutDate != null)
                    Expanded(
                      child: _buildInfoRow(
                        Icons.calendar_today,
                        'יצא: ${_formatDate(resident.moveOutDate!)}',
                        showIcon: false,
                      ),
                    ),
                ],
              ),

              // Tags
              if (resident.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: resident.tags.map((tag) {
                    return Chip(
                      label: Text(
                        _t(tag),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue[50],
                      side: BorderSide(color: Colors.blue[200]!),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    );
                  }).toList(),
                ),
              ],

              // Notes if available
              if (resident.notes != null && resident.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.note, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'הערות:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resident.notes!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Last updated info
              const SizedBox(height: 12),
              Text(
                'עודכן לאחרונה: ${_formatDate(resident.updatedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text,
      {bool showIcon = true, bool isEmergency = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              icon,
              size: 16,
              color: isEmergency ? Colors.red : Colors.grey[600],
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isEmergency ? Colors.red : Colors.grey[700],
                fontWeight: isEmergency ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ResidentStatus status) {
    Color color;
    String text;

    switch (status) {
      case ResidentStatus.active:
        color = Colors.green;
        text = 'פעיל';
        break;
      case ResidentStatus.inactive:
        color = Colors.grey;
        text = 'לא פעיל';
        break;
      case ResidentStatus.pending:
        color = Colors.orange;
        text = 'ממתין';
        break;
      case ResidentStatus.suspended:
        color = Colors.red;
        text = 'מושעה';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypeChip(ResidentType type) {
    Color color;
    String text;

    switch (type) {
      case ResidentType.owner:
        color = Colors.blue;
        text = 'בעל דירה';
        break;
      case ResidentType.tenant:
        color = Colors.green;
        text = 'שוכר';
        break;
      case ResidentType.familyMember:
        color = Colors.purple;
        text = 'בן משפחה';
        break;
      case ResidentType.guest:
        color = Colors.orange;
        text = 'אורח';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getAvatarColor(ResidentType type) {
    switch (type) {
      case ResidentType.owner:
        return Colors.blue;
      case ResidentType.tenant:
        return Colors.green;
      case ResidentType.familyMember:
        return Colors.purple;
      case ResidentType.guest:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _makePhoneCall(BuildContext context, String phoneNumber) {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('מתקשר ל: $phoneNumber'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sendEmail(BuildContext context, String email) {
    // TODO: Implement email functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('שולח אימייל ל: $email'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
