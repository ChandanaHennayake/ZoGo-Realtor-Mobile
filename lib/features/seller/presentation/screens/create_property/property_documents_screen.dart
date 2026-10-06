import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/seller/data/services/seller_service.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_media_screen.dart';

class PropertyDocumentType {
  final int id;
  final String name;
  final String description;
  final IconData icon;

  const PropertyDocumentType({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

const List<PropertyDocumentType> kPropertyDocumentTypes = [
  PropertyDocumentType(
    id: 1,
    name: 'Title Deed / Deed of Transfer',
    description: 'Primary legal proof of ownership registered with land registry',
    icon: Icons.description_outlined,
  ),
  PropertyDocumentType(
    id: 2,
    name: 'Survey Plan / Cadastral Map',
    description: 'Boundary demarcations and land extent by a licensed surveyor',
    icon: Icons.map_outlined,
  ),
  PropertyDocumentType(
    id: 3,
    name: 'Building Plan Approval',
    description: 'Local Municipal / Council approved building architectural plans',
    icon: Icons.architecture_outlined,
  ),
  PropertyDocumentType(
    id: 4,
    name: 'Certificate of Conformity (COC)',
    description: 'Local authority completion and compliance certificate',
    icon: Icons.verified_outlined,
  ),
  PropertyDocumentType(
    id: 5,
    name: 'Non-Vesting / Street Line Certificate',
    description: 'Clearance verifying property is free from road widening reservations',
    icon: Icons.alt_route_outlined,
  ),
  PropertyDocumentType(
    id: 6,
    name: 'Tax & Rates Assessment Receipts',
    description: 'Municipal council assessment receipts and paid tax records',
    icon: Icons.receipt_long_outlined,
  ),
  PropertyDocumentType(
    id: 7,
    name: 'Power of Attorney',
    description: 'Registered Power of Attorney if signing on behalf of an owner',
    icon: Icons.assignment_ind_outlined,
  ),
  PropertyDocumentType(
    id: 8,
    name: 'Other Supporting Document',
    description: 'Valuation report, NIC copy, condominium declaration, etc.',
    icon: Icons.folder_open_outlined,
  ),
];

class PropertyDocumentsScreen extends StatefulWidget {
  final String propertyId;
  final String? propertyType;

  const PropertyDocumentsScreen({
    super.key,
    required this.propertyId,
    this.propertyType,
  });

  @override
  State<PropertyDocumentsScreen> createState() => _PropertyDocumentsScreenState();
}

class _PropertyDocumentsScreenState extends State<PropertyDocumentsScreen> {
  static const Color primaryColor = Color(0xFF00C6D4);
  static const int maxFileSizeBytes = 15 * 1024 * 1024; // 15 MB limit

  final SellerService _sellerService = SellerService();

  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadStatusText;
  int _selectedTypeId = 1;

  File? _selectedFile;
  String? _selectedFileName;
  int _selectedFileSize = 0;

  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docs = await _sellerService.getPropertyDocuments(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load documents: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _pickDocument() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (files.isNotEmpty) {
        final path = files.first.path;
        if (path == null) return;

        final file = File(path);
        final size = await file.length();

        if (size > maxFileSizeBytes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('File size exceeds the 15 MB limit. Please select a smaller file.'),
              backgroundColor: Colors.red.shade700,
            ),
          );
          return;
        }

        setState(() {
          _selectedFile = file;
          _selectedFileName = files.first.name;
          _selectedFileSize = size;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _uploadSelectedDocument() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a file to upload first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatusText = 'Starting upload...';
    });

    try {
      await _sellerService.uploadPropertyDocument(
        propertyId: widget.propertyId,
        file: _selectedFile!,
        documentTypeId: _selectedTypeId,
        onSendProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() {
              _uploadProgress = sent / total;
              final percent = (_uploadProgress * 100).toInt();
              _uploadStatusText = 'Uploading $percent%...';
            });
          }
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedFile = null;
        _selectedFileName = null;
        _selectedFileSize = 0;
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadStatusText = null;
      });

      await _loadDocuments();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadStatusText = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _confirmDeleteDocument(Map<String, dynamic> doc) async {
    final docId = doc['id']?.toString() ?? '';
    final fileName = doc['originalFileName']?.toString() ?? 'Document';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "$fileName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _sellerService.deletePropertyDocument(widget.propertyId, docId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadDocuments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete document: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _downloadOrViewDocument(Map<String, dynamic> doc) async {
    final docId = doc['id']?.toString() ?? '';
    final fileName = doc['originalFileName']?.toString() ?? 'document';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "$fileName"...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final bytes = await _sellerService.downloadPropertyDocument(
        widget.propertyId,
        docId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded "$fileName" (${(bytes.length / 1024).toStringAsFixed(1)} KB) successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _proceedToMedia() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyMediaScreen(
          propertyId: widget.propertyId,
          propertyType: widget.propertyType,
        ),
      ),
    );
  }

  String _formatFileSize(dynamic bytes) {
    if (bytes == null) return 'Unknown size';
    final num b = bytes is num ? bytes : num.tryParse(bytes.toString()) ?? 0;
    if (b <= 0) return '0 KB';
    final mb = b / (1024 * 1024);
    if (mb >= 1.0) {
      return '${mb.toStringAsFixed(1)} MB';
    }
    final kb = b / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }

