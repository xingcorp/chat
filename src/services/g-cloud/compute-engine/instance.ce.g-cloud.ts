import * as dotenv from 'dotenv';

dotenv.config();

import { InstancesClient } from "@google-cloud/compute";
import { Client } from "ssh2";
import { readFileToArray } from "@utils/file.utils";
import { getPrivateSshKey, sleep } from "@utils/common.utils";

const getInstance = new InstancesClient({
    credentials: JSON.parse(process.env.GOOGLE_AUTH_CERTS ?? ""),
})

export async function gcpCEInstanceGetList(project: string, zone: string) {
    const request = {
        project,
        zone,
    };
    // Run request
    const iterable = getInstance.listAsync(request);
    const res = []
    for await (const response of iterable) {
        console.log(response);
        res.push(response)
    }

    return res
}

export async function gcpCEInstanceGet(project: string, zone: string, instance: string) {
    const request = {
        instance,
        project,
        zone,
    };


    // Run request
    const response = await getInstance.get(request);
    console.log(response);

    return response
}

async function getLoadBalancerCfg(listReplicaIps: string[], filename: string = "") {
    const tmpCfgFilename = new Date().getTime().toString()
    const loadBalancerCfgFilename = '/etc/haproxy/haproxy.cfg'
    const cfgDefault = await readFileToArray()
    let cmd = ''

    cfgDefault.map((item, line) => {
        if (line) {
            cmd += ` && sudo echo "${item}" >> ${tmpCfgFilename}`
        } else {
            cmd += `sudo echo "${item}" > ${tmpCfgFilename}`
        }
    })

    listReplicaIps.map((ip, index) => {
        cmd += ` && sudo echo "    server      replica-${index + 1}       ${ip}:5432   check" >> ${tmpCfgFilename}`
    })

    cmd += ` && sudo cp ${tmpCfgFilename} ${loadBalancerCfgFilename}`
    cmd += ` && sleep .05 `
    cmd += ` && sudo rm ${tmpCfgFilename}`

    return cmd
}

export async function gcpCEUpdateAndRestartLoadBalancingInstance(listReplicaIps: string[]) {
    await gcpCEUpdateAndRestartLoadBalancingInstanceFirstStep(listReplicaIps)

    await sleep(200)

    return gcpCERestartLoadBalancingInstance()
}

export async function gcpCEUpdateAndRestartLoadBalancingInstanceFirstStep(listReplicaIps: string[]) {
    const conn = new Client();
    let connectWithoutError = true

    let startUpdate = false

    conn.on('ready', async () => {
        if (startUpdate) return
        startUpdate = true

        const cmd = await getLoadBalancerCfg(listReplicaIps)

        console.log('Start edit load balance with new list ip', listReplicaIps);

        conn.exec(`${cmd}`, (err, stream) => {
            if (err) {
                console.log('gcpCEUpdateAndRestartLoadBalancingInstance err', err)
                connectWithoutError = false
                conn.end();
                return;
            }
            stream.on('data', (data) => {
                console.log('data', data.toString())
            });

            stream.on('close', (code, signal) => {
                console.log('ssh remote close', new Date())
                conn.end();
            });

            stream.on('exit', (code, signal) => {
                console.log('ssh remote exit', new Date())
                conn.end();
            });

            stream.on('error', (err) => {
                console.log('gcpCEUpdateAndRestartLoadBalancingInstance err', err)
                connectWithoutError = false
                conn.end();
            });
        });
    })
        .on('error', (e) => {
            console.log('gcpCEUpdateAndRestartLoadBalancingInstance error', e)
            connectWithoutError = false
        });

    const auth = {
        host: process.env.GCE_LOAD_BALANCER_INSTANCE_HOST,
        username: process.env.GCE_SSH_USER_NAME,
        privateKey: getPrivateSshKey(process.env.GCE_SSH_PRIVATE_KEY),
    }

    conn.connect(auth);

    return connectWithoutError
}

export async function gcpCERestartLoadBalancingInstance() {
    const conn = new Client();
    let connectWithoutError = true

    conn.on('ready', async () => {

        conn.exec(`sudo systemctl restart haproxy`, (err, stream) => {
            if (err) {
                console.log('gcpCEUpdateAndRestartLoadBalancingInstance err', err)
                connectWithoutError = false
                conn.end();
                return;
            }
            stream.on('data', (data) => {
                console.log('data', data.toString())
            });

            stream.on('close', (code, signal) => {
                console.log('ssh remote close', new Date())
                conn.end();
            });

            stream.on('exit', (code, signal) => {
                console.log('ssh remote exit', new Date())
                conn.end();
            });

            stream.on('error', (err) => {
                console.log('gcpCEUpdateAndRestartLoadBalancingInstance err', err)
                connectWithoutError = false
                conn.end();
            });
        });
    })
        .on('error', (e) => {
            console.log('gcpCEUpdateAndRestartLoadBalancingInstance error', e)
            connectWithoutError = false
        });

    const auth = {
        host: process.env.GCE_LOAD_BALANCER_INSTANCE_HOST,
        username: process.env.GCE_SSH_USER_NAME,
        privateKey: getPrivateSshKey(process.env.GCE_SSH_PRIVATE_KEY),
    }

    conn.connect(auth);

    return connectWithoutError
}

export async function gcpCEStoreInstanceRemoveNameToServer(name: string) {
    const conn = new Client();
    let connectWithoutError = true
    const REMOVE_INSTANCE_FILE= '/etc/haproxy/delete-instance.txt'

    conn.on('ready', async () => {

        conn.exec(`sudo echo "${name}" >> ${REMOVE_INSTANCE_FILE}`, (err, stream) => {
            if (err) {
                console.log('gcpCEStoreInstanceRemoveNameToServer err', err)
                connectWithoutError = false
                conn.end();
                return;
            }
            stream.on('data', (data) => {
                console.log('data', data.toString())
            });

            stream.on('close', (code, signal) => {
                console.log('ssh remote close', new Date())
                conn.end();
            });

            stream.on('exit', (code, signal) => {
                console.log('ssh remote exit', new Date())
                conn.end();
            });

            stream.on('error', (err) => {
                console.log('gcpCEStoreInstanceRemoveNameToServer err', err)
                connectWithoutError = false
                conn.end();
            });
        });
    })
        .on('error', (e) => {
            console.log('gcpCEStoreInstanceRemoveNameToServer error', e)
            connectWithoutError = false
        });

    const auth = {
        host: process.env.GCE_LOAD_BALANCER_INSTANCE_HOST,
        username: process.env.GCE_SSH_USER_NAME,
        privateKey: getPrivateSshKey(process.env.GCE_SSH_PRIVATE_KEY),
    }

    conn.connect(auth);

    return connectWithoutError
}

export async function gcpCECheckConnectLoadBalancerInstance() {
    const conn = new Client();

    conn
        .on('ready', async () => {
            console.log('gcpCECheckConnectLoadBalancerInstance ready')
        })
        .on('error', (e) => {
            console.log('gcpCECheckConnectLoadBalancerInstance error', e)
        });

    const auth = {
        host: process.env.DATABASE_HOST,
        port: Number(process.env.DATABASE_PORT),
        username: process.env.DATABASE_USERNAME,
        password: process.env.DATABASE_PASSWORD,
    }

    conn.connect(auth);

    return null
}
