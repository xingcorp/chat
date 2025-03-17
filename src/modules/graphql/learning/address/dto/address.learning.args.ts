import { DefaultFilterInput } from "@common/args.common";
import { IsExistAddressLearningDbValidate } from "@decorators/validation/db/learning/address/is-exist.address.learning.db.validate";
import { IsNameNotExistAddressLearningDbValidate } from "@decorators/validation/db/learning/address/is-name-not-exits.address.learning.db.validate";
import { LearnAddress } from "@models/entities";
import { Field, InputType } from "@nestjs/graphql";
import { ValidateIf } from "class-validator";

@InputType()
export class AddressLearningFilterInput extends DefaultFilterInput {}

@InputType()
export class LearningAddressCreateInput {
    @Field(_type => String, {nullable: false})
    @IsNameNotExistAddressLearningDbValidate()
    name: string
}

@InputType()
export class LearningAddressUpdateInput extends LearningAddressCreateInput {
    @Field(_type => String, { nullable: true })
    @IsExistAddressLearningDbValidate()
    addressId: string

    address?: LearnAddress
}

@InputType()
export class LearningAddressUpsertInput extends LearningAddressUpdateInput {
    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.addressId)
    @IsExistAddressLearningDbValidate()
    addressId: string
}