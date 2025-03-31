const OMToken = artifacts.require("OMToken");
const OCToken = artifacts.require("OCToken");
const Airdrop = artifacts.require("Airdrop");
const SecureManager = artifacts.require("SecureManager");

module.exports = async function (deployer, network, accounts) {
    try {
        const initialSupplyOM = 1000000 * (10 ** 6); // OM with 6 decimals
        const initialSupplyOC = 500000 * (10 ** 6);  // OC with 6 decimals
        
        console.log("Starting deployment of contracts...");

        await deployer.deploy(OMToken, initialSupplyOM);
        const omToken = await OMToken.deployed();
        console.log(`OMToken deployed at: ${omToken.address}`);

        await deployer.deploy(OCToken, initialSupplyOC);
        const ocToken = await OCToken.deployed();
        console.log(`OCToken deployed at: ${ocToken.address}`);

        await deployer.deploy(Airdrop, omToken.address, ocToken.address);
        const airdrop = await Airdrop.deployed();
        console.log(`Airdrop deployed at: ${airdrop.address}`);

        const approvers = network === 'development' 
            ? [accounts[1], accounts[2], accounts[3]]  // Use test accounts in development but change in production
            : [
                "0x1234567890abcdef1234567890abcdef12345678", 
                "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
                "0x9876543210fedcba9876543210fedcba98765432"
              ];
        
        const requiredApprovals = 2; // Requires 2 of 3 signatures

        console.log("SecureManager configuration for approvers:");
        approvers.forEach((addr, i) => console.log(`   Approver ${i+1}: ${addr}`));
        console.log(`   Required approvals: ${requiredApprovals}`);

        await deployer.deploy(SecureManager, omToken.address, ocToken.address, approvers, requiredApprovals);
        const secureManager = await SecureManager.deployed();
        console.log(`SecureManager deployed at: ${secureManager.address}`);

        console.log("Transfiriendo tokens al SecureManager...");
        await omToken.transfer(secureManager.address, 100000 * (10 ** 6)); 
        await ocToken.transfer(secureManager.address, 50000 * (10 ** 6)); 
        console.log("Tokens transferred to SecureManager for security control.");
        console.log("Financing the Airdrop contract...");
        await ocToken.approve(airdrop.address, 10000 * (10 ** 6)); 
        await airdrop.fundAirdrop(10000 * (10 ** 6));
        console.log("Airdrop successfully funded.");
        console.log("Deployment completed successfully!");
        
    } catch (error) {
        console.error("❌ Error during deployment:", error.message);
        throw error;
    }
};
