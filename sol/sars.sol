pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./common/random/rand.sol";

library MathLib {
    function arith100(uint256 a, uint256 b, bool minus) internal pure returns(uint256) {
        if(minus){
            if(a < b)
                b = a;
            return a - b;
        }
        a += b;
        if(a > 100)
            a = 100;
        return a;
    }
}

interface CommonType {
    enum ActionType {
        Normal,
        Item
    }
    struct Action {
        address owner; // u160
        uint256 blockNo; // u32
        ActionType typ; // u16
    }

    function actionEncode(Action memory ac) private pure returns(uint256) {
        return uint256(ac.typ) | (ac.blockNo << 16) | (uint256(ac.owner) << 96);
    }
    function actionDecode(uint256 en) private pure returns(Action memory) {
        return Action(address(en>>96), (en>>16)&0xffffffff, ActionType(en&0xffff));
    }

    struct Person{
        uint256 health; // 健康度 0-100
        uint256 virus;  // 病毒力 0-100
        uint256 magicCenter; // 魔幻数字 0-100
        uint256 magicRange; // 魔幻范围
        uint256 immunity; // 抵抗力 0-99
        uint256 birth;  // 出生数字
        address owner; // 地址
    }

    function PersonEncode(Person memory p) private pure returns(uint256) {
        return p.health |
        (p.virus << 8) |
        (p.magicCenter << 16) |
        (p.magicRange << 24) |
        (p.immunity << 32) |
        (p.birth << 40) |
        (uint256(p.owner)<<96);
    }
    function PersonDecode(uint256 pen) private pure returns(Person memory) {
        return Person(
            pen&0xff,
            (pen>>8)&0xff,
            (pen>>16)&0xff,
            (pen>>24)&0xff,
            (pen>>32)&0xff,
            (pen>>40)&0xffffffff,
            address(pen>>96)
        );
    }

    struct RetVal {
        bool isEvent;
        uint256 eventVal;
    }
}

interface ItemBase {
    // item: {blockNo, lifeNu, status}
    // expire 是否过期
    // use 立即生效or判定Action
    // transfer 自由转让？过期？
    // pushAction 放action
    // map: sender => uid => value
    // map: uid => attr
    function expire(uint256 itemID) public returns (CommonType.RetVal memory);
    function use(uint256 itemID) public returns (CommonType.RetVal memory);
    function transfer(address to, uint256 itemID) public;
}

contract ItemN95 {
    struct N95 {
        uint256 createNo;
        uint256 expire;
    }
    N95[] public items;
    mapping(address=>uint256[]) public _ownedN95;
    mapping(address=>uint256) public _ownedAccount;
    address public game;
    modifier onlyGame() {require(msg.sender == game, "onlyGame");_;}
    function buy() public returns(CommonType.RetVal memory){

    }
    function use(CommonType.Person memory p) public onlyGame returns(CommonType.RetVal memory) {
        p.magicRange -= 5;
    }

    function Callback(uint256 en, uint256 r) public return(CommonType.RetVal memory) {
        
    }

}

