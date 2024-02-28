import { ethers } from 'hardhat';
import { deployContract, sendTxn } from './helper';
import { MUSD } from '../typechain-types';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address);
  const blast = '0x4300000000000000000000000000000000000002';
  const usdb = '0x4300000000000000000000000000000000000003';
  const blastPoints = '0x2536FE9ab3F511540F2f9e2eC2A805005C3Dd800';
  const burnFeeTo = '0xD20687d1c79DaE7B3A5b22B43fe15f360ceA0fAF';
  const musd = await deployContract(
    'MUSD',
    [blast, blastPoints, usdb, burnFeeTo],
    'MUSD',
    null
  );

  await sendTxn(musd.config(), 'MUSD.config');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
