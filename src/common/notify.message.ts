import {
    datetimeOfLocalDayToString,
} from "@utils/datetime.utils";
import { ApprovalActionTitle, ApprovalStatusPredicateTitle, ApprovalTypeTitle } from "../constant/approval.const";
import { capitalizeString } from "@utils/string.utils";

export const NotifyType = {
    PaycheckCreate: 'paycheck.created',
    PaycheckUpdate: 'paycheck.updated',
    PaycheckCommentCreate: 'paycheck.comment.created',
    Task: {
        Create: 'task.created',
        Update: 'task.updated',
        Notify: {
            NeedToDone: 'task.notify.ntd',
            Late: 'task.notify.late',
        }
    },
    Campaign: 'system.campaign',
    BookingRoomCreate: 'book_room.create',
    BookingRoomUpdate: 'book_room.update',
    BookingRoomDelete: 'book_room.delete',
    BookingRoomNotify: 'book_room.notify',
    BookingCarNotify: 'book_car.notify',
    BookingRoomApproval: 'book_room.approval',
    BookCarApproval: 'car.booking.approval',
    Car: {
        Booking: {
            Remove: 'car.booking.remove',
        }
    },
    ChatNotify: 'chat.notify',
    ApprovalCommentCreate: 'approval.comment.created',
    Approval: {
        Submitted: 'approval.submitted',
        Approved: 'approval.approved',
        Reject: 'approval.reject',
        Grant: 'approval.grant',
        Pending: 'approval.pending',
        Consent: 'approval.consent',
        Consented: 'approval.consented',
        Subscriber: {
            Create: 'approval.subscriber.create',
            Remove: 'approval.subscriber.remove',
            Approval: {
                Action: 'approval.subscriber.approval.action',
            }
        },
        Forward: {
            NotifyToUser: 'approval.forward.notify-to-user',
        }
    },
    Wiki: {
        Public: 'wiki.public',
        Copy: 'wiki.copy',
        Move: 'wiki.move',
        Version: {
            Comment: 'wiki.version.comment'
        }
    }
}

export const NotifyMessageTitle = {
    UserPaycheckUpsert: (args: any) => `${args.paycheckName} tháng ${args.paycheckMonth}/${args.paycheckYear}.`,
    TaskTitle: (args: any) => `${args.key} – ${args.title}`,
    TaskCreate: (args: any) => `${args.key} – ${args.title} thực hiện bởi ${args.assigned.fullname}`,
    TaskCreateNoAssigned: (args: any) => `${args.key} – ${args.title}`,
    TaskUpdateDescription: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateStatus: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdatePriority: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateStartTime: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateFinishTime: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateStartAt: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateEndAt: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateStartTimeIn: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdatePeriodType: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateWeekDays: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateMonthDays: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateWorkDays: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateAssigned: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateAssignedNewUser: (args: any) => `${args.key} – ${args.title} cần thực hiện`,
    TaskUpdateReporter: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateReporterNewUser: (args: any) => `${args.key} – ${args.title} cần quản lý`,
    TaskUpdateWatchers: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateWatchersNewUser: (args: any) => `${args.key} – ${args.title} cần theo dõi`,
    TaskUpdateAssignees: (args: any) => `${args.key} – ${args.title} được cập nhật`,
    TaskUpdateAssigneesNewUser: (args: any) => `${args.key} – ${args.title} cần thực hiện`,
    TaskUpdateComment: (args: any) => `${args.key} – Bình luận công việc`,
    Task: {
        Notify: {
            NeedToDone: (args: any) => `${args.key} – ${args.title} cần thực hiện`,
            Late: (args: any) => `${args.key} – ${args.title} trễ hạn cần thực hiện`,
        }
    },
    BookingRoomCreate: () => `Thông báo lịch họp`,
    BookingRoomNotify: () => `Thông báo lịch họp`,
    BookingRoomUpdate: () => `Thông báo cập nhật lịch họp`,
    BookingRoomDelete: () => `Thông báo xóa lịch họp`,
    BookingRoomApproval: () => `Thông báo lịch họp của bạn`,
    BookCarApproval: () => `Thông báo lịch sử dụng xe của bạn.`,
    Car: {
        Booking: {
            Remove: 'Thông báo xóa lịch đặt xe',
        }
    },
    Approval: {
        Title: (args: any) => `Phê duyệt - ${capitalizeString(ApprovalTypeTitle[args.type])}`,
        Submitted: (args: any) => `Yêu cầu ${args.name} cần phê duyệt`,
        Approved: (args: any) => `Yêu cầu ${args.name} đã được phê duyệt`,
        Reject: (args: any) => `Yêu cầu ${args.name} đã bị từ chối`,
        Grant: (args: any) => `Yêu cầu ${args.name} đã được ủy quyền`,
        Pending: (args: any) => `Yêu cầu ${args.name} chưa đạt`,
        Consent: (args: any) => `Yêu cầu ${args.name} cần thẩm định`,
        Consented: (args: any) => `Yêu cầu ${args.name} đã thẩm định`,
        Subscriber: {
            Create: (args: any) => `Yêu cầu ${args.name}`,
            Remove: (args: any) => `Yêu cầu ${args.name}`,
            Approval: {
                Action: (args: any) => `Yêu cầu ${args.name} đã ${args.action}`,
            }
        },
        Forward: {
            NotifyToUser: (args?: any) => `Bạn có phê duyệt được chuyển tiếp`,
        }
    },
    Wiki: {
        Default: (args?: any) => `Tài liệu`,
        Public: (args?: any) => `Tài liệu`,
    },
}

