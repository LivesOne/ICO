pragma solidity ^0.4.11;

contract ThrowableCalc {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      require((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      require(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      require((x == 0)||(z/x == y));
      return z;
    }
}

contract LVTPreICO is ThrowableCalc {

  event Deposit(address indexed _from, uint256 _eth, uint256 _lvt);
  event TransferEth(uint256 _value);

  address public ethFundAddress;
  uint256 public deployBlockNum;
  uint256 public beginBlockNum;
  uint256 public endBlockNum;
  bool public isClosed;

  mapping (address => uint256) public deposits;
  mapping (address => uint256) public allocations;
  uint256 public lvtCreated;
  uint256 public ethReceived;

  uint256 public constant EXPONENT = 10**18;
  uint256 public constant LVTCREATIONCAP = 100 * (10**6) * EXPONENT;
  uint256 public constant EXCHANGERATE100 = 9333;
  uint256 public constant EXCHANGERATE95 = 9824;
  uint256 public constant EXCHANGERATE85 = 10980;
  uint256 public constant EXCHANGERATE75 = 12444;
  uint256 public constant ETHMIN = 20 * EXPONENT;
  uint256 public constant ETHMAX = 500 * EXPONENT;
  
  function LVTPreICO(address _ethFundAddress) {
    ethFundAddress = _ethFundAddress;
    deployBlockNum = block.number;
    beginBlockNum = 0;
    endBlockNum = 0;
    lvtCreated = 0;
    ethReceived = 0;
    isClosed = true;
  }

  function calcSupply(uint256 eth) internal returns(uint256) {
    require(eth >= ETHMIN);
    require(eth <= ETHMAX);

    uint256 tokens = 0;
    uint256 ethtotal = eth;

    if (ethtotal > 100 * EXPONENT) {
      tokens = EXCHANGERATE100 * 20 * EXPONENT + EXCHANGERATE95 * 30 * EXPONENT + EXCHANGERATE85 * 50 * EXPONENT + EXCHANGERATE75 * (ethtotal - 100 * EXPONENT);
    } else if (ethtotal > 50 * EXPONENT) {
      tokens = EXCHANGERATE100 * 20 * EXPONENT + EXCHANGERATE95 * 30 * EXPONENT + EXCHANGERATE85 * (ethtotal - 50 * EXPONENT);
    } else if (ethtotal > 20 * EXPONENT) {
      tokens = EXCHANGERATE100 * 20 * EXPONENT + EXCHANGERATE95 * (ethtotal - 20 * EXPONENT);
    } else {
      tokens = EXCHANGERATE100 * ethtotal;
    }

    return tokens;
  }


  function () payable {
    require(msg.value > 0);
    require(!isClosed);
    require(block.number <= endBlockNum);
    require(lvtCreated < LVTCREATIONCAP);

    uint256 ethTotal = safeAdd(msg.value, deposits[msg.sender]);
    require(ethTotal >= ETHMIN);
    require(ethTotal <= ETHMAX);

    uint256 tokens = safeSubtract(calcSupply(ethTotal), allocations[msg.sender]);
    uint256 checkedSupply = safeAdd(lvtCreated, tokens);
    require(LVTCREATIONCAP >= checkedSupply);
    lvtCreated += tokens;
    ethReceived += msg.value;
    allocations[msg.sender] += tokens;
    deposits[msg.sender] += msg.value;

    Deposit(msg.sender, msg.value, tokens);
  }

  function transferETH() external {
    require(msg.sender == ethFundAddress);
    uint256 total = this.balance;
    require(total > 0);
    require(ethFundAddress.send(total));
    
    TransferEth(total);
  }

  function beginNow(uint256 durationBlockNum) external {
    require(msg.sender == ethFundAddress);
    require(isClosed);
    isClosed = false;
    beginBlockNum = block.number;
    endBlockNum = beginBlockNum + durationBlockNum;
  }

  function closeNow() external {
    require(msg.sender == ethFundAddress);
    require(!isClosed);
    isClosed = true;
  }
}

