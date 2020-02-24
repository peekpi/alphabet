pragma solidity ^0.5.0;
import "../versionable/Versionable.sol";

contract Delegatecallable is Versionable {
    address public logicAddress;

    event DelegateResult(address dest);
    event ProxyCall(address dest);
    event LogicAddressChanged(address oldAddress, address newAddress);
    modifier goDelegateCall {
        if (logicAddress != address(0)) {
            (bool result,bytes memory mesg) = logicAddress.delegatecall(msg.data);
            if (!result) revert(string(mesg));
            emit DelegateResult(logicAddress);
            assembly {return(add(mesg, 0x20), mload(mesg))}
        }
        _;
    }
    function ChangeLogicAddress(address newLogicAddress) external;
    function changeLogicAddress(address newLogicAddress) internal {
        string memory newVersion;
        if (newLogicAddress == address(0)) {
            newVersion = initVersion;
        } else {
            newVersion = Versionable(newLogicAddress).getCodeVersion();
        }
        emit ChangeVersion(codeVersion, newVersion);
        emit LogicAddressChanged(logicAddress, newLogicAddress);
        codeVersion = newVersion;
        logicAddress = newLogicAddress;
    }

    function proxyCall(address dest, bytes memory msgData) internal {
        (bool ok,bytes memory rb) = dest.delegatecall(msgData);
        if (!ok) revert(string(rb));
        emit ProxyCall(dest);
        assembly {return(add(rb, 0x20), mload(rb))}
    }
}

contract RouteProxy is Delegatecallable{
    address[] public routeTable;
    mapping(address=>uint256) public routeMap;
    function AddRoute(address route) external;
    function addRoute(address route) internal goDelegateCall{
        require(routeMap[route] == 0, "route exist");
        routeTable.push(route);
        routeMap[route] = routeTable.length;
    }

    function() external payable goDelegateCall {
        bytes memory msgData = msg.data;
        uint256 index;
        assembly {index := mload(add(msgData, 36))} // length + sig4
        proxyCall(routeTable[index], msgData);
    }
    /*
    function() external payable goDelegateCall {
        uint256 index = abi.decode(msg.data[4:36], (uint256));
        proxyCall(routeTable[index], msg.data);
    }
    */
}