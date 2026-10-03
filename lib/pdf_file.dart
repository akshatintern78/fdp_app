import 'pdf_file_io.dart' if (dart.library.html) 'pdf_file_web.dart' as opener;

Future<void> saveAndOpenPdf(List<int> bytes, String filename) {
  return opener.saveAndOpenPdf(bytes, filename);
}
