const OMToken = artifacts.require("OMToken");
const OCToken = artifacts.require("OCToken");
const Airdrop = artifacts.require("Airdrop");
const SecureManager = artifacts.require("SecureManager");

contract("Sistema Completo: OM, OC, Airdrop & SecureManager", (accounts) => {
    let omToken, ocToken, airdrop, secureManager;
    const owner = accounts[0];  
    const approver1 = accounts[1];  
    const approver2 = accounts[2];  
    const nonApprover = accounts[3];  
    const user1 = accounts[4];  
    const user2 = accounts[5];  

    before(async () => {
        // 🚀 Desplegar los tokens
        omToken = await OMToken.new(1000000 * (10 ** 6));
        ocToken = await OCToken.new(500000 * (10 ** 6));

        // 🚀 Desplegar el Airdrop
        airdrop = await Airdrop.new(omToken.address, ocToken.address);

        // 🚀 Desplegar SecureManager con 2 approvers y 2 firmas requeridas
        secureManager = await SecureManager.new(
            omToken.address, 
            ocToken.address, 
            [approver1, approver2], 
            2
        );
    });

    it("✅ Verifica que los tokens OM y OC tengan el suministro inicial correcto", async () => {
        const totalSupplyOM = await omToken.totalSupply();
        const totalSupplyOC = await ocToken.totalSupply();
        assert.equal(totalSupplyOM.toString(), (1000000 * (10 ** 6)).toString(), "OM supply incorrecto");
        assert.equal(totalSupplyOC.toString(), (500000 * (10 ** 6)).toString(), "OC supply incorrecto");
    });

    it("✅ OMToken permite transferencias correctamente", async () => {
        await omToken.transfer(user1, 1000 * (10 ** 6), { from: owner });
        const balance = await omToken.balanceOf(user1);
        assert.equal(balance.toString(), (1000 * (10 ** 6)).toString(), "Transferencia incorrecta");
    });

    it("✅ Airdrop solo permite reclamar a usuarios con 100 OM o más", async () => {
        await ocToken.transfer(airdrop.address, 10000 * (10 ** 6), { from: owner });
        await omToken.transfer(user1, 100 * (10 ** 6), { from: owner });

        await airdrop.claimAirdrop({ from: user1 });
        const balanceOC = await ocToken.balanceOf(user1);
        assert.equal(balanceOC.toString(), (10 * (10 ** 6)).toString(), "Airdrop incorrecto");
    });

    it("❌ Un usuario sin 100 OM no puede reclamar el Airdrop", async () => {
        try {
            await airdrop.claimAirdrop({ from: user2 }); 
            assert.fail("El usuario sin 100 OM no debería poder reclamar");
        } catch (error) {
            assert(error.toString().includes("No tienes suficientes OM"), "No mostró el error esperado");
        }
    });

    it("✅ SecureManager solo permite agregar approvers desde el owner", async () => {
        await secureManager.addApprover(accounts[6], { from: owner });
        const isApprover = await secureManager.approvers(accounts[6]);
        assert.equal(isApprover, true, "No se pudo agregar un nuevo approver");
    });

    it("✅ SecureManager requiere firmas múltiples para ejecutar retiros", async () => {
        await omToken.transfer(secureManager.address, 10000 * (10 ** 6), { from: owner });
        await ocToken.transfer(secureManager.address, 5000 * (10 ** 6), { from: owner });

        // 🚀 1er approver firma
        await secureManager.approveWithdrawal({ from: approver1 });

        // 🚀 2do approver firma
        await secureManager.approveWithdrawal({ from: approver2 });

        // 🚀 El owner ejecuta el retiro
        await secureManager.executeWithdrawal(user1, 1000 * (10 ** 6), 500 * (10 ** 6), { from: owner });

        const balanceOMUser = await omToken.balanceOf(user1);
        const balanceOCUser = await ocToken.balanceOf(user1);

        assert.equal(balanceOMUser.toString(), (1100 * (10 ** 6)).toString(), "OM no se transfirió correctamente");
        assert.equal(balanceOCUser.toString(), (510 * (10 ** 6)).toString(), "OC no se transfirió correctamente");
    });

    it("❌ No se puede ejecutar un retiro sin las firmas requeridas", async () => {
        try {
            await secureManager.executeWithdrawal(user2, 500 * (10 ** 6), 200 * (10 ** 6), { from: owner });
            assert.fail("No debería ejecutarse el retiro sin firmas suficientes");
        } catch (error) {
            assert(error.toString().includes("Not enough approvals"), "No mostró el error esperado");
        }
    });
});
