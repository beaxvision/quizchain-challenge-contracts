require('dotenv').config();
const { ethers } = require('ethers');
const { run } = require("hardhat");

const main = async () => {
    console.log("Verifying contracts...");

    await run("verify:verify", {
        address: "0x55364e03D8b684deC4343313F8BEa2e15c2E2882",
        constructorArguments: [],
    });

    await run("verify:verify", {
        address: "0x080173fAb95c96B9C71F6063A019D738623f9EA1",
        constructorArguments: ["0x55364e03D8b684deC4343313F8BEa2e15c2E2882", 100],
    });
};

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})