  PropertyDocumentType _getTypeInfo(int typeId) {
    return kPropertyDocumentTypes.firstWhere(
      (t) => t.id == typeId,
      orElse: () => PropertyDocumentType(
        id: typeId,
        name: 'Document #$typeId',
        description: 'Property verification document',
        icon: Icons.insert_drive_file_outlined,
      ),
    );
  }

  Widget _buildStatusBadge(dynamic status, String? statusName) {
    Color bg;
    Color fg;
    String label;

    final s = status is num ? status.toInt() : 1;
    switch (s) {
      case 2:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'Under Review';
        break;
      case 3:
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'Verified';
        break;
      case 4:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'Rejected';
        break;
      case 1:
      default:
        bg = const Color(0xFFE0F7FA);
        fg = const Color(0xFF00838F);
        label = statusName?.isNotEmpty == true ? statusName! : 'Uploaded';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeName = widget.propertyType ?? 'Property';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Property Documents',
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
                            'Legal & Official Documents',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Upload Title Deed, Survey Plan, and municipal approvals. Verified documents boost buyer confidence and streamline closing.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildPropertyTypeCard(typeName),
                          const SizedBox(height: 24),

                          // Uploader Section
                          _buildUploadCard(),
                          const SizedBox(height: 28),

                          // List of Uploaded Documents
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Uploaded Documents (${_documents.length})',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              if (_documents.isNotEmpty)
                                Text(
                                  'Tap item to download',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_documents.isEmpty)
                            _buildEmptyDocumentsCard()
                          else
                            ..._documents.map(_buildDocumentItem),

                          const SizedBox(height: 20),
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
          _buildStepItem(number: '6', title: 'Documents', isCompleted: false, isActive: true),
          _buildStepLine(false),
          _buildStepItem(number: '7', title: 'Media', isCompleted: false, isActive: false),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 2),
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
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted ? primaryColor : Colors.grey.shade300,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 13, color: Colors.white)
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
            fontSize: 9.5,
            fontWeight: isActive || isCompleted ? FontWeight.w700 : FontWeight.w500,
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
              Icons.folder_shared_outlined,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property ID: ${widget.propertyId.length > 12 ? '${widget.propertyId.substring(0, 12)}...' : widget.propertyId}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
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

  Widget _buildUploadCard() {
    final selectedType = _getTypeInfo(_selectedTypeId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.upload_file_outlined, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Upload New Document',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Document Type Selector
          const Text(
            'Document Type *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedTypeId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: primaryColor),
                items: kPropertyDocumentTypes.map((type) {
                  return DropdownMenuItem<int>(
                    value: type.id,
                    child: Row(
                      children: [
                        Icon(type.icon, size: 18, color: primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            type.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _isUploading
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTypeId = val;
                          });
                        }
                      },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            selectedType.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // File Picker / Chosen File Container
          InkWell(
            onTap: _isUploading ? null : _pickDocument,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedFile != null
                    ? primaryColor.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedFile != null
                      ? primaryColor
                      : Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
              ),
              child: _selectedFile == null
                  ? Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 36,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Choose PDF, Image or Document',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supported: .pdf, .jpg, .png, .docx (Max 15MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.insert_drive_file,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFileName ?? 'Selected File',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatFileSize(_selectedFileSize),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _isUploading
                              ? null
                              : () {
                                  setState(() {
                                    _selectedFile = null;
                                    _selectedFileName = null;
                                    _selectedFileSize = 0;
                                  });
                                },
                          icon: const Icon(Icons.close, color: Colors.grey),
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
            ),
          ),

          if (_isUploading) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            const SizedBox(height: 6),
            Text(
              _uploadStatusText ?? 'Uploading...',
              style: const TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600),
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: (_isUploading || _selectedFile == null)
                  ? null
                  : _uploadSelectedDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.upload, size: 18),
              label: Text(
                _isUploading ? 'Uploading...' : 'Upload Document',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDocumentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No documents uploaded yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload Title Deed or Survey Plan above to strengthen listing legitimacy.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> doc) {
    final typeId = (doc['documentTypeId'] as num?)?.toInt() ?? 1;
    final typeInfo = _getTypeInfo(typeId);
    final fileName = doc['originalFileName']?.toString() ?? 'Document';
    final fileSize = _formatFileSize(doc['fileSizeBytes']);
    final status = doc['status'];
    final statusName = doc['statusName']?.toString();
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    final isImage = fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isPdf
                ? Colors.red.shade50
                : isImage
                    ? Colors.teal.shade50
                    : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isPdf
                ? Icons.picture_as_pdf_outlined
                : isImage
                    ? Icons.image_outlined
                    : Icons.description_outlined,
            color: isPdf
                ? Colors.red.shade700
                : isImage
                    ? Colors.teal.shade700
                    : Colors.blue.shade700,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                typeInfo.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _buildStatusBadge(status, statusName),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                fileSize,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download_outlined, color: primaryColor),
              tooltip: 'Download',
              onPressed: () => _downloadOrViewDocument(doc),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              tooltip: 'Delete',
              onPressed: () => _confirmDeleteDocument(doc),
            ),
          ],
        ),
      ),
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
          Icon(Icons.shield_outlined, color: primaryColor, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Documents are kept secure and confidential. Buyers only see verification badges and verified extracts once authorized by you.',
              style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
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
            flex: 1,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context, true);
                  }
                },
                style: OutlinedButton.styleFrom(
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _proceedToMedia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Next: Media',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
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
