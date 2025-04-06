import 'package:flutter_bloc/flutter_bloc.dart';
import 'base_state.dart';

/// Lớp cơ sở trừu tượng cho tất cả các BLoC.
/// EventType là kiểu dữ liệu cho các sự kiện mà BLoC này xử lý.
abstract class BaseBloc<EventType, StateType extends BaseState> extends Bloc<EventType, StateType> {

  // Khởi tạo BLoC với trạng thái ban đầu.
  BaseBloc(StateType initialState) : super(initialState) {
    // Đăng ký bộ xử lý lỗi chung cho tất cả các BLoC kế thừa.
    onError = (error, stackTrace) {
      // Ghi log lỗi (bạn có thể sử dụng một thư viện logging như logger hoặc đơn giản là print)
      print('[BaseBloc Error] In ${runtimeType}: $error\n$stackTrace');

      // Phát ra trạng thái BaseError nếu trạng thái hiện tại chưa phải là lỗi.
      // Điều này ngăn việc phát ra nhiều lỗi liên tiếp nếu một lỗi xảy ra
      // trong quá trình xử lý một lỗi khác.
      if (state is! BaseError) {
        // Cố gắng tạo một thông điệp lỗi thân thiện hơn nếu có thể
        // (Ví dụ: từ các loại exception cụ thể)
        String errorMessage = "Đã có lỗi xảy ra. Vui lòng thử lại.";
        // TODO: Tùy chỉnh việc trích xuất thông điệp lỗi dựa trên loại 'error'
        // Ví dụ: if (error is MyCustomException) errorMessage = error.friendlyMessage;

        emit(BaseError(errorMessage, error: error, stackTrace: stackTrace) as StateType);
      }

      // Gọi lại bộ xử lý lỗi mặc định của flutter_bloc (nếu cần)
      super.onError?.call(error, stackTrace);
    };
  }

  /// Phương thức tiện ích để phát ra trạng thái Loading.
  void emitLoading({String? message}) {
    if (state is! BaseLoading) { // Tránh phát ra loading liên tiếp
      emit(BaseLoading(message: message) as StateType);
    }
  }

  /// Phương thức tiện ích để phát ra trạng thái Error.
  /// Bạn có thể gọi trực tiếp phương thức này hoặc để bộ xử lý `onError` tự động bắt.
  void emitError(String message, {dynamic error, StackTrace? stackTrace}) {
     if (state is! BaseError) {
        emit(BaseError(message, error: error, stackTrace: stackTrace) as StateType);
     }
  }

  // Bạn có thể thêm các phương thức hoặc thuộc tính chung khác ở đây,
  // ví dụ:
  // - stream để báo hiệu các sự kiện cần hiển thị một lần (showSnackBar, showDialog)
  // - getter để kiểm tra trạng thái mạng
  // - phương thức để xử lý các event chung

  @override
  void onChange(Change<StateType> change) {
    super.onChange(change);
    // Ghi log thay đổi trạng thái nếu cần (hữu ích khi debug)
    // print('[BaseBloc State Change] In ${runtimeType}: ${change.currentState} -> ${change.nextState}');
  }

  @override
  void onTransition(Transition<EventType, StateType> transition) {
    super.onTransition(transition);
    // Ghi log các transition nếu cần (hữu ích khi debug)
    // print('[BaseBloc Transition] In ${runtimeType}: ${transition.event} caused ${transition.currentState} -> ${transition.nextState}');
  }
} 