export const NotifyMessageContent = {
    UserPaycheckUpsert: (args: any) => `Thông báo ${args.paycheckName} tháng ${args.paycheckMonth}/${args.paycheckYear} của ${args.username}.`,
    TaskCreate: (args: any) => `${args.key} – ${args.title} thực hiện bởi ${args.assigned.fullname} được tạo bởi ${args.reporter.fullname}`,
    TaskCreateNoAssigned: (args: any) => `${args.key} – ${args.title} được tạo bởi ${args.reporter.fullname}`,
    TaskUpdateDescription: (args: any) => `${args.key} – ${args.title} được cập nhật mô tả công việc bởi ${args.creator.fullname}`,
    TaskUpdateStatus: (args: any) => `${args.key} – ${args.title} được cập nhật trạng thái ${args.newValueName} bởi ${args.creator.fullname}`,
    TaskUpdatePriority: (args: any) => `${args.key} – ${args.title} được cập nhật độ ưu tiên ${args.newValueName} bởi ${args.creator.fullname}`,
    TaskUpdateStartTime: (args: any) => `${args.key} – ${args.title} được cập nhật thời gian bắt đầu bởi ${args.creator.fullname}`,
    TaskUpdateFinishTime: (args: any) => `${args.key} – ${args.title} được cập nhật thời gian kết thúc bởi ${args.creator.fullname}`,
    TaskUpdateStartAt: (args: any) => `${args.key} – ${args.title} được cập nhật ngày bắt đầu (chu kỳ) bởi ${args.creator.fullname}`,
    TaskUpdateEndAt: (args: any) => `${args.key} – ${args.title} được cập nhật ngày kết thúc (chu kỳ) bởi ${args.creator.fullname}`,
    TaskUpdateStartTimeIn: (args: any) => `${args.key} – ${args.title} được cập nhật thời gian tạo`,
    TaskUpdatePeriodType: (args: any) => `${args.key} – ${args.title} được cập nhật loại lặp lại`,
    TaskUpdateWeekDays: (args: any) => `${args.key} – ${args.title} được cập nhật ngày lặp lại trong tuần`,
    TaskUpdateMonthDays: (args: any) => `${args.key} – ${args.title} được cập nhật ngày lặp lại trong tháng`,
    TaskUpdateWorkDays: (args: any) => `${args.key} – ${args.title} được cập nhật thời gian hoàn thành (ngày)`,
    TaskUpdateAssigned: (args: any) => `${args.key} – ${args.title} được cập nhật người nhận công việc bởi ${args.creator.fullname}`,
    TaskUpdateAssignedNewUser: (args: any) => `${args.key} – ${args.title} cần thực hiện được tạo bởi ${args.creator.fullname}`,
    TaskUpdateReporter: (args: any) => `${args.key} – ${args.title} được cập nhật người kiểm tra công việc bởi ${args.creator.fullname}`,
    TaskUpdateReporterNewUser: (args: any) => `${args.key} – ${args.title} cần kiểm tra được tạo bởi ${args.creator.fullname}`,
    TaskUpdateWatchers: (args: any) => `${args.key} – ${args.title} được cập nhật người nhận thông báo công việc bởi ${args.creator.fullname}`,
    TaskUpdateWatchersNewUser: (args: any) => `${args.key} – ${args.title} cần theo dõi được tạo bởi ${args.creator.fullname}`,
    TaskUpdateAssignees: (args: any) => `${args.key} – ${args.title} được cập nhật danh sách người nhận công việc bởi ${args.creator.fullname}`,
    TaskUpdateAssigneesNewUser: (args: any) => `${args.key} – ${args.title} cần thực hiện được tạo bởi ${args.creator.fullname}`,
    Task: {
        Notify: {
            NeedToDone: (args: any) => `${args.key} – ${args.title} cần bạn thực hiện trước ngày ${datetimeOfLocalDayToString('DD/MM HH:mm', args.finishTime)}`,
            Late: (args: any) => `${args.key} – ${args.title} đã trễ hạn cần bạn thực hiện`,
        }
    },
    BookingRoomApproval: (args: any) => `Bạn có lịch họp ${args.meetingContent} vào ${datetimeOfLocalDayToString('DD/MM HH:mm', args.startAt)} đến ${datetimeOfLocalDayToString('DD/MM HH:mm', args.endAt)} tại ${args.meetingRoom?.name}`,
    BookCarApproval: (args: any) => `Bạn có lịch sử dụng xe từ ${datetimeOfLocalDayToString('DD/MM HH:mm', args.startAt)} đến ${datetimeOfLocalDayToString('DD/MM HH:mm', args.endAt)} di chuyển từ ${args.fromAddress} đến ${args.toAddress} bằng xe ${args.car.model} - ${args.car.plateNumber}`,
    Car: {
        Booking: {
            Remove: (args: any) => `Xóa lịch đặt xe ${args.car.model} – ${args.car.plateNumber} thời gian từ  ${datetimeOfLocalDayToString('DD/MM HH:mm', args.startAt)} đến ${datetimeOfLocalDayToString('DD/MM HH:mm', args.endAt)}`,
        }
    },
    Approval: {
        ActionHaveRelation: (args: any) => `Bạn có yêu cầu cần ${ApprovalActionTitle[args.approvalAction]} cho ${ApprovalTypeTitle[args.type]}: ${args.relationName}`,
        ActedHaveRelation: (args: any) => `${capitalizeString(ApprovalTypeTitle[args.type])} do bạn tạo đã ${ApprovalStatusPredicateTitle[args.action]}: ${args.relationName}`,
        Submitted: (args: any) => `Bạn có yêu cầu ${args.approvalName} cần phê duyệt từ ${args?.requesterName}`,
        GrantSubmitted: (args: any) => `Bạn có yêu cầu ${args.approvalName} cần phê duyệt được ủy quyền bởi ${args?.userActionName}`,
        Consent: (args: any) => `Yêu cầu ${args.approvalName} cần thẩm định được tạo bởi ${args?.requesterName}`,
        Consented: (args: any) => `Yêu cầu ${args.approvalName} đã được thẩm định bởi ${args?.userActionName}`,
        Approved: (args: any) => `Yêu cầu ${args.approvalName} của bạn đã được phê duyệt bởi ${args?.userActionName}`,
        Reject: (args: any) => `Yêu cầu ${args.approvalName} của bạn đã bị từ chối bởi ${args?.userActionName}`,
        Grant: (args: any) => `Yêu cầu ${args.approvalName} của bạn đã được ủy quyền bởi ${args?.userActionName}`,
        Pending: (args: any) => `Yêu cầu ${args.approvalName} của bạn chưa đạt đánh giá bởi ${args?.userActionName}`,
        Subscriber: {
            Create: (args: any) => `Yêu cầu ${args.approvalName} được tạo bởi ${args?.creatorName}`,
            Remove: (args: any) => `Yêu cầu ${args.approvalName} đã hủy theo dõi bởi ${args?.userActionName}`,
            Approval: {
                Action: (args: any) => `Yêu cầu ${args.name} đã ${args.action} bởi ${args?.userActionName}`,
            },
            Approved: (args: any) => `Yêu cầu ${args.approvalName} được tạo bởi ${args?.requesterName} đã được phê duyệt bởi ${args?.userActionName}`,
            Reject: (args: any) => `Yêu cầu ${args.approvalName} được tạo bởi ${args?.requesterName} đã bị từ chối bởi ${args?.userActionName}`,
            Grant: (args: any) => `Yêu cầu ${args.approvalName} được tạo bởi ${args?.requesterName} đã được ủy quyền bởi ${args?.userActionName}`,
            Pending: (args: any) => `Yêu cầu ${args.approvalName} được tạo bởi ${args?.requesterName} chưa đạt đánh giá bởi ${args?.userActionName}`,
            Consented: (args: any) => `Yêu cầu ${args.approvalName} được tạo bởi ${args?.requesterName} đã được thẩm định bởi ${args?.userActionName}`,
        }
        ,
        Forward: {
            NotifyToUser: (args: any) => `Phê duyệt ${args.name} được chuyển tiếp bởi ${args?.creatorName}`,
        }
    },
    Wiki: {
        Public: (args: any) => `Đã ban hành tài liệu: ${args.name}`,
        Copy: (args: any) => `Bạn cần gửi phê duyệt cho bản sao chép tài liệu: ${args.name}`,
        Move: {
            StillView: (args: any) => `Đã di chuyển tài liệu ${args.name} từ thư mục ${args.oldFolderName} sang thư mục ${args.newFolderName}`
        },
    },
}
