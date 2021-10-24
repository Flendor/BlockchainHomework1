// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.7;

contract CrowdFunding {
    
    uint fundingGoal;
    uint accumulatedSum;
    possibleState currentState;
    
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
    
    constructor (uint _fundingGoal) payable {
        fundingGoal = _fundingGoal;
        accumulatedSum = 0;
        currentState = possibleState.FUNDING_GOAL_NOT_REACHED;
    }
    
    modifier onlyIfGoalNotReached() {
        if (currentState == possibleState.FUNDING_GOAL_REACHED) {
            revert("Goal already reached! Your operation is not supported anymore.");
        }
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
        accumulatedSum += contributionValue;
        
        if (fundingGoal <= accumulatedSum) {
            currentState = possibleState.FUNDING_GOAL_REACHED;
            uint remainingChange = accumulatedSum - fundingGoal;
            payable(msg.sender).transfer(remainingChange);
            accumulatedSum = fundingGoal;
            contributors[msg.sender].contribution -= remainingChange;
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
            accumulatedSum -= requestedValue;
        }
    }
    
    function getCurrentState() public returns (string memory) {
        if (currentState == possibleState.FUNDING_GOAL_NOT_REACHED) {
            return "Funding goal not yet reached!";
        }
        
        else {
            return "Funding goal was reached!";
        }
    }
}