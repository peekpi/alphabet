//import TronWeb from 'tronweb'
TronWeb = require('tronweb');
fs = require('fs')

File = (name) => fs.readFileSync(name)
FileWrite = (file, data) => fs.writeFileSync(file, data)
Json = JSON.parse;
JsonDump = JSON.stringify;


const shasta = '.shasta'

const fullNode = `https://api${shasta}.trongrid.io`;
const solidityNode = `https://api${shasta}.trongrid.io`;
const eventServer = `https://api${shasta}.trongrid.io/`;
const anyPrivate = File(".key");
const bet16Address = 'TWE37uQa9gDkWnHN5SdZC9XsWCX2m8dwro';

const tronWeb = new TronWeb(
    fullNode,
    solidityNode,
    eventServer,
    anyPrivate
);

const D = console.info;


//D(tronWeb.address.toHex())
//tronWeb.address.fromHex
function helpAPI() {
    enadd = tronWeb.address.fromPrivateKey(anyPrivate)
    hexadd = tronWeb.address.toHex(enadd)
    tadd = tronWeb.address.fromHex(hexadd)
    D(enadd, hexadd, tadd == enadd)
}

function getContract(addr){
    return tronWeb.contract().at(addr).then(
        (x) => {return x;}
    );
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function deploy_contract(cinfo, input){
  return tronWeb.contract().new({
    abi:cinfo.abi,
    bytecode:cinfo.bin,
    feeLimit: 1000000000,
    callValue: 0,
    userFeePercentage: 100,
    parameters:input
  });
}

function sendTx(txobj, trx=0, fee=2, sync=true) {
    return txobj.send({
        feeLimit: tronWeb.toSun(fee),
        shouldPollResponse: sync,
        callValue: tronWeb.toSun(trx),
    });
}

function parseCombinedJson(filename) {
    combindedObj = Json(File(filename));
    D("compiler:", combindedObj.version);
    return combindedObj.contracts;
}

async function main(){
    helpAPI();
    contractMap = parseCombinedJson(process.argv[2])
    mainEntry = contractMap['action.sol:Main']
    mainEntryDeploy = await deploy_contract(mainEntry, [])
    D("mainEntry:", mainEntryDeploy.address, tronWeb.address.fromHex(mainEntryDeploy.address))
    D(await mainEntryDeploy.owner().call())
    pushCard = contractMap['PushCard.sol:PushCard']
    pushCardDeploy = await deploy_contract(pushCard, [mainEntryDeploy.address])
    D("pushCard:", pushCardDeploy.address, tronWeb.address.fromHex(pushCardDeploy.address))
    tx = mainEntryDeploy.addItem(pushCardDeploy.address)
    ret = await sendTx(tx)
    D(ret)
    let jstr = JsonDump({
        mainEntry:tronWeb.address.fromHex(mainEntryDeploy.address),
        pushCard:tronWeb.address.fromHex(pushCardDeploy.address)
    })
    FileWrite('Contract.json', jstr);
    FileWrite('../webpage/Contract.js', "cAddress="+jstr);
}

main();
