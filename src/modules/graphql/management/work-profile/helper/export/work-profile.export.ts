import * as ExcelJS from "exceljs";
import { UserWorkProfile } from "@models/entities";
import { WorkProfileChangeTypeExplain } from "@enum/work-profile/work-profile.enum";
import { datetimeGetFormat } from "@utils/datetime.utils";
import { LangVi } from "@utils/lang";

export function exportWorkProfileData(chartSheet: ExcelJS.Worksheet, data?: UserWorkProfile[]) {
    for (const row of data) {
        chartSheet.addRow({
            ...row.detail,
            ...row.info,
            ...row,
            id: row.id,
            userCodeUpdate: row.detail.userCode,
            typeText: WorkProfileChangeTypeExplain[row.info.type],
            activeDate: datetimeGetFormat("DD/MM/YYYY", row.info.activeDate),
            // reason: "Lý do thay đổi",
            decided: row.info.isDecided ? LangVi.YES : LangVi.NO,
            // decidedNumber: "QDD214123-123",
            decidedDate: datetimeGetFormat("DD/MM/YYYY", row.info.decidedDate),
            // userCode: "U123412",
            title: row.detail?.title?.name,
            department: row.detail?.department?.name,
            leader: row.detail?.leader?.fullname,
            major: row.detail.major,
            note: row.info.note,
            ...row.detail.metadata
        })
    }
}