pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract hashlock {
    enum Status {
        NONE,
        OPEN,
        SUCCESS,
        EXPIRED
    }
    struct lockMsg {
        bytes32 hash;
        address from;
        address payable to;
        uint256 value;
        uint256 expire;
        Status status;
    }
    lockMsg[] public lockList;
    mapping(address=>uint256[]) sendMap;
    mapping(address=>uint256[]) recvMap;
    mapping(bytes32=>uint256) hashMap;
    event lockEvent(lockMsg);
    event cancelEvent(lockMsg);
    event withdrawEvent(lockMsg);

    address payable owner;
    uint256 public minSafetime;
    uint256 public minFee;
    uint256 public fee;

    constructor()public{
        owner = msg.sender;
        minFee = 0;
        minSafetime = 30 minutes;
    }

    function lock(address payable to, bytes32 hash, uint256 expire) public payable {
        require(hashMap[hash] == 0, "lock exist");
        require(expire > block.timestamp + minSafetime, "already expired");
        lockList.push(lockMsg(hash, msg.sender, to, msg.value, expire, Status.OPEN));
        sendMap[msg.sender].push(lockList.length);
        recvMap[msg.sender].push(lockList.length);
        hashMap[hash] = lockList.length;
        emit lockEvent(lockList[hashMap[hash]-1]);
    }

    function cancel(bytes32 hash) public {
        uint256 index = hashMap[hash];
        require(index > 0, "hash not exist");
        lockMsg storage l = lockList[index-1];
        require(l.status == Status.OPEN, "lock closed");
        require(l.expire < block.timestamp, "lock not expired");
        msg.sender.transfer(l.value);
        l.status = Status.EXPIRED;
        emit cancelEvent(l);
    }

    function withdraw(bytes memory originMsg) public {
        bytes32 hash = keccak256(originMsg);
        uint256 index = hashMap[hash];
        require(index > 0, "hash not exist");
        lockMsg storage l = lockList[index-1];
        require(l.status == Status.OPEN, "lock closed");
        l.to.transfer(l.value - minFee);
        fee += minFee;
        l.status = Status.SUCCESS;
        emit withdrawEvent(l);
    }

    function feeWithdraw() public {owner.transfer(fee);}
    function () external payable {fee += msg.value;}

}