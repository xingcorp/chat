import { Field, Float, Int, ObjectType } from "@nestjs/graphql"
import {
    AfterInsert,
    AfterUpdate,
    BaseEntity,
    BeforeInsert,
    BeforeUpdate,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity,
    Generated, ILike,
    JoinColumn, ManyToMany,
    ManyToOne, OneToMany,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm"
import { ObjectStatus } from "./profile.info.block"
import { OfficeOrgChart } from "./org.chart"
import { OfficeError } from "@common/office.error"
import { getCompanyByDepartmentId } from "@modules/graphql/management/orgchart/helpers/orgchart.helpers";
import { stringNumberWithZeroLeading } from "@utils/string.utils";
import { OfficeUserPaycheck } from "@models/entities/payroll/user.paycheck";
import { OfficeChatConversationMember } from "@models/entities/chat/conversation-member.chat";
import { OfficeChatMessage } from "@models/entities/chat/message.chat";
import { OfficeChatMessageReader } from "@models/entities/chat/message-reader.chat";
import { OfficeTask } from "@models/entities/task/task";
import { OfficeTaskLog } from "@models/entities/task/log.task";
import { OfficeChatMessageReaction } from "@models/entities/chat/message.reaction.chat";
import { OfficeLogs } from "@models/entities/logs/office-logs";
import { UserWorkProfile } from "@models/entities/work-profile/work-profile";
import { UserWorkProfileDetail } from "@models/entities/work-profile/detail.work-profile";
import { Asset } from "@models/entities/asset/asset";
import { AssignmentAsset } from "@models/entities/asset/assignment.asset";
import { ApprovalForm } from "./approval.form"
import { OfficeApproval } from "@models/entities/approval";
import { OfficeChatConversation } from "./chat/conversation.chat"
import { OrganizationDevice } from "./organization.device"
import { LearnStudent } from "./learning/student.learn"
import { LearnCourse } from "./learning/course.learn"

@ObjectType()
@Entity("office-users")
// @Unique(["code"])
export class OfficeUser extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    // @Generated('increment')
    rtcUserId: number

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: false })
    // @Generated('increment')
    no: number

    @Field(_type => Float, { nullable: true }) //Ngày sinh
    @Column({ nullable: true })
    dateOfBirth: Date

    @Field(_type => Int, { nullable: true }) //Độ tuổi
    @Column({ nullable: true })
    age: number

    @Field(_type => String, { nullable: true }) //Họ tên
    @Column({ nullable: false })
    fullname: string

    @Field(_type => String, { nullable: true }) //Mã nhân viên
    @Column({ nullable: true })
    code: string

    @Field(_type => String, { nullable: true }) //Mã chấm công
    @Column({ nullable: true })
    hrCode: string

    @Field(_type => String, { nullable: true }) //Ngạch bậc
    @Column({ nullable: true })
    major: string

    @Field(_type => String, { nullable: true }) //Số điện thoại
    @Column({ nullable: false })
    phone: string

    @Field(_type => String, { nullable: true }) //Email công ty
    @Column({ nullable: true })
    email: string

    @Field(_type => String, { nullable: true }) //Email cá nhân
    @Column({ nullable: true })
    personalEmail: string

    @Field(_type => String, { nullable: true }) //Email cá nhân
    @Column({ nullable: true })
    identityCard: string

    @Field(_type => Float, { nullable: true }) //Ngày cấp CMND
    @Column({ nullable: true })
    idCardIssuedOn: Date

    @Field(_type => String, { nullable: true }) //Nơi cấp CMND
    @Column({ nullable: true })
    idCardIssuedPlace: string

    @Field(_type => String, { nullable: true }) //Mã bảo hiểm xã hội
    @Column({ nullable: true })
    socialInsuranceCode: string

    @Field(_type => String, { nullable: true }) //Mã số thuế
    @Column({ nullable: true })
    taxCode: string

    @Field(_type => String, { nullable: true }) //Số điện thoại người thân
    @Column({ nullable: true })
    relativePhone: string

    @Field(_type => ObjectStatus, { nullable: true })
    @Column({ nullable: false, type: 'enum', enum: ObjectStatus, default: ObjectStatus.Active })
    status: ObjectStatus

    @Column('text', { nullable: true, array: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    imageUrls: string[]

    @Column('text', { nullable: true, array: true })
    attachFileIds: string[]

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    attachFileUrls: string[]

    @Column({ nullable: false })
    iamUserId: string

    @Column('simple-array', { nullable: true })
    iamUserUsedIds: string[]

    @Column({ nullable: true })
    leaderId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

    @Column('text', { array: true, nullable: true })
    metadata: string[]

    @Field(_type => Float, { nullable: true }) //Ngày vào công ty
    @Column({ nullable: true })
    onboardingOn: Date

    @Field(_type => Float, { nullable: true }) //Ngày hiệu lực thôi việc
    @Column({ nullable: true, default: new Date('12/31/9999') })
    leaveOn: Date

    @Field(_type => Float, { nullable: true }) //Ngày chính thức làm việc
    @Column({ nullable: true })
    officalWorkingOn: Date

    @Field({ nullable: true, defaultValue: false }) //Thôi việc
    @Column({ nullable: false, default: false })
    resigned: boolean

    @Field(_type => Float, { nullable: true }) //Ngày làm việc cuối cùng
    @Column({ nullable: true })
    lastWorkingOn: Date

    @Field(_type => String, { nullable: true }) //Loại thôi việc
    @Column({ nullable: true })
    resignationType: string

    @Field(_type => String, { nullable: true }) //Lý do thôi việc
    @Column({ nullable: true })
    resignationReason: string

    @Field(_type => String, { nullable: true }) //Diễn giải lý do thôi việc
    @Column({ nullable: true })
    resignationDetailReason: string

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    lastLoginAt: Date

    @Field(_type => Float, { nullable: true })
    @CreateDateColumn()
    createdAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field(_type => Float, { nullable: true })
    @UpdateDateColumn()
    updatedAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date

    @ManyToOne(() => OfficeOrgChart, { nullable: true })
    @JoinColumn()
    company: OfficeOrgChart

    @Column({ nullable: true })
    companyId: string

    @Field(_type => [OfficeUserPaycheck], { nullable: true })
    @OneToMany(() => OfficeUserPaycheck, (ob) => ob.user)
    paychecks: OfficeUserPaycheck[]

    @Field(_type => OfficeChatConversationMember, { nullable: true })
    @OneToMany(() => OfficeChatConversationMember, (ob) => ob.user)
    conversations: OfficeChatConversationMember[]

    @Field(_type => OfficeChatConversation, { nullable: true })
    @OneToMany(() => OfficeChatConversation, (ob) => ob.creator)
    creatorConversation: OfficeChatConversation[]

    @Field(_type => [OfficeChatMessageReader], { nullable: true })
    @OneToMany(() => OfficeChatMessageReader, (ob) => ob.user)
    messagesReader: OfficeChatMessageReader[]

    @Field(_type => [OfficeTask], { nullable: true })
    @OneToMany(() => OfficeTask, (ob) => ob.reporter)
    tasksCreated: OfficeTask[]

    @Field(_type => [OfficeTask], { nullable: true })
    @OneToMany(() => OfficeTask, (ob) => ob.assigned)
    tasksAssigned: OfficeTask[]

    @Field(_type => [OfficeTask], { nullable: true })
    @ManyToMany(() => OfficeTask, (ob) => ob.watchers)
    taskWatchers: OfficeTask[]

    @Field(_type => [OfficeTaskLog], { nullable: true })
    @OneToMany(() => OfficeTaskLog, (ob) => ob.creator)
    tasksLog: OfficeTaskLog[]

    @Field(_type => [OfficeLogs], { nullable: true })
    @OneToMany(() => OfficeLogs, (ob) => ob.userCreator)
    logs: OfficeLogs[]

    @Field(_type => [OfficeChatMessageReaction], { nullable: true })
    reactions: OfficeChatMessageReaction[]

    // @Field(_type => [UserWorkProfile], { nullable: true })
    @OneToMany(() => UserWorkProfile, (ob) => ob.user)
    workProfiles: UserWorkProfile[]

    // @Field(_type => [UserWorkProfileDetail], { nullable: true })
    @OneToMany(() => UserWorkProfileDetail, (ob) => ob.leader)
    mentees: UserWorkProfileDetail[]

    @Field(_type => [ApprovalForm], { nullable: true })
    @ManyToMany(() => ApprovalForm, (ob) => ob.users)
    approvalForms: ApprovalForm[]

    @Field(_type => [Asset], { nullable: true })
    @OneToMany(() => Asset, (ob) => ob.department)
    assetsManagement: Asset[]

    @Field(_type => [Asset], { nullable: true })
    @OneToMany(() => Asset, (ob) => ob.assignedUser)
    assetsAssigned: Asset[]

    @Field(_type => [LearnStudent], { nullable: true })
    @OneToMany(() => LearnStudent, (ob) => ob.user)
    learnStudents: LearnStudent[]

    @Field(_type => [LearnCourse], { nullable: true })
    @OneToMany(() => LearnCourse, (ob) => ob.teacher)
    courses: LearnCourse[]

    @Field(_type => [OfficeApproval], { nullable: true })
    @ManyToMany(() => OfficeApproval, (ob) => ob.readBy)
    approvalsRead: OfficeApproval[]

    @BeforeInsert()
    async assignCompanyId() {
        const company = await getCompanyByDepartmentId(this.companyId)

        if (!company) {
            throw OfficeError.OrgChartNotFound;
        }

        this.companyId = company.id
    }

    @BeforeInsert()
    // @BeforeUpdate()
    async assignCode() {
        if (!this.no) {
            const qb = await OfficeUser.createQueryBuilder('qb')
                .orderBy('qb.no', 'DESC')
                .getOne()

            this.no = qb?.no ? qb.no + 1 : 1
        }

        if (!this.code) {
            const company = await OfficeOrgChart.findOne({ where: { id: this.companyId } })

            let lastOrgUser = await OfficeUser.findOne({
                where: {
                    companyId: company.id
                },
                order: {
                    code: 'DESC'
                }
            })

            if (lastOrgUser) {
                lastOrgUser = await OfficeUser.findOne({
                    where: {
                        code: ILike(`${company.code}%`)
                    },
                    order: {
                        code: 'DESC'
                    }
                })
            }

            const numberLength = 7
            let currentNumber = parseInt(lastOrgUser ? lastOrgUser.code.slice(-numberLength).replace(/\D/g, "") : '0')

            let check = true
            while (check) {
                currentNumber = currentNumber + 1
                this.code = `${company.code}${stringNumberWithZeroLeading(currentNumber, numberLength)}`
                check = !!(await OfficeUser.count({
                    where: {
                        code: this.code
                    }
                }))
            }

        }
    }

    @BeforeInsert()
    @BeforeUpdate()
    async calculateAge() {
        if (!this.dateOfBirth) {
            return
        }
        const today = new Date();
        const birthDate = this.dateOfBirth;
        let age = today.getFullYear() - birthDate.getFullYear();
        const m = today.getMonth() - birthDate.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
            age--;
        }
        this.age = age;
    }

    @BeforeInsert()
    @BeforeUpdate()
    async updateResignedData() {
        if (this.resigned === false) {
            this.lastWorkingOn = null
            this.leaveOn = null
            this.resignationType = null
            this.resignationReason = null
            this.resignationDetailReason = null
        }

        if (
            this.resigned === true
            && this.status === ObjectStatus.Active
            && this.leaveOn <= new Date()
        ) {
            this.status = ObjectStatus.Inactive
        }

        /*if (this.resigned === false) {
            this.status = ObjectStatus.Active
        }*/
    }
}