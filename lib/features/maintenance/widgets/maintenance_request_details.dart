import 'package:flutter/material.dart';
import '../../../core/models/maintenance_request.dart';
import '../../../core/services/maintenance_service.dart';

class MaintenanceRequestDetails extends StatefulWidget {
  final MaintenanceRequest request;
  final VoidCallback? onRequestUpdated;

  const MaintenanceRequestDetails({
    super.key,
    required this.request,
    this.onRequestUpdated,
  });

  @override
  State<MaintenanceRequestDetails> createState() =>
      _MaintenanceRequestDetailsState();
}

class _MaintenanceRequestDetailsState extends State<MaintenanceRequestDetails> {
  late MaintenanceRequest _request;
  final _vendorNameController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _rejectionReasonController = TextEditingController();
  final _cancellationReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    _vendorNameController.text = _request.assignedVendorName ?? '';
    _costController.text = _request.actualCost ?? '';
    _notesController.text = _request.notes ?? '';
  }

  @override
  void dispose() {
    _vendorNameController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _rejectionReasonController.dispose();
    _cancellationReasonController.dispose();
    super.dispose();
  }

  void _updateRequest() {
    if (widget.onRequestUpdated != null) {
      widget.onRequestUpdated!();
    }
    setState(() {});
  }

  void _assignToVendor() {
    if (_vendorNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין שם הספק'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = MaintenanceService.assignToVendor(
      _request.id,
      'vendor_${DateTime.now().millisecondsSinceEpoch}',
      _vendorNameController.text.trim(),
    );

    if (success) {
      setState(() {
        _request = MaintenanceService.getRequestById(_request.id)!;
      });
      _updateRequest();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('הבקשה הוקצתה לספק בהצלחה'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _startWork() {
    final success = MaintenanceService.startWork(_request.id);
    if (success) {
      setState(() {
        _request = MaintenanceService.getRequestById(_request.id)!;
      });
      _updateRequest();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('העבודה החלה בהצלחה'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _completeWork() {
    if (_costController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין עלות בפועל'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = MaintenanceService.completeWork(
      _request.id,
      _costController.text.trim(),
    );
    if (success) {
      setState(() {
        _request = MaintenanceService.getRequestById(_request.id)!;
      });
      _updateRequest();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('העבודה הושלמה בהצלחה'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _putOnHold() {
    final success = MaintenanceService.putOnHold(_request.id);
    if (success) {
      setState(() {
        _request = MaintenanceService.getRequestById(_request.id)!;
      });
      _updateRequest();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('הבקשה הושהתה בהצלחה'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _rejectRequest() {
    if (_rejectionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין סיבת דחייה'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = MaintenanceService.rejectRequest(
      _request.id,
      _rejectionReasonController.text.trim(),
    );
    if (success) {
      setState(() {
        _request = MaintenanceService.getRequestById(_request.id)!;
      });
      _updateRequest();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('הבקשה נדחתה בהצלחה'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelRequest() {
    if (_cancellationReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין סיבת ביטול'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = MaintenanceService.cancelRequest(
      _request.id,
      _cancellationReasonController.text.trim(),
    );
    if (success) {
      setState(() {
        _request = MaintenanceService.getRequestById(_request.id)!;
      });
      _updateRequest();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('הבקשה בוטלה בהצלחה'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('פרטי בקשה'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  // TODO: Implement edit functionality
                  break;
                case 'delete':
                  _showDeleteConfirmation();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('ערוך'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('מחק', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and priority
            _buildHeaderCard(),
            const SizedBox(height: 16),

            // Request details
            _buildDetailsCard(),
            const SizedBox(height: 16),

            // Timeline
            _buildTimelineCard(),
            const SizedBox(height: 16),

            // Media attachments
            if (_request.photoUrls.isNotEmpty ||
                _request.documentUrls.isNotEmpty)
              _buildMediaCard(),
            if (_request.photoUrls.isNotEmpty ||
                _request.documentUrls.isNotEmpty)
              const SizedBox(height: 16),

            // Action buttons based on status
            _buildActionButtons(),
            const SizedBox(height: 16),

            // Notes and updates
            _buildNotesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _request.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_request.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(_request.status)),
                  ),
                  child: Text(
                    _getStatusDisplay(_request.status),
                    style: TextStyle(
                      color: _getStatusColor(_request.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getPriorityColor(_request.priority).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _getPriorityColor(_request.priority)),
                  ),
                  child: Text(
                    _getPriorityDisplay(_request.priority),
                    style: TextStyle(
                      color: _getPriorityColor(_request.priority),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    _getCategoryDisplay(_request.category),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'פרטי הבקשה',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('תיאור', _request.description),
            if (_request.location != null)
              _buildDetailRow('מיקום', _request.location!),
            if (_request.unitId != null)
              _buildDetailRow('יחידה', 'יחידה ${_request.unitId}'),
            _buildDetailRow('דווח על ידי', 'דייר ${_request.residentId}'),
            _buildDetailRow('תאריך דיווח', _formatDate(_request.reportedAt)),
            if (_request.estimatedCost != null)
              _buildDetailRow('עלות משוערת', _request.estimatedCost!),
            if (_request.actualCost != null)
              _buildDetailRow('עלות בפועל', _request.actualCost!),
            if (_request.assignedVendorName != null)
              _buildDetailRow('ספק מוקצה', _request.assignedVendorName!),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ציר זמן',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              'דווח',
              _formatDate(_request.reportedAt),
              Icons.report_problem,
              Colors.blue,
            ),
            if (_request.assignedAt != null)
              _buildTimelineItem(
                'הוקצה לספק',
                _formatDate(_request.assignedAt!),
                Icons.person_add,
                Colors.orange,
              ),
            if (_request.startedAt != null)
              _buildTimelineItem(
                'העבודה החלה',
                _formatDate(_request.startedAt!),
                Icons.engineering,
                Colors.yellow,
              ),
            if (_request.completedAt != null)
              _buildTimelineItem(
                'הושלם',
                _formatDate(_request.completedAt!),
                Icons.check_circle,
                Colors.green,
              ),
            if (_request.cancelledAt != null)
              _buildTimelineItem(
                'בוטל',
                _formatDate(_request.cancelledAt!),
                Icons.cancel,
                Colors.red,
              ),
            if (_request.rejectionReason != null)
              _buildTimelineItem(
                'נדחה',
                'סיבה: ${_request.rejectionReason}',
                Icons.block,
                Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'קבצים מצורפים',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_request.photoUrls.isNotEmpty) ...[
              const Text('תמונות:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _request.photoUrls.map((photo) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.image, size: 40, color: Colors.grey),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (_request.documentUrls.isNotEmpty) ...[
              const Text('מסמכים:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(_request.documentUrls.map((doc) {
                return ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(doc),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      // TODO: Implement download
                    },
                  ),
                );
              })),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'פעולות',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_request.status == MaintenanceStatus.pending) ...[
                  ElevatedButton.icon(
                    onPressed: _assignToVendor,
                    icon: const Icon(Icons.person_add),
                    label: const Text('הקצה לספק'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _putOnHold,
                    icon: const Icon(Icons.pause),
                    label: const Text('השהה'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showRejectionDialog(),
                    icon: const Icon(Icons.block),
                    label: const Text('דחה'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (_request.status == MaintenanceStatus.assigned) ...[
                  ElevatedButton.icon(
                    onPressed: _startWork,
                    icon: const Icon(Icons.engineering),
                    label: const Text('התחל עבודה'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (_request.status == MaintenanceStatus.inProgress) ...[
                  ElevatedButton.icon(
                    onPressed: () => _showCompletionDialog(),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('השלם'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (_request.status == MaintenanceStatus.onHold) ...[
                  ElevatedButton.icon(
                    onPressed: _startWork,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('המשך עבודה'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (_request.status != MaintenanceStatus.completed &&
                    _request.status != MaintenanceStatus.cancelled &&
                    _request.status != MaintenanceStatus.rejected)
                  ElevatedButton.icon(
                    onPressed: () => _showCancellationDialog(),
                    icon: const Icon(Icons.cancel),
                    label: const Text('בטל'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'הערות ועדכונים',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'הערות נוספות',
                border: OutlineInputBorder(),
                hintText: 'הוסף הערות או עדכונים על הבקשה',
              ),
              maxLines: 3,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement notes update
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ההערות נשמרו בהצלחה'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('שמור הערות'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
      String title, String date, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(date,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('דחיית בקשה'),
        content: TextFormField(
          controller: _rejectionReasonController,
          decoration: const InputDecoration(
            labelText: 'סיבת הדחייה',
            border: OutlineInputBorder(),
            hintText: 'הסבר מדוע הבקשה נדחית',
          ),
          maxLines: 3,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectRequest();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('דחה', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('השלמת עבודה'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'עלות בפועל',
                border: OutlineInputBorder(),
                hintText: 'למשל: ₪500',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'הערות סיום',
                border: OutlineInputBorder(),
                hintText: 'תיאור העבודה שבוצעה',
              ),
              maxLines: 3,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeWork();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('השלם', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCancellationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ביטול בקשה'),
        content: TextFormField(
          controller: _cancellationReasonController,
          decoration: const InputDecoration(
            labelText: 'סיבת הביטול',
            border: OutlineInputBorder(),
            hintText: 'הסבר מדוע הבקשה מבוטלת',
          ),
          maxLines: 3,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelRequest();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('בטל בקשה', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת בקשה'),
        content: const Text('האם אתה בטוח שברצונך למחוק בקשה זו?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              MaintenanceService.deleteRequest(_request.id);
              Navigator.of(context).pop();
              _updateRequest();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('הבקשה נמחקה בהצלחה'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('מחק', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Helper methods for display properties
  String _getCategoryDisplay(MaintenanceCategory category) {
    switch (category) {
      case MaintenanceCategory.plumbing:
        return 'אינסטלציה';
      case MaintenanceCategory.electrical:
        return 'חשמל';
      case MaintenanceCategory.hvac:
        return 'מיזוג אוויר';
      case MaintenanceCategory.cleaning:
        return 'ניקיון';
      case MaintenanceCategory.gardening:
        return 'גינון';
      case MaintenanceCategory.elevator:
        return 'מעליות';
      case MaintenanceCategory.security:
        return 'אבטחה';
      case MaintenanceCategory.structural:
        return 'מבני';
      case MaintenanceCategory.general:
        return 'כללי';
    }
  }

  String _getPriorityDisplay(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.urgent:
        return 'דחוף';
      case MaintenancePriority.high:
        return 'גבוה';
      case MaintenancePriority.normal:
        return 'רגיל';
      case MaintenancePriority.low:
        return 'נמוך';
    }
  }

  Color _getPriorityColor(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.urgent:
        return Colors.red;
      case MaintenancePriority.high:
        return Colors.orange;
      case MaintenancePriority.normal:
        return Colors.blue;
      case MaintenancePriority.low:
        return Colors.green;
    }
  }

  String _getStatusDisplay(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return 'ממתין';
      case MaintenanceStatus.assigned:
        return 'מוקצה';
      case MaintenanceStatus.inProgress:
        return 'בתהליך';
      case MaintenanceStatus.onHold:
        return 'מושהה';
      case MaintenanceStatus.completed:
        return 'הושלם';
      case MaintenanceStatus.cancelled:
        return 'בוטל';
      case MaintenanceStatus.rejected:
        return 'נדחה';
    }
  }

  Color _getStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return Colors.grey;
      case MaintenanceStatus.assigned:
        return Colors.blue;
      case MaintenanceStatus.inProgress:
        return Colors.orange;
      case MaintenanceStatus.onHold:
        return Colors.yellow;
      case MaintenanceStatus.completed:
        return Colors.green;
      case MaintenanceStatus.cancelled:
        return Colors.red;
      case MaintenanceStatus.rejected:
        return Colors.red;
    }
  }
}
