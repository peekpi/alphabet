pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./common/random/rand.sol";
import "./common/ownership/Ownable.sol";
import "./common/delegatecallable/Delegatecallable.sol";

interface ItemBase {
    function ActionHandler(uint256 en, uint256 r) external returns(uint256);
}

library CommonBase {
    struct Action {
        uint32 playerNo; // u32
        uint32 blockNo; // u32
        uint16 acType;  // u16
        uint16 itemNo; // u16
        uint160 data;
    }

    function ActionEncode(Action memory s) internal pure returns(uint256) {return uint256(s.playerNo)|uint256(s.blockNo)<<32|uint256(s.acType)<<64|uint256(s.itemNo)<<80|uint256(s.data)<<96;}

    function ActionDecode(uint256 en) internal pure returns(Action memory) {return Action(uint32(en),uint32(en>>32),uint16(en>>64),uint16(en>>80),uint160(en>>96));}

    function newAction(uint32 playerIndex, uint16 typ, uint16 itemNo, uint160 data) internal view returns(Action memory) {
        require(block.number < 0xffffffff, "block No wrong");
        return Action(playerIndex, uint32(block.number), typ, itemNo, data);
    }

    struct RetVal {
        uint16 typ;
        uint160 data;
    }

    function RetvalEncode(RetVal memory s) internal pure returns(uint256) {return uint256(s.typ)|uint256(s.data)<<16;}
    function RetvalDecode(uint256 en) internal pure returns(RetVal memory) {return RetVal(uint16(en),uint160(en>>16));}

    function newRetVal(uint16 typ, uint160 data) internal pure returns(RetVal memory) {
        return RetVal(typ, data);
    }
}

contract ActionBase {
    mapping(address=>uint256) public playerIndex;
    address[] public players;
    ItemBase[] public items;
    mapping(address=>uint256) public itemIndex;

    uint256 public nextAction;
    uint256[] public actions;

    function playerInit(address player) private {
        if (playerIndex[player] == 0){
            players.push(player);
            playerIndex[player] = players.length;
        }
    }

    function getPlayerIndex(address player) private view returns(uint256 r) {
        r = playerIndex[player];
        require(r > 0, "player not exist");
        return r;
    }

    function getPlayerAdress(uint256 index) private view returns(address player) {
        return players[index-1];
    }

    function pushAction(uint16 typ, uint16 itemNo, uint160 data) internal returns(CommonBase.Action memory ac) {
        require(block.number < 0xffffffff, "block No wrong");
        ac = CommonBase.newAction(uint32(getPlayerIndex(msg.sender)), typ, itemNo, data);
        actions.push(CommonBase.ActionEncode(ac));
    }
    function getAction() internal returns(CommonBase.Action memory ac) {
        return CommonBase.ActionDecode(actions[nextAction++]);
    }

    function acEmpty() internal view returns(bool) {
        return nextAction == actions.length;
    }
}

contract Person is ItemBase {
    using CommonBase for CommonBase.Action;
    using CommonBase for CommonBase.RetVal;
    using CommonBase for uint256;
    uint256[] public humans;
    function newPeople() public returns(uint256) {
        humans.push(0);
        return CommonBase.newRetVal(0, uint160(humans.length-1)).RetvalEncode();
    }
    function ActionHandler(uint256 en, uint256 r) external returns(uint256) {
        CommonBase.Action memory ac = CommonBase.ActionDecode(en);
        humans[ac.data] = r;
        return 0;
    }
}

contract CommonImpl is random,Ownable,RouteProxy {
    constructor() Ownable() public {

    }
    function ChangeLogicAddress(address addr) public onlyOwner {
        changeLogicAddress(addr);
    }
    function AddRoute(address route) external onlyOwner {
        addRoute(route);
    }
    function FeedHash(uint256 number, uint256 _hash) external onlyOwner {
        feedHash(number, _hash);
    }
}

contract Main is ActionBase,CommonImpl {
    using CommonBase for CommonBase.Action;
    using CommonBase for CommonBase.RetVal;
    using CommonBase for uint256;

    constructor() CommonImpl() public {

    }

    function addItem(ItemBase _item) public onlyOwner {
        require(itemIndex[address(_item)] > 0, "exist");
        items.push(_item);
        itemIndex[address(_item)] = items.length;
    }

    function doRet(CommonBase.RetVal memory ret, uint16 index) private {
        if(ret.typ > 0)
            pushAction(0, index, ret.data);
    }

    function exec(uint16 index) public {
        deal();
        Person p = Person(address(items[index]));
        CommonBase.RetVal memory ret = p.newPeople().RetvalDecode();
        doRet(ret, index);
    }

    function execCommon(uint16 index, bytes memory callData) public payable {
        (bool ok,bytes memory rb) = address(items[index]).call.value(msg.value)(callData);
        if (!ok) {
            revert(string(rb));
        }
        CommonBase.RetVal memory retval = abi.decode(rb, (uint256)).RetvalDecode();
        doRet(retval, index);
    }

    function deal() public {
        if (acEmpty()) return;
        CommonBase.Action memory ac = getAction();
        if(ac.blockNo == block.number) return;
        CommonBase.RetVal memory ret = items[ac.itemNo - 1].ActionHandler(ac.ActionEncode(), rand32(ac.blockNo)).RetvalDecode();
        doRet(ret, ac.itemNo);
    }
}