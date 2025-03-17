import { Resolver } from "@nestjs/graphql";

import { AddressLearningRepo } from "@models/repositories/learning/address.learning.repo";
import { LearnAddress } from "@models/entities/learning/address.learn";

@Resolver(_of => LearnAddress)
export class AddressLearningResolver {
    constructor(
        private addressLearningRepo: AddressLearningRepo,
    ) {
    }
}