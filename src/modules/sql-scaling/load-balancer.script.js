const util = require('util');
const exec = util.promisify(require('child_process').exec);
const fs = require('fs');
const readline = require("node:readline");

const REMOVE_INSTANCE_FILE= '/etc/haproxy/delete-instance.txt'

async function execRun(cmd) {
    const { stdout, stderr } = await exec(cmd);
    if (stderr.length) {
        console.log('execRun', stderr)
        return false
    }

    return stdout
}
async function readFileToArray(filename) {
    const fileStream = fs.createReadStream(filename);

    const rl = readline.createInterface({
        input: fileStream,
        crlfDelay: Infinity
    });

    let res = []
    for await (const line of rl) {
        res.push(line)
    }

    return res
}

async function makeNewLoadBalancerFile(listIps) {
    const tmpCfgFilename = `${new Date().getTime().toString()}.txt`
    const defaultFile = '/etc/haproxy/haproxy.cfg.txt'
    const loadBalancerCfgFilename = '/etc/haproxy/haproxy.cfg'

    let stdout = await execRun(`sudo cp ${defaultFile} ${tmpCfgFilename}`);
    if (stdout === false) return stdout

    stdout = await execRun(`sudo chmod -R 777 ${tmpCfgFilename}`);
    if (stdout === false) return stdout

    let haveReplica = false
    for (const index in listIps) {
        if (listIps[index].length) {
            haveReplica = true
            stdout = await execRun(`sudo echo "    server      replica-${index + 1}       ${listIps[index]}:5432   check" >> ${tmpCfgFilename}`)
            if (stdout === false) return stdout
        }
    }

    if (!haveReplica) {
        stdout = await execRun('gcloud sql instances list --filter="name:srt-stg-office AND state:RUNNABLE" --format="value(PRIVATE_ADDRESS)"');
        if (stdout === false) return stdout

        stdout = await execRun(`sudo echo "    server      replica-1       ${stdout.split("\n")[0]}:5432   check" >> ${tmpCfgFilename}`)
        if (stdout === false) return stdout
    }

    stdout = await execRun(`sudo cp ${tmpCfgFilename} ${loadBalancerCfgFilename}`);
    if (stdout === false) return stdout

    stdout = await execRun(`sudo rm ${tmpCfgFilename}`);
    if (stdout === false) return stdout

    return true
}

async function getListIpInstanceReplica() {
    const stdout = await execRun('gcloud sql instances list --filter="name:srt-stg-office-replica AND state:RUNNABLE" --format="value(PRIVATE_ADDRESS)"');
    if (stdout === false) return []

    console.log('getListIpInstanceReplica:', stdout);

    let data = structuredClone(stdout);

    data = data.split("\n")
    return data
}

async function getListInstanceRemoveReplica() {
    let listInstances = await readFileToArray(REMOVE_INSTANCE_FILE)

    return [...new Set(listInstances)]
}

async function reloadLoadBalancer(ips) {
    if (await makeNewLoadBalancerFile(ips)) {
        let stdout = await execRun(`sudo systemctl restart haproxy`);
        if (stdout === false) return stdout
    }

    return true
}

async function getListIpsRemoveReplica(listRemoveInstances) {
    let res = []
    for (const instance of listRemoveInstances) {
        let stdout = await execRun(`gcloud sql instances list --filter="name:${instance} AND state:RUNNABLE" --format="value(PRIVATE_ADDRESS)"`);
        if (stdout === false) continue

        res[instance] = stdout.split("\n")[0]
    }

    console.log('list remove: ', res)

    return res
}

async function removeReplicaInstance(instance) {
    if (instance === 'srt-stg-office') return false

    let stdout = await execRun(`gcloud sql instances delete ${instance} --async --quiet`);
    if (stdout === false) return stdout

    return true
}

async function clearRemoveFile() {
    fs.writeFile(REMOVE_INSTANCE_FILE, '', function(){console.log('CLEAR SUCCESS')})
}

async function run() {

    const listIps = await getListIpInstanceReplica()
    const listRemoveInstances = await getListInstanceRemoveReplica()
    const listRemove = await getListIpsRemoveReplica(listRemoveInstances)

    const reload = await reloadLoadBalancer(listIps.filter(i => !Object.values(listRemove).includes(i)))

    if (reload) {
        for (const replica of listRemoveInstances) {
            await removeReplicaInstance(replica)
        }

        await clearRemoveFile()
    }

    return true

}
run();