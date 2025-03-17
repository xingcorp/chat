import { Module } from '@nestjs/common';
import { ChatFirebaseService } from './chat-firebase.service';
import { ChatFirebaseResolver } from './chat-firebase.resolver';
import { ObjectStoreModule } from "@service-modules/object-store/object-store.module";
import { FirebaseModule } from "@service-modules/firebase/firebase.module";
import { TypeOrmModule } from "@nestjs/typeorm";
import { OfficeUser } from "@models/entities";
import { ChatFirebaseController } from './chat-firebase.controller';
import { OfficeOrgChartRepo, OfficeSysUserRepo, OfficeUserRepo } from "@models/repositories";
import { AlgoliaService } from "@modules/search-engine/algolia.service";
import { ThrottlerModule } from '@nestjs/throttler';

@Module({
    imports: [
        ObjectStoreModule,
        FirebaseModule,
        TypeOrmModule.forFeature([
            OfficeUser
        ]),
        ThrottlerModule.forRoot([{
            ttl: 60000,
            limit: 10,
        }])
    ],
    providers: [
        ChatFirebaseService,
        ChatFirebaseResolver,
        OfficeUserRepo,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
        {
            provide: 'SearchEngineFirebaseService',
            useClass: AlgoliaService
        }
    ],
    exports: [
        ChatFirebaseService
    ],
    controllers: [ChatFirebaseController]
})
export class ChatFirebaseModule {
}
