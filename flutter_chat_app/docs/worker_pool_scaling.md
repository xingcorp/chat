# Cơ chế Động cho Worker Pool

## Tổng quan

Hệ thống worker pool linh hoạt cho phép ứng dụng tự động điều chỉnh số lượng isolate (worker) dựa trên tải hệ thống và nhu cầu xử lý. Cách tiếp cận này giúp:

1. **Tối ưu tài nguyên hệ thống** khi tải thấp
2. **Cải thiện hiệu suất** khi cần xử lý nhiều tác vụ song song
3. **Thích ứng thông minh** với các thiết bị có cấu hình khác nhau

## Cách hoạt động

### 1. Theo dõi tài nguyên hệ thống

`SystemResourceMonitor` liên tục thu thập dữ liệu về:

- **CPU usage**: Phần trăm sử dụng CPU
- **Memory usage**: Phần trăm bộ nhớ đã sử dụng
- **UI lag**: Độ trễ của giao diện người dùng
- **Pending tasks**: Số lượng tác vụ đang chờ xử lý

Các thông số này được kết hợp để tính toán một "điểm tải" (load score) tổng thể.

### 2. Chiến lược mở rộng và thu hẹp

#### Mở rộng (Scale Up)

Worker pool sẽ tăng số lượng isolate khi:

- **Load score > 60**: Hệ thống đang chịu tải nặng
- **Số tác vụ đang chờ > 3x số worker hiện tại**: Có quá nhiều tác vụ đang chờ

#### Thu hẹp (Scale Down)

Worker pool sẽ giảm số lượng isolate khi:

- **Load score < 30**: Hệ thống đang chịu tải nhẹ
- **Số tác vụ đang chờ < số worker hiện tại**: Không cần nhiều worker

### 3. Cơ chế "Cool Down"

Để tránh tình trạng thay đổi số lượng worker quá thường xuyên (thrashing), hệ thống áp dụng cơ chế "cool down":

- Sau mỗi lần scale up/down, hệ thống phải đợi ít nhất 30 giây trước khi có thể scale lại.

### 4. Giới hạn

- **Số worker tối thiểu**: 1 (luôn đảm bảo có ít nhất 1 worker)
- **Số worker tối đa**: 6 (hoặc dựa trên số lõi CPU - 1, tránh chiếm toàn bộ tài nguyên)

## Quy trình khi Scale Up

1. Tìm slot trống trong worker pool
2. Khởi tạo isolate mới
3. Tăng biến `targetWorkerCount`
4. Cập nhật thời gian scale gần nhất
5. Xử lý ngay các tác vụ đang chờ

## Quy trình khi Scale Down

1. Tìm worker đang rảnh rỗi
2. Đóng isolate một cách an toàn
3. Giảm biến `targetWorkerCount`
4. Cập nhật thời gian scale gần nhất

## Xử lý sự cố và Khôi phục

- Nếu một isolate không phản hồi (5 phút không hoạt động), nó sẽ được khởi động lại
- Các tác vụ đang xử lý trên isolate bị lỗi sẽ được đưa lại vào queue
- Hệ thống kiểm tra tính khoẻ mạnh của isolate mỗi 30 giây

## Các thành phần chính

1. **SystemResourceMonitor**: Thu thập và phân tích metrics hệ thống
2. **IsolateManager**: Quản lý vòng đời của isolate và scale pool
3. **Load Score Calculator**: Tích hợp các metrics thành một số đo tải tổng thể

## Tối ưu hoá cho các thiết bị

Hệ thống tự động điều chỉnh số lượng worker ban đầu dựa trên số lõi CPU:

- Thiết bị 2 lõi: 1 worker ban đầu
- Thiết bị 4 lõi: 2 worker ban đầu
- Thiết bị 6+ lõi: 3 worker ban đầu

## Theo dõi và Gỡ lỗi

Hệ thống ghi log các thông tin quan trọng:

- Khi mở rộng/thu hẹp pool: "Scaling up/down isolate pool"
- Khi phát hiện isolate không phản hồi: "Isolate appears to be dead, restarting..."
- Khi gặp lỗi: "Error during auto-scaling check: ..."

## Khả năng Tùy chỉnh

Cơ chế này có thể được bật/tắt và tùy chỉnh thông qua các thông số:

- Bật/tắt scaling động: `dynamicScalingEnabled = true/false`
- Thời gian giữa các lần kiểm tra: 10 giây (có thể điều chỉnh)
- Thời gian "cool down": 30 giây (có thể điều chỉnh)
- Ngưỡng scale up/down: 60/30 (có thể điều chỉnh)

## Phân tích Hiệu suất

### Ưu điểm

- **Tiết kiệm tài nguyên** khi không cần nhiều isolate
- **Tăng khả năng xử lý song song** khi tải cao
- **Phản ứng tự động** với thay đổi tải hệ thống
- **Thích ứng với thiết bị** có cấu hình khác nhau

### Nhược điểm

- **Overhead** từ việc giám sát tài nguyên hệ thống
- **Độ trễ khởi tạo** isolate mới (~200-300ms)
- **Nguy cơ thrashing** nếu cấu hình không phù hợp

## Kết luận

Cơ chế worker pool linh hoạt cung cấp sự cân bằng tốt giữa hiệu suất và sử dụng tài nguyên. Trong hầu hết các trường hợp, việc dynamic scaling giúp ứng dụng đạt hiệu quả tối ưu hơn so với số lượng isolate cố định. 