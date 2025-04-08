import { Field, Float, ID, ObjectType } from "@nestjs/graphql";
import { Schema } from "dynamoose";

export type NfcHistoryKey = {
    id: string;
};

@ObjectType()
export class NfcHistory {
    @Field(_type => String, { nullable: false })
    id: string

    @Field(_type => Float, { nullable: false })
    createdAt: Date

    @Field(_type => String, { nullable: false })
    createdBy: string

    @Field(_type => Float, { nullable: false })
    updatedAt: Date

    @Field(_type => String, { nullable: false })
    updatedBy: string

    @Field(_type => String, { nullable: true })
    serial: string

    @Field(_type => String, { nullable: true })
    nfcId: string

    @Field(_type => String, { nullable: true })
    rollingCode: string

    @Field(_type => Float, { nullable: true })
    longitude: number

    @Field(_type => Float, { nullable: true })
    latitude: number

    @Field(_type => String, { nullable: true })
    address: string

    @Field(_type => String, { nullable: true })
    provinceId: string

    @Field(_type => String, { nullable: true })
    province: string

    @Field(_type => String, { nullable: true })
    districtId: string

    @Field(_type => String, { nullable: true })
    district: string

    @Field(_type => String, { nullable: true })
    wardId: string

    @Field(_type => String, { nullable: true })
    ward: string

    @Field(_type => String, { nullable: true })
    convertAddress: string

    @Field(_type => String, { nullable: true })
    assetName: string

    @Field(_type => String, { nullable: true })
    assetCode: string
}

export const NfcHistorySchema = new Schema({
    id: {
        type: String,
        hashKey: true,
    },
    createdAt: {
        type: Date,
    },
    createdBy: {
        type: String,
        index: {
            type: 'global',
            // rangeKey: 'status',
        }
    },
    updatedAt: {
        type: Date,
    },
    updatedBy: {
        type: String,
    },
    serial: {
        type: String,
        index: {
            type: 'global',
        }
    },
    nfcId: {
        type: String,
        index: {
            type: 'global',
        }
    },
    rollingCode: {
        type: String,
    },
    longitude: {
        type: Number,
    },
    latitude: {
        type: Number,
    },
    address: {
        type: String,
    },
    provinceId: {
        type: String,
    },
    province: {
        type: String,
    },
    districtId: {
        type: String,
    },
    district: {
        type: String,
    },
    wardId: {
        type: String,
    },
    ward: {
        type: String,
    },
    convertAddress: {
        type: String,
    },
    assetName: {
        type: String,
    },
    assetCode: {
        type: String,
        index: {
            type: 'global',
        }
    },
})