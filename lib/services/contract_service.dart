import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'dart:ui' as ui;
import '../models/contract_model.dart';
import '../database/db_helper.dart';
import 'dart:ui';
import 'contract_email_service.dart';  // ✅ ADD THIS IMPORT
import 'package:shared_preferences/shared_preferences.dart';  // ✅ ADD THIS IMPORT


class ContractService {
  static final ContractService instance = ContractService._init();
  ContractService._init();

  // ==================== CREATE CONTRACT ====================

  /// Create a new contract with watermarked PDF
  Future<int> createContract(Contract contract) async {
    final db = await DatabaseHelper.instance.database;

    // Validate dates
    DateTime start = DateTime.parse(contract.startDate);
    DateTime end = DateTime.parse(contract.endDate);

    if (end.isBefore(start)) {
      throw Exception('End date cannot be before start date');
    }

    // Create watermarked PDF from the uploaded file
    final watermarkedPath = await _addWatermarkToPDF(
      contract.pdfPath,
      contract.title ?? 'Contract',
    );

    // Update contract with watermarked PDF path
    final contractWithWatermark = contract.copyWith(pdfPath: watermarkedPath);

    // Insert contract into database
    final contractId = await db.insert('contracts', contractWithWatermark.toMap());

    // ✅ NEW: Send email notification
    try {
      // Get creator information from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final userRole = prefs.getString('userRole') ?? 'unknown';

      // Get creator name from database
      String creatorName = 'Unknown User';
      if (userId != null) {
        final userResult = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [userId],
        );

        if (userResult.isNotEmpty) {
          creatorName = userResult.first['name'] as String;
        }
      }

      // Send notification email
      final emailSent = await ContractEmailService.sendNewContractNotification(
        contract: contractWithWatermark.copyWith(id: contractId),
        creatorName: creatorName,
        creatorRole: userRole,
      );

      if (emailSent) {
        print('✅ Contract creation notification sent successfully');
      } else {
        print('⚠️ Failed to send contract creation notification');
      }
    } catch (e) {
      print('❌ Error sending contract notification: $e');
      // Don't throw error - contract creation should succeed even if email fails
    }

