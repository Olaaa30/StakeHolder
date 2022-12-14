// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PriceConverter.sol";

error NotOwner();
error InsufficientStake(uint256 _minAVAX);
error StakingPeriodElapsed();
error StakeBeingUsed();
error ZeroStakeBalance();

/// @title StakeHolder
/// @author Shootfish XYZ
contract StakeHolder is Ownable, ReentrancyGuard {
    /// @todo add natspec comments to functions in this contract
    using PriceConverter for uint256;

    uint8 private constant DECIMALS = 18;
    uint256 private constant STAKING_PERIOD = 365 days;
    uint256 private constant MINIMUM_AVAX = 1 * (10 ** DECIMALS);
    address public contractOwner;

    uint256 public totalStake;
    address[] private stakers;
    mapping(address => uint256) private amountStaked;

    enum Action {
        FUND,
        WITHDRAW
    }
    enum StakingStatus {
        PENDING,
        IN_STAKE,
        ENDED
    }
    StakingStatus public stakingStatus;

    constructor() {
        stakingStatus = StakingStatus.PENDING;
    }

    event Withdraw(address _contractOwner, uint256 value);
    event Fund(address sender, uint256 value);

    function fund() public payable {
        require(msg.value >= MINIMUM_AVAX, "You need to spend more avax");
        // if (msg.value.getUsdAmount < MINIMUM_USD) revert InsufficientStake();
        stakers.push(msg.sender);
        amountStaked[msg.sender] += msg.value;
        totalStake += msg.value;

        // addFunder(msg.sender, msg.value);
    }

    function withdraw() public onlyOwner {
        address[] memory _stakers = stakers;
        for (uint256 _stakersIndex = 0; _stakersIndex < _stakers.length; ) {
            _sync(_stakers[_stakersIndex], Action.WITHDRAW);
            unchecked {
                ++_stakersIndex;
            }
        }

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
        totalStake = 0;
    }

    // function addFunder(address _funderAddress, uint256 _amountFunded) internal returns(uint256){
    //     funderCount+=1;
    //     // funders.push(Funder(funderCount, _funderAddress, _amountFunded));
    //     return funderCount;
    // }
    // modifier onlyOwner() {
    //     require(msg.sender == contractOwner, "UNAUTHORIZED!!");
    //     if (msg.sender != contractOwner) revert NotOwner();
    //     _;
    // }

    function activate() external onlyOwner returns (StakingStatus) {
        stakingStatus = StakingStatus.IN_STAKE;
        return stakingStatus;
    }

    function stakingEnded() external returns (StakingStatus) {
        stakingStatus = StakingStatus.ENDED;
        return stakingStatus;
    }

    /* Private Functions */
    function _sync(address _account, Action _action) private {
        uint256 lastIndex = stakers.length - 1;

        if (_action == Action.FUND) {
            for (uint256 i = 0; i < stakers.length; ) {
                if (stakers[i] == _account) {
                    break;
                } else if (i == lastIndex) {
                    stakers.push(_account);
                }

                unchecked {
                    ++i;
                }
            }
        } else if (_action == Action.WITHDRAW) {
            for (uint256 i = 0; i < stakers.length; ) {
                if (stakers[i] == _account) {
                    if (i != lastIndex) {
                        stakers[i] = stakers[lastIndex];
                    }
                    stakers.pop();
                    amountStaked[_account] = 0;
                    break;
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    function getStaker(uint256 _index) public view returns (address funder) {
        return stakers[_index];
    }

    function getAmountStaked(
        address _funder
    ) public view returns (uint256 _amountStaked) {
        return amountStaked[_funder];
    }

    //contract recieves avax
    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}
