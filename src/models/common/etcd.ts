import { Field, Int } from '@nestjs/graphql'
import { BaseEntity, Column, Entity, PrimaryGeneratedColumn, Unique } from 'typeorm'

export enum ETCDDataType {
    Text = 'text',
    Number = 'number',
    JSON = 'json'
}

@Entity('common-etcds')
@Unique(['key', 'organizationId'])
export class ETCD extends BaseEntity {
    @Field(() => Int)
    @PrimaryGeneratedColumn()
    id: string

    @Column({ nullable: false })
    type: ETCDDataType

    @Column({ nullable: false })
    key: string

    @Column({ nullable: false })
    value: string

    @Column({ nullable: false })
    organizationId: string
}
