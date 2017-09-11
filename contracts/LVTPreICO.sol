pragma solidity ^0.4.11;

contract Owned {
  address public owner;
  function Owned() {
     owner = msg.sender; 
  }

  modifier onlyowner {
    require(msg.sender == owner);
    _;
  }
}

contract LVTPreICO is Owned {

  event Deposit(address indexed _from, uint256 _value);
  event TransferEth(uint256 _value);

  address public ethFundAddress;
  uint256 public deployBlockNum;
  uint256 public beginBlockNum;
  uint256 public endBlockNum;
  bool public isClosed;

  mapping (address => uint256) public deposits;
  uint256 public ethReceived;

  uint256 public constant ETHMIN = 198 * 10**17;
  uint256 public constant ETHMAX = 500 * 10**18;
  
  function LVTPreICO(address _ethFundAddress) {
    ethFundAddress = _ethFundAddress;
    deployBlockNum = block.number;
    beginBlockNum = 0;
    endBlockNum = 0;
    ethReceived = 0;
    isClosed = true;
  }

  function () payable {
    require(!isClosed);
    require(msg.value >= ETHMIN);
    require(msg.value <= ETHMAX);

    ethReceived += msg.value;
    deposits[msg.sender] += msg.value;

    Deposit(msg.sender, msg.value);
  }

  function transferETH() onlyowner {
    uint256 total = this.balance;
    require(total > 0);
    require(ethFundAddress.send(total));
    
    TransferEth(total);
  }

  function beginNow() onlyowner {
    require(isClosed);
    isClosed = false;
    beginBlockNum = block.number;
  }

  function closeNow() onlyowner {
    require(!isClosed);
    isClosed = true;
    endBlockNum = block.number;
  }
}


