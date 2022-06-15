//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

/// from https://github.com/MaxMustermann2/harmony-staking-precompiles/blob/main/contracts/lib/StakingPrecompiles.sol
interface BrickBuidlersInterface {
    function tokenOfOwnerByIndex( address , uint256 ) external view returns(uint256);
}

interface C2SafeStakeInterface {
    function bytecodeHash() external returns(bytes32);
}

abstract contract StakingPrecompilesSelectors {
    function Delegate(address delegatorAddress,
        address validatorAddress,
        uint256 amount) public virtual;

    function Undelegate(address delegatorAddress,
        address validatorAddress,
        uint256 amount) public virtual;

    function CollectRewards(address delegatorAddress) public virtual;

    function Migrate(address from, address to) public virtual;
}

library Staking {
    enum StakingAction {
        CREATE_VALIDATOR, // unused
        EDIT_VALIDATOR, // unused
        DELEGATE,
        UNDELEGATE,
        COLLECT_REWARDS
    }

    event StakingSuccess(StakingAction action, address validatorAddress, uint256 amount, uint256 result);
    event StakingFailure(StakingAction action, address validatorAddress, uint256 amount, uint256 result);

    function _delegate(address validatorAddress, uint256 amount) internal returns (uint256 result) {
        bytes memory encodedInput = abi.encodeWithSelector(StakingPrecompilesSelectors.Delegate.selector,
            address(this),
            validatorAddress,
            amount);
        assembly {
        // we estimate a gas consumption of 25k per precompile
            result := call(25000,
            0xfc,
            0x0,
            add(encodedInput, 32),
            mload(encodedInput),
            mload(0x40),
            0x20
            )
        }
    }

    function _undelegate(address validatorAddress, uint256 amount) internal returns (uint256 result) {
        bytes memory encodedInput = abi.encodeWithSelector(StakingPrecompilesSelectors.Undelegate.selector,
            address(this),
            validatorAddress,
            amount);
        assembly {
            result := call(25000,
            0xfc,
            0x0,
            add(encodedInput, 32),
            mload(encodedInput),
            mload(0x40),
            0x20
            )
        }
    }

    function _collectRewards() internal returns (uint256 result) {
        bytes memory encodedInput = abi.encodeWithSelector(StakingPrecompilesSelectors.CollectRewards.selector,
            address(this));
        assembly {
            result := call(
            25000,
            0xfc,
            0x0,
            add(encodedInput, 32),
            mload(encodedInput),
            mload(0x40),
            0x20
            )
        }
    }
}

contract SafeStaking {

    address public c2SafeStakeContract = 0xA831F4e5dC3dbF0e9ABA20d34C3468679205B10A;
    address public BrickBuidlersContract = 0x23F3A7B2dF75B131595B6Fe6b452f68a8362d67C;
    bytes32 public codeHash = C2SafeStakeInterface(c2SafeStakeContract).bytecodeHash();

    mapping ( address => uint256  ) public delegatedToValidator;
    mapping ( address => bool ) public isMyValidator;
    address [] public validators;

    function userWithdraw(address to, uint256 amount) public payable {
        require(address(this) == Create2.computeAddress( bytes32(BrickBuidlersInterface(BrickBuidlersContract).tokenOfOwnerByIndex(msg.sender, 0)), codeHash));
        Address.sendValue( payable(to) , amount );
    }

    function delegate(address validatorAddress, uint256 amount) public returns (bool) {
        require(address(this) == Create2.computeAddress( bytes32(BrickBuidlersInterface(BrickBuidlersContract).tokenOfOwnerByIndex(msg.sender, 0)), codeHash));
        uint256 result = Staking._delegate(validatorAddress, amount);
        bool success = result != 0;
        if (success) {
            if ( isMyValidator[validatorAddress] == false ) {
                isMyValidator[validatorAddress] = true;
                validators.push(validatorAddress);
            }
            delegatedToValidator[validatorAddress] += amount;
            emit Staking.StakingSuccess(Staking.StakingAction.DELEGATE, validatorAddress, amount, result);
        } else {
            emit Staking.StakingFailure(Staking.StakingAction.DELEGATE, validatorAddress, amount, result);
        }
        return success;
    }

    function undelegate(address validatorAddress, uint256 amount) public returns (bool) {
        require(address(this) == Create2.computeAddress( bytes32(BrickBuidlersInterface(BrickBuidlersContract).tokenOfOwnerByIndex(msg.sender, 0)), codeHash));
        uint256 result = Staking._undelegate(validatorAddress, amount);
        bool success = result != 0;
        if (success) {
            delegatedToValidator[validatorAddress] -= amount;
            emit Staking.StakingSuccess(Staking.StakingAction.UNDELEGATE, validatorAddress, amount, result);
        } else {
            emit Staking.StakingFailure(Staking.StakingAction.UNDELEGATE, validatorAddress, amount, result);
        }
        return success;
    }

    function collectRewards() public returns (bool) {
        require(address(this) == Create2.computeAddress( bytes32(BrickBuidlersInterface(BrickBuidlersContract).tokenOfOwnerByIndex(msg.sender, 0)), codeHash));
        uint256 result = Staking._collectRewards();
        bool success = result != 0;
        if (success) {
            emit Staking.StakingSuccess(Staking.StakingAction.COLLECT_REWARDS, address(0), 0, result);
        } else {
            emit Staking.StakingFailure(Staking.StakingAction.COLLECT_REWARDS, address(0), 0, result);
        }
        return success;
    }

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
            delegate(delegation.validator, delegation.amount);
            
        }
        
    }
    // Undelegate to an array of validators
    function multiUndelegate(Undelegation[] memory undelegations) public {
        
        uint256 length = undelegations.length;
        Undelegation memory undelegation;
        for(uint256 i = 0; i < length; i ++) {
            undelegation = undelegations[i];
            undelegate(undelegation.validator, undelegation.amount);
            
        }
        

    }

    function epoch() public view returns (uint256) {
        bytes32 input;
        bytes32 epochNumber;
        assembly {
            let memPtr := mload(0x40)
            if iszero(staticcall(not(0), 0xfb, input, 32, memPtr, 32)) {
                invalid()
            }
            epochNumber := mload(memPtr)
        }
        return uint256(epochNumber);
    }

    fallback() external payable {}
    receive() external payable {}

}
