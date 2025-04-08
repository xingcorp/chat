import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity, BeforeInsert,
    Column,
    CreateDateColumn, DeleteDateColumn,
    Entity,
    Generated,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm";
import GraphQLJSON from "graphql-type-json";
import { ActiveStatus } from "@common/enum.common";
import { FilterRelationType } from "@enum/filter/filter.enum";
import { stringNumberWithZeroLeading } from "@utils/string.utils";

registerEnumType(ActiveStatus, {name: 'ActiveStatus'})
registerEnumType(FilterRelationType, {name: 'FilterRelationType'})

@ObjectType()
@Entity("office-filter")
export class OfficeFilter extends BaseEntity {
    @Field(_type => String, { nullable: true })
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Column({ nullable: true })
    @Generated('increment')
    no: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    code: string

    @Column({ nullable: false, default: FilterRelationType.Default })
    relationType: FilterRelationType

    @Column({ nullable: true })
    relationId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    name: string

    @Column({ nullable: true })
    order: number

    @Field(_type => GraphQLJSON, { nullable: true })
    @Column({
        type: "jsonb",
        nullable: true,
    })
    filter: any

    @Field(_type => ActiveStatus, { nullable: true })
    @Column({ nullable: true, type: 'enum', enum: ActiveStatus, default: ActiveStatus.Active })
    status: ActiveStatus

    @Field(_type => Float, { nullable: true })
    @CreateDateColumn()
    createdAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field(_type => Float, { nullable: true })
    @UpdateDateColumn()
    updatedAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date

    @BeforeInsert()
    async genData() {
        await this.genCode()
        await this.genOrder()
    }

    private async genCode() {
        const count = await OfficeFilter.count({withDeleted: true})

        this.code = `FIL${stringNumberWithZeroLeading(count + 1)}`
    }

    private async genOrder() {
        if (this.order) return

        const count = await OfficeFilter.count({
            where: {
                relationType: this.relationType,
                relationId: this.relationId,
            }
        })

        this.order = count + 1
    }
}