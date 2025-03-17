import { OfficeOrgChartRepo } from "./office-org-chart.repo"
import { OfficeSysUserRepo } from "./office-sys-user.repo"
import { OfficePayrollRepo } from "./payroll/office-payroll.repo"
import { OfficeUserPaycheckRepo } from "./payroll/office-user-paycheck.repo"
import { OfficeInfoBlockRepo } from "./office-info-block.repo"
import { OfficeInfoFieldRepo } from "./office-info-field.repo"
import { OfficeUserRepo } from "./profile.user.repo"
import { ApprovalFormStepRepo } from "./approval/approval.form.step.repo"
import { WhiteListIpRepo } from "./check-in/white-list.ip.repo"
import { ChatConversationRepo } from "./chat/conversation.chat.repo"
import { ChatConversationMemberRepo } from "./chat/conversation-member.chat.repo"
import { ChatMessageRepo } from "./chat/message.chat.repo"
import { ChatMessageReaderRepo } from "./chat/message-reader.chat.repo"
import { ReactionMessageChatRepo } from "./chat/reaction.message.chat.repo"
import { OfficeObjectRepo } from "./object-store/office-object.repo"
import { OfficeTaskRepo } from "./task/task.repo"
import { OfficeTaskProjectRepo } from "./task/project.task.repo"
import { OfficeTaskLogRepo } from "./task/log.task.repo"
import { BookingMeetingRoomRepo } from "./book-room/booking.meeting.room.repo"
import { MeetingRoomScheduleRepo } from "./book-room/meeting.room.schedule.repo"
import { NotificationCampaignRepo } from "./notification/notification.campaign.repo"
import { BookingCarScheduleRepo } from "./book-car/booking.car.schedule.repo"
import { OfficeLogRepo } from "./office-log/office-log.repo"
import { OfficeApprovalRepo } from "./approval/approval.repo"
import { CarRepo } from "./car/car.repo"
import { ApprovalStepRepo } from "./approval/approval.step.repo"
import { WorkProfileRepo } from "./work-profile/work-profile.repo"
import { InfoWorkProfileRepo } from "./work-profile/info.work-profile.repo"
import { DetailWorkProfileRepo } from "./work-profile/detail.work-profile.repo"
import { TitleRepo } from "./title/title.repo"
import { UserDepartmentRepo } from "./user/department.user.repo"
import { AssetRepo } from "./asset/asset.repo"
import { CategoryAssetRepo } from "./asset/category.asset.repo"
import { WarehouseAssetRepo } from "./asset/warehouse.asset.repo"
import { ApprovalFormRepo } from "./approval/approval.form.repo"
import { FilterRepo } from "./filter/filter.repo"
import { DateCloneRepo } from "./clone/date.clone.repo"
import { ApprovalFormGroupRepo } from "./approval/approval.form.group.repo"
import { ApprovalForwardRepo } from "./approval/approval.forward.repo"
import { ApprovalForwardUserRepo } from "./approval/approval.forward.user.repo"
import { FolderDocumentRepo } from "./document/folder/folder.document.repo"
import { WikiRepo } from "./wiki/wiki.repo"
import { VersionWikiRepo } from "./wiki/version.wiki.repo"
import { CategoryWikiRepo } from "./wiki/category.wiki.repo"
import { ViewerRepo } from "./viewer/viewer.repo"
import { TagDocumentRepo } from "./document/tag/tag.document.repo"
import { CertificateLearningRepo } from "./learning/certificate.learning.repo"
import { CourseLearningRepo } from "./learning/course.learning.repo"
import { LessonLearningRepo } from "./learning/lesson.learning.repo"
import { ProjectLearningRepo } from "./learning/project.learning.repo"
import { SectionLearningRepo } from "./learning/section.learning.repo"
import { SkillLearningRepo } from "./learning/skill.learning.repo"
import { RequirementLearningRepo } from "./learning/requirement.learning.repo"
import { ExaminationLearningRepo } from "./learning/examination.learning.repo"
import { StudentLearningRepo } from "./learning/student.learning.repo"
import { UserScheduleRepo } from "./user/schedule.user.repo"
import { AddressLearningRepo } from "./learning/address.learning.repo"
import { LearningUserPinnedRepo } from "./learning/pinned.learning.repo"

export {
    OfficeOrgChartRepo,
    OfficeSysUserRepo,
    OfficePayrollRepo,
    OfficeUserPaycheckRepo,
    OfficeInfoBlockRepo,
    OfficeInfoFieldRepo,
    OfficeUserRepo,
    ApprovalFormStepRepo,
    WhiteListIpRepo,
    ChatConversationRepo,
    ChatConversationMemberRepo,
    ChatMessageRepo,
    ChatMessageReaderRepo,
    ReactionMessageChatRepo,
    OfficeObjectRepo,
    OfficeTaskRepo,
    OfficeTaskProjectRepo,
    OfficeTaskLogRepo,
    BookingMeetingRoomRepo,
    MeetingRoomScheduleRepo,
    NotificationCampaignRepo,
    BookingCarScheduleRepo,
    OfficeLogRepo,
    OfficeApprovalRepo,
    CarRepo,
    ApprovalStepRepo,
    WorkProfileRepo,
    InfoWorkProfileRepo,
    DetailWorkProfileRepo,
    TitleRepo,
    UserDepartmentRepo,
    AssetRepo,
    CategoryAssetRepo,
    WarehouseAssetRepo,
    ApprovalFormRepo,
    FilterRepo,
    DateCloneRepo,
    ApprovalFormGroupRepo,
    ApprovalForwardRepo,
    ApprovalForwardUserRepo,
    FolderDocumentRepo,
    WikiRepo,
    VersionWikiRepo,
    CategoryWikiRepo,
    ViewerRepo,
    TagDocumentRepo,
    CertificateLearningRepo,
    CourseLearningRepo,
    LessonLearningRepo,
    ProjectLearningRepo,
    SectionLearningRepo,
    SkillLearningRepo,
    AddressLearningRepo,
    RequirementLearningRepo,
    ExaminationLearningRepo,
    StudentLearningRepo,
    UserScheduleRepo,
    LearningUserPinnedRepo,
}