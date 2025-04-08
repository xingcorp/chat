import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, Generated, ManyToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm";
import { Asset } from "@models/entities";
import { AssetAssignType } from "@enum/asset/asset.enum";

registerEnumType(AssetAssignType, { name: 'AssetAssignType' })

@ObjectType()
@Entity("office-asset-assignment")
export class AssignmentAsset extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Column({ nullable: true })
    @Generated('increment')
    no: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    code: string

    @Field(_type => String, {nullable: true})
    @Column({nullable: true})
    reason: string

    @Field(_type => Float, {nullable: true})
    @Column({nullable: true})
    startAt: Date

    @Field(_type => Float, {nullable: true})
    @Column({nullable: true})
    endAt: Date

    @Field(_type => AssetAssignType, { nullable: true })
    @Column({ nullable: true })
    assignedType: AssetAssignType

    @Field(_type => String, {nullable: true})
    @Column({nullable: true})
    assignedId: string

    @Field(_type => AssetAssignType, { nullable: true })
    @Column({ nullable: true })
    handoverType: AssetAssignType

    @Field(_type => String, {nullable: true})
    @Column({nullable: true})
    handoverId: string

    @Field(_type => Float)
    @CreateDateColumn()
    createdAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field(_type => Float)
    @UpdateDateColumn()
    updatedAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date

    /*@Field(_type => Asset, { nullable: true })
    @ManyToOne(() => Asset, (ob) => ob.assignments)
    asset: Asset*/
}