// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DividendPayingToken.sol";
import "./Ownable.sol";
import "./IterableMapping.sol";

contract BABYBILZDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    event ExcludeFromDividends(address indexed account);

    constructor() DividendPayingToken("BabyBilz Dividends", "BABYBILZ_D") {}

    function _transfer(address, address, uint256) internal pure override {
        require(false, "BABYBILZ_D: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "BABYBILZ_D: withdrawDividend disabled. Use the 'claim' function in BABYBILZ");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account],"BABYBILZ_D: Address already excluded from dividends");
    	excludedFromDividends[account] = true;
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
    	emit ExcludeFromDividends(account);
    }

    function isExcludedFromDividends(address account) public view returns(bool) {
        return excludedFromDividends[account];
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() public view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex
                ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0);
        address account = tokenHoldersMap.getKeyAtIndex(index);
        return getAccount(account);
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) return;
        if(newBalance > 0) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	} else {
            _setBalance(account, 0);
    	    tokenHoldersMap.remove(account);
    	}
    	processAccount(account);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) return (0, 0, lastProcessedIndex);

        uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) _lastProcessedIndex = 0;

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(processAccount(payable(account))) claims++;

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }
    function processAccount(address payable account) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
        return amount > 0;
    }
}