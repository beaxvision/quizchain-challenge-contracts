require('dotenv').config();
const { ethers } = require('ethers');

const main = async () => {
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

    const qctokenContractFactory = new ethers.ContractFactory(
        require('../artifacts/contracts/QCToken.sol/QCToken.json').abi,
        require('../artifacts/contracts/QCToken.sol/QCToken.json').bytecode,
        wallet
    );

    const qctokenContract = await qctokenContractFactory.deploy();
    await qctokenContract.waitForDeployment();
    const qctokenAddress = await qctokenContract.getAddress();

    console.log("QCToken deployed to:", qctokenAddress);

    const quizChainChallengeContractFactory = new ethers.ContractFactory(
        require('../artifacts/contracts/QuizChainChallenge.sol/QuizChainChallenge.json').abi,
        require('../artifacts/contracts/QuizChainChallenge.sol/QuizChainChallenge.json').bytecode,
        wallet
    );

    const quizChainChallengeContract = await quizChainChallengeContractFactory.deploy(qctokenAddress, 100);
    await quizChainChallengeContract.waitForDeployment();
    const quizChainChallengeAddress = await quizChainChallengeContract.getAddress();

    await (await qctokenContract.approve(quizChainChallengeAddress, ethers.MaxUint256)).wait();
    await (await quizChainChallengeContract.addRewards(ethers.parseEther("10000"))).wait();
    
    console.log("QuizChainChallenge deployed to:", quizChainChallengeAddress);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})