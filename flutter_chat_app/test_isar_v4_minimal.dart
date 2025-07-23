import 'dart:io';
import 'package:isar/isar.dart';

/// **MINIMAL ISAR V4.0.0-DEV.14 TEST**
/// 
/// Test basic Isar v4 functionality without custom schemas

@collection
class SimpleTestModel {
  late Id id;
  
  String name = '';
  int value = 0;
  DateTime createdAt = DateTime.now();
}

Future<void> main() async {
  print('🚀 Testing Isar v4.0.0-dev.14 Minimal API...');
  
  try {
    // Test basic model creation
    final model = SimpleTestModel()
      ..name = 'Test Model'
      ..value = 42
      ..createdAt = DateTime.now();
    
    print('✅ Model created: ${model.name} - ${model.value}');
    
    // Try to discover Isar v4 API patterns
    print('🔍 Discovering Isar v4 API...');
    
    // Check if Isar has built-in schema generation
    print('Isar class methods:');
    print('- openAsync: ${Isar.openAsync}');
    
    // Try to initialize without schemas (might work in v4)
    final tempDir = Directory.systemTemp.createTempSync('isar_minimal_test');
    print('Temp directory: ${tempDir.path}');
    
    try {
      // Test 1: Try opening without schemas
      print('🧪 Test 1: Opening Isar without explicit schemas...');
      final isar1 = await Isar.openAsync(
        schemas: [], // Empty schemas
        directory: tempDir.path,
        name: 'test_empty',
      );
      print('✅ Empty Isar opened successfully');
      await isar1.close();
    } catch (e) {
      print('❌ Empty Isar failed: $e');
    }
    
    try {
      // Test 2: Try with auto-discovery (if supported)
      print('🧪 Test 2: Testing auto-discovery patterns...');
      
      // Check if Isar v4 has auto-discovery
      final reflectedSchemas = <dynamic>[];
      
      final isar2 = await Isar.openAsync(
        schemas: reflectedSchemas,
        directory: tempDir.path,
        name: 'test_auto',
      );
      print('✅ Auto-discovery Isar opened successfully');
      await isar2.close();
    } catch (e) {
      print('❌ Auto-discovery failed: $e');
    }
    
    // Cleanup
    tempDir.deleteSync(recursive: true);
    
    print('🎉 Isar v4 minimal test completed!');
    
  } catch (e, stackTrace) {
    print('❌ Isar v4 minimal test failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
