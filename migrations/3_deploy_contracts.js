const OMToken = artifacts.require("OMToken");

module.exports = function (deployer) {
    const initialSupply = 1000000; // Define el suministro inicial de OM Tokens (1 token por m²)
    deployer.deploy(OMToken, initialSupply);
};
