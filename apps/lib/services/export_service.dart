import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show XFile, SharePlus, ShareParams;
import '../models/program.dart';

/// Service for exporting and printing saved programs
class ExportService {
  /// Export programs to CSV format
  static Future<String?> exportToCsv(List<Program> programs) async {
    if (programs.isEmpty) return null;

    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('Name,Category,Description,Eligibility,Areas,Website,Phone,Email,Address,Cost,Last Updated');

    // CSV Rows
    for (final program in programs) {
      buffer.writeln([
        _escapeCsv(program.name),
        _escapeCsv(program.category),
        _escapeCsv(program.description),
        _escapeCsv(program.eligibility.join('; ')),
        _escapeCsv(program.areas.join('; ')),
        _escapeCsv(program.website),
        _escapeCsv(program.phone ?? ''),
        _escapeCsv(program.email ?? ''),
        _escapeCsv(program.address ?? ''),
        _escapeCsv(program.cost ?? ''),
        _escapeCsv(program.lastUpdated),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Save CSV to file and share/save
  static Future<bool> saveAndShareCsv(
    List<Program> programs,
    BuildContext context,
  ) async {
    final csv = await exportToCsv(programs);
    if (csv == null) return false;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${directory.path}/bay_area_discounts_$timestamp.csv');
      await file.writeAsString(csv);

      // On desktop, use share_plus to save/share
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Bay Navigator - Saved Programs Export',
          ),
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Copy program info to clipboard
  static Future<void> copyToClipboard(Program program) async {
    final buffer = StringBuffer();
    buffer.writeln(program.name);
    buffer.writeln('Category: ${program.category}');
    buffer.writeln();
    buffer.writeln(program.description);
    buffer.writeln();

    if (program.eligibility.isNotEmpty) {
      buffer.writeln('Eligibility: ${program.eligibility.join(', ')}');
    }
    if (program.areas.isNotEmpty) {
      buffer.writeln('Areas: ${program.areas.join(', ')}');
    }
    if (program.website.isNotEmpty) {
      buffer.writeln('Website: ${program.website}');
    }
    if (program.phone != null && program.phone!.isNotEmpty) {
      buffer.writeln('Phone: ${program.phone}');
    }
    if (program.email != null && program.email!.isNotEmpty) {
      buffer.writeln('Email: ${program.email}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  /// Copy all saved programs summary to clipboard
  static Future<void> copyAllToClipboard(List<Program> programs) async {
    if (programs.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('Bay Navigator - Saved Programs');
    buffer.writeln('=' * 40);
    buffer.writeln();

    for (final program in programs) {
      buffer.writeln(program.name);
      buffer.writeln('  Category: ${program.category}');
      buffer.writeln('  ${program.description}');
      if (program.website.isNotEmpty) {
        buffer.writeln('  Website: ${program.website}');
      }
      buffer.writeln();
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  /// Generate printable HTML
  static String generatePrintableHtml(List<Program> programs) {
    final buffer = StringBuffer();

    buffer.writeln('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Bay Navigator - Saved Programs</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
      color: #1e293b;
    }
    h1 {
      color: #0d9488;
      border-bottom: 2px solid #0d9488;
      padding-bottom: 10px;
    }
    .program {
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 16px;
      margin-bottom: 16px;
      page-break-inside: avoid;
    }
    .program-name {
      font-size: 18px;
      font-weight: 600;
      color: #0f172a;
      margin-bottom: 4px;
    }
    .category {
      display: inline-block;
      background: #0d9488;
      color: white;
      padding: 2px 8px;
      border-radius: 4px;
      font-size: 12px;
      text-transform: uppercase;
      margin-bottom: 8px;
    }
    .description {
      color: #475569;
      margin-bottom: 12px;
    }
    .detail {
      font-size: 14px;
      color: #64748b;
      margin-bottom: 4px;
    }
    .detail strong {
      color: #334155;
    }
    .eligibility {
      display: flex;
      flex-wrap: wrap;
      gap: 4px;
      margin-top: 8px;
    }
    .eligibility span {
      background: #f1f5f9;
      padding: 2px 6px;
      border-radius: 4px;
      font-size: 12px;
    }
    .footer {
      margin-top: 30px;
      text-align: center;
      color: #94a3b8;
      font-size: 12px;
    }
    @media print {
      body { padding: 0; }
      .program { border: 1px solid #ccc; }
    }
  </style>
</head>
<body>
  <h1>Bay Navigator</h1>
  <p style="color: #64748b;">Saved Programs (${programs.length})</p>
''');

    for (final program in programs) {
      buffer.writeln('''
  <div class="program">
    <div class="program-name">${_escapeHtml(program.name)}</div>
    <span class="category">${_escapeHtml(program.category)}</span>
    <p class="description">${_escapeHtml(program.description)}</p>
''');

      if (program.areas.isNotEmpty) {
        buffer.writeln('    <div class="detail"><strong>Areas:</strong> ${_escapeHtml(program.areas.join(', '))}</div>');
      }
      if (program.website.isNotEmpty) {
        buffer.writeln('    <div class="detail"><strong>Website:</strong> ${_escapeHtml(program.website)}</div>');
      }
      if (program.phone != null && program.phone!.isNotEmpty) {
        buffer.writeln('    <div class="detail"><strong>Phone:</strong> ${_escapeHtml(program.phone!)}</div>');
      }
      if (program.email != null && program.email!.isNotEmpty) {
        buffer.writeln('    <div class="detail"><strong>Email:</strong> ${_escapeHtml(program.email!)}</div>');
      }

      if (program.eligibility.isNotEmpty) {
        buffer.writeln('    <div class="eligibility">');
        for (final e in program.eligibility) {
          buffer.writeln('      <span>${_escapeHtml(_formatEligibility(e))}</span>');
        }
        buffer.writeln('    </div>');
      }

      buffer.writeln('  </div>');
    }

    buffer.writeln('''
  <div class="footer">
    Generated from Bay Navigator App - ${DateTime.now().toLocal().toString().split('.').first}
  </div>
</body>
</html>
''');

    return buffer.toString();
  }

  /// Save printable HTML and open for printing
  static Future<bool> printPrograms(List<Program> programs) async {
    if (programs.isEmpty) return false;

    try {
      final html = generatePrintableHtml(programs);
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${directory.path}/bay_area_discounts_print_$timestamp.html');
      await file.writeAsString(html);

      // Open in default browser for printing
      if (Platform.isMacOS) {
        await Process.run('open', [file.path]);
      } else if (Platform.isWindows) {
        await Process.run('start', [file.path], runInShell: true);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [file.path]);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper methods
  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String _formatEligibility(String eligibility) {
    return eligibility
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}
