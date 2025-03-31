const OMToken = artifacts.require("OMToken");
const OCToken = artifacts.require("OCToken");
const Airdrop = artifacts.require("Airdrop");
const SecureManager = artifacts.require("SecureManager");

contract("Complete system: OM, OC, Airdrop & SecureManager", (accounts) => {
    let omToken, ocToken, airdrop, secureManager;
    const owner = accounts[0];  
    const approver1 = accounts[1];  
    const approver2 = accounts[2];  
    const nonApprover = accounts[3];  
    const user1 = accounts[4];  
    const user2 = accounts[5];  

    before(async () => {
        // 🚀 Deploy the tokens
        omToken = await OMToken.new(1000000 * (10 ** 6));
        ocToken = await OCToken.new(500000 * (10 ** 6));

        // 🚀 Deploy the Airdrop
        airdrop = await Airdrop.new(omToken.address, ocToken.address);

        // 🚀 Deploy the SecureManager with 2 approvers and 2 required signatures
        secureManager = await SecureManager.new(
            omToken.address, 
            ocToken.address, 
            [approver1, approver2], 
            2
        );
    });

    it("✅ Verifies that the OM and OC tokens have the correct initial supply", async () => {
        const totalSupplyOM = await omToken.totalSupply();
        const totalSupplyOC = await ocToken.totalSupply();
        assert.equal(totalSupplyOM.toString(), (1000000 * (10 ** 6)).toString(), "OM supply incorrecto");
        assert.equal(totalSupplyOC.toString(), (500000 * (10 ** 6)).toString(), "OC supply incorrecto");
    });

    it("✅ OMToken allows correct transfers", async () => {
        await omToken.transfer(user1, 1000 * (10 ** 6), { from: owner });
        const balance = await omToken.balanceOf(user1);
        assert.equal(balance.toString(), (1000 * (10 ** 6)).toString(), "Incorrect transfer");
    });

    it("✅ Airdrop only allows claiming by users with 100 OM or more", async () => {
        await ocToken.transfer(airdrop.address, 10000 * (10 ** 6), { from: owner });
        await omToken.transfer(user1, 100 * (10 ** 6), { from: owner });

        await airdrop.claimAirdrop({ from: user1 });
        const balanceOC = await ocToken.balanceOf(user1);
        assert.equal(balanceOC.toString(), (10 * (10 ** 6)).toString(), "Incorrect airdrop");
    });

    it("❌ A user without 100 OM cannot claim the Airdrop", async () => {
        try {
            await airdrop.claimAirdrop({ from: user2 }); 
            assert.fail("The user without 100 OM should not be able to claim");
        } catch (error) {
            assert(error.toString().includes("No tienes suficientes OM"), "No showed the expected error");
        }
    });

    it("✅ SecureManager only allows adding approvers from the owner", async () => {
        await secureManager.addApprover(accounts[6], { from: owner });
        const isApprover = await secureManager.approvers(accounts[6]);
        assert.equal(isApprover, true, "Could not add a new approver");
    });

    it("✅ SecureManager requires multiple signatures to execute withdrawals", async () => {
        // Transfer tokens to the SecureManager contract
        await omToken.transfer(secureManager.address, 10000 * (10 ** 6), { from: owner });
        await ocToken.transfer(secureManager.address, 5000 * (10 ** 6), { from: owner });

        // 🚀 Request a withdrawal (new step in the updated contract)
        await secureManager.requestWithdrawal(
            user1,                    // recipient
            1000 * (10 ** 6),         // OM amount
            500 * (10 ** 6),          // OC amount
            { from: owner }
        );

        // 🚀 1st approver signature
        await secureManager.approveWithdrawal({ from: approver1 });

        // 🚀 2nd approver signature
        await secureManager.approveWithdrawal({ from: approver2 });

        // 🚀 The owner executes the withdrawal (no parameters needed in updated contract)
        await secureManager.executeWithdrawal({ from: owner });

        // Check the final balances
        const balanceOMUser = await omToken.balanceOf(user1);
        const balanceOCUser = await ocToken.balanceOf(user1);

        assert.equal(balanceOMUser.toString(), (1100 * (10 ** 6)).toString(), "OM was not transferred correctly");
        assert.equal(balanceOCUser.toString(), (510 * (10 ** 6)).toString(), "OC was not transferred correctly");
    });

    it("❌ Cannot execute a withdrawal without the required signatures", async () => {
        // Request a new withdrawal
        await secureManager.requestWithdrawal(
            user2,                    // recipient
            500 * (10 ** 6),          // OM amount
            200 * (10 ** 6),          // OC amount
            { from: owner }
        );

        // No approvals are made

        try {
            await secureManager.executeWithdrawal({ from: owner });
            assert.fail("The withdrawal should not be executed without enough signatures");
        } catch (error) {
            assert(error.toString().includes("Not enough approvals"), "Did not show the expected error");
        }
    });

    it("✅ Approver can cancel their approval", async () => {
        // Request a new withdrawal
        await secureManager.requestWithdrawal(
            user2,                    // recipient
            500 * (10 ** 6),          // OM amount
            200 * (10 ** 6),          // OC amount
            { from: owner }
        );
        
        // First approver approves
        await secureManager.approveWithdrawal({ from: approver1 });
        
        // Check that the approval count is 1
        let approvalCount = await secureManager.approvalCount();
        assert.equal(approvalCount.toNumber(), 1, "Approval count should be 1");
        
        // Now the first approver changes their mind and cancels
        await secureManager.cancelApproval({ from: approver1 });
        
        // Check that the approval count is back to 0
        approvalCount = await secureManager.approvalCount();
        assert.equal(approvalCount.toNumber(), 0, "Approval count should be 0 after cancellation");
        
        // Attempt to execute should fail
        try {
            await secureManager.executeWithdrawal({ from: owner });
            assert.fail("The withdrawal should not be executed after approval cancellation");
        } catch (error) {
            assert(error.toString().includes("Not enough approvals"), "Did not show the expected error");
        }
    });

    it("✅ Owner can cancel a withdrawal request", async () => {
        // Request a new withdrawal
        await secureManager.requestWithdrawal(
            user2,                    // recipient
            500 * (10 ** 6),          // OM amount
            200 * (10 ** 6),          // OC amount
            { from: owner }
        );
        
        // Verify the withdrawal is requested
        let withdrawalRequested = await secureManager.withdrawalRequested();
        assert.equal(withdrawalRequested, true, "Withdrawal should be requested");
        
        // Owner cancels the withdrawal
        await secureManager.cancelWithdrawal({ from: owner });
        
        // Verify withdrawal is no longer requested
        withdrawalRequested = await secureManager.withdrawalRequested();
        assert.equal(withdrawalRequested, false, "Withdrawal should be cancelled");
        
        // Attempt to approve should fail
        try {
            await secureManager.approveWithdrawal({ from: approver1 });
            assert.fail("Approval should not be possible after withdrawal cancellation");
        } catch (error) {
            assert(error.toString().includes("No withdrawal request in progress"), "Did not show the expected error");
        }
    });

    it("✅ Approver list management functions correctly", async () => {
        // Add a new approver
        await secureManager.addApprover(accounts[7], { from: owner });
        
        // Check approver was added
        let isApprover = await secureManager.approvers(accounts[7]);
        assert.equal(isApprover, true, "New approver should be added");
        
        // Get the total number of approvers
        let approversCount = await secureManager.getApproversCount();
        
        // Remove an approver
        await secureManager.removeApprover(accounts[7], { from: owner });
        
        // Check approver was removed
        isApprover = await secureManager.approvers(accounts[7]);
        assert.equal(isApprover, false, "Approver should be removed");
        
        // Verify count decreased
        let newApproversCount = await secureManager.getApproversCount();
        assert.equal(newApproversCount.toNumber(), approversCount.toNumber() - 1, "Approvers count should decrease");
    });
});
