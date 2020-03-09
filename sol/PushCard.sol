pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./action.sol";
import "./common/ownership/Ownable.sol";

library Card {
    struct CardInfo {
        address payable player;
        uint32 betNo;
        uint32 betValue;
        uint8 cardNo;
        uint16 index;
        uint8 isInit;
    }
function CardInfoEncode(CardInfo memory s) internal pure returns(uint256) {return uint256(s.player)|uint256(s.betNo)<<160|uint256(s.betValue)<<192|uint256(s.cardNo)<<224|uint256(s.index)<<232|uint256(s.isInit)<<248;}
function CardInfoDecode(uint256 en) internal pure returns(CardInfo memory) {return CardInfo(address(en),uint32(en>>160),uint32(en>>192),uint8(en>>224),uint16(en>>232),uint8(en>>248));}
}

contract PushCard is ItemBase,PushCardInterface,Ownable,Indirect {
    using CommonBase for CommonBase.Action;
    using CommonBase for CommonBase.RetVal;
    using CommonBase for uint256;
    using Card for Card.CardInfo;
    using Card for uint256;
    event winner(uint256 win1, uint256 win2, uint256 total);
    event card(uint256 carden);
    uint256 public benefit;
    mapping(uint256=>uint256) indexMap;
    uint256 public cardsLength;
    uint256[1024] public cards;
    constructor(Ownable entry) Ownable(entry.owner()) Indirect(address(entry)) public {}
    function pushCard() external payable onlyIndirect returns(uint256) {
        require(msg.value >= (20 trx), "must >= 20trx");
        uint256 curLen = cardsLength;
        cards[curLen] = Card.CardInfo(tx.origin, uint32(block.number), uint32(msg.value/1 trx), 0, 0, 0).CardInfoEncode();
        cardsLength = curLen + 1;
        return CommonBase.newRetVal(1, uint160(curLen)).RetvalEncode();
    }

    function dealTrx(Card.CardInfo memory p1, Card.CardInfo memory p2, uint256 trxAmount) private {
        uint256 sunAmount = trxAmount * (1 trx);
        uint256 _benefit = sunAmount/10;
        benefit += _benefit;
        sunAmount -= _benefit;
        uint256 win1 = trxAmount*p1.betValue/(p1.betValue+p2.betValue);
        p1.player.transfer(win1);
        p2.player.transfer(sunAmount-win1);
    }

    function winSearch88(uint256 start, uint256 end) private view returns(uint256 totalValue) {
        while(end --> start) {
            Card.CardInfo memory c = cards[end].CardInfoDecode();
            totalValue += c.betValue;
        }
        totalValue = (address(this).balance - benefit)/(1 trx) - totalValue;
        return totalValue;
    }

    function winSearch(uint256 end, uint8 cardNo) private view returns(uint256, uint256, Card.CardInfo memory c) {
        uint256 totalValue = 0;
        while(end --> 0) {
            c = cards[end].CardInfoDecode();
            totalValue += c.betValue;
            if (c.cardNo == cardNo)
                return (totalValue, end, c);
        }
        return (0, 0xffffffff, c);
    }

    function moveCard(uint256 dest, uint256 src, uint256 length) private returns(uint256){
        for(uint256 i = 0; i < length; i++) {
            indexMap[src] = dest+1;
            cards[dest++] = cards[src++];
        }
        return length;
    }

    function getIndex(uint256 index) private returns(uint256) {
        while(true) {
            uint256 mapIndex = indexMap[index];
            if (mapIndex == 0)
                return index;
            //delete(indexMap[index]);
            indexMap[index] = 0;
            index = mapIndex - 1;
        }
    }

    function ActionHandler(uint256 en, uint256 r) external onlyIndirect returns(uint256) {
        CommonBase.Action memory ac = CommonBase.ActionDecode(en);
        uint256 index = getIndex(uint256(ac.data));

        Card.CardInfo memory c = cards[index].CardInfoDecode();
        uint8 cardNo = uint8(r);
        c.cardNo = cardNo;
        c.isInit = 1;
        c.index = uint16(index);
        cards[index] = c.CardInfoEncode();
        emit card(cards[index]);
        uint256 totalValue;
        uint256 si;
        uint256 unhandle = index + 1;
        Card.CardInfo memory sc;
        if(cardNo == 88) {
            totalValue = winSearch88(unhandle, cardsLength);
            si = 0;
            sc = c;
            emit winner(cards[index], cards[index], totalValue);
        }else{
            (totalValue, si, sc) = winSearch(index, cardNo);
            if (si == 0xffffffff)
                return 0;
            totalValue += c.betValue;
            emit winner(cards[si], cards[index], totalValue);
        }
        uint256 moveCount = cardsLength-unhandle;
        if(moveCount > 0)
            moveCard(si, unhandle, moveCount);
        cardsLength = si + moveCount;
        dealTrx(c, sc, totalValue);
        return 0;
    }

    function CardView(uint256 index) view public returns(Card.CardInfo memory) {
        return cards[index].CardInfoDecode();
    }

    function withdraw() external onlyOwner {
        msg.sender.transfer(benefit);
    }
/*
    function withdrawToken(uint256 tokenID) external onlyOwner {
        msg.sender.transferToken(address(this).tokenBalance(tokenID), tokenID);
    }
*/
    function balanceTRX() external view returns(uint256){
        return address(this).balance;
    }
    /*
    function balanceToken(uint256 token) external view returns(uint256){
        return address(this).tokenBalance(token);
    }
    */
}
