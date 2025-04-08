import { forwardRef, Module } from "@nestjs/common"
import { IAMModule } from "../iam/iam.module"
import { FactoryGraphQlClient } from "./factory.client"
import { FactoryResolver } from "./factory.resolver"
import { FactoryService } from "./factory.service"

@Module({
    imports: [
        forwardRef(() => IAMModule)
    ],
    providers: [
        FactoryResolver,
        FactoryService,
        FactoryGraphQlClient
    ],
    exports: [
        FactoryService
    ]
})
export class FactoryModule { }