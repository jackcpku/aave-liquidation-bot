const hre = require("hardhat");

const { daiABI, daiImplABI } = require("../libs/abi");

// https://docs.aave.com/developers/v/2.0/deployed-contracts/matic-polygon-market

const botAddress = "0x58361c200F28607DE97bAAB85025c9Fe5755B815";
const daiAddress = "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063";

async function main() {
  const bot = await hre.ethers.getContractAt("LiquidationBot", botAddress);
  console.log("Bot is indeed deployed at:", bot.address);

  let dai = await hre.ethers.getContractAt(daiABI, daiAddress);

  const daiImplAddress = await dai.implementation();

  let daiImpl = await hre.ethers.getContractAt(daiImplABI, daiImplAddress);

  // https://ethereum.stackexchange.com/questions/96437/how-can-i-use-a-proxy-contract-with-ethers-js
  dai = daiImpl.attach(daiAddress);

  const balanceBefore = await dai.balanceOf(botAddress);
  console.log(
    `Bot balance of Dai before flashloan = ${balanceBefore.toString()}`
  );

  const tx = await bot.requestFlashLoan(
    [daiAddress],
    [10000],
    [0],
    "0x40414243"
  );

  console.log({ tx });

  const receipt = await tx.wait();

  console.log({ receipt });

  const balanceAfter = await dai.balanceOf(botAddress);
  console.log(
    `Bot balance of Dai before flashloan = ${balanceAfter.toString()}`
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
