// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.7;

contract SponsorFunding {
    
    uint availableFunds;
    uint sponsorPercentage;
    address owner;
    address payable crowdContractAddress;
    bool alreadyOfferedSponsorMoney;
    
    constructor (uint _sponsorPercentage) payable {
        if (_sponsorPercentage <= 0 || _sponsorPercentage > 100) {
            revert("The sponsorship percentage must be a valid integer between 0 and 100!");
        }
        availableFunds = msg.value;
        sponsorPercentage = _sponsorPercentage;
        owner = msg.sender;
        alreadyOfferedSponsorMoney = false;
    }
    
    modifier onlyBySponsorFundingOwner () {
        require(msg.sender == owner, "Only this contract's owner can set the Crowd Contract address!");
        _;
    }
    
    modifier onlyByCrowdContract () {
        require(msg.sender == crowdContractAddress, "Only the Crowd Contract can initiate this action!");
        _;
    }
    
    function setCrowdContractAddress (address payable _crowdContractAddress) onlyBySponsorFundingOwner external {
        crowdContractAddress = _crowdContractAddress;
    }
    
    function getSponsorSumToBeReceivedOrRefunded (uint amount) public view returns (uint) {
        return (amount * sponsorPercentage) / 100;
    }
    
    function makeSponsorshipTransaction(uint crowdBalance) onlyByCrowdContract external {
        uint totalSponsorSum = getSponsorSumToBeReceivedOrRefunded(crowdBalance);
        if (availableFunds >= totalSponsorSum && alreadyOfferedSponsorMoney == false) {
            payable(msg.sender).transfer(totalSponsorSum);
            alreadyOfferedSponsorMoney = true;
        }
        else {
            revert("Sponsor money was already received or there is not enough money in the sponsor's balance!");
        }
    }
}