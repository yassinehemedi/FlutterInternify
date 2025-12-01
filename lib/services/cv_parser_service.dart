import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../database/db_helper.dart';
import '../models/parsed_cv.dart';
import 'package:pdfx/pdfx.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CvParserService {
  CvParserService._();
  static final CvParserService instance = CvParserService._();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Groq API key and base URL
  static const String _groqKey = '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';
  static const String _groqBase = String.fromEnvironment('GROQ_API_BASE', defaultValue: 'https://api.groq.com/openai/v1'); // ← Fixed URL

  /// Parse resume text using Groq API
  Future<Map<String, dynamic>?> parseTextWithGroq(String text) async {
    if (_groqKey.isEmpty) throw Exception('GROQ_API_KEY is not provided. Use --dart-define=GROQ_API_KEY=...');

    final prompt = '''You are a resume parsing assistant. Respond ONLY with a JSON object exactly matching the schema described.
{
  "contact": { "emails": [], "phones": [], "name": "" },
  "technical_skills": [],
  "non_technical_skills": [],
  "education": [],
  "experience_summary": "",
  "confidence": { "emails": "low|medium|high", "skills": "low|medium|high" },
  "raw_extracted_text_snippet": ""
}

Parse the following resume text and fill the fields. Keep outputs concise. If you can't find a field, use empty array or empty string. Provide only JSON.

Resume text:
"""
${text.substring(0, text.length > 15000 ? 15000 : text.length)}
"""
''';

    final uri = Uri.parse('$_groqBase/chat/completions');
    final body = jsonEncode({
      'model': 'llama-3.3-70b-versatile',  // or 'mixtral-8x7b-32768',
      'messages': [
        {'role': 'system', 'content': 'You are a strict JSON generator; output only JSON.'},
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.0,
      'max_tokens': 800,
    });

    final resp = await http.post(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_groqKey',
    }, body: body);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Groq API error ${resp.statusCode}: ${resp.body}');
    }

    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    String? assistant;
    assistant = map['choices']?[0]?['message']?['content'] as String?;
    assistant ??= (map['choices'] is List && map['choices'].isNotEmpty && map['choices'][0]['text'] != null)
        ? map['choices'][0]['text'] as String?
        : null;
    assistant ??= (map['output'] is List && map['output'].isNotEmpty && map['output'][0]['content'] != null)
        ? map['output'][0]['content'] as String?
        : null;
    assistant ??= map['output'] is String ? map['output'] as String? : null;

    if (assistant == null) throw Exception('groq_no_content: provider returned no content');

    try {
      return jsonDecode(assistant) as Map<String, dynamic>;
    } catch (e) {
      final start = assistant.indexOf('{');
      final end = assistant.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final sub = assistant.substring(start, end + 1);
        try {
          return jsonDecode(sub) as Map<String, dynamic>;
        } catch (_) {}
      }
      final preview = assistant.length > 500 ? '${assistant.substring(0, 500)}... (truncated)' : assistant;
      throw Exception('groq_invalid_json: provider returned non-JSON output. Preview: $preview');
    }
  }

  Future<String> _extractTextFromPdf(String path) async {
    try {
      final doc = await PdfDocument.openFile(path);
      final buffer = StringBuffer();
      for (int i = 1; i <= doc.pagesCount; i++) {
        final page = await doc.getPage(i);
        String pageText = '';
        try {
          pageText = await (page as dynamic).text;
        } catch (_) {
          try {
            pageText = await (page as dynamic).getText();
          } catch (_) {
            try {
              pageText = await (page as dynamic).textContent;
            } catch (_) {
              pageText = '';
            }
          }
        }
        if (pageText.isNotEmpty) buffer.writeln(pageText);
        try { await page.close(); } catch (_) {}
      }
      try { await doc.close(); } catch (_) {}
      return buffer.toString().trim();
    } catch (e) {
      print('PDF extraction failed: $e');
      return '';
    }
  }

  Future<String> extractTextFromFile(String path) async {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      try {
        final uri = Uri.parse(path);
        final resp = await http.get(uri);
        if (resp.statusCode == 200) {
          final bytes = resp.bodyBytes;
          final tmpDir = Directory.systemTemp;
          final ext = p.extension(uri.path).isNotEmpty ? p.extension(uri.path) : '.bin';
          final tmpFile = File('${tmpDir.path}/resume_${DateTime.now().millisecondsSinceEpoch}$ext');
          await tmpFile.writeAsBytes(bytes);
          final text = await extractTextFromFile(tmpFile.path);
          try { await tmpFile.delete(); } catch (_) {}
          return text;
        }
      } catch (_) {}
    }

    if (path.toLowerCase().endsWith('.pdf')) {
      try {
        return await _extractTextFromPdf(path);
      } catch (_) {
        try { return await File(path).readAsString(); } catch (_) { return ''; }
      }
    } else if (path.toLowerCase().endsWith('.txt')) {
      return await File(path).readAsString();
    } else {
      try { return await File(path).readAsString(); } catch (_) { return ''; }
    }
  }

  Future<ParsedCv?> parseCvFileAndSave({required int demandId, required String filePath, int? parsedBy}) async {
    String text = await extractTextFromFile(filePath);
    if (text.isEmpty) {
      final img = await renderFirstPageAsImage(filePath);
      if (img != null && img.isNotEmpty) {
        final ocr = await _ocrImageBytes(img);
        if (ocr.isNotEmpty) text = ocr;
      }
    }
    if (text.isEmpty) throw Exception('extract_failed: could not extract text from file.');
    return await parseAndSaveFromText(demandId: demandId, text: text, parsedBy: parsedBy);
  }

  Future<ParsedCv?> parseAndSaveFromText({required int demandId, required String text, int? parsedBy}) async {
    final parsed = await parseTextWithGroq(text);
    if (parsed == null) throw Exception('parsing_failed: Groq returned no structured result');

    final contactEmails = (parsed['contact']?['emails'] as List?)?.map((e) => e.toString()).toList();
    final contactPhones = (parsed['contact']?['phones'] as List?)?.map((e) => e.toString()).toList();
    final tech = (parsed['technical_skills'] as List?)?.map((e) => e.toString()).toList();
    final nonTech = (parsed['non_technical_skills'] as List?)?.map((e) => e.toString()).toList();
    final summary = parsed['experience_summary'] as String?;

    final parsedCv = ParsedCv(
      demandId: demandId,
      parsedJson: parsed,
      contactEmail: contactEmails?.isNotEmpty == true ? contactEmails!.first : null,
      contactPhone: contactPhones?.isNotEmpty == true ? contactPhones!.first : null,
      technicalSkills: tech,
      nonTechnicalSkills: nonTech,
      summary: summary,
      parsedBy: parsedBy,
    );

    final db = await _dbHelper.database;
    await db.insert('parsed_cvs', parsedCv.toMap());
    return parsedCv;
  }

  Future<Uint8List?> renderFirstPageAsImage(String path, {int width = 1200}) async {
    try {
      final doc = await PdfDocument.openFile(path);
      if (doc.pagesCount < 1) { try { await doc.close(); } catch (_) {} return null; }
      final page = await doc.getPage(1);
      dynamic img;
      try { img = await (page as dynamic).render(width: width); } catch (_) { img = null; }
      if (img != null) {
        final bytes = (img as dynamic).bytes as Uint8List?;
        try { await page.close(); } catch (_) {}
        try { await doc.close(); } catch (_) {}
        return bytes;
      }
      try { await page.close(); } catch (_) {}
      try { await doc.close(); } catch (_) {}
      return null;
    } catch (_) { return null; }
  }

  Future<String> _ocrImageBytes(Uint8List imgBytes) async {
    final tmpDir = Directory.systemTemp;
    final tmpFile = File('${tmpDir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.png');
    await tmpFile.writeAsBytes(imgBytes);
    final inputImage = InputImage.fromFilePath(tmpFile.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await textRecognizer.processImage(inputImage);
      final extracted = result.text;
      try { await tmpFile.delete(); } catch (_) {}
      await textRecognizer.close();
      return extracted;
    } catch (_) {
      try { await tmpFile.delete(); } catch (_) {}
      await textRecognizer.close();
      return '';
    }
  }
}
