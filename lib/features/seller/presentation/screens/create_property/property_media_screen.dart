import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zogo_realtor/features/seller/data/services/seller_service.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_documents_screen.dart';

class PropertyMediaScreen extends StatefulWidget {
  final String propertyId;
  final String? propertyType;

  const PropertyMediaScreen({
    super.key,
    required this.propertyId,
    this.propertyType,
  });

  @override
  State<PropertyMediaScreen> createState() => _PropertyMediaScreenState();
}

class _MediaItem {
  final String? id;
  final File? localFile;
  final String name;
  final int sizeBytes;
  final int mediaType; // 1: Image, 2: Video
  bool isCover;
  bool isUploading;
  double uploadProgress;
  String? error;
  String? remoteUrl;

  _MediaItem({
    this.id,
    this.localFile,
    required this.name,
    required this.sizeBytes,
    required this.mediaType,
    this.isCover = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.remoteUrl,
  });

  String get sizeFormatted {
    final mb = sizeBytes / (1024 * 1024);
    if (mb >= 1.0) {
      return '${mb.toStringAsFixed(1)} MB';
    }
    final kb = sizeBytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }
}

class _PropertyMediaScreenState extends State<PropertyMediaScreen> {
  static const Color primaryColor = Color(0xFF00C6D4);
  static const int maxSizeBytes = 10 * 1024 * 1024; // 10 MB limit

  final SellerService _sellerService = SellerService();
  final ImagePicker _picker = ImagePicker();

  final List<_MediaItem> _mediaItems = [];
  bool _isLoading = true;
  bool _isFinalizing = false;

  @override
  void initState() {
    super.initState();
    _loadExistingMedia();
  }

  Future<void> _loadExistingMedia() async {
    try {
      final mediaList = await _sellerService.getPropertyMedia(widget.propertyId);
      if (mounted) {
        setState(() {
          for (final m in mediaList) {
            final mediaId = m['id']?.toString() ?? m['mediaId']?.toString();
            final mediaType = (m['mediaType'] as num?)?.toInt() ?? 1;
            final isCover = m['isCover'] == true;
            final originalName = m['originalFileName']?.toString() ?? 'Media';
            final sizeBytes = (m['fileSizeBytes'] as num?)?.toInt() ?? 0;
            final storageKey = m['storageKey']?.toString();

            _mediaItems.add(
              _MediaItem(
                id: mediaId,
                name: originalName,
                sizeBytes: sizeBytes,
                mediaType: mediaType,
                isCover: isCover,
                remoteUrl: storageKey,
              ),
            );
          }
        });
      }
    } catch (_) {
      // Non-blocking
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final pickedFiles = await _picker.pickMultiImage(imageQuality: 85);
        if (pickedFiles.isEmpty) return;

        for (final xfile in pickedFiles) {
          await _processAndUploadFile(xfile, mediaType: 1);
        }
      } else {
        final xfile = await _picker.pickImage(source: source, imageQuality: 85);
        if (xfile == null) return;
        await _processAndUploadFile(xfile, mediaType: 1);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final xfile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 3),
      );
      if (xfile == null) return;

