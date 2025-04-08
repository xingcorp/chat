import { Module } from "@nestjs/common";
import { AddressLearningService } from "./address.learning.service";
import { AddressLearningResolver } from "./address.learning.resolver";
import { ModelModule } from "@models/model.module";

@Module({
    imports: [ModelModule],
    providers: [
        AddressLearningService,
        AddressLearningResolver,
    ]
})
export class AddressLearningModule { }