contract PersonBase is random {

    modifier onlyHuman() {
        require(msg.sender == tx.origin, "only human");
        _;
    }

    struct Person{
        uint256 health; // 健康度 0-100
        uint256 virus;  // 病毒力 0-100
        uint256 magicCenter; // 魔幻数字 0-100
        uint256 magicRange; // 魔幻范围
        uint256 immunity; // 抵抗力 0-99
        uint256 birth;  // 出生数字
        address owner; // 地址
    }
    mapping(address=>uint256) public Persons;

    function PersonEncode(Person memory p) private pure returns(uint256) {
        return p.health |
        (p.virus << 8) |
        (p.magicCenter << 16) |
        (p.magicRange << 24) |
        (p.immunity << 32) |
        (p.birth << 40) |
        (uint256(p.owner)<<96);
    }
    function PersonDecode(uint256 pen) private pure returns(Person memory) {
        return Person(
            pen&0xff,
            (pen>>8)&0xff,
            (pen>>16)&0xff,
            (pen>>24)&0xff,
            (pen>>32)&0xff,
            (pen>>40)&0xffffffff,
            address(pen>>96)
        );
    }
    
    function newPerson() private view returns(Person memory) {
        return Person(90, 10, 0, 10, 4, block.number, msg.sender);
    }

    function isActive(Person memory p) private pure returns(bool) {
        return p.magicCenter > 0;
    }

    function Register() public {
        uint256 en = Persons[msg.sender];
        require(en == 0, "registered");
        Person memory p = newPerson();
        Persons[msg.sender] = PersonEncode(p);
    }

    function Active() public {
        uint256 en = Persons[msg.sender];
        require(en > 0, "only brith");
        Person memory p = PersonDecode(en);
        require(p.magicCenter == 0, "actived");
        p.magicCenter = rand32(p.birth)%100;
    }

    function EventHandle(uint256 en, uint256 r) internal {
        Person memory p = PersonEncode(p);
        require(p.magicCenter == 0, "actived");
        p.magicCenter = rand32(p.birth)%100;
        setPerson(p);
    }

    function getPerson(address owner) internal view returns(Person memory) {
        return PersonDecode(Persons[owner]);
    }
    function setPerson(Person memory p) internal {
        Persons[p.owner] = PersonEncode(p);
    }

    function addHealth(Person memory p, uint256 health, bool minus) internal pure {
        require(p.health > 0, "only live");
        p.health = arith100(p.health, health, minus);
    }

    function addVirus(Person memory p, uint256 virus, bool minus) internal pure {
        p.virus = arith100(p.virus, virus, minus);
    }
    function addMagicRange(Person memory p, uint256 range, bool minus) internal pure {
        p.magicRange = arith100(p.magicRange, range, minus);
    }
    function addImmunity(Person memory p, uint256 immunity, bool minus) internal pure {
        p.immunity = arith100(p.immunity, immunity, minus);
    }
    function infectJudge(Person memory p, uint256 r32) internal pure returns (uint256) {
        uint256 loc = r32 % 100;
        if (loc > p.magicCenter)
            loc = loc - p.magicCenter;
        else
            loc = p.magicCenter - loc;
        if (loc > p.magicRange)
            return 0;
        return loc == 0 ? 2 : 1;
    }
}

contract ActionBase {
    enum ActionType {
        Normal,
        Item
    }
    struct Action {
        address owner; // u160
        uint256 blockNo; // u32
        ActionType typ; // u16
    }
    uint256 public nextAction;
    uint256[] public actions;
    function actionEncode(Action memory ac) private pure returns(uint256) {
        return uint256(ac.typ) | ac.blockNo<<16 | (uint256(ac.owner) << 96);
    }
    function actionDecode(uint256 en) private pure returns(Action memory) {
        return Action(address(en>>96), (en>>16)&0xffffffff, ActionType(en&0xffff));
    }
    function newAction(ActionType typ) internal returns(Action memory ac) {
        ac = Action(msg.sender, block.number, typ);
        actions.push(actionEncode(ac));
    }
    function getAction() internal returns(Action memory ac) {
        return actionDecode(actions[nextAction++]);
    }

    function acEmpty() internal view returns(bool) {
        return nextAction == actions.length;
    }
}

contract SARS is ActionBase,PersonBase {
    function infectTry() public {
        if(acEmpty())
            return;
        Action memory ac = getAction();
        if(ac.blockNo == block.number)
            return;
        if(ac.typ == ActionBase.ActionType.Item) {
            // do Item
            return;
        }
        uint256 r = rand32(ac.blockNo);
        Person memory p = getPerson(ac.owner);
        r = infectJudge(p, r);
        addVirus(p, r, false);
        setPerson(p);
    }
    function BuyN95() public {

    }
    function BuyFood() public {

    }
    function BuyMedicine() public {

    }
    function UseN95() public {

    }
    function UseFood() public {

    }
    function UseMedicine() public {

    }
    function DoExercise() public {
        Person memory p = getPerson(msg.sender);
        addHealth(p, 1, true);
        addImmunity(p, 1, false);
        setPerson(p);
    }
    
}