pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract L2Staking is Ownable {
    IERC20 public altToken;
    uint256 public constant MIN_STAKE = 32 * 1e18;  // 32 ALT
    uint256 public totalStaked;
    uint256 public rewardPool;
    uint256 public constant OFFLINE_THRESHOLD = 5 minutes;
    uint256 public constant SLASH_THRESHOLD = 1 hours;

    struct Validator {
        uint256 stakedAmount;
        uint256 voteWeight;  // stakedAmount / 1e18
        bool active;
        uint256 lastHeartbeat;
        bool isOnline;
    }
    mapping(address => Validator) public validators;
    address[] public validatorList;
    address public relayer;

    event Staked(address indexed validator, uint256 amount);
    event Heartbeat(address indexed validator, bool online);
    event OfflinePause(address indexed validator);
    event RewardClaimed(address indexed validator, uint256 amount);
    event Slashed(address indexed validator, uint256 amount);

    constructor(address _altToken, address _relayer) Ownable(msg.sender) {
        altToken = IERC20(_altToken);
        relayer = _relayer;
    }

    function stake(uint256 amount) external {
        require(amount >= MIN_STAKE, "Below min stake");
        altToken.transferFrom(msg.sender, address(this), amount);
        Validator storage val = validators[msg.sender];
        if (!val.active) {
            val.active = true;
            validatorList.push(msg.sender);
            val.lastHeartbeat = block.timestamp;
        }
        val.stakedAmount += amount;
        val.voteWeight = val.stakedAmount / 1e18;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function updateHeartbeat(address validator) external {
        require(msg.sender == relayer, "Only relayer");
        Validator storage val = validators[validator];
        require(val.active, "Not active");
        val.isOnline = true;
        val.lastHeartbeat = block.timestamp;
        emit Heartbeat(validator, true);
    }

    function pauseOffline(address validator) external {
        require(msg.sender == relayer || msg.sender == owner(), "Unauthorized");
        Validator storage val = validators[validator];
        if (block.timestamp - val.lastHeartbeat > OFFLINE_THRESHOLD) {
            val.isOnline = false;
            emit OfflinePause(validator);
        }
    }

    function claimRewards() external {
        Validator storage val = validators[msg.sender];
        require(val.active && val.isOnline, "Offline or inactive");
        uint256 totalVotes = totalStaked / 1e18;
        uint256 share = (rewardPool * val.voteWeight) / totalVotes;
        require(share > 0, "No rewards");
        rewardPool -= share;
        altToken.transfer(msg.sender, share);
        emit RewardClaimed(msg.sender, share);
    }

    function slash(address validator, uint256 penalty) external onlyOwner {
        Validator storage val = validators[validator];
        require(val.stakedAmount >= penalty, "Insufficient");
        if (block.timestamp - val.lastHeartbeat > SLASH_THRESHOLD) {
            val.stakedAmount -= penalty;
            val.voteWeight = val.stakedAmount / 1e18;
            totalStaked -= penalty;
            altToken.transfer(owner(), penalty / 2);
            emit Slashed(validator, penalty);
        }
    }

    function unstake(uint256 amount) external {
        Validator storage val = validators[msg.sender];
        require(val.stakedAmount >= amount, "Insufficient stake");
        val.stakedAmount -= amount;
        val.voteWeight = val.stakedAmount / 1e18;
        totalStaked -= amount;
        if (val.stakedAmount < MIN_STAKE) val.active = false;
        altToken.transfer(msg.sender, amount);
    }

    function fundRewards(uint256 amount) external onlyOwner {
        altToken.transferFrom(msg.sender, address(this), amount);
        rewardPool += amount;
    }

    function getValidators() external view returns (address[] memory, uint256[] memory) {
        uint256 len = validatorList.length;
        address[] memory addrs = new address[](len);
        uint256[] memory weights = new uint256[](len);
        for (uint i = 0; i < len; i++) {
            address addr = validatorList[i];
            addrs[i] = addr;
            weights[i] = validators[addr].voteWeight;
        }
        return (addrs, weights);
    }
}
