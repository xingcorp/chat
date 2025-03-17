import { Field, ObjectType } from '@nestjs/graphql'

@ObjectType()
export class BankAccount {
  @Field(() => String)
  id: string

  @Field(() => String, { nullable: true })
  bankId: string

  @Field(() => String, { nullable: true })
  bankName: string

  @Field(() => String, { nullable: true })
  accountNumber: string

  @Field(() => String, { nullable: true })
  accountHolder: string

  @Field(() => String, { nullable: true })
  cardNumber: string

  @Field(() => String, { nullable: true })
  bankBranch: string

  public backup() {
    return JSON.stringify({
      id: this.id,
      bankName: this.bankName,
      accountNumber: this.accountNumber,
      accountHolder: this.accountHolder,
      cardNumber: this.cardNumber
    })
  }

  static restore(snapshot: string) {
    try {
      const dict = JSON.parse(snapshot)
      const result = new BankAccount()

      result.id = dict.id
      result.bankName = dict.bankName
      result.accountNumber = dict.accountNumber
      result.accountHolder = dict.accountHolder
      result.cardNumber = dict.cardNumber

      return result
    } catch (error) {
      console.log(`BankAccount restore has error: ${error}`)
    }

    return null
  }
}
