import { ActiveStatus } from "@common/enum.common";
import { OrgChartBase } from "@models/office.base";
import { Field, ObjectType, registerEnumType } from "@nestjs/graphql";
import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";

registerEnumType(ActiveStatus, { name: 'ActiveStatus' })

@ObjectType()
@Entity("office-learn-address")
export class LearnAddress extends OrgChartBase {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    name: string

    @Field(_type => ActiveStatus, { nullable: true })
    @Column({ nullable: true, default: ActiveStatus.Active })
    status: ActiveStatus

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string
}