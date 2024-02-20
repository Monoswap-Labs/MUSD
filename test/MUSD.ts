import {
  time,
  loadFixture,
} from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import {
  BlastTest,
  MUSD,
  TestERC20,
  TestERC20Rebasing,
} from '../typechain-types';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';

describe('MUSD', function () {
  let musd: MUSD;
  let usdb: TestERC20Rebasing;
  let mono: TestERC20;
  let blast: BlastTest;
  let deployer: SignerWithAddress,
    user1: SignerWithAddress,
    user2: SignerWithAddress,
    feeTo: SignerWithAddress;

  beforeEach(async function () {
    [deployer, user1, user2, feeTo] = await ethers.getSigners();

    usdb = await ethers.deployContract('TestERC20Rebasing', []);
    mono = await ethers.deployContract('TestERC20', []);
    blast = await ethers.deployContract('BlastTest', []);
    musd = await ethers.deployContract('MUSD', [
      await blast.getAddress(),
      await usdb.getAddress(),
    ]);

    musd.setMono(await mono.getAddress());
    await musd.setPath([await usdb.getAddress(), await mono.getAddress()]);

    await usdb.transfer(user1.address, ethers.parseEther('1000'));
    await usdb.transfer(user2.address, ethers.parseEther('100'));

    await usdb.approve(await musd.getAddress(), ethers.MaxUint256);
    await usdb
      .connect(user1)
      .approve(await musd.getAddress(), ethers.MaxUint256);
    await usdb
      .connect(user2)
      .approve(await musd.getAddress(), ethers.MaxUint256);
    musd.setFeeTo(feeTo.address, feeTo.address);
  });

  it('should deploy successfully', async function () {
    expect(await musd.mono()).to.equal(await mono.getAddress(), 'mono');
    expect(await musd.usdb()).to.equal(await usdb.getAddress(), 'usdb');
    expect(await musd.path(0)).to.equal(await usdb.getAddress()), 'path0';
    expect(await musd.path(1)).to.equal(await mono.getAddress(), 'path1');
  });

  it('should mint musd', async function () {
    const ONE_THOUSAND = ethers.parseEther('1000');
    const ONE_HUNDRED = ethers.parseEther('100');

    await musd.connect(user1).deposit(ONE_THOUSAND);
    expect(await musd.balanceOf(user1.address)).to.equal(ONE_THOUSAND);
    expect(await usdb.balanceOf(await musd.getAddress())).to.equal(
      ONE_THOUSAND
    );
    await musd.connect(user2).deposit(ONE_HUNDRED);
    expect(await musd.balanceOf(user2.address)).to.equal(ONE_HUNDRED);
  });

  it('should withdraw musd', async function () {
    const ONE_THOUSAND = ethers.parseEther('1000');
    const ONE_HUNDRED = ethers.parseEther('100');

    await musd.connect(user1).deposit(ONE_THOUSAND);
    await musd.connect(user2).deposit(ONE_HUNDRED);

    let user1Balance = await musd.balanceOf(user1.address);

    await musd.connect(user1).withdraw(ONE_HUNDRED);
    expect(await musd.balanceOf(user1.address)).to.equal(
      BigInt(user1Balance) - BigInt(ONE_HUNDRED)
    );
    expect(await usdb.balanceOf(user1.address)).to.equal(
      (BigInt(ONE_HUNDRED) * BigInt(995)) / BigInt(1000)
    );
    await musd.connect(user2).withdraw(ONE_HUNDRED);
    expect(await musd.balanceOf(user2.address)).to.equal(0);
  });

  it('should increase price', async function () {
    const ONE_THOUSAND = ethers.parseEther('1000');
    const ONE_HUNDRED = ethers.parseEther('100');
    await musd.connect(user1).deposit(ONE_THOUSAND);
    await musd.increasePrice(ONE_HUNDRED);
    expect(await musd.getPrice()).to.equal('110000000');
    await musd.connect(user1).withdraw(ONE_HUNDRED);
    expect(await musd.balanceOf(user1.address)).to.equal(
      ONE_THOUSAND - ONE_HUNDRED
    );
    expect(await usdb.balanceOf(user1.address)).to.equal(
      (((BigInt(ONE_HUNDRED) * BigInt(995)) / BigInt(1000)) *
        BigInt(110000000)) /
        BigInt(100000000)
    );
  });
});
