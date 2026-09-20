import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_legal_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_review_screen.dart';


class PropertyMediaResult {
  final PropertyLegalDetailsResult legalData;
  final List<File> photos;
  final List<File> documents;

  const PropertyMediaResult({
    required this.legalData,
    required this.photos,
    required this.documents,
  });
}

class PropertyMediaScreen extends StatefulWidget {
  final PropertyLegalDetailsResult legalData;

  const PropertyMediaScreen({
    super.key,
    required this.legalData,
  });

  @override
  State<PropertyMediaScreen> createState() => _PropertyMediaScreenState();
}

class _PropertyMediaScreenState extends State<PropertyMediaScreen> {
  static const Color primaryColor = Color(0xFF00C6D4);

  final ImagePicker _picker = ImagePicker();

  final List<File> _photos = [];
  final List<File> _documents = [];

  Future<void> _addPhotos() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isEmpty || !mounted) {
        return;
      }

      setState(() {
        for (final image in images) {
          final file = File(image.path);

          if (!_photos.any((item) => item.path == file.path)) {
            _photos.add(file);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to select photos.',
        isError: true,
      );
    }
  }

  Future<void> _addCameraPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null || !mounted) {
        return;
      }

      final file = File(image.path);

      setState(() {
        _photos.add(file);
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to take photo.',
        isError: true,
      );
    }
  }

  Future<void> _addDocument() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (file == null || !mounted) {
        return;
      }

      setState(() {
        _documents.add(File(file.path));
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to select document.',
        isError: true,
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _removeDocument(int index) {
    setState(() {
      _documents.removeAt(index);
    });
  }

  void _setAsCover(int index) {
    if (index == 0) {
      return;
    }

    setState(() {
      final photo = _photos.removeAt(index);
      _photos.insert(0, photo);
    });
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : null,
      ),
    );
  }

 Future<void> _continue() async {
  if (_photos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please add at least one property photo.'),
      ),
    );
    return;
  }

  final result = PropertyMediaResult(
    legalData: widget.legalData,
    photos: _photos,
    documents: _documents,
  );

  final reviewResult =
      await Navigator.push<PropertyMediaResult>(
    context,
    MaterialPageRoute(
      builder: (_) => PropertyReviewScreen(
        mediaData: result,
      ),
    ),
  );

  if (reviewResult != null && mounted) {
    Navigator.pop(context, reviewResult);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Property Media',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    const Text(
                      'Add photos of your property',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Good quality photos help buyers understand your property better.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle(
                      'Property Photos',
                      Icons.photo_library_outlined,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Add at least one photo. The first photo will be used as the cover photo.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildPhotoSection(),

                    const SizedBox(height: 26),

                    _buildSectionTitle(
                      'Property Documents',
                      Icons.description_outlined,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'You can add relevant property documents for later review.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildDocumentsSection(),

                    const SizedBox(height: 24),

                    _buildTipsCard(),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Review Property',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    const steps = [
      'Type',
      'Basic',
      'Location',
      'Details',
      'Features',
      'Financial',
      'Legal',
      'Media',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        12,
        10,
        14,
      ),
      child: Row(
        children: List.generate(
          steps.length,
          (index) {
            final isActive = index == 7;
            final isCompleted = index < 7;

            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? primaryColor
                                : Colors.grey.shade300,
                          ),
                        ),

                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive || isCompleted
                              ? primaryColor
                              : Colors.grey.shade200,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ),
                        ),
                      ),

                      if (index < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index < 7
                                ? primaryColor
                                : Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    steps[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isActive
                          ? primaryColor
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    if (_photos.isEmpty) {
      return _buildEmptyPhotoState();
    }

    return Column(
      children: [
        _buildCoverPhoto(),

        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _photos.length > 1
              ? _photos.length - 1
              : 0,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final actualIndex = index + 1;

            return _buildPhotoTile(
              actualIndex,
            );
          },
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addPhotos,
                icon: const Icon(
                  Icons.photo_library_outlined,
                ),
                label: const Text('Add Photos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(
                    color: primaryColor,
                  ),
                  minimumSize: const Size(
                    double.infinity,
                    48,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 48,
              child: OutlinedButton(
                onPressed: _addCameraPhoto,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(
                    color: primaryColor,
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyPhotoState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              size: 34,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'No photos added yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Add photos from your gallery or take new photos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _addPhotos,
                icon: const Icon(
                  Icons.photo_library_outlined,
                ),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(
                    color: primaryColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              OutlinedButton.icon(
                onPressed: _addCameraPhoto,
                icon: const Icon(
                  Icons.camera_alt_outlined,
                ),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(
                    color: primaryColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPhoto() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.file(
              _photos.first,
              fit: BoxFit.cover,
            ),
          ),
        ),

        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: 15,
                  color: Colors.white,
                ),
                SizedBox(width: 5),
                Text(
                  'Cover Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 10,
          right: 10,
          child: _buildDeleteButton(
            onPressed: () => _removePhoto(0),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoTile(int index) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _photos[index],
              fit: BoxFit.cover,
            ),
          ),
        ),

        Positioned(
          top: 6,
          right: 6,
          child: _buildDeleteButton(
            small: true,
            onPressed: () => _removePhoto(index),
          ),
        ),

        Positioned(
          left: 6,
          right: 6,
          bottom: 6,
          child: GestureDetector(
            onTap: () => _setAsCover(index),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Set Cover',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton({
    required VoidCallback onPressed,
    bool small = false,
  }) {
    final size = small ? 28.0 : 34.0;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: small ? 16 : 19,
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      children: [
        if (_documents.isEmpty)
          _buildEmptyDocuments()
        else
          ...List.generate(
            _documents.length,
            (index) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: _buildDocumentTile(index),
              );
            },
          ),

        const SizedBox(height: 4),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _addDocument,
            icon: const Icon(
              Icons.upload_file_outlined,
            ),
            label: const Text(
              'Add Document',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(
                color: primaryColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDocuments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: primaryColor,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'No documents added',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Documents are optional at this stage.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(int index) {
    final file = _documents[index];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              color: primaryColor,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              file.path.split(Platform.pathSeparator).last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          IconButton(
            onPressed: () => _removeDocument(index),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: primaryColor.withOpacity(0.15),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: primaryColor,
            size: 21,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tip: Include photos of the exterior, living areas, bedrooms, kitchen, bathrooms, garden, parking area and surrounding views.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}