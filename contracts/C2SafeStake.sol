// SPDX-License-Identifier: MIT
// @title Brick Buidlers
// @author bouncePass Labs
// @custom:security-contact kbetzjr@gmail.com

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";


interface BrickBuidlersInterface {
    function safeMint(address) external payable;
    function tokenIdAt() external view returns(uint256);
    function tokenOfOwnerByIndex( address , uint256 ) external view returns(uint256);

}

interface SafeStakingInterface  {
    function userWithdraw(address , uint256) external payable;
    function delegate(address , uint256) external returns (bool);
    function undelegate(address , uint256) external returns (bool);
    function collectRewards() external returns (bool);

}

//C2SafeStake allows a user to deploy a safe for native staking.
contract C2SafeStake  {

    bool public initialized;

    address public BrickBuidlersContract = 0x8431717927C4a3343bCf1626e7B5B1D31E240406;
   // uint256 public brickId = BrickBuidlersInterface(BrickBuidlersContract).tokenIdAt();

    //SafeStaking Contract bytecode
    bytes public bytecode;

    //Stored during initialize
    bytes32 public bytecodeHash;

    //brickId to Safe Address
    mapping (uint256 => address) public BrickIdToSafe;

    //brick price
    uint256 public mintPrice;

    //log brickId when vault created
    event brickReg( uint256 );

    struct Delegation {
        address validator;
        uint256 amount;
    }

    struct Undelegation {
        address validator;
        uint256 amount;
    }
        // Delegate to an array of validators
    function multiDelegate(Delegation[] memory delegations) public {
        
        uint256 length = delegations.length;
        Delegation memory delegation;
        for(uint256 i = 0; i < length; i ++) {
            delegation = delegations[i];
            SafeStakingInterface(depositAddress()).delegate(delegation.validator, delegation.amount);
            
        }
        
    }
    // Undelegate to an array of validators
    function multiUndelegate(Undelegation[] memory undelegations) public {
        
        uint256 length = undelegations.length;
        Undelegation memory undelegation;
        for(uint256 i = 0; i < length; i ++) {
            undelegation = undelegations[i];
            SafeStakingInterface(depositAddress()).undelegate(undelegation.validator, undelegation.amount);
            
        }
        

    }

    //initialize and submit bytecode for SafeStaking contract, store hash
    function initialize( bytes memory _bytecode ) public {
        require(initialized == false);
        initialized = true;
        bytecode = _bytecode;
        bytecodeHash = keccak256(bytecode);
    }


    //brickId specific deposit address == SafeStaking contract address
    function depositAddress() public view returns(address){
        uint256 _brickId = BrickBuidlersInterface(BrickBuidlersContract).tokenOfOwnerByIndex( msg.sender , 0 );
        return Create2.computeAddress( bytes32(uint256(_brickId)), bytecodeHash, address(this)  );

    }

    //true if address is contract based on presence of data
    function depositAddressDeployed() public view returns(bool) {
        return Address.isContract(depositAddress());
    }

    function setBrickPrice(uint256 _price) external {
        mintPrice = _price;
    }

    //builds SafeStaking and mints Brick
    function registerSafeAddress() external payable {
        require(msg.value == mintPrice);
        uint256 brickId = BrickBuidlersInterface(BrickBuidlersContract).tokenIdAt();
        buildSafeStaking(brickId);
        BrickBuidlersInterface(BrickBuidlersContract).safeMint( msg.sender);
    }
   
    //internal build user safe using Create2, brickId as salt and bytecode from SafeStaking contract
    function buildSafeStaking(uint256 brickId) internal returns (address) {
        address userSafe = Create2.deploy( 0 , bytes32(uint256(brickId)) , bytecode);
        BrickIdToSafe[brickId] = userSafe;
        emit brickReg(brickId);
        return userSafe;
    }

    //deposit from user in ONE
    function deposit() external payable {
        require(msg.value > 0);
        require(depositAddressDeployed() == true);
        address to = depositAddress();
        Address.sendValue( payable(to) , msg.value );
        //(bool success,) = payable(to).call{value: msg.value }("");
        //require(success);
    }



    function withdraw(uint256 amount) external {
        address _sender = msg.sender;
        SafeStakingInterface S = SafeStakingInterface(depositAddress());
        S.userWithdraw( _sender , amount );

    }



    //withdraw ONE from C2Safe JustInCase(JIC)
    function withdrawC2Safe(uint256 amount) external payable {
        Address.sendValue( payable(msg.sender) , amount );
    }

    //receive() external payable {}
    //fallback() external payable {}

}
