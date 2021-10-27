// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.7;

contract SponsorFunding {
    
    uint availableFunds;
    uint sponsorPercentage;
    
    constructor (uint _sponsorPercentage) payable {
        if (_sponsorPercentage <= 0 || _sponsorPercentage > 100) {
            revert("The sponsorship percentage must be a valid integer between 0 and 100!");
        }
        availableFunds = msg.value;
        sponsorPercentage = _sponsorPercentage;
    }
    
    modifier onlyByCrowdContract (address payable crowdContractAddress) {
        require(msg.sender == crowdContractAddress, "Only the Crowd Contract can initiate this action!");
        _;
    }
    
    function getSponsorSumToBeReceivedOrRefunded (uint amount) public view returns (uint) {
        return (amount * sponsorPercentage) / 100;
    }
    
    function makeSponsorshipTransaction(uint crowdBalance, address payable crowdContractAddress) onlyByCrowdContract(crowdContractAddress) external {
        uint totalSponsorSum = getSponsorSumToBeReceivedOrRefunded(crowdBalance);
        if (availableFunds >= totalSponsorSum) {
            crowdContractAddress.transfer(totalSponsorSum);
        }
        else {
            revert("Not enough available funds in sponsor balance!");
        }
    }
}