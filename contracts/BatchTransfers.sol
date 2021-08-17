// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract BatchTransfers is Ownable{
    using SafeMath for uint256;
    IERC20 public token;
    event Deposit(address depositer, uint amount);
    event Withdraw(uint256 amount);
    event BatchTransfer(uint256 iterations, uint256 transfers, int256 lastProcessedIndex);
    constructor(){}
    function setToken(address _token) public onlyOwner{
        token = IERC20(_token);
    }
    function deposit(uint amount) public onlyOwner{
        token.transferFrom(msg.sender,address(this),amount);
        emit Deposit(msg.sender,amount);
    }
    function withdraw() public onlyOwner{
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(),balance);
        emit Withdraw(balance);
    }
    function transfer(
        address[] calldata addrs,
        uint256 amountForEach,
        int256 lastProcessedIndex,
        uint256 gas) public onlyOwner{
        int256 len = int256(addrs.length);
        require(lastProcessedIndex >= -1 && len > lastProcessedIndex + 1,
            "BABYBILZ: you have reached the end");

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 transfers = 0;

    	while(gasUsed < gas) {
    	    lastProcessedIndex++;
    		if(token.transfer(addrs[uint256(lastProcessedIndex)],amountForEach)) transfers++;
    		iterations++;
    		uint256 newGasLeft = gasleft();
    		if(gasLeft > newGasLeft) gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		gasLeft = newGasLeft;
    	}
    	emit BatchTransfer(iterations,transfers,lastProcessedIndex);
    }
}