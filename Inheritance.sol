pragma solidity ^0.8.0;


/// @title Inheritance contract
/// @author Petar Calic
/// @notice Contract that alows one owner to wthdraw ETH from the contract. 
/// @dev If it takes more than a month his heir becomes the owner and he has to choose his heir. After withdrawing the counter resets.
contract Inheritance {
    address public owner; 
    address public heir; 
    uint256 public newOwnerTime;

    modifier ownerOnly() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    event OwnerTimeUpdated();
    event NewOwner(address owner, address heir);
    
    function updateOwnerTime() private {
        newOwnerTime = block.timestamp;
        emit OwnerTimeUpdated();
    }

    /// @dev Set msg.sender as owner.
    constructor(address _heir) {
        owner = msg.sender;
        heir = _heir;
        updateOwnerTime();
        emit NewOwner(owner, heir);
    }

    /// @dev Place inheritence in the contract balance fund
    receive() external payable {}

    /**  @notice Can be call by the heir to become the new owner if the 
                 owner didn't interact with the contract for one month */
    function becomeOwner(address newHeir) external {
        require(
            msg.sender == heir && block.timestamp > (newOwnerTime + 30 days),
            "Owner can set the new heir after 30 days"
        );
        owner = heir;
        heir = newHeir;

        updateOwnerTime();

        emit NewOwner(owner, heir);
    }

    /// @dev withdrawing funds and reset time
    function withdraw() external ownerOnly {
        updateOwnerTime();
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = owner.call{value: balance}("");
            require(success == true, "Error during the withdraw");
        }
    }
}