const ROUTER_ADDRESS = "0x89ABBAFD6DbCE234468C8D78E6934f25572e6a06";
const FLUX_ADDRESS = "0x2C350EF436fA6288C752547E9bc7f30E1E8448c1"; 

const ROUTER_ABI = [
    "function swapEthForFlux(uint256 minFlux) external payable",
    "function addLiquidity(uint256 amountFlux) external payable"
];

const TOKEN_ABI = [
    "function approve(address spender, uint256 amount) external returns (bool)",
    "function balanceOf(address account) view returns (uint256)"
];

let provider;
let signer;
let routerContract;
let fluxContract;

async function connectWallet() {
    if (window.ethereum) {
        provider = new ethers.BrowserProvider(window.ethereum);
        signer = await provider.getSigner();
        const address = await signer.getAddress();
        
        document.getElementById("connectBtn").innerText = "Connected";
        document.getElementById("userAddress").innerText = address.substring(0, 6) + "...";
        
        routerContract = new ethers.Contract(ROUTER_ADDRESS, ROUTER_ABI, signer);
        fluxContract = new ethers.Contract(FLUX_ADDRESS, TOKEN_ABI, signer);
        
        updateBalances(address);
    } else {
        alert("Please install MetaMask");
    }
}

async function updateBalances(address) {
    const ethBal = await provider.getBalance(address);
    const fluxBal = await fluxContract.balanceOf(address);
    
    document.getElementById("ethBalance").innerText = parseFloat(ethers.formatEther(ethBal)).toFixed(4);
    document.getElementById("fluxBalance").innerText = parseFloat(ethers.formatEther(fluxBal)).toFixed(2);
}

async function swapEthToFlux() {
    const amount = document.getElementById("swapAmount").value;
    if (!amount) return alert("Enter Amount");

    try {
        const tx = await routerContract.swapEthForFlux(0, { 
            value: ethers.parseEther(amount) 
        });
        
        document.getElementById("swapBtn").innerText = "Swapping...";
        await tx.wait();
        alert("Swap Successful!");
        document.getElementById("swapBtn").innerText = "Swap ETH for Flux";
        
        updateBalances(await signer.getAddress());
    } catch (error) {
        console.error(error);
        alert("Swap Failed");
        document.getElementById("swapBtn").innerText = "Swap ETH for Flux";
    }
}

async function addLiquidity() {
    const ethAmount = document.getElementById("liqEth").value;
    const fluxAmount = document.getElementById("liqFlux").value;

    if (!ethAmount || !fluxAmount) return alert("Enter Both Amounts");

    try {
        const fluxWei = ethers.parseEther(fluxAmount);
        const ethWei = ethers.parseEther(ethAmount);

        document.getElementById("liqBtn").innerText = "Approving Flux...";
        const approveTx = await fluxContract.approve(ROUTER_ADDRESS, fluxWei);
        await approveTx.wait();

        document.getElementById("liqBtn").innerText = "Adding Liquidity...";
        const tx = await routerContract.addLiquidity(fluxWei, {
            value: ethWei
        });
        
        await tx.wait();
        alert("Liquidity Added!");
        document.getElementById("liqBtn").innerText = "Add Liquidity";
        
        updateBalances(await signer.getAddress());
    } catch (error) {
        console.error(error);
        alert("Liquidity Failed");
        document.getElementById("liqBtn").innerText = "Add Liquidity";
    }
}