// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IMonoswapRouter.sol";
import "./interface/IMono.sol";
import "./interface/IBlast.sol";
import "./interface/IERC20Rebasing.sol";

contract MUSD is
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    AccessControl,
    ERC20Permit
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public constant PERCENT_DENOMINATOR = 10000;

    uint256 public blockTimestampLast;
    IERC20Rebasing public usdb;
    IBlast public blast;
    IMono public mono;
    IMonoswapRouter public monoswapRouter;
    uint256 public treasureFee = 30; // 0.3%
    uint256 public burnMonoFee = 20; // 0.2%
    address public burnMonoFeeTo;
    address[] public path;

    event StaticcallResult(bytes result);
    event Deposited(
        address indexed user,
        uint256 amountUSDB,
        uint256 amountMUSD
    );
    event Withdrawed(
        address indexed user,
        uint256 amountUSDB,
        uint256 amountMUSD
    );
    event IncreasePrice(address indexed user, uint256 amount);

    constructor(
        address _blast,
        address _usdb,
        address _burnMonoFeeTo
    ) ERC20("Monoswap USD", "MUSD") ERC20Permit("Monoswap USD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        burnMonoFeeTo = _burnMonoFeeTo;

        blast = IBlast(_blast);
        usdb = IERC20Rebasing(_usdb);
        usdb.configure(YieldMode.AUTOMATIC);

        blast.configureClaimableGas();
        blast.configureGovernor(msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function deposit(uint256 amount) public {
        (uint256 usdbReserve, uint256 musdReserve, ) = getReserves();
        uint256 amountMUSD = amount;
        if (usdbReserve != 0) {
            amountMUSD = (amount * musdReserve) / usdbReserve;
        }

        usdb.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amountMUSD);

        blockTimestampLast = block.timestamp;
        emit Deposited(msg.sender, amount, amountMUSD);
    }

    function withdraw(uint256 amount) public {
        (uint256 usdbReserve, uint256 musdReserve, ) = getReserves();
        uint256 amountUSDB = amount;
        if (usdbReserve != 0) {
            amountUSDB = (amount * usdbReserve) / musdReserve;
        }
        uint256 treasureFeeAmount = (amountUSDB * treasureFee) /
            PERCENT_DENOMINATOR;
        uint256 burnMonoFeeAmount = (amountUSDB * burnMonoFee) /
            PERCENT_DENOMINATOR;
        amountUSDB = amountUSDB - treasureFeeAmount - burnMonoFeeAmount;
        if (address(monoswapRouter) != address(0)) {
            _swap(burnMonoFeeAmount);
            mono.burn(mono.balanceOf(address(this)));
        } else {
            usdb.transfer(burnMonoFeeTo, burnMonoFeeAmount);
        }
        _burn(msg.sender, amount);
        usdb.transfer(msg.sender, amountUSDB);
        blockTimestampLast = block.timestamp;
        emit Withdrawed(msg.sender, amountUSDB, amount);
    }

    function setFeeTo(
        address _burnMonoFeeTo
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_burnMonoFeeTo != address(0), "MUSD: INVALID_BURN_MONO_FEE_TO");
        burnMonoFeeTo = _burnMonoFeeTo;
    }

    function increasePrice(uint256 amount) public {
        usdb.transferFrom(msg.sender, address(this), amount);
        emit IncreasePrice(msg.sender, amount);
    }

    function getReserves()
        public
        view
        returns (
            uint256 usdbReserve,
            uint256 musdReserve,
            uint256 _blockTimestampLast
        )
    {
        usdbReserve = usdb.balanceOf(address(this));
        musdReserve = totalSupply();
        _blockTimestampLast = blockTimestampLast;
    }

    function _swap(uint256 amountIn) internal {
        monoswapRouter.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp + 100
        );
    }

    function setMono(address _mono) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mono = IMono(_mono);
    }

    function setMonoswapRouter(
        address _monoswapRouter
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        monoswapRouter = IMonoswapRouter(_monoswapRouter);
        if (_monoswapRouter != address(0)) {
            usdb.approve(_monoswapRouter, type(uint256).max);
        }
    }

    function setPath(
        address[] memory _path
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < path.length; i++) {
            path.pop();
        }
        for (uint256 i = 0; i < _path.length; i++) {
            path.push(_path[i]);
        }
    }

    function setWithdrawFee(
        uint256 _treasureFee,
        uint256 _burnMonoFee
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _treasureFee + _burnMonoFee < PERCENT_DENOMINATOR &&
                _treasureFee > 0 &&
                _burnMonoFee > 0,
            "MUSD: INVALID_WITHDRAW_FEE"
        );
        treasureFee = _treasureFee;
        burnMonoFee = _burnMonoFee;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "MUSD: INSUFFICIENT_INPUT_AMOUNT");
        if (reserveIn == 0 || reserveOut == 0) {
            amountOut = amountIn;
        } else {
            amountOut = (amountIn * reserveOut) / reserveIn;
        }
    }

    function getPrice() public view returns (uint256 price) {
        (uint256 usdbReserve, uint256 musdReserve, ) = getReserves();
        price = (usdbReserve * 1e8) / musdReserve;
    }
    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
