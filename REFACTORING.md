# Refactoring Edit Page

## Ringkasan Perubahan

File edit_page.dart yang sebelumnya berisi 977 baris telah dipisahkan menjadi beberapa file yang lebih kecil dan mudah dikelola.

## Struktur File Baru

### 1. Domain Models
**File:** `lib/domain/models/export_models.dart`
- `ExportQuality` enum: Low, Medium, High
- `ExportSpec` class: Model untuk spesifikasi export SVG

### 2. Utils
**File:** `lib/utils/svg_utils.dart`
- `tryParseExportSpec()`: Function untuk parsing SVG string menjadi ExportSpec

### 3. Widgets

#### `lib/presentation/widgets/checkerboard_painter.dart`
- `CheckerboardPainter`: CustomPainter untuk background checkerboard

#### `lib/presentation/widgets/svg_window_clipper.dart`
- `SvgWindowClipper`: CustomClipper untuk clipping window SVG

#### `lib/presentation/widgets/export_canvas.dart`
- `ExportCanvas`: Widget untuk rendering canvas saat export

#### `lib/presentation/widgets/export_options_dialog.dart`
- `ExportOptionsDialog`: Dialog untuk memilih opsi export (nama file & kualitas)

#### `lib/presentation/widgets/edit_mode_switcher.dart`
- `EditModeSwitcher`: Widget untuk toggle antara mode Frame dan Image
- `EditMode` enum: Frame, Image

### 4. Main Page
**File:** `lib/presentation/pages/edit_page.dart` (Refactored)
- Berkurang dari 977 baris menjadi ~570 baris
- Import semua widget dan utilities yang sudah dipisahkan
- Fokus pada logic utama halaman edit

## Keuntungan Refactoring

1. **Modularitas**: Setiap komponen memiliki file sendiri
2. **Reusability**: Widget dapat digunakan kembali di tempat lain
3. **Maintainability**: Lebih mudah menemukan dan memperbaiki bug
4. **Testability**: Setiap komponen dapat ditest secara terpisah
5. **Readability**: Kode lebih mudah dibaca dan dipahami

## Import yang Dibutuhkan

Edit page sekarang mengimport:
```dart
import '../../domain/models/export_models.dart';
import '../../utils/svg_utils.dart';
import '../widgets/checkerboard_painter.dart';
import '../widgets/export_canvas.dart';
import '../widgets/export_options_dialog.dart';
import '../widgets/edit_mode_switcher.dart';
```

## Catatan

- Semua fungsi utama tetap sama
- Tidak ada perubahan behavior
- Hanya refactoring struktur kode
- Semua test Flutter analyze sudah passed ✅
