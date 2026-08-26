import 'package:pdf/pdf.dart';

class ReportPalette {
  static const PdfColor ink = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor inkSoft = PdfColor.fromInt(0xFF374151);
  static const PdfColor muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor faint = PdfColor.fromInt(0xFF9CA3AF);

  static const PdfColor background = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor stripe = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor divider = PdfColor.fromInt(0xFFE5E7EB);

  static const PdfColor income = PdfColor.fromInt(0xFF059669);
  static const PdfColor incomeBg = PdfColor.fromInt(0xFFECFDF5);

  static const PdfColor expense = PdfColor.fromInt(0xFFE11D48);
  static const PdfColor expenseBg = PdfColor.fromInt(0xFFFFF1F2);

  static const PdfColor net = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor netNegative = PdfColor.fromInt(0xFFD97706);
  static const PdfColor netBg = PdfColor.fromInt(0xFFEFF6FF);
}
