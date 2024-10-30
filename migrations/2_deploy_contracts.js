const OCToken = artifacts.require("OCToken");

module.exports = function (deployer) {
    const initialSupply = 1000000; // Define el suministro inicial de OC Tokens
    deployer.deploy(OCToken, initialSupply);
};
