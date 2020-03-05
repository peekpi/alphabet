pragma solidity ^0.5.0;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address payable public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor(address payable _owner) public {
        owner = _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender != owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address payable _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    bool public opening;
    modifier onlyOpen() {require(opening, "onlyOpen");_;}
    modifier onlyClose() {require(!opening, "onlyClose");_;}
    function setOpen(bool open) public onlyOwner {
        opening = open;
    }
    function destory() internal onlyOwner {
        selfdestruct(owner);
    }
}

contract Indirect {
    address public indirect;

    constructor(address _indirect) public {
        indirect = _indirect;
    }

    modifier onlyIndirect(){require(msg.sender == indirect, "onlyIndirect");_;}
}
