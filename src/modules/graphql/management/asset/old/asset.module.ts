import { forwardRef, Module } from "@nestjs/common";
import { IAMModule } from "@core/iam/iam.module";
import { StorageModule } from "@core/storage/storage.module";
// import { AssetResolver } from "./asset.resolver";
import { AssetServiceOld } from "./asset.service";
import { AwsQLDBService } from "@modules/3rd/aws/qldb.service";
import { DynamooseModule } from "nestjs-dynamoose";
import { NfcHistorySchema } from "@modules/graphql/management/asset/old/schema/nfc.history.schema";

@Module({
    imports: [
        forwardRef(() => IAMModule),
        forwardRef(() => StorageModule),
        DynamooseModule.forFeature([
            {
                name: 'nfc-history',
                schema: NfcHistorySchema,
            },
        ]),
    ],
    providers: [
        // AssetResolver,
        AssetServiceOld,
        AwsQLDBService
    ],
    exports: []
})
export class AssetOldModule { }