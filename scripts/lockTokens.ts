import { ethers } from "hardhat";
import dotenv from "dotenv";

dotenv.config();

async function lockTokens(amount: string) {
    const providerBesu = new ethers.JsonRpcProvider(process.env.BESU_RPC_URL);
    const signerBesu = new ethers.Wallet(process.env.BESU_PRIVATE_KEY!, providerBesu);

    // Correct ABI for BesuBridge contract
    const besuBridgeABI = [
        "function lockTokens(uint256 amount) external"
    ];

    const besuBridgeAddress = new ethers.Contract("BESU_BRIDGE_ADDRESS_HERE", besuBridgeABI, signerBesu);

    console.log(`Locking ${amount} tokens in Besu`);

    try {
        const amountBigInt = BigInt(amount);
        const tx = await besuBridgeAddress.lockTokens(amountBigInt);
        await tx.wait();
        console.log(`tx hash: ${tx.hash}`);
        console.log(`${amount} locked tokens in Besu`);
    } catch (error) {
        console.error("Error locking tokens:", error);
    }
}


lockTokens("1");

