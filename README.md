# MarketMake
Combining Molecule, Bloom, &amp; Aave to build unsecured lending vaults

Faucet on Kovan:
https://testnet.aave.com/faucet
NFT tokens:
low credit: 0xe22da380ee6B445bb8273C81944ADEB6E8450422
high credit: 0x9b82433944Cf77f0C90C90bAC473324f93910ed0
USDC Kovan: 0xe22da380ee6b445bb8273c81944adeb6e8450422
Investor + Borrower Wallet: (use same for demo): 0x93DF203b8Da82d57113709015D0A9e08a1615DF9
Aave Lending Pool Kovan: 0x9FE532197ad76c5a68961439604C037EB79681F0
MyV2CreditDelegation:
Prelaunched: 0x1D2048b4673a7D3C874D5Ca0cB584695Fcc4CC7e
Demo contract address:  
0x81911FddCB42647B295BcDa8f2e801e4C3325fFa
Steps:
1) Launch MyV2CreditDelegation smart contract
- Input params:
   - low credit (0xe22da380ee6B445bb8273C81944ADEB6E8450422)
   - high credit (0x9b82433944Cf77f0C90C90bAC473324f93910ed0)
2) approve investor & borrower for MyV2CreditDelegation smart contract
- load ERC20 token at USDC address 0xe22da380ee6b445bb8273c81944adeb6e8450422
- approve investor & borrower wallet, spend: MyV2CreditDelegation contract up to max (6 decimals for USDC): 999999999999999
3) Investor: depositCollateral
- call depositCollateral with asset address (USDC: 0xe22da380ee6b445bb8273c81944adeb6e8450422)
- amount: 100000000 ($100)
- check: call balances:
   - asset: 0xe22da380ee6b445bb8273c81944adeb6e8450422
   - user wallet: 0x93DF203b8Da82d57113709015D0A9e08a1615DF9
   - should see 100000000 deposited
4) Borrower:
- initiate borrow (click of a button) --> install Bloom app for DID/KYC & credit score
https://credit-delegation-starter.herokuapp.com/?ethAddress=0x93DF203b8Da82d57113709015D0A9e08a1615DF9
- Scan QR Code in Bloom app to verify ID and credit score
(Steps not shown)
   - callback based on credit bucket (high or low, which determines credit amount and interest rate)
   - link to helloSign for legal borrow document signing, once signed, then:
   - mint low or high credit NFT token using Molecule Protocol (from last EthGlobal hackathon)
(Steps in demo)
- borrower call requestCredit with credit NFT token address, approved tokenId (will log and invalidate for future use), asset address (USDC)
- borrower borrow from Aave
   - load Aave lendingpool address to call borrow
   - invoke borrow with: asset (USDC), amount 10000000 ($10), interestRateMode: 1 (stable), referralCode: 0 (none), onBehalfOf: lending vault contract
   - check transaction hash, see Aave token to vault smart contract, and USDC to borrower
(not in demo)
- verify: call balanceOf with account (borrower wallet address) and asset (USDC)
