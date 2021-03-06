//import TronWeb from 'tronweb'
TronWeb = require('tronweb');
fs = require('fs')

File = (name) => fs.readFileSync(name)
Json = JSON.parse;
JsonFile = (name) => Json(File(name))


const shasta = '.shasta'

const fullNode = `https://api${shasta}.trongrid.io`;
const solidityNode = `https://api${shasta}.trongrid.io`;
const eventServer = `https://api${shasta}.trongrid.io/`;
const anyPrivate = File('.key').toString();
const bet16Address = 'TWE37uQa9gDkWnHN5SdZC9XsWCX2m8dwro';

const tronWeb = new TronWeb(
    fullNode,
    solidityNode,
    eventServer,
    anyPrivate
);

Int = parseInt
bigInt = tronWeb.BigNumber

const D = console.info;

function getContract(addr) {
    return tronWeb.contract().at(addr).then(
        (x) => { return x; }
    );
}

function localContract(abi, addr) {
    return tronWeb.contract(Json(abi), addr)
}

function parseCombinedJson(filename) {
    combindedObj = JsonFile(filename);
    D("compiler:", combindedObj.version);
    return combindedObj.contracts;
}

function sendTx(txobj, trx = 0, fee = 2, sync = true) {
    return txobj.send({
        feeLimit: tronWeb.toSun(fee),
        shouldPollResponse: sync,
        callValue: tronWeb.toSun(trx),
    });
}

function winSearch(cards) {
    winCard = cards[cards.length-1]
    winValue = winCard.betValue;
    let i
    for(i = cards.length-1; i > 0; i--){
        curCard = cards[i]
        winValue += curCard.betValue
        if(curCard.cardNo == winCard.cardNo)
            break;
    }
    return {
        benefit: Int(winValue*0.1),
        start: {
            index: i,
            winValue: winValue*0.45
        },
        end: {
            index: cards.length-1,
            winValue: winValue*0.45
        }
    }
}

function CardInfoDecode(en){en=BigInt(en);return {player:'0x'+(en&BigInt('0xffffffffffffffffffffffffffffffffffffffff')).toString(16),betNo:'0x'+((en>>BigInt('160'))&BigInt('0xffffffff')).toString(16),betValue:'0x'+((en>>BigInt('192'))&BigInt('0xffffffff')).toString(16),cardNo:'0x'+((en>>BigInt('224'))&BigInt('0xff')).toString(16),isInit:'0x'+((en>>BigInt('232'))&BigInt('0xff')).toString(16)};}
async function main() {
    let contractMap = parseCombinedJson(process.argv[2])
    let mainEntry = contractMap['action.sol:Main']
    let pushCard = contractMap['PushCard.sol:PushCard']
    let cAddress = JsonFile("Contract.json")
    let mainEntryDeploy = localContract(mainEntry.abi, cAddress.mainEntry)
    let pushCardDeploy = localContract(pushCard.abi, cAddress.pushCard)
    //pushCardDeploy = await getContract("TKyW3nNtE8TDzbSF3a1PF8F4fBn2EpjcFf")
    let tx = mainEntryDeploy.pushCard(0)
    let lastInit = 0;
    let cards = [];
    let benefit = await pushCardDeploy.benefit().call()
    for (i = 0; i < 512; i++) {
        await sendTx(tx, trx=20)
        continue
        let cardsLength = await pushCardDeploy.cardsLength().call()
        let index
        if(lastInit > cardsLength){
            benefit = await pushCardDeploy.benefit().call()
            D("win!", benefit)
            await sendTx(mainEntryDeploy.deal())
            break;
        }
        for (index = lastInit; index < cardsLength; index++) {
            //let cardi = await pushCardDeploy.CardView(lastRead).call()
            let cardi = await pushCardDeploy.cards(index).call()
            let decard = CardInfoDecode(cardi)
            if(Int(decard.isInit) > 0)
                lastInit++;
            nzero = (n)=>{return (BigInt(10)**BigInt(n)).toString().slice(1)}
            hexadd = decard.player.slice(2)
            decard.player = tronWeb.address.fromHex("0x"+nzero(hexadd.length-40)+hexadd);
            if(index < cards.length)
                cards[index] = decard
            else
                cards.push(decard)
        }

        balance = await pushCardDeploy.balanceTRX().call()
        D("------", i, Int(balance), Int(benefit), Int(cardsLength))
        for (j = 0; j < cardsLength; j++) {
            cardinfo = cards[j]
            D("  ", j, cardinfo.player, Int(cardinfo.betValue), Int(cardinfo.cardNo));
        }
    }
}
main()
