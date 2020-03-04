
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./action.sol";

library Card {
    struct CardInfo {
        address payable player;
        uint32 betNo;
        uint32 betValue;
        uint8 cardNo;
        uint8 isInit;
    }
    function CardInfoEncode(CardInfo memory s) internal pure returns(uint256) {return uint256(s.player)|uint256(s.betNo)<<160|uint256(s.betValue)<<192|uint256(s.cardNo)<<224|uint256(s.isInit)<<232;}
    function CardInfoDecode(uint256 en) internal pure returns(CardInfo memory) {return CardInfo(address(en),uint32(en>>160),uint32(en>>192),uint8(en>>224),uint8(en>>232));}
}

contract PushCard is ItemBase,PushCardInterface {
    using CommonBase for CommonBase.Action;
    using CommonBase for CommonBase.RetVal;
    using CommonBase for uint256;
    using Card for Card.CardInfo;
    using Card for uint256;
    uint256 public cardsLength;
    uint256[256] public cards;
    uint256 benefit;
    function pushCard() public payable returns(uint256) {
        uint256 curLen = cardsLength;
        uint256 curOff = curLen - 1;
        cards[curOff] = Card.CardInfo(tx.origin, uint32(block.number), uint32(msg.value/1e6), 0, 0).CardInfoEncode();
        cardsLength = curLen + 1;
        return CommonBase.newRetVal(0, uint160(curLen)).RetvalEncode();
    }

    function dealTrx(address payable p1, address payable p2, uint256 trxAmount) private {
        uint256 sunAmount = trxAmount*1e6;
        uint256 _benefit = sunAmount/10;
        benefit += _benefit;
        sunAmount -= _benefit;
        sunAmount/=2;
        p1.transfer(sunAmount);
        p2.transfer(sunAmount);
    }

    function winSearch(uint256 end, uint8 cardNo) private view returns(uint256, uint256, Card.CardInfo memory c) {
        uint256 totalValue = 0;
        while(end-- > 0) {
            c = cards[end].CardInfoDecode();
            totalValue += c.betValue;
            if (c.cardNo == cardNo)
                return (totalValue, end, c);
        }
        return (0, 0x100, c);
    }

    function ActionHandler(uint256 en, uint256 r) external returns(uint256) {
        CommonBase.Action memory ac = CommonBase.ActionDecode(en);
        uint256 index = uint256(ac.data);
        Card.CardInfo memory c = cards[index].CardInfoDecode();
        uint8 cardNo = uint8(r);
        (uint256 totalValue, uint256 si, Card.CardInfo memory sc) = winSearch(index, cardNo);
        if (si == 0x100) {
            c.cardNo = cardNo;
            c.isInit = 1;
            return 0;
        }
        totalValue += c.betValue;
        cardsLength = si;
        dealTrx(c.player, sc.player, totalValue);
    }
}
