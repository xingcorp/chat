import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo'
import { MiddlewareConsumer, Module } from '@nestjs/common'
import { GraphQLModule } from '@nestjs/graphql'
import { ModelModule } from './models/model.module'
import { AwsSdkModule } from 'nest-aws-sdk'
import { ProfileModule } from './modules/graphql/profile/profile.module'
import { EmployeeModule } from './modules/graphql/management/employee/employee.module'
import { OrgChartModule } from './modules/graphql/management/orgchart/orgchart.module'
import GraphQLJSON from 'graphql-type-json'
import { ApprovalModule } from './modules/graphql/approval/approval.module'
import { DocumentModule } from './modules/graphql/management/document/document.module'
import { CheckInModule } from './modules/graphql/checkin/checkin.module'
import { MeetingRoomModule } from './modules/graphql/management/meeting-room/meeting.room.module'
import { BookingModule } from './modules/graphql/booking/booking.module'
import { DynamooseModule } from 'nestjs-dynamoose'
import { CarModule } from './modules/graphql/management/car/car.module'
import { PermissionModule } from './modules/graphql/management/permission/permission.module'
import { ChatFirebaseModule } from '@modules/chat-firebase/chat-firebase.module';
import { ServicesModule } from './modules/services/services.module';
import { WorkingShiftModule } from './modules/graphql/management/working-shift/working-shift.module';
import { SqlScalingModule } from './modules/sql-scaling/sql-scaling.module';
import { PayrollModule } from './modules/graphql/management/payroll/payroll.module';
import { UserPaycheckModule } from './modules/graphql/management/user-paycheck/user-paycheck.module';
import { RequestContextMiddleware } from "@middlewares/request-context.middleware";
import { RequestMethod } from "@nestjs/common/enums/request-method.enum";
import { RTCModule } from '@modules/graphql/rtc/rtc.module'
import { SearchEngineModule } from './modules/search-engine/search-engine.module';
import { ChatModule } from './modules/chat/chat.module';
import { TaskModule } from '@modules/graphql/task/task/task.module';
import { TaskLogModule } from './modules/graphql/task/task-log/task-log.module';
import { LogModule } from './modules/graphql/log/log.module';
import { WorkProfileModule } from './modules/graphql/management/work-profile/work-profile.module';
import { MasterDataModule } from './modules/graphql/master-data/master-data.module';
import { CronJobModule } from './modules/cron-job/cron-job.module';
import { CustomIntOrAIntScalar } from "@helpers/scalar/graphql/int-or-array-of-int.graphql.scalar";
import { AssetModule } from '@modules/graphql/management/asset/asset/asset.module';
import { CategoryAssetModule } from './modules/graphql/management/asset/category-asset/category-asset.module';
import { WarehouseAssetModule } from './modules/graphql/management/asset/warehouse-asset/warehouse-asset.module';
import { ApprovalFromGroupModule } from './modules/graphql/management/approval/approval-from-group/approval-from-group.module';
import { BullModule } from '@nestjs/bull'
import { OrganizationDeviceModule } from '@modules/graphql/organization-devices/organization.device.module'
import { WikiModule } from './modules/graphql/management/wiki/wiki.module';
import { AdminModule } from './modules/graphql/management/admin/admin.module';
import { ViewerModule } from './modules/graphql/viewer/viewer.module';
import { LearningModule } from '@modules/graphql/learning/learning.module';
import { ValidatorModule } from '@decorators/validation/validator.module'
import { RequestContext } from '@common/context/request.context'
import { LoggerService } from '@core/common/logger.service'
@Module({
  imports: [
    GraphQLModule.forRoot<ApolloDriverConfig>({
      driver: ApolloDriver,
      autoSchemaFile: true,
      sortSchema: true,
      context: ({ req, connection, res, payload, extra }) => {
        return {
          req,
          res,
          payload,
          connection,
          extra
        }
      },
      subscriptions: {
        // "graphql-ws": {
        //   onConnect: (context: Context<any>) => {
        //     const { connectionParams, extra } = context;
        //     extra.req = { ...connectionParams };
        //   },
        //   // connectionInitWaitTimeout: Infinity
        // },
        "subscriptions-transport-ws": {
          onConnect: (connectionParams) => {
            return { extra: { ...connectionParams } }
          }
        }
      },
      resolvers: {
        JSON: GraphQLJSON,
        IntOrAInt: CustomIntOrAIntScalar
      },
      formatError: (error) => {
        logger.error('[Exception]', JSON.stringify(error));
        try {
          const messageDict = JSON.parse(error.message)
          if (messageDict) {
            return {
              code: messageDict.code || "500",
              message: messageDict.message || "Unexpected error message",
              extensions: {
                code: messageDict.code,
                message: messageDict.message,
                ...messageDict.extensions
              },
              requestId: RequestContext && RequestContext.requestId()
            }
          }
        } catch (e) {}

        return {
          code: error.extensions?.code || "500",
          message: error.message,
          extensions: error.extensions,
          requestId: RequestContext && RequestContext.requestId()
        }
      },
      // plugins: [
      //   {
      //     async requestDidStart(requestContext: GraphQLRequestContext) {
      //       try {
      //         const request: any = requestContext.request
      //         request.requestDidStart = new Date()
      //         return {
      //           async willSendResponse(requestContext: GraphQLRequestContext) {
      //             try {
      //               const request: any = requestContext.request
      //               request.willSendResponse = new Date()
      //               console.log(`[RequestStatistic]:[GraphQL] ${request.operationName} -> ${JSON.stringify({
      //                 sourceIP: requestContext.context?.req?.ip || 'unknow',
      //                 didStart: request.requestDidStart?.getTime() || 0,
      //                 sendResponse: request.willSendResponse?.getTime() || 0,
      //                 processTime: request.willSendResponse.getTime() - request.requestDidStart.getTime()
      //               })}`)
      //             } catch (error) {
      //               console.log(`[RequestStatistic]:[GraphQL] willSendResponse has error: ${error}`)
      //             }
      //           },
      //         }
      //       } catch (error) {
      //         console.log(`[RequestStatistic]:[GraphQL] requestDidStart has error: ${error}`)
      //       }
      //     },
      //   }
      // ]
    }),
    AwsSdkModule.forRootAsync({
      defaultServiceOptions: {
        useValue: {
          region: process.env.AWS_S3_REGION,
          credentials: {
            accessKeyId: process.env.AWS_IAM_ACCESS_KEY_ID,
            secretAccessKey: process.env.AWS_IAM_ACCESS_KEY_SECRET
          }
        }
      }
    }),
    DynamooseModule.forRoot({
      aws: {
        accessKeyId: process.env.AWS_IAM_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_IAM_ACCESS_KEY_SECRET,
        region: process.env.AWS_DYNAMO_DB_REGION
      },
      table: {
        create: true,
        prefix: `${process.env.SERVICE_CODE}-${process.env.STAGE}-`,
        suffix: `-table`
      }
    }),
    BullModule.forRoot({
      redis: {
        host: process.env.REDIS_HOST,
        port: Number(process.env.REDIS_PORT),
        password: process.env.REDIS_PASSWORD
      }
    }),
    // CoreModule,
    ModelModule,
    ProfileModule,
    EmployeeModule,
    OrgChartModule,
    PermissionModule,
    ApprovalModule,
    DocumentModule,
    CheckInModule,
    MeetingRoomModule,
    BookingModule,
    CarModule,
    ChatFirebaseModule,
    ServicesModule,
    WorkingShiftModule,
    SqlScalingModule,
    PayrollModule,
    RTCModule,
    UserPaycheckModule,
    SearchEngineModule,
    ChatModule,
    TaskModule,
    TaskLogModule,
    LogModule,
    WorkProfileModule,
    MasterDataModule,
    CronJobModule,
    AssetModule,
    CategoryAssetModule,
    WarehouseAssetModule,
    ApprovalFromGroupModule,
    WarehouseAssetModule,
    WikiModule,
    AdminModule,
    WarehouseAssetModule,
    OrganizationDeviceModule,
    ViewerModule,
    LearningModule,
    ValidatorModule.register()
  ],
  controllers: [],
  providers: [],
  exports: []
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(RequestContextMiddleware)
      .forRoutes({
        path: "*",
        method: RequestMethod.POST,
      })
  }
}
const logger = new LoggerService(AppModule.name)
