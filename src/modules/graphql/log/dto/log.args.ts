import { OfficeFeatureLogType } from "@enum/logs/logs.enum";
import { OfficeLogData } from "../../../../arguments/logs/office-logs.args";

export class OfficeLogCommentArgs {
    featureLogType?: OfficeFeatureLogType

    description?: string

    featureLogId: string

    attachmentIds?: string[]

    imageIds?: string[]
}

export class OfficeLogHistoryArgs {
    featureLogType: OfficeFeatureLogType

    featureLogId: string

    logs: OfficeLogData[]
}