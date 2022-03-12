const hre = require("hardhat");

// https://docs.aave.com/developers/v/2.0/deployed-contracts/matic-polygon-market

const providerAddress = "0xd05e3E715d945B59290df0ae8eF85c1BdB684744";

async function main() {
  const Bot = await hre.ethers.getContractFactory("LiquidationBot");
  const bot = await Bot.deploy(providerAddress);

  console.log("Liquidation bot deployed to:", bot.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
