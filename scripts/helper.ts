import { ethers } from 'hardhat';
import { ContractFactory } from 'ethers';

async function deployContract(
  name: string,
  args: any[],
  label: any,
  options: any
) {
  if (!options && typeof label === 'object') {
    label = null;
    options = label;
  }

  let info = name;
  if (label) {
    info = name + ':' + label;
  }
  if (!options) {
    options = {};
  }
  const contract = await ethers.deployContract(name, args, options);
  const argStr = args.map((i) => `"${i}"`).join(' ');
  console.info(`Deploying ${info} ${await contract.getAddress()} ${argStr}`);
  await contract.waitForDeployment();
  console.info('... Completed!');
  return contract;
}

async function deployContractWithArtifact(
  artifact: any,
  args: any[],
  label: any,
  options: any
) {
  if (!options && typeof label === 'object') {
    label = null;
    options = label;
  }

  let info = artifact.contractName;
  if (label) {
    info = artifact.contractName + ':' + label;
  }
  const contractFactory = new ContractFactory(
    artifact.abi,
    artifact.bytecode,
    await ethers.provider.getSigner()
  );

  let contract = await contractFactory.deploy(...args);
  const argStr = args.map((i) => `"${i}"`).join(' ');
  console.info(`Deploying ${info} ${await contract.getAddress()} ${argStr}`);
  await contract.waitForDeployment();
  console.info('... Completed!');
  return contract;
}

async function sendTxn(txnPromise: Promise<any>, label: string) {
  console.info(`Processsing ${label}:`);
  const txn = await txnPromise;
  console.info(`Sending ${label}...`);
  await txn.wait(1);
  console.info(`... Sent! ${txn.hash}`);
  return txn;
}

export { deployContract, sendTxn, deployContractWithArtifact };
