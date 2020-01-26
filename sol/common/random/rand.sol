pragma solidity ^0.5.0;

contract random {
    uint256 seed;
    mapping(uint256=>bytes32) public Hashes;

    function FeedHashes(uint256 number, uint256 _hash) external onlyOwner {
        Hashes[number] = bytes32(_hash);
    }

    function blockHashUnsafe(uint256 number) private view returns (bytes32 _hash){
        _hash = blockhash(number);
        if(uint256(_hash) == 0)
            _hash = Hashes[number];
    }

    function blockHash(uint256 number)private view returns (bytes32 _hash){
        _hash = blockHashUnsafe(number);
        require(uint256(_hash) > 0, "hash check");
    }

    function update(uint256 s) private pure returns(uint256) {
        return s&0xffffffff;
    }
    function rand32(uint256 no) private returns(uint256)  {
        if( no > (seed>>32))
            seed = (no << 32) | update(uint256(blockHash(no)));
        else
            seed = (seed & (~uint256(0xffffffff))) | update(seed&0xffffffff);
        return seed&0xffffffff;
    }
}