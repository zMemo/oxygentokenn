const OMToken = artifacts.require("OMToken");
const OCToken = artifacts.require("OCToken");
const Airdrop = artifacts.require("Airdrop");
const SecureManager = artifacts.require("SecureManager");

module.exports = async function (deployer, network, accounts) {
    const initialSupplyOM = 1000000 * (10 ** 6); // 1,000,000 OM con 6 decimales
    const initialSupplyOC = 500000 * (10 ** 6);  // 500,000 OC con 6 decimales

    // 🚀 Desplegar OMToken
    await deployer.deploy(OMToken, initialSupplyOM);
    const omToken = await OMToken.deployed();

    // 🚀 Desplegar OCToken
    await deployer.deploy(OCToken, initialSupplyOC);
    const ocToken = await OCToken.deployed();

    // 🚀 Desplegar Airdrop
    await deployer.deploy(Airdrop, omToken.address, ocToken.address);
    const airdrop = await Airdrop.deployed();

    // 🔐 Definir wallets de seguridad (Multisig)
    const approvers = [
        "0x1234567890abcdef1234567890abcdef12345678", // Cambia por wallets reales
        "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
        "0x9876543210fedcba9876543210fedcba98765432"
    ];
    
    const requiredApprovals = 2; // Necesita 2 de 3 firmas

    // 🚀 Desplegar SecureManager con OM y OC
    await deployer.deploy(SecureManager, omToken.address, ocToken.address, approvers, requiredApprovals);
    const secureManager = await SecureManager.deployed();

    console.log(`✅ OMToken deployed at: ${omToken.address}`);
    console.log(`✅ OCToken deployed at: ${ocToken.address}`);
    console.log(`✅ Airdrop deployed at: ${airdrop.address}`);
    console.log(`✅ SecureManager deployed at: ${secureManager.address}`);

    // ✅ Opcional: Transferir tokens al SecureManager para mayor seguridad
    await omToken.transfer(secureManager.address, 100000 * (10 ** 6)); // Transfiere 100,000 OM al multisig
    await ocToken.transfer(secureManager.address, 50000 * (10 ** 6)); // Transfiere 50,000 OC al multisig

    console.log("✅ Tokens transferidos al SecureManager para control de seguridad.");
};
