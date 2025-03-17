import { forwardRef, Global, Module } from '@nestjs/common'
import { TypeOrmModule } from '@nestjs/typeorm'
import { CommonModule } from 'src/modules/core/common/common.module'
import { IAMModule } from 'src/modules/core/iam/iam.module'
import { StorageModule } from 'src/modules/core/storage/storage.module'
import { ProfileService } from 'src/modules/graphql/profile/profile.service'
import {
    ApprovalField,
    ApprovalForm,
    ApprovalFormField,
    ApprovalFormStep,
    ApprovalStep,
    CheckIn,
    CheckInDetail,
    CheckInPlace,
    DocumentFile,
    DocumentFolder, InfoBlock, InfoField,
    MeetingRoom,
    OfficeApproval,
    OfficeOrgChart,
    OfficePayroll, OfficeTitle, OfficeUser, OfficeUserPaycheck,
    OrgChartApprovalForm,
    OrgChartDocument, UserAddress, UserBankAccount, UserDepartment,
    WhitelistIP
} from './entities'
import {
    ApprovalFormStepFieldResolver,
    ApprovalFormFieldResolver,
    UserDepartmentFieldResolver,
    InfoFieldFieldResolver,
    InfoBlockFieldResolver,
    OrgChartFieldResolver,
    OfficeUserFieldResolver,
    UserFieldResolver,
    DocumentFolderFieldResolver,
    DocumentFileFieldResolver,
    CheckInPlaceFieldResolver,
    CheckInFieldResolver,
    CheckInDetailFieldResolver,
    FolderElementFieldResolver,
    OfficeApprovalFieldResolver,
    ApprovalStepFieldResolver
} from './resolvers'
import * as Entities from "./entities"
import * as Subscribers from "./subscribers"
import * as Notifies from "./notify"
import * as Repos from "./repositories"
import * as Resolvers from "./resolvers"
import { MeetingRoomFieldResolver } from './resolvers/meeting.room.resolver'
import { Car } from './entities/car'
import { CarBookingRequest } from './entities/car.booking.request'
import { CarBookingSchedule } from './entities/car.booking.schedule'
import { CarBookingRequestFieldResolver } from './resolvers/car.booking.request.resolver'
import { CarBookingScheduleFieldResolver } from './resolvers/car.booking.schedule.resolver'
import { CarFieldResolver } from './resolvers/car.resolver'
import { BookingMeetingRoomFieldResolver } from './resolvers/room.booking.request.resolver'
import { ApprovalTableRowData } from './entities/approval.table.row.data'
import { ApprovalTableRow } from './entities/approval.table.row'
import { ApprovalFormTableColumn } from './entities/approval.form.table.column'
import { ApprovalFormFieldFieldResolver } from './resolvers/approval.form.field.resolver'
import { OfficeShoppingRequest } from './entities/office.shopping.request'
import { ApprovalFieldFieldResolver } from './resolvers/approval.field.resolver'
import { ApprovalTableRowFieldResolver } from './resolvers/approval.table.row.resolver'
import { ShoppingRequestFieldResolver } from './resolvers/shopping.request.resolver'
import { ApprovalService } from 'src/modules/graphql/approval/approval.service'
import { OfficePermissionActionMenu } from './entities/permission.action.menu'
import { OfficeSysUser } from './entities/system.user'
import { OfficeSysUserFieldResolver } from './resolvers/sys.user.resolver'
import { ChatFirebaseModule } from "@modules/chat-firebase/chat-firebase.module";
import { NotificationCampaign } from './entities/notification.campaign'
import { NotificationCampaignFieldResolver } from './resolvers/notification.campaign.resolver'
import { NotificationSchedule } from './entities/notification.schedule'
import { isEnvDeploy } from "@helpers/environment.helper";
import { OfficeOrgChartRepo } from "@repositories/office-org-chart.repo";
import { OfficeSysUserRepo } from "@repositories/office-sys-user.repo";
import { OfficePayrollRepo } from "@repositories/payroll/office-payroll.repo";
import { OfficeUserPaycheckRepo } from "@repositories/payroll/office-user-paycheck.repo";
import { OfficeInfoBlockRepo } from "@repositories/office-info-block.repo";
import { OfficeInfoFieldRepo } from "@repositories/office-info-field.repo";
import { OfficePayrollFieldResolver } from "@models/resolvers/payroll/office-payroll.field.resolver";
import { OfficeUserRepo } from "@repositories/profile.user.repo";
import { OfficeUserPaycheckFieldResolver } from "@models/resolvers/payroll/office-user-paycheck.field.resolver";
import { ApprovalFormStepRepo } from "@repositories/approval/approval.form.step.repo";
import { WhiteListIpRepo } from "@repositories/check-in/white-list.ip.repo";
import { SearchEngineModule } from "@modules/search-engine/search-engine.module";
import { DataSource } from "typeorm";
import { TypeOrmModuleOptions } from "@nestjs/typeorm/dist/interfaces/typeorm-options.interface";
import { DataSourceOptions } from "typeorm/data-source/DataSourceOptions";
import { CallRecord } from './entities/rtc/call.record'
import { CallParticipant } from './entities/rtc/call.participant'
import { CallRecordFieldResolver } from './resolvers/rtc/call.record.resolver'
import { DefaultAvatar } from './entities/default.avatar'
import { LogModule } from "@modules/graphql/log/log.module";
import { WorkProfileModule } from "@modules/graphql/management/work-profile/work-profile.module";
import { TaskLogModule } from "@modules/graphql/task/task-log/task-log.module";
import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { ChatConversationMemberRepo } from './repositories/chat/conversation-member.chat.repo'
import { DocumentModule } from "@modules/graphql/management/document/document.module";

