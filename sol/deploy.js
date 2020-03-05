//import TronWeb from 'tronweb'
TronWeb = require('tronweb');
fs = require('fs')

File = (name) => fs.readFileSync(name)
Json = JSON.parse;


const shasta = '.shasta'

const fullNode = `https://api${shasta}.trongrid.io`;
const solidityNode = `https://api${shasta}.trongrid.io`;
const eventServer = `https://api${shasta}.trongrid.io/`;
const anyPrivate = '9ebd1d36e2123e7019bc2a98f1ad0c7cac8bdb9006cb93553c20e15b927b911f';
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
    pushCard = contractMap['PushCard.sol:PushCard']
    pushCardDeploy = await deploy_contract(pushCard, [mainEntryDeploy.address])
    D("pushCard:", pushCardDeploy.address, tronWeb.address.fromHex(pushCardDeploy.address))
    tx = mainEntryDeploy.addItem(pushCardDeploy.address)
    ret = await sendTx(tx)
    D(ret)
}

main();
