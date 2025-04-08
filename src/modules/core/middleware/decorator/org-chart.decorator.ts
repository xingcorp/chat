import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { GqlExecutionContext } from "@nestjs/graphql";

function getParamManyAndCount(_data: string, res: any) {
    if (!res) return null

    switch (_data) {
        case 'ids':
            let t = res[0]
            if (Array.isArray(t) && !t.length) return t

            return t?.map(i => i.id)
        case 'count':
            return res[1]
        case 'list':
        default:
            return res[0]
    }
}

export const ListDepartmentsOfOrg = createParamDecorator(
    async (_data: string, ctx: ExecutionContext) => {
        const { req } = GqlExecutionContext.create(ctx).getContext()

        return getParamManyAndCount(_data, req?.listDepartmentsOfOrg)
    }
)

export const ListUsersOfOrg = createParamDecorator(
    async (_data: string, ctx: ExecutionContext) => {
        const { req } = GqlExecutionContext.create(ctx).getContext()

        return getParamManyAndCount(_data, req?.listUsersOfOrg)
    }
)

export const ListDataOfOrg = createParamDecorator(
    async (_data: string, ctx: ExecutionContext) => {
        const { req } = GqlExecutionContext.create(ctx).getContext()

        return req?.[_data]
    }
)

export const ListDataIdsOfOrg = createParamDecorator(
    async (_data: string, ctx: ExecutionContext) => {
        const { req } = GqlExecutionContext.create(ctx).getContext()

        return getParamManyAndCount('ids', req?.[_data])
    }
)
