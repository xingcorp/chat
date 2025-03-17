import { DataSourceOptions, DataSource } from 'typeorm';

export async function isCanConnect(options: DataSourceOptions) {
    try {
        const connection = await new DataSource(options).initialize();
        console.log('connect success')

        if(connection.isInitialized){
            await connection.destroy();
        }

        return true
    } catch (error) {
        console.log('cannot connect', error)

        return false
    }
}