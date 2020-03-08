pragma solidity ^0.5.0;

contract random {
    mapping(uint256=>uint256) private seeds;
    mapping(uint256=>bytes32) public Hashes;

    function feedHash(uint256 number, uint256 _hash) internal {
        Hashes[number] = bytes32(_hash);
    }

    function FeedHash(uint256 number, uint256 _hash) external;

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
        return uint256(keccak256(abi.encodePacked(s)));
    }
    function rand32(uint256 no) internal returns(uint256)  {
        uint256 seed = seeds[no];
        if(seed == 0)
            seed = uint256(blockHash(no));
        seed = update((no << 224) | seed);
        seeds[no] = seed;
        return seed;
    }
}