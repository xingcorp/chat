import 'package:flutter_chat_app/core/services/performance_service.dart';
import 'package:firebase_performance/firebase_performance.dart';

// Trong hàm khởi tạo dependencies, đăng ký PerformanceService
// Thêm vào cuối hàm registerDependencies() hoặc nơi phù hợp

// Đăng ký FirebasePerformance
final firebasePerformance = FirebasePerformance.instance;
sl.registerLazySingleton<FirebasePerformance>(() => firebasePerformance);

// Đăng ký PerformanceService
sl.registerLazySingleton<PerformanceService>(() => PerformanceService(sl()));

// Hoặc nếu đã có phương thức registerServices(), thêm đoạn code sau vào đó:

void registerServices() {
  // Các đăng ký khác...
  
  // Đăng ký FirebasePerformance
  final firebasePerformance = FirebasePerformance.instance;
  sl.registerLazySingleton<FirebasePerformance>(() => firebasePerformance);
  
  // Đăng ký PerformanceService
  sl.registerLazySingleton<PerformanceService>(() => PerformanceService(sl()));
} 