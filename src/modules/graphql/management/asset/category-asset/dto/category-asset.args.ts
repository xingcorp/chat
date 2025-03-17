import { Field, InputType, Int } from "@nestjs/graphql";
import { ValidateIf } from "class-validator";
import { IsExistUserDbValidate } from "@decorators/validation/db/user/is-exist.user.db.validate";
import { DatePeriod } from "@common/args.common";

@InputType()
export class ManagementCategoryAssetFilter {
    @Field(() => Int, {nullable: true})
    page: number

    @Field(() => Int, {nullable: true})
    size: number

/*    @Field({ nullable: true })
    keyword: string*/
}