import { ethers } from 'hardhat';
import { deployContract, sendTxn } from './helper';
import { MUSD } from '../typechain-types';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address);
  const mono = await ethers.getContractAt(
    'IERC20',
    '0xa07aC8cDe2a98B189477b8e41F0c2Ea6CdDbC055'
  );
  const musd = await deployContract('MUSD', [], 'MUSD', null);

  await sendTxn(musd.setMono(await mono.getAddress()), 'MUSD.setMono');
  await sendTxn(
    musd.setFeeTo(deployer.address, deployer.address),
    'MUSD.setFeeTo'
  );
  await sendTxn(musd.config(), 'MUSD.config');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
