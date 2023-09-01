const { ethers, upgrades, network } = require("hardhat");

const fs = require("fs");
const CONFIG = require("../credentials.json");

const boxABI = (JSON.parse(fs.readFileSync('./artifacts/contracts/LoanManager.sol/LoanManager.json', 'utf8'))).abi;



describe("Box - upgradeable", function(){

    const provider = new ethers.providers.JsonRpcProvider(CONFIG["GOERLI"]["URL"]);
    signer = new ethers.Wallet(CONFIG["GOERLI"]["PKEY"]);
    account = signer.connect(provider);

    before(async function(){
        
        const Lm = await ethers.getContractFactory("LoanManager")
        box = await upgrades.deployProxy(Lm, [],{kind: 'transparent'});

        console.log({
            boxProxy: box.address,
            boxImplementation: await upgrades.erc1967.getImplementationAddress(box.address),
            boxProxyAdmin: await upgrades.erc1967.getAdminAddress(box.address)
        })
    })

    it("Should verify deployment:", async ()=>{

        boxLink = new ethers.Contract("0xC58107908784D4CB91BD740391f8CdB09daAB93F", boxABI, account)
        console.log(await boxLink.retrieve())

    })
})