const SQL_INSTANCES = (isEnvDeploy && false)
    ? {
        replication: {
            master: {
                host: process.env.DATABASE_HOST,
                port: Number(process.env.DATABASE_PORT),
                username: process.env.DATABASE_USERNAME,
                password: process.env.DATABASE_PASSWORD,
                database: process.env.DATABASE_NAME,
            },
            slaves: [
                {
                    host: process.env.GCE_LOAD_BALANCER_INSTANCE_PRIVATE_IP,
                    port: Number(process.env.DATABASE_PORT),
                    username: process.env.DATABASE_USERNAME,
                    password: process.env.DATABASE_PASSWORD,
                    database: process.env.DATABASE_NAME,
                }
            ]
        },
    }
    : {
        host: process.env.DATABASE_HOST,
        port: Number(process.env.DATABASE_PORT),
        username: process.env.DATABASE_USERNAME,
        password: process.env.DATABASE_PASSWORD,
        database: process.env.DATABASE_NAME,
    }

@Module({
    imports: [
        TypeOrmModule.forRoot({
            type: 'postgres',
            poolSize: 15,
            schema: process.env.DATABASE_SCHEMA,
            ssl: process.env.CLOUD_PLATFORM !== 'AMAZON',
            ...SQL_INSTANCES,
            synchronize: process.env.DATABASE_SYNCHRONIZE == "true" ? true : false,
            entities: [
                // ...CommonEntities,
                // ...bitrixEntities,
                // ...saleEntities,
                // ...managementEntities,
                // ...serviceEntities,
                // ...warehouseEntities,
                // ...socialNetworkEntities
                // ...Object.values(entities)
                InfoBlock,
                InfoField,
                OfficeTitle,
                OfficeUser,
                DefaultAvatar,
                OfficeOrgChart,
                OfficeSysUser,
                OfficePermissionActionMenu,
                NotificationCampaign,
                NotificationSchedule,
                UserAddress,
                UserBankAccount,
                UserDepartment,
                ApprovalForm,
                ApprovalFormField,
                ApprovalFormStep,
                OrgChartApprovalForm,
                OrgChartDocument,
                DocumentFolder,
                DocumentFile,
                CheckInPlace,
                WhitelistIP,
                CheckIn,
                CheckInDetail,
                OfficeApproval,
                OfficeShoppingRequest,
                ApprovalFormTableColumn,
                ApprovalTableRow,
                ApprovalTableRowData,
                ApprovalField,
                ApprovalStep,
                CallRecord,
                CallParticipant,
                Car,
                CarBookingRequest,
                CarBookingSchedule,
                ...Object.values(Entities)
            ]
        }),
        forwardRef(() => CommonModule),
        forwardRef(() => StorageModule),
        forwardRef(() => IAMModule),
        // TypeOrmModule.forFeature([InfoBlock])
        forwardRef(() => ChatFirebaseModule),
        forwardRef(() => SearchEngineModule),
        forwardRef(() => LogModule),
        forwardRef(() => WorkProfileModule),
        forwardRef(() => TaskLogModule),
        forwardRef(() => DocumentModule),
        TypeOrmModule.forFeature([
            ...Object.values(Entities)
        ]),
        CommonModule
    ],
    providers: [
        {
            provide: DynamoDBClient,
            useFactory: () => {
                return new DynamoDBClient({
                    region: process.env.AWS_DYNAMO_DB_REGION,
                    credentials: {
                        accessKeyId: process.env.AWS_IAM_ACCESS_KEY_ID,
                        secretAccessKey: process.env.AWS_IAM_ACCESS_KEY_SECRET,
                    },
                });
            },
            inject: [],
        },
        ApprovalService,
        // ...saleFieldResolvers,
        // ...managementFieldResolvers,
        // ...serviceFieldResolvers,
        // ...warehouseFieldResolvers
        // ...Object.values(resolvers),
        InfoFieldFieldResolver,
        InfoBlockFieldResolver,
        OfficeUserFieldResolver,
        OfficeSysUserFieldResolver,
        OrgChartFieldResolver,
        UserFieldResolver,
        UserDepartmentFieldResolver,
        ApprovalFormFieldResolver,
        ApprovalFormStepFieldResolver,
        ApprovalFormFieldFieldResolver,
        ApprovalFieldFieldResolver,
        ApprovalTableRowFieldResolver,
        ShoppingRequestFieldResolver,
        DocumentFolderFieldResolver,
        DocumentFileFieldResolver,
        NotificationCampaignFieldResolver,
        CheckInPlaceFieldResolver,
        CheckInFieldResolver,
        CheckInDetailFieldResolver,
        FolderElementFieldResolver,
        OfficeApprovalFieldResolver,
        ApprovalStepFieldResolver,
        ProfileService,
        MeetingRoomFieldResolver,
        CarFieldResolver,
        CarBookingRequestFieldResolver,
        BookingMeetingRoomFieldResolver,
        CarBookingScheduleFieldResolver,
        CallRecordFieldResolver,
        OfficePayrollFieldResolver,
        OfficeUserPaycheckFieldResolver,
        OfficeOrgChartRepo,
        OfficeSysUserRepo,
        OfficePayrollRepo,
        OfficeUserPaycheckRepo,
        OfficeInfoBlockRepo,
        OfficeInfoFieldRepo,
        ApprovalFormStepRepo,
        WhiteListIpRepo,
        ChatConversationMemberRepo,
        ...Object.values(Subscribers),
        ...Object.values(Notifies),
        ...Object.values(Repos),
        ...Object.values(Resolvers),
    ],
    exports: [...Object.values(Repos)]
})
export class ModelModule {
}
