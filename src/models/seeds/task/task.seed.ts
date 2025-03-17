import { OfficeTask, } from "@models/entities";
import { MoreThanOrEqual, LessThanOrEqual, IsNull } from "typeorm";
import { datetimeEndOfLocalDay, datetimeGetFormat, datetimeStartOfLocalDay, getDateLocal } from "@utils/datetime.utils";
import { stringNumberWithZeroLeading } from "@utils/string.utils";

export async function seedUpdateTaskKey() {
    const tasks = await OfficeTask.find({
        relations: ['project'],
        where: {
            keyPostfix: IsNull()
        }
    })


    for (const task of tasks) {
        if (task.keyPostfix) return
        if (task.project.rootOrg.id !== process.env.K_ORG_ID && task.no) {
            task.keyPostfix = task.no.toString()
            await task.save()
            continue
        }

        const min = await OfficeTask.createQueryBuilder('qb')
            .leftJoinAndSelect('qb.project', 'project')
            .where(`project.id::text = :projectId`, {projectId: task.project.id})
            .andWhere({
                createdAt: MoreThanOrEqual(datetimeStartOfLocalDay(task.createdAt))
            })
            .andWhere({
                createdAt: LessThanOrEqual(datetimeEndOfLocalDay(task.createdAt))
            })
            .orderBy(`qb."no"`, 'ASC')
            .getOne()

        task.keyPostfix = `${datetimeGetFormat('DD/MM/YYYY', (getDateLocal(new Date(task.createdAt))).toString()).replaceAll('/', '')}-${stringNumberWithZeroLeading(task.no - min.no + 1)}`
        await task.save()
    }

    return tasks.length
}

