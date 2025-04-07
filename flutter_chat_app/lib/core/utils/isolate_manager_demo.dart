import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/utils/isolate_manager.dart';
import 'package:flutter_chat_app/core/utils/system_resources.dart';

/// Ví dụ sử dụng IsolateManager nâng cao
class IsolateManagerDemo extends StatefulWidget {
  final IsolateManager isolateManager;
  final SystemResourceMonitor resourceMonitor;
  
  const IsolateManagerDemo({
    Key? key,
    required this.isolateManager,
    required this.resourceMonitor,
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
  
  // Thông tin về worker pool
  int _activeWorkers = 0;
  int _targetWorkers = 0;
  int _pendingTasks = 0;
  bool _dynamicScalingEnabled = true;
  
  // Thông tin hệ thống
  int _loadScore = 0;
  String _cpuLevel = 'Thấp';
  String _memoryLevel = 'Thấp';
  
  // Timer cập nhật thông tin
  Timer? _updateTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Cập nhật thông tin worker pool mỗi giây
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updatePoolInfo();
    });
    
    // Lắng nghe thay đổi tài nguyên hệ thống
    widget.resourceMonitor.resourceStateStream.listen((state) {
      setState(() {
        _loadScore = state.loadScore;
        _cpuLevel = _getCpuLevelName(state.cpuLevel);
        _memoryLevel = _getMemoryLevelName(state.memoryLevel);
        _pendingTasks = state.pendingTasksCount;
      });
    });
    
    // Cập nhật ngay lần đầu
    _updatePoolInfo();
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
  
  // Cập nhật thông tin về worker pool
  void _updatePoolInfo() {
    setState(() {
      _activeWorkers = widget.isolateManager.activeWorkerCount;
      _targetWorkers = widget.isolateManager.targetWorkerCount;
    });
  }
  
  // Trả về tên mức CPU
  String _getCpuLevelName(CpuUsageLevel level) {
    switch (level) {
      case CpuUsageLevel.low:
        return 'Thấp';
      case CpuUsageLevel.medium:
        return 'Trung bình';
      case CpuUsageLevel.high:
        return 'Cao';
      default:
        return 'Không xác định';
    }
  }
  
  // Trả về tên mức memory
  String _getMemoryLevelName(MemoryUsageLevel level) {
    switch (level) {
      case MemoryUsageLevel.low:
        return 'Thấp';
      case MemoryUsageLevel.medium:
        return 'Trung bình';
      case MemoryUsageLevel.high:
        return 'Cao';
      default:
        return 'Không xác định';
    }
  }
  
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
  
  // Xử lý dữ liệu lớn để kiểm tra auto-scaling
  Future<void> _processHeavyLoad() async {
    // Tạo và chạy nhiều tác vụ song song để kích hoạt auto-scaling
    
    setState(() {
      _statusMessage = 'Đang tạo tải nặng...';
      _isProcessing = true;
      _resultMessage = null;
    });
    
    // Đếm số tác vụ hoàn thành
    int completedTasks = 0;
    const totalTasks = 10;
    
    try {
      // Tạo 10 tác vụ song song
      final tasks = List.generate(totalTasks, (index) {
        // Tạo controller để theo dõi tiến độ cho mỗi tác vụ
        final progressController = StreamController<IsolateProgress>();
        
        // Lấy tiến độ cụ thể cho tác vụ này
        progressController.stream.listen((_) {
          // Không cần cập nhật UI với từng tác vụ
        });
        
        // Dữ liệu giả lập
        final data = List.generate(10000, (i) => {'id': i, 'value': 'item-$i'});
        
        // Trả về future của tác vụ
        return widget.isolateManager.processInBackground(
          taskType: IsolateTaskType.dataProcessing,
          data: data,
          params: {
            'operation': 'transform',
            'complexity': 'high',
          },
          progressController: progressController,
          priority: index % 3 == 0 ? TaskPriority.high : TaskPriority.medium,
        ).then((result) {
          // Đóng controller
          progressController.close();
          
          // Cập nhật tiến độ tổng thể
          completedTasks++;
          setState(() {
            _progress = completedTasks / totalTasks;
            _statusMessage = 'Đã xử lý $completedTasks/$totalTasks tác vụ';
          });
          
          return result;
        });
      });
      
      // Chờ tất cả tác vụ hoàn thành
      final results = await Future.wait(tasks);
      
      // Đếm số tác vụ thành công
      final successCount = results.where((r) => r.isSuccess).length;
      
      setState(() {
        _resultMessage = 'Đã hoàn thành $successCount/$totalTasks tác vụ\n'
            'Worker pool đã thay đổi thành $_activeWorkers worker';
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Lỗi khi tạo tải nặng: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
        _progress = 1.0;
      });
    }
  }
  
  // Bật/tắt auto scaling
  void _toggleAutoScaling() {
    _dynamicScalingEnabled = !_dynamicScalingEnabled;
    widget.isolateManager.dynamicScalingEnabled = _dynamicScalingEnabled;
    setState(() {});
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thông tin worker pool
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Worker Pool', 
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Worker hoạt động: $_activeWorkers / $_targetWorkers'),
                      Text('Tác vụ đang chờ: $_pendingTasks'),
                      Text('Auto-scaling: ${_dynamicScalingEnabled ? "Bật" : "Tắt"}'),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Auto-scaling'),
                        value: _dynamicScalingEnabled,
                        onChanged: (_) => _toggleAutoScaling(),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Thông tin tài nguyên hệ thống
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tài nguyên hệ thống', 
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Mức tải: $_loadScore/100'),
                      Text('CPU: $_cpuLevel'),
                      Text('Bộ nhớ: $_memoryLevel'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Hiển thị tiến độ
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tiến độ tác vụ', 
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kết quả', 
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(_resultMessage!),
                      ],
                    ),
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
                    onPressed: _isProcessing ? null : _processHeavyLoad,
                    child: const Text('Tạo tải nặng'),
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
      ),
    );
  }
}

// Hàm để bỏ qua Future mà không cần await
void unawaited(Future<void> future) {} 