export enum WorkProfileAction {
    Create = 'Create',
    Update = 'Update',
    Remove = 'Remove',
}

export enum WorkProfileChangeType {
    /*Create*/
    NewRecruitment = "NewRecruitment",
    ReturnToWork = "ReturnToWork",
    TransferCompany = "TransferCompany",

    /*Remove*/
    Quitting = "Quitting",
    QuittingTransfer = "QuittingTransfer",

    /*Update*/
    Official = "Official",
    ChangeImmediateSuperior = "ChangeImmediateSuperior",
    CurrentlyWorking = "CurrentlyWorking",
    SuspendLaborContract = "SuspendLaborContract",
    NotUsedForRecruitment = "NotUsedForRecruitment",
    Transfer = "Transfer",
    Removal = "Removal",
    Appointment = "Appointment",
    ProbationaryAppointment = "ProbationaryAppointment",
    Demotion = "Demotion",
    TemporaryTransfer = "TemporaryTransfer",
    Dismissal = "Dismissal",
    ChangeOfTitle = "ChangeOfTitle",
    ChangeOfOrganizationalStructure = "ChangeOfOrganizationalStructure",
}

export enum WorkProfileChangeTypeExplain {
    /*Create*/
    NewRecruitment = "Tuyển mới",
    ReturnToWork = "Quay lại làm việc",
    TransferCompany = "Thuyên chuyển công ty",

    /*Remove*/
    Quitting = "Thôi việc",
    QuittingTransfer = "Thôi việc - thuyên chuyển",

    /*Update*/
    Official = "Chính thức",
    ChangeImmediateSuperior = "Thay đổi cấp trên trực tiếp",
    CurrentlyWorking = "Đang làm việc",
    SuspendLaborContract = "Tạm hoãn HĐLĐ",
    Transfer = "Thuyên chuyển",
    NotUsedForRecruitment = "Không dùng tuyển dụng",
    Removal = "Bãi nhiệm",
    Appointment = "Bổ nhiệm",
    ProbationaryAppointment = "Bổ nhiệm thử thách",
    Demotion = "Cách chức",
    TemporaryTransfer = "Điều động tạm thời",
    Dismissal = "Miễn nhiệm",
    ChangeOfTitle = "Thay đổi chức danh",
    ChangeOfOrganizationalStructure = "Thay đổi cơ cấu tổ chức",
}

export const WorkProfileActionType = {
    'Create': [
        WorkProfileChangeType.NewRecruitment,
        WorkProfileChangeType.ReturnToWork,
        WorkProfileChangeType.TransferCompany,
    ],
    'Remove': [
        WorkProfileChangeType.Quitting,
        WorkProfileChangeType.QuittingTransfer,
    ],
    'Update': [
        WorkProfileChangeType.Official,
        WorkProfileChangeType.ChangeImmediateSuperior,
        WorkProfileChangeType.CurrentlyWorking,
        WorkProfileChangeType.SuspendLaborContract,
        WorkProfileChangeType.Transfer,
        WorkProfileChangeType.NotUsedForRecruitment,
        WorkProfileChangeType.Removal,
        WorkProfileChangeType.Appointment,
        WorkProfileChangeType.ProbationaryAppointment,
        WorkProfileChangeType.Demotion,
        WorkProfileChangeType.TemporaryTransfer,
        WorkProfileChangeType.Dismissal,
        WorkProfileChangeType.ChangeOfTitle,
        WorkProfileChangeType.ChangeOfOrganizationalStructure,
    ],
}

export enum WorkProfileActionKind {
    Create,
    Update
}
