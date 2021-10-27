// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.7;

import "SponsorFunding.sol";

contract CrowdFunding {
    
    uint fundingGoal;
    uint accumulatedSumExcludingSponsorship;
    uint accumulatedSumIncludingSponsorship;
    possibleState currentState;
    address contractOwner;
    SponsorFunding sponsorFundingContract;
    
    enum possibleState {
        FUNDING_GOAL_NOT_REACHED,
        FUNDING_GOAL_REACHED
    }
    
    struct Contributor {
        string name;
        uint contribution;
        address payable bankAccount;
    }
    
    mapping (address => Contributor) contributors;
    
    constructor (uint _fundingGoal, SponsorFunding _sponsorFundingContract) {
        fundingGoal = _fundingGoal;
        accumulatedSumIncludingSponsorship = 0;
        currentState = possibleState.FUNDING_GOAL_NOT_REACHED;
        contractOwner = msg.sender;
        sponsorFundingContract = _sponsorFundingContract;
        sponsorFundingContract.setCrowdOwner(contractOwner);
    }
    
    modifier onlyIfGoalNotReached() {
        if (currentState == possibleState.FUNDING_GOAL_REACHED) {
            revert("Goal already reached! Your operation is not supported anymore.");
        }
        _;
    }
    
    modifier onlyIfGoalReached() {
        if (currentState == possibleState.FUNDING_GOAL_NOT_REACHED) {
            revert("You can send the money only after the goal is reached!");
        }
        _;
    }
    
    modifier onlyIfOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can initiate this action!");
        _;
    }
    
    modifier onlyIfAddressNotInUse() {
        Contributor memory currentContributor = contributors[msg.sender];
        if (currentContributor.bankAccount != address(0)) {
            revert("Your address is already in use!");
        }
        _;
    }
    
    modifier onlyIfContributorHasAccount() {
        Contributor memory currentContributor = contributors[msg.sender];
        if (currentContributor.bankAccount == address(0)) {
            revert ("Your must create an account before contributing!");
        }
        _;
    }
    
    function createAccount(string memory _name) onlyIfAddressNotInUse external returns (Contributor memory) {
        Contributor memory newContributor = Contributor(_name, 0, payable(msg.sender));
        contributors[msg.sender] = newContributor;
        return newContributor;
    }
    
    function contribute() onlyIfGoalNotReached onlyIfContributorHasAccount payable external {
        uint contributionValue = msg.value;
        contributors[msg.sender].contribution += contributionValue;
        accumulatedSumExcludingSponsorship += contributionValue;
        accumulatedSumIncludingSponsorship += contributionValue;
        accumulatedSumIncludingSponsorship += sponsorFundingContract.getSponsorSumToBeReceivedOrRefunded(contributionValue);
        
        if (fundingGoal <= accumulatedSumIncludingSponsorship) {
            currentState = possibleState.FUNDING_GOAL_REACHED;
        }
    }
    
    function refund() onlyIfGoalNotReached onlyIfContributorHasAccount payable external {
        uint requestedValue = msg.value;
        if (requestedValue > contributors[msg.sender].contribution) {
            revert ("You cannot ask for a refund with a higher value than your contribution!");
        }
        else {
            payable(msg.sender).transfer(requestedValue);
            contributors[msg.sender].contribution -= requestedValue;
            accumulatedSumExcludingSponsorship -= requestedValue;
            accumulatedSumIncludingSponsorship -= requestedValue;
            accumulatedSumIncludingSponsorship -= sponsorFundingContract.getSponsorSumToBeReceivedOrRefunded(requestedValue);
        }
    }
    
    function getCurrentState() public view returns (string memory) {
        if (currentState == possibleState.FUNDING_GOAL_NOT_REACHED) {
            return "Funding goal not yet reached!";
        }
        
        else {
            return "Funding goal was reached!";
        }
    }
    
    function notifySponsorFunding() external onlyIfOwner onlyIfGoalReached {
        sponsorFundingContract.makeSponsorshipTransaction(accumulatedSumExcludingSponsorship, payable(address(this)));
    }
    
    function transferMoneyToDistributeFunding() external onlyIfOwner onlyIfGoalReached {
        // distributeFundingContract.distributeFunding{value:fundingGoal}();
    }
}