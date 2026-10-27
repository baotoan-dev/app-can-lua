import 'dart:convert';
import 'dart:typed_data';
import 'package:printing/printing.dart';

/// Cross-platform utility for exporting, sharing and downloading data files
/// (PDF, JSON, CSV) on Web, Mobile (Android/iOS), and Desktop.
class FileShareHelper {
  FileShareHelper._();

  /// Shares or downloads a string content with the given filename and optional mime type.
  static Future<void> shareTextFile({
    required String content,
    required String filename,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    await shareBinaryFile(bytes: bytes, filename: filename);
  }

  /// Shares or downloads binary bytes with the given filename.
  static Future<void> shareBinaryFile({
    required Uint8List bytes,
    required String filename,
  }) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
    );
  }
}
