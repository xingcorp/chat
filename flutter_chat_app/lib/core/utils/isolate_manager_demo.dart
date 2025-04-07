import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/utils/isolate_manager.dart';

/// Ví dụ sử dụng IsolateManager nâng cao
class IsolateManagerDemo extends StatefulWidget {
  final IsolateManager isolateManager;
  
  const IsolateManagerDemo({
    Key? key,
    required this.isolateManager,
  }) : super(key: key);

  @override
  State<IsolateManagerDemo> createState() => _IsolateManagerDemoState();
}

class _IsolateManagerDemoState extends State<IsolateManagerDemo> {
  // Theo dõi tiến độ xử lý
  double _progress = 0.0;
  String _statusMessage = 'Sẵn sàng';
  bool _isProcessing = false;
  String? _taskId;
  String? _resultMessage;
  
  // Xử lý hình ảnh với báo cáo tiến độ
  Future<void> _processImageWithProgress() async {
    // Tạo controller để theo dõi tiến độ
    final progressController = StreamController<IsolateProgress>();
    
    setState(() {
      _progress = 0.0;
      _statusMessage = 'Bắt đầu xử lý...';
      _isProcessing = true;
      _resultMessage = null;
    });
    
    // Lắng nghe cập nhật tiến độ
    progressController.stream.listen((progress) {
      setState(() {
        _progress = progress.progress;
        _statusMessage = progress.message ?? 'Đang xử lý...';
      });
    });
    
    try {
      // Dữ liệu giả lập
      final mockImageData = {
        'size': 5000000, // 5MB
        'dimensions': '3000x2000',
      };
      
      // Xử lý trong isolate với báo cáo tiến độ
      final result = await widget.isolateManager.processInBackground(
        taskType: IsolateTaskType.imageProcessing,
        data: mockImageData,
        params: {
          'operation': 'compress',
          'quality': 80,
        },
        progressController: progressController,
        taskId: 'image_task_${DateTime.now().millisecondsSinceEpoch}',
        priority: TaskPriority.high,
      );
      
      // Lưu task ID để có thể hủy
      _taskId = result.taskId;
      
      if (result.isSuccess) {
        setState(() {
          _resultMessage = 'Xử lý thành công!\n'
              'Kích thước ban đầu: ${(mockImageData['size'] as int) / 1024 / 1024}MB\n'
              'Kích thước mới: ${(result.result['new_size'] as num) / 1024 / 1024}MB\n'
              'Tỷ lệ nén: ${result.result['compression_ratio'] ?? '?'}';
        });
      } else {
        setState(() {
          _resultMessage = 'Xử lý thất bại: ${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Lỗi: $e';
      });
    } finally {
      await progressController.close();
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  // Xử lý vượt quá thời gian (hủy tác vụ sau 5 giây)
  Future<void> _processWithCancellation() async {
    // Tạo controller để theo dõi tiến độ
    final progressController = StreamController<IsolateProgress>();
    
    setState(() {
      _progress = 0.0;
      _statusMessage = 'Bắt đầu xử lý tệp lớn...';
      _isProcessing = true;
      _resultMessage = null;
    });
    
    // Lắng nghe cập nhật tiến độ
    progressController.stream.listen((progress) {
      setState(() {
        _progress = progress.progress;
        _statusMessage = progress.message ?? 'Đang xử lý...';
      });
    });
    
    try {
      // Tạo task ID
      final taskId = 'file_task_${DateTime.now().millisecondsSinceEpoch}';
      _taskId = taskId;
      
      // Xử lý trong isolate với báo cáo tiến độ
      // Sử dụng Future.microtask để bắt đầu xử lý trước
      unawaited(Future.microtask(() async {
        await Future.delayed(const Duration(seconds: 5));
        if (_isProcessing && _taskId == taskId) {
          debugPrint('Hủy tác vụ sau 5 giây: $taskId');
          await widget.isolateManager.cancelTask(taskId);
        }
      }));
      
      final result = await widget.isolateManager.processInBackground(
        taskType: IsolateTaskType.fileOperation,
        taskId: taskId,
        data: {
          'path': '/path/to/large/file.dat',
          'size': 100000000, // 100MB
        },
        params: {
          'operation': 'encode',
        },
        progressController: progressController,
        priority: TaskPriority.medium,
        enableCancellation: true,
      );
      
      if (result.isSuccess) {
        setState(() {
          _resultMessage = 'Xử lý thành công!';
        });
      } else {
        setState(() {
          _resultMessage = 'Xử lý thất bại: ${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Lỗi: $e';
      });
    } finally {
      await progressController.close();
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  // Xử lý dữ liệu lớn
  Future<void> _processLargeData() async {
    // Tạo controller để theo dõi tiến độ
    final progressController = StreamController<IsolateProgress>();
    
    setState(() {
      _progress = 0.0;
      _statusMessage = 'Bắt đầu xử lý dữ liệu lớn...';
      _isProcessing = true;
      _resultMessage = null;
    });
    
    // Lắng nghe cập nhật tiến độ
    progressController.stream.listen((progress) {
      setState(() {
        _progress = progress.progress;
        _statusMessage = progress.message ?? 'Đang xử lý...';
      });
    });
    
    try {
      // Tạo dữ liệu lớn (danh sách 10000 phần tử)
      final largeData = List.generate(10000, (i) => {'id': i, 'value': 'item-$i'});
      
      // Xử lý trong isolate với báo cáo tiến độ
      final result = await widget.isolateManager.processInBackground(
        taskType: IsolateTaskType.dataProcessing,
        data: largeData,
        params: {
          'operation': 'transform',
        },
        progressController: progressController,
        priority: TaskPriority.low,
      );
      
      _taskId = result.taskId;
      
      if (result.isSuccess) {
        setState(() {
          _resultMessage = 'Xử lý dữ liệu thành công!\n'
              'Số lượng phần tử: ${result.result['count'] ?? '?'}\n'
              'Kết quả: ${result.result['summary'] ?? '?'}';
        });
      } else {
        setState(() {
          _resultMessage = 'Xử lý thất bại: ${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Lỗi: $e';
      });
    } finally {
      await progressController.close();
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  // Hủy tác vụ đang chạy
  Future<void> _cancelCurrentTask() async {
    if (_taskId != null) {
      final cancelled = await widget.isolateManager.cancelTask(_taskId!);
      if (cancelled) {
        setState(() {
          _statusMessage = 'Đã hủy tác vụ $_taskId';
        });
      } else {
        setState(() {
          _statusMessage = 'Không thể hủy tác vụ $_taskId';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví dụ IsolateManager'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hiển thị tiến độ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trạng thái: $_statusMessage'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 8),
                    Text('Tiến độ: ${(_progress * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Hiển thị kết quả
            if (_resultMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_resultMessage!),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Các nút hành động
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processImageWithProgress,
                  child: const Text('Xử lý hình ảnh'),
                ),
                
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processWithCancellation,
                  child: const Text('Xử lý & tự động hủy (5s)'),
                ),
                
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processLargeData,
                  child: const Text('Xử lý dữ liệu lớn'),
                ),
                
                ElevatedButton(
                  onPressed: _isProcessing ? _cancelCurrentTask : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Hủy tác vụ hiện tại'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Hàm để bỏ qua Future mà không cần await
void unawaited(Future<void> future) {} 