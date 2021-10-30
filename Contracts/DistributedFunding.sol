// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.7;


contract ShareHolder {

     address payable shareHolderAddress;
         event receivedFunds(address, uint);
  receive() external payable {
       emit receivedFunds(msg.sender, msg.value);
   }
}

contract DistributedFunding{
    address payable[] shareHolders;
    uint totalShares;
    uint leftShares;
    mapping(address => uint) sharesPerShareHolder;
    event receivedFunds(address, uint);
    address payable crowdContractAddress;
    address owner;

    constructor(uint _totalShares) {
        totalShares = _totalShares;
        leftShares = _totalShares;
                owner = msg.sender;

    }
    
   receive() external payable {
       emit receivedFunds(msg.sender, msg.value);
   }
   
   modifier onlyDistributedFundingOwner () {
        require(msg.sender == owner, "Only this contract's owner can set the Crowd Contract address!");
        _;
    }
    
     modifier onlyByCrowdContract () {
        require(msg.sender == crowdContractAddress, "Only the Crowd Contract can initiate this action!");
        _;
    }
    
   function setCrowdContractAddress (address payable _crowdContractAddress) onlyDistributedFundingOwner external {
        crowdContractAddress = _crowdContractAddress;
    }
  
     function getBalance() external view returns (uint) {
        return address(this).balance;
    }
    
    function addSharesToShareHolder(uint numberOfShares, address payable addressOfShareHolder) public onlyDistributedFundingOwner{
        if(numberOfShares <= leftShares){
            leftShares -= numberOfShares;
            sharesPerShareHolder[addressOfShareHolder] += numberOfShares;
            shareHolders.push(addressOfShareHolder);
        }
        else{
            revert("Not Enough Shares Left");
        }
    }
    
    function removeSharesFromShareHolder(uint numberOfShares, address payable addressOfShareHolder) public onlyDistributedFundingOwner{
        if(numberOfShares > sharesPerShareHolder[addressOfShareHolder]){
            revert("You don't have that many shares! ");
        }
        sharesPerShareHolder[addressOfShareHolder] -= numberOfShares;
        leftShares += numberOfShares;
    }
    
    function createShareHolder() public returns(ShareHolder){
        ShareHolder shareHolder = new ShareHolder();
        return shareHolder;
    
    }
    
    function distributeFunds() external payable {
        uint funds = address(this).balance;
        uint sharesToBeDistributed = totalShares - leftShares;
        if(sharesToBeDistributed == 0){
            revert("There are no shares to be distributed!");
        }
        for(uint index = 0; index< shareHolders.length; index++){
            payable(shareHolders[index]).transfer((funds * sharesPerShareHolder[shareHolders[index]])/sharesToBeDistributed);
        }
    }
    
    function getLeftShares() public view returns(uint){
        return leftShares;
    }
    
    
   
}