    return contractId;
  }

  // ==================== READ CONTRACTS ====================

  /// Get all contracts
  Future<List<Contract>> getAllContracts() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('contracts', orderBy: 'id DESC');
    return result.map((map) => Contract.fromMap(map)).toList();
  }

  /// Get contract by ID
  Future<Contract?> getContractById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'contracts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Contract.fromMap(result.first);
    }
    return null;
  }

  /// Get contracts by job seeker ID
  Future<List<Contract>> getContractsByJobSeeker(int jobSeekerId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'contracts',
      where: 'jobSeekerId = ?',
      whereArgs: [jobSeekerId],
      orderBy: 'id DESC',
    );
    return result.map((map) => Contract.fromMap(map)).toList();
  }

  /// Get contracts by enterprise ID
  Future<List<Contract>> getContractsByEnterprise(int enterpriseId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'contracts',
      where: 'enterpriseId = ?',
      whereArgs: [enterpriseId],
      orderBy: 'id DESC',
    );
    return result.map((map) => Contract.fromMap(map)).toList();
  }

  /// Get contracts by status
  Future<List<Contract>> getContractsByStatus(String status) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'contracts',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'id DESC',
    );
    return result.map((map) => Contract.fromMap(map)).toList();
  }

  // ==================== UPDATE CONTRACT ====================

  /// Update an existing contract
  Future<int> updateContract(Contract contract) async {
    final db = await DatabaseHelper.instance.database;

    // Validate dates if they're being updated
    DateTime start = DateTime.parse(contract.startDate);
    DateTime end = DateTime.parse(contract.endDate);

    if (end.isBefore(start)) {
      throw Exception('End date cannot be before start date');
    }

    return await db.update(
      'contracts',
      contract.toMap(),
      where: 'id = ?',
      whereArgs: [contract.id],
    );
  }

  /// Update contract status
  Future<int> updateContractStatus(int id, String status) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'contracts',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== SIGN CONTRACT ====================

  /// Sign a contract and update status to 'Signed'
  Future<void> signContract(int contractId, String signaturePath) async {
    final db = await DatabaseHelper.instance.database;

    // Update contract with signature path and change status to Signed
    await db.update(
      'contracts',
      {
        'signaturePath': signaturePath,
        'status': 'Signed',
      },
      where: 'id = ?',
      whereArgs: [contractId],
    );
  }

  // ==================== DELETE CONTRACT ====================

  /// Delete a contract by ID
  Future<int> deleteContract(int id) async {
    final db = await DatabaseHelper.instance.database;

    // Get contract to delete PDF file
    final contract = await getContractById(id);
    if (contract != null) {
      try {
        final file = File(contract.pdfPath);
        if (await file.exists()) {
          await file.delete();
        }

        // Delete signature file if exists
        if (contract.signaturePath != null) {
          final sigFile = File(contract.signaturePath!);
          if (await sigFile.exists()) {
            await sigFile.delete();
          }
        }
      } catch (e) {
        print('Error deleting files: $e');
      }
    }

    return await db.delete(
      'contracts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== PDF WATERMARK ====================

  /// Add watermark to existing PDF file
  Future<String> _addWatermarkToPDF(String originalPdfPath, String title) async {
    try {
      // Read the original PDF
      final originalFile = File(originalPdfPath);
      final pdfBytes = await originalFile.readAsBytes();

      // Load the existing PDF using Syncfusion
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: pdfBytes);

      // Get font for watermark
      final sf.PdfFont font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 28);

      // Process each page
      for (int i = 0; i < document.pages.count; i++) {
        final sf.PdfPage page = document.pages[i];
        final sf.PdfGraphics graphics = page.graphics;

        // Get page dimensions
        final double pageWidth = page.getClientSize().width;
        final double pageHeight = page.getClientSize().height;

        // Save graphics state
        graphics.save();

        // Calculate number of watermarks based on page size
        final int horizontalCount = (pageWidth / 150).ceil();
        final int verticalCount = (pageHeight / 120).ceil();

        // Add watermarks in a grid pattern
        for (int x = 0; x < horizontalCount; x++) {
          for (int y = 0; y < verticalCount; y++) {
            final double posX = x * (pageWidth / horizontalCount);
            final double posY = y * (pageHeight / verticalCount);

            // Save state before rotation
            graphics.save();

            // Translate to position and rotate
            graphics.translateTransform(posX, posY);
            graphics.rotateTransform(-30); // -30 degrees

            // Draw watermark with transparency
            graphics.setTransparency(0.15);
            graphics.drawString(
              'CONFIDENTIAL',
              font,
              brush: sf.PdfSolidBrush(sf.PdfColor(128, 128, 128)),
            );

            // Restore state after rotation
            graphics.restore();
          }
        }

        // Restore graphics state
        graphics.restore();
      }

      // Save watermarked PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'contract_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      // Save the document
      final List<int> bytes = await document.save();
      await file.writeAsBytes(bytes);

      // Dispose the document
      document.dispose();

      return file.path;
    } catch (e) {
      print('Error adding watermark: $e');
      // If watermarking fails, copy original to app directory
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'contract_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final newPath = '${directory.path}/$fileName';
        await File(originalPdfPath).copy(newPath);
        return newPath;
      } catch (copyError) {
        print('Error copying file: $copyError');
        return originalPdfPath;
      }
    }
  }

  // ==================== ADD SIGNATURE TO PDF ====================

  /// Add signature image to PDF at bottom right
  Future<String> _addSignatureToPDF(String pdfPath, String signaturePath) async {
    try {
      // Read the original PDF
      final pdfFile = File(pdfPath);
      final pdfBytes = await pdfFile.readAsBytes();

      // Load the PDF using Syncfusion
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: pdfBytes);

      // Read signature image
      final signatureFile = File(signaturePath);
      final signatureBytes = await signatureFile.readAsBytes();

      // Get the last page
      final sf.PdfPage lastPage = document.pages[document.pages.count - 1];
      final sf.PdfGraphics graphics = lastPage.graphics;

      // Get page dimensions
      final double pageWidth = lastPage.getClientSize().width;
      final double pageHeight = lastPage.getClientSize().height;

      // Load signature image
      final sf.PdfBitmap signatureImage = sf.PdfBitmap(signatureBytes);

      // Define signature dimensions and position (bottom right)
      final double signatureWidth = 150;
      final double signatureHeight = 75;
      final double margin = 20;
      final double xPos = pageWidth - signatureWidth - margin;
      final double yPos = pageHeight - signatureHeight - margin;

      // Draw signature image
      graphics.drawImage(
        signatureImage,
        Rect.fromLTWH(xPos, yPos, signatureWidth, signatureHeight),
      );

      // Add "Signed on:" text above signature
      final sf.PdfFont font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 10);
      final String dateText = 'Signed on: ${DateTime.now().toString().split(' ')[0]}';
      graphics.drawString(
        dateText,
        font,
        bounds: Rect.fromLTWH(xPos, yPos - 20, signatureWidth, 20),
        brush: sf.PdfSolidBrush(sf.PdfColor(0, 0, 0)),
      );

      // Save the signed PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'signed_contract_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      // Save the document
      final List<int> bytes = await document.save();
      await file.writeAsBytes(bytes);

      // Dispose the document
      document.dispose();

      // Delete old unsigned PDF
      try {
        await pdfFile.delete();
      } catch (e) {
        print('Error deleting old PDF: $e');
      }

      return file.path;
    } catch (e) {
      print('Error adding signature to PDF: $e');
      rethrow;
    }
  }

  // ==================== DOWNLOAD CONTRACT ====================

  /// Copy contract PDF to downloads folder (with signature if available)
  Future<String> downloadContract(int contractId) async {
    final contract = await getContractById(contractId);
    if (contract == null) {
      throw Exception('Contract not found');
    }

    String pdfPath = contract.pdfPath;

    // If contract is signed, add signature to PDF before downloading
    if (contract.signaturePath != null && contract.status == 'Signed') {
      try {
        pdfPath = await _addSignatureToPDF(contract.pdfPath, contract.signaturePath!);

        // Update contract with new signed PDF path
        await updateContract(contract.copyWith(pdfPath: pdfPath));
      } catch (e) {
        print('Error adding signature to download: $e');
        // Continue with original PDF if signature addition fails
      }
    }

    final sourceFile = File(pdfPath);
    if (!await sourceFile.exists()) {
      throw Exception('Contract file not found');
    }

    // Get downloads directory (Android specific)
    Directory directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        // Fallback to app documents directory
        directory = await getApplicationDocumentsDirectory();
      }
    } else {
      // For iOS and other platforms
      directory = await getApplicationDocumentsDirectory();
    }

    final fileName = 'contract_${contract.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final destinationPath = '${directory.path}/$fileName';

    await sourceFile.copy(destinationPath);
    return destinationPath;
  }
}