      await _processAndUploadFile(xfile, mediaType: 2);
    } catch (e) {
      _showErrorSnackBar('Failed to pick video: $e');
    }
  }

  Future<void> _processAndUploadFile(
    XFile xfile, {
    required int mediaType,
  }) async {
    final size = await xfile.length();
    final fileName = xfile.name;

    // Enforce 10 MB maximum limit
    if (size > maxSizeBytes) {
      final sizeMb = (size / (1024 * 1024)).toStringAsFixed(1);
      _showSizeLimitDialog(fileName, sizeMb, mediaType);
      return;
    }

    final isFirst = _mediaItems.isEmpty;
    final item = _MediaItem(
      localFile: File(xfile.path),
      name: fileName,
      sizeBytes: size,
      mediaType: mediaType,
      isCover: isFirst,
      isUploading: true,
      uploadProgress: 0.1,
    );

    setState(() {
      _mediaItems.add(item);
    });

    try {
      final order = _mediaItems.length - 1;
      final response = await _sellerService.uploadPropertyMedia(
        widget.propertyId,
        filePath: xfile.path,
        mediaType: mediaType,
        displayOrder: order,
        isCover: item.isCover,
        onSendProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() {
              item.uploadProgress = sent / total;
            });
          }
        },
      );

      final mediaId =
          response['id']?.toString() ?? response['mediaId']?.toString();

      if (mounted) {
        setState(() {
          item.isUploading = false;
          item.uploadProgress = 1.0;
        });
      }

      // Reload list to get clean server IDs
      if (mediaId == null) {
        _refreshMedia();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          item.isUploading = false;
          item.error = e.toString();
        });
      }
      _showErrorSnackBar('Upload failed for $fileName: $e');
    }
  }

  Future<void> _refreshMedia() async {
    final list = await _sellerService.getPropertyMedia(widget.propertyId);
    if (!mounted) return;
    setState(() {
      _mediaItems.clear();
      for (final m in list) {
        final mediaId = m['id']?.toString() ?? m['mediaId']?.toString();
        final mediaType = (m['mediaType'] as num?)?.toInt() ?? 1;
        final isCover = m['isCover'] == true;
        final originalName = m['originalFileName']?.toString() ?? 'Media';
        final sizeBytes = (m['fileSizeBytes'] as num?)?.toInt() ?? 0;

        _mediaItems.add(
          _MediaItem(
            id: mediaId,
            name: originalName,
            sizeBytes: sizeBytes,
            mediaType: mediaType,
            isCover: isCover,
          ),
        );
      }
    });
  }

  Future<void> _deleteMedia(_MediaItem item) async {
    final id = item.id;
    setState(() {
      _mediaItems.remove(item);
    });

    if (id != null) {
      try {
        await _sellerService.deletePropertyMedia(widget.propertyId, id);
      } catch (e) {
        _showErrorSnackBar('Failed to remove media on server: $e');
      }
    }
  }

  void _setAsCover(_MediaItem item) {
    setState(() {
      for (final m in _mediaItems) {
        m.isCover = (m == item);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${item.name}" set as property cover photo.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSizeLimitDialog(String fileName, String sizeMb, int mediaType) {
    final typeName = mediaType == 2 ? 'Video' : 'Image';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Text('$typeName Too Large', style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File: $fileName',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Selected size: $sizeMb MB\nMaximum allowed size: 10 MB per file.',
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please compress or select a different image or video under 10 MB.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _finishListing() async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: primaryColor, size: 28),
            SizedBox(width: 10),
            Text('Listing Ready', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'You have completed all sections and media for this property. How would you like to proceed?',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'draft'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save as Draft', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, 'submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Submit Now', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    setState(() {
      _isFinalizing = true;
    });

    try {
      if (choice == 'submit') {
        await _sellerService.submitProperty(widget.propertyId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.send_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Property submitted for admin review successfully!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.deepPurple,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Property listing saved as draft.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to submit property: $e');
      setState(() {
        _isFinalizing = false;
      });
      return;
    }

    if (!mounted) return;

    // Auto-redirect to home / root screen
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final typeName = widget.propertyType ?? 'Property';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Property Media',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : Column(
                children: [
                  _buildProgress(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'Photos & Videos',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Upload high quality photos and videos. Max limit: 10 MB per file.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildPropertyTypeCard(typeName),
                          const SizedBox(height: 20),

                          // Media Upload Buttons
                          _buildUploadButtons(),
                          const SizedBox(height: 24),

                          // Uploaded Media Grid
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Uploaded Media (${_mediaItems.length})',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              if (_mediaItems.isNotEmpty)
                                const Text(
                                  'Tap ⭐ to set Cover',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_mediaItems.isEmpty)
                            _buildEmptyMediaState()
                          else
                            _buildMediaGrid(),

                          const SizedBox(height: 24),
                          _buildInfoCard(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        children: [
          _buildStepItem(number: '1', title: 'Basic', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '2', title: 'Features', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '3', title: 'Amenities', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '4', title: 'Financials', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '5', title: 'Legal', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '6', title: 'Docs', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '7', title: 'Media', isCompleted: false, isActive: true),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        color: isCompleted ? primaryColor : const Color(0xFFE5E7EB),
      ),
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    required bool isCompleted,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted ? primaryColor : Colors.grey.shade300,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    number,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : Colors.black45,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight:
                isActive || isCompleted ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyTypeCard(String propertyType) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.perm_media_outlined,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Step 7 of 7 • Photos & Media Gallery',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  propertyType,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.photo_library_outlined,
            title: 'Add Photos',
            subtitle: 'Gallery (Max 10MB)',
            onTap: () => _pickImages(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionCard(
            icon: Icons.camera_alt_outlined,
            title: 'Camera',
            subtitle: 'Snap photo',
            onTap: () => _pickImages(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionCard(
            icon: Icons.videocam_outlined,
            title: 'Add Video',
            subtitle: 'Max 10MB',
            onTap: () => _pickVideo(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMediaState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No media added yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Listings with 5+ photos receive 3x more buyer inquiries.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _mediaItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final item = _mediaItems[index];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isCover ? primaryColor : Colors.grey.shade200,
              width: item.isCover ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              children: [
                // Media preview or icon
                Positioned.fill(
                  child: item.localFile != null && item.mediaType == 1
                      ? Image.file(
                          item.localFile!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: Icon(
                              item.mediaType == 2
                                  ? Icons.videocam
                                  : Icons.image_outlined,
                              size: 42,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                ),

                // Top bar: Badges & Delete
                Positioned(
                  top: 6,
                  left: 6,
                  right: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Type / Cover badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isCover
                              ? primaryColor
                              : Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.isCover
                              ? '⭐ COVER'
                              : (item.mediaType == 2 ? 'VIDEO' : 'IMAGE'),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Delete button
                      InkWell(
                        onTap: () => _deleteMedia(item),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Uploading progress overlay
                if (item.isUploading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(item.uploadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Bottom bar: Size & Set Cover Action
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.sizeFormatted,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!item.isCover)
                          InkWell(
                            onTap: () => _setAsCover(item),
                            child: const Text(
                              'Set Cover',
                              style: TextStyle(
                                fontSize: 10,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: primaryColor, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Each image and video is capped at 10 MB. High-resolution horizontal landscape photos are recommended for maximum visibility.',
              style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isFinalizing
                    ? null
                    : () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyDocumentsScreen(
                                propertyId: widget.propertyId,
                                propertyType: widget.propertyType,
                              ),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.arrow_back, size: 15),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _isFinalizing
                    ? null
                    : () async {
                        await _sellerService.setDraftStep(widget.propertyId, 7);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Media & listing saved as draft.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  side: const BorderSide(color: primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Save & Exit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isFinalizing ? null : _finishListing,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isFinalizing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Complete Listing',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.done_all, size: 16),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
