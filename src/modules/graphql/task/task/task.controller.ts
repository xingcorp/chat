import { Body, Controller, Post } from '@nestjs/common';
import { TaskService } from "@modules/graphql/task/task/task.service";

@Controller('task')
export class TaskController {
    constructor(private readonly taskService: TaskService) { }

    @Post('notify')
    async notify(@Body() body: { key: string }): Promise<any> {

        console.log('SCHEDULE_NOTIFY_TASK_DAILY_KEY check')

        try {
            if (!body?.key || body?.key !== process.env.SCHEDULE_NOTIFY_TASK_DAILY_KEY) {
                return
            }

            console.log('SCHEDULE_NOTIFY_TASK_DAILY_KEY start')

            console.log('SCHEDULE_NOTIFY_TASK_DAILY_KEY notifyTaskNeedToDoneInTime')
            this.taskService.notifyTaskNeedToDoneInTime()

            console.log('SCHEDULE_NOTIFY_TASK_DAILY_KEY notifyTaskLate')
            this.taskService.notifyTaskLate()

            console.log('SCHEDULE_NOTIFY_TASK_DAILY_KEY end')

            return 'ok'
        } catch (e) {
            console.log('SCHEDULE_NOTIFY_TASK_DAILY_KEY err', e)
        }
    }

    @Post('taskConfigGen')
    async taskConfigGen(@Body() body: { key: string }): Promise<any> {

        console.log('SCHEDULE_TASK_CONFIG_GEN_KEY check')

        if (!body?.key || body?.key !== process.env.SCHEDULE_TASK_CONFIG_GEN_KEY) {
            return
        }

        console.log('SCHEDULE_TASK_CONFIG_GEN_KEY start')

        console.log('SCHEDULE_TASK_CONFIG_GEN_KEY gen')
        this.taskService.taskReportCreate().catch(e => {
            console.error('SCHEDULE_TASK_CONFIG_GEN_KEY', e)
        })

        console.log('SCHEDULE_TASK_CONFIG_GEN_KEY end')

        return 'ok'

    }
}
