import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MediaCapture {
  static final ImagePicker _picker = ImagePicker();

  /// Capture photo from camera
  static Future<XFile?> capturePhoto({
    ImageSource source = ImageSource.camera,
    int imageQuality = 70,
    double maxWidth = 1920,
    double maxHeight = 1080,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      return photo;
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return null;
    }
  }

  /// Capture video from camera
  static Future<XFile?> captureVideo({
    ImageSource source = ImageSource.camera,
    Duration maxDuration = const Duration(seconds: 60),
  }) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );
      return video;
    } catch (e) {
      debugPrint('Error capturing video: $e');
      return null;
    }
  }

  /// Pick media from gallery
  static Future<List<XFile>> pickMultipleMedia() async {
    try {
      final List<XFile> mediaFiles = await _picker.pickMultipleMedia();
      return mediaFiles;
    } catch (e) {
      debugPrint('Error picking multiple media: $e');
      return [];
    }
  }

  /// Upload media to Firebase Storage
  static Future<String?> uploadMedia({
    required String buildingId,
    required String workOrderId,
    required XFile mediaFile,
    String? customFileName,
  }) async {
    try {
      final storage = FirebaseStorage.instance;
      final fileName = customFileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${mediaFile.name}';

      // Determine content type and file extension
      final isVideo = mediaFile.name.toLowerCase().contains('.mp4') ||
          mediaFile.name.toLowerCase().contains('.mov') ||
          mediaFile.name.toLowerCase().contains('.avi');

      final contentType = isVideo ? 'video/mp4' : 'image/jpeg';
      final fileExtension = isVideo ? '.mp4' : '.jpg';

      // Create storage reference
      final ref = storage
          .ref('buildings/$buildingId/wo/$workOrderId/$fileName$fileExtension');

      // Upload file
      final bytes = await mediaFile.readAsBytes();
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'originalName': mediaFile.name,
          'uploadedAt': DateTime.now().toIso8601String(),
          'fileSize': bytes.length.toString(),
        },
      );

      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Media uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading media: $e');
      return null;
    }
  }

  /// Save media document to Firestore
  static Future<String?> saveMediaDocument({
    required String buildingId,
    required String workOrderId,
    required String mediaUrl,
    required String mediaType,
    String? description,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final mediaRef = await FirebaseFirestore.instance
          .doc('buildings/$buildingId/work_orders/$workOrderId')
          .collection('media')
          .add({
        'url': mediaUrl,
        'type': mediaType, // 'image' or 'video'
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'uploadedBy': 'current_user_id', // TODO: Replace with actual user ID
        'fileSize': 0, // TODO: Add actual file size
        'metadata': additionalData ?? {},
      });

      debugPrint('Media document saved with ID: ${mediaRef.id}');
      return mediaRef.id;
    } catch (e) {
      debugPrint('Error saving media document: $e');
      return null;
    }
  }

  /// Complete media upload workflow
  static Future<Map<String, dynamic>?> uploadAndSaveMedia({
    required String buildingId,
    required String workOrderId,
    required XFile mediaFile,
    String? description,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Upload to Storage
      final mediaUrl = await uploadMedia(
        buildingId: buildingId,
        workOrderId: workOrderId,
        mediaFile: mediaFile,
      );

      if (mediaUrl == null) {
        throw Exception('Failed to upload media to storage');
      }

      // Determine media type
      final mediaType = mediaFile.name.toLowerCase().contains('.mp4') ||
              mediaFile.name.toLowerCase().contains('.mov') ||
              mediaFile.name.toLowerCase().contains('.avi')
          ? 'video'
          : 'image';

      // Save to Firestore
      final mediaDocId = await saveMediaDocument(
        buildingId: buildingId,
        workOrderId: workOrderId,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        description: description,
        additionalData: additionalData,
      );

      if (mediaDocId == null) {
        throw Exception('Failed to save media document');
      }

      return {
        'mediaUrl': mediaUrl,
        'mediaDocId': mediaDocId,
        'mediaType': mediaType,
        'fileName': mediaFile.name,
      };
    } catch (e) {
      debugPrint('Error in complete media upload workflow: $e');
      return null;
    }
  }

  /// Delete media from Storage and Firestore
  static Future<bool> deleteMedia({
    required String buildingId,
    required String workOrderId,
    required String mediaDocId,
    required String mediaUrl,
  }) async {
    try {
      // Delete from Firestore first
      await FirebaseFirestore.instance
          .doc(
              'buildings/$buildingId/work_orders/$workOrderId/media/$mediaDocId')
          .delete();

      // Extract file path from URL and delete from Storage
      try {
        final storage = FirebaseStorage.instance;
        final ref = storage.refFromURL(mediaUrl);
        await ref.delete();
      } catch (storageError) {
        debugPrint('Warning: Could not delete from storage: $storageError');
        // Continue even if storage deletion fails
      }

      debugPrint('Media deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting media: $e');
      return false;
    }
  }

  /// Get media files for a work order
  static Stream<QuerySnapshot> getWorkOrderMedia({
    required String buildingId,
    required String workOrderId,
  }) {
    return FirebaseFirestore.instance
        .doc('buildings/$buildingId/work_orders/$workOrderId')
        .collection('media')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

/// Widget for displaying media preview
class MediaPreviewWidget extends StatelessWidget {
  final String mediaUrl;
  final String mediaType;
  final double? width;
  final double? height;
  final BoxFit fit;

  const MediaPreviewWidget({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaType == 'video') {
      return _buildVideoPreview();
    } else {
      return _buildImagePreview();
    }
  }

  Widget _buildVideoPreview() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Video Preview', style: TextStyle(color: Colors.grey)),
            Text('(Video player not yet implemented)',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Image.network(
      mediaUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(
            Icons.error,
            color: Colors.red,
            size: 48,
          ),
        );
      },
    );
  }
}
