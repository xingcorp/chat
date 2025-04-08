export enum TaskStatus {
    Todo = 'Todo', //“Chờ xử lý”
    In_progress = 'In_progress', // “Đang xử lý”
    Resolved = 'Resolved', // “Đã xử lý”
    Pending = 'Pending', // “Tạm dừng”
    Reject = 'Reject', // “Từ chối”
    Cancel = 'Cancel', // "Đã hủy"
    Done = 'Done', // "Hoàn thành"
    Undefined = 'Undefined', // "Undefined"
}

export enum TaskStatusTitle {
    Todo = 'chờ xử lý',
    In_progress = 'đang xử lý',
    Resolved = 'đã xử lý',
    Pending = 'tạm dừng',
    Reject = 'từ chối',
    Cancel = 'đã hủy',
    Done = 'hoàn thành',
    Undefined = 'Không xác định', // "Undefined"
}

export enum TaskPriority {
    // Highest = 'Highest',
    High = 'High',
    Medium = 'Medium',
    Low = 'Low',
    // Lowest = 'Lowest',
    Undefined = 'Undefined', // "Undefined"
}

export enum TaskPriorityTitle {
    Highest = 'cao nhất',
    High = 'cao',
    Medium = 'trung bình',
    Low = 'thấp',
    Lowest = 'thấp nhất',
    Undefined = 'Không xác định', // "Undefined"
}

export enum TaskLogType {
    Comment = 'Comment',
    History = 'History',
}

export enum TaskAction {
    Create = 'Create',
    Update = 'Update',
}

export enum TaskComplete {
    All = 'All',
    In_Time = 'In_Time',
    Late = 'Late',
}

export enum TaskTypeEnum {
    Task = 'Task',
    ReportConfig = 'ReportConfig',
    Report = 'Report',
    ReportArise = 'ReportArise',
}

export enum TaskKindEnum {
    ReportParent = 'ReportParent',
    ReportChild = 'ReportChild',
}

export enum TaskQuickSearchEnum {
    ASSIGN_TO_ME = 'ASSIGN_TO_ME',
    IM_REPORT = 'IM_REPORT',
    IM_CREATED = 'IM_CREATED',
    IM_WATCHED = 'IM_WATCHED',
}

export enum TaskSpeciesEnum {
    TASK = 'TASK',
    REPORT = 'REPORT',
}
