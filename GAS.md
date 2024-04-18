| src/CSAccounting.sol:CSAccounting contract                          |                 |        |        |        |         |
|---------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                                       | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                             | 274             | 274    | 274    | 274    | 180     |
| ADD_BOND_CURVE_ROLE                                                 | 252             | 252    | 252    | 252    | 694     |
| MIN_BOND_LOCK_RETENTION_PERIOD                                      | 295             | 295    | 295    | 295    | 1       |
| PAUSE_ROLE                                                          | 317             | 317    | 317    | 317    | 180     |
| RECOVERER_ROLE                                                      | 305             | 305    | 305    | 305    | 12      |
| RESET_BOND_CURVE_ROLE                                               | 318             | 318    | 318    | 318    | 455     |
| RESUME_ROLE                                                         | 318             | 318    | 318    | 318    | 180     |
| SET_BOND_CURVE_ROLE                                                 | 252             | 252    | 252    | 252    | 634     |
| SET_DEFAULT_BOND_CURVE_ROLE                                         | 339             | 339    | 339    | 339    | 180     |
| addBondCurve                                                        | 24641           | 122935 | 121407 | 144545 | 300     |
| chargeFee                                                           | 21810           | 48281  | 48281  | 74752  | 2       |
| chargeRecipient                                                     | 491             | 491    | 491    | 491    | 1       |
| claimRewardsStETH                                                   | 25141           | 82068  | 96726  | 104543 | 16      |
| claimRewardsWstETH                                                  | 25076           | 118036 | 156391 | 158763 | 16      |
| compensateLockedBondETH                                             | 47504           | 47504  | 47504  | 47504  | 1       |
| defaultBondCurveId                                                  | 394             | 394    | 394    | 394    | 1       |
| depositETH                                                          | 24183           | 112098 | 113268 | 113508 | 104     |
| depositStETH                                                        | 25196           | 94179  | 104018 | 107937 | 7       |
| depositWstETH                                                       | 25193           | 105414 | 120251 | 123963 | 6       |
| feeDistributor                                                      | 405             | 1738   | 2405   | 2405   | 3       |
| getActualLockedBond                                                 | 559             | 679    | 719    | 719    | 8       |
| getBondAmountByKeysCount                                            | 1325            | 1414   | 1325   | 1588   | 247     |
| getBondAmountByKeysCountWstETH(uint256)                             | 3889            | 9728   | 4152   | 26720  | 4       |
| getBondAmountByKeysCountWstETH(uint256,(uint256,uint256[],uint256)) | 3309            | 8801   | 8856   | 14239  | 6       |
| getBondCurve                                                        | 2226            | 15906  | 16322  | 16322  | 256     |
| getBondLockRetentionPeriod                                          | 413             | 1746   | 2413   | 2413   | 3       |
| getBondShares                                                       | 563             | 601    | 563    | 2563   | 103     |
| getBondSummary                                                      | 14092           | 22841  | 21375  | 29875  | 12      |
| getBondSummaryShares                                                | 14067           | 22816  | 21350  | 29850  | 12      |
| getCurveInfo                                                        | 2158            | 2158   | 2158   | 2158   | 1       |
| getLockedBondInfo                                                   | 815             | 815    | 815    | 815    | 13      |
| getRequiredBondForNextKeys                                          | 10230           | 29186  | 24470  | 51405  | 34      |
| getRequiredBondForNextKeysWstETH                                    | 23593           | 35071  | 30819  | 57228  | 17      |
| getUnbondedKeysCount                                                | 3368            | 25073  | 15957  | 46457  | 441     |
| getUnbondedKeysCountToEject                                         | 5335            | 9208   | 7654   | 19278  | 72      |
| grantRole                                                           | 29570           | 108925 | 118658 | 118658 | 2505    |
| initialize                                                          | 207352          | 344963 | 345871 | 345871 | 458     |
| isPaused                                                            | 438             | 838    | 438    | 2438   | 5       |
| lockBondETH                                                         | 21804           | 68440  | 70230  | 70254  | 27      |
| pauseFor                                                            | 24043           | 45429  | 47568  | 47568  | 11      |
| penalize                                                            | 21722           | 34358  | 34358  | 46994  | 2       |
| recoverERC20                                                        | 24511           | 35890  | 24527  | 58633  | 3       |
| recoverEther                                                        | 23878           | 37448  | 28384  | 60084  | 3       |
| recoverStETHShares                                                  | 23834           | 43212  | 43212  | 62590  | 2       |
| releaseLockedBondETH                                                | 21782           | 26682  | 26682  | 31582  | 2       |
| requestRewardsETH                                                   | 25121           | 66836  | 72366  | 80183  | 16      |
| resetBondCurve                                                      | 24032           | 25907  | 25907  | 27783  | 2       |
| resume                                                              | 23851           | 26771  | 26771  | 29692  | 2       |
| setBondCurve                                                        | 24193           | 48783  | 49901  | 49901  | 23      |
| setChargeRecipient                                                  | 24192           | 26208  | 24195  | 30238  | 3       |
| setDefaultBondCurve                                                 | 24063           | 28150  | 28150  | 32237  | 2       |
| setLockedBondRetentionPeriod                                        | 30105           | 30105  | 30105  | 30105  | 1       |
| settleLockedBondETH                                                 | 43731           | 43731  | 43731  | 43731  | 1       |
| totalBondShares                                                     | 350             | 350    | 350    | 350    | 51      |


| src/CSEarlyAdoption.sol:CSEarlyAdoption contract |                 |       |        |       |         |
|--------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                    | min             | avg   | median | max   | # calls |
| consume                                          | 24902           | 37953 | 29950  | 51257 | 7       |
| consumed                                         | 593             | 593   | 593    | 593   | 1       |
| curveId                                          | 261             | 1761  | 2261   | 2261  | 4       |
| isEligible                                       | 1422            | 1422  | 1422   | 1422  | 2       |
| module                                           | 402             | 402   | 402    | 402   | 1       |
| treeRoot                                         | 283             | 283   | 283    | 283   | 1       |


| src/CSFeeDistributor.sol:CSFeeDistributor contract |                 |        |        |        |         |
|----------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                      | min             | avg    | median | max    | # calls |
| ORACLE_ROLE                                        | 240             | 240    | 240    | 240    | 10      |
| RECOVERER_ROLE                                     | 315             | 315    | 315    | 315    | 7       |
| distributeFees                                     | 22334           | 42664  | 27944  | 76284  | 6       |
| distributedShares                                  | 523             | 1523   | 1523   | 2523   | 4       |
| getFeesToDistribute                                | 1820            | 2820   | 2820   | 3820   | 2       |
| grantRole                                          | 118703          | 118703 | 118703 | 118703 | 15      |
| hashLeaf                                           | 678             | 678    | 678    | 678    | 1       |
| initialize                                         | 44500           | 131773 | 137592 | 137592 | 16      |
| pendingToDistribute                                | 1432            | 1432   | 1432   | 1432   | 1       |
| processOracleReport                                | 32656           | 68128  | 77419  | 77419  | 7       |
| recoverERC20                                       | 24480           | 35853  | 24494  | 58586  | 3       |
| recoverEther                                       | 23804           | 41922  | 41922  | 60040  | 2       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 261             | 261    | 261    | 261    | 12      |
| MANAGE_CONSENSUS_VERSION_ROLE            | 239             | 239    | 239    | 239    | 12      |
| MANAGE_FEE_DISTRIBUTOR_CONTRACT_ROLE     | 238             | 238    | 238    | 238    | 12      |
| PAUSE_ROLE                               | 262             | 262    | 262    | 262    | 12      |
| RESUME_ROLE                              | 262             | 262    | 262    | 262    | 12      |
| SUBMIT_DATA_ROLE                         | 284             | 284    | 284    | 284    | 27      |
| getConsensusReport                       | 1019            | 1826   | 1057   | 3019   | 30      |
| getConsensusVersion                      | 405             | 1605   | 2405   | 2405   | 20      |
| getLastProcessingRefSlot                 | 494             | 2283   | 2494   | 2494   | 57      |
| grantRole                                | 101393          | 114955 | 118493 | 118493 | 87      |
| initialize                               | 22935           | 242609 | 260913 | 260925 | 13      |
| pauseFor                                 | 47614           | 47614  | 47614  | 47614  | 2       |
| pauseUntil                               | 47608           | 47608  | 47608  | 47608  | 1       |
| resume                                   | 23535           | 26690  | 26690  | 29845  | 2       |
| setFeeDistributorContract                | 24081           | 27134  | 27134  | 30187  | 2       |
| submitReportData                         | 25486           | 40971  | 44533  | 53601  | 8       |


| src/CSModule.sol:CSModule contract                  |                 |        |        |         |         |
|-----------------------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                                       | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                                  | 260             | 260    | 260    | 260     | 1       |
| DEPOSIT_SIZE                                        | 307             | 307    | 307    | 307     | 12      |
| EL_REWARDS_STEALING_FINE                            | 306             | 306    | 306    | 306     | 23      |
| INITIAL_SLASHING_PENALTY                            | 439             | 439    | 439    | 439     | 4       |
| LIDO_LOCATOR                                        | 282             | 282    | 282    | 282     | 1       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 263             | 263    | 263    | 263     | 2       |
| MODULE_MANAGER_ROLE                                 | 283             | 283    | 283    | 283     | 281     |
| PAUSE_ROLE                                          | 262             | 262    | 262    | 262     | 240     |
| RECOVERER_ROLE                                      | 381             | 381    | 381    | 381     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 307             | 307    | 307    | 307     | 241     |
| RESUME_ROLE                                         | 373             | 373    | 373    | 373     | 240     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 328             | 328    | 328    | 328     | 241     |
| STAKING_ROUTER_ROLE                                 | 381             | 381    | 381    | 381     | 263     |
| VERIFIER_ROLE                                       | 371             | 371    | 371    | 371     | 243     |
| accounting                                          | 404             | 404    | 404    | 404     | 1       |
| activatePublicRelease                               | 23828           | 46597  | 46769  | 46769   | 256     |
| addNodeOperatorETH                                  | 26317           | 591716 | 546188 | 1172955 | 247     |
| addNodeOperatorStETH                                | 27103           | 366830 | 534411 | 538977  | 3       |
| addNodeOperatorWstETH                               | 27015           | 378833 | 552239 | 557246  | 3       |
| addValidatorKeysETH                                 | 25733           | 219410 | 258084 | 313072  | 9       |
| addValidatorKeysStETH                               | 26513           | 171199 | 241254 | 245832  | 3       |
| addValidatorKeysWstETH                              | 26491           | 183221 | 259290 | 263883  | 3       |
| cancelELRewardsStealingPenalty                      | 26393           | 92651  | 102163 | 139888  | 4       |
| claimRewardsStETH                                   | 25042           | 50759  | 27265  | 99972   | 3       |
| claimRewardsWstETH                                  | 25086           | 50417  | 27309  | 98856   | 3       |
| cleanDepositQueue                                   | 21609           | 35023  | 32788  | 53221   | 13      |
| compensateELRewardsStealingPenalty                  | 23665           | 114494 | 137896 | 158521  | 4       |
| confirmNodeOperatorManagerAddressChange             | 23645           | 28993  | 29058  | 34147   | 5       |
| confirmNodeOperatorRewardAddressChange              | 23713           | 33089  | 33975  | 38923   | 6       |
| decreaseOperatorVettedKeys                          | 24927           | 87711  | 101724 | 155786  | 22      |
| depositETH                                          | 23678           | 118897 | 125336 | 175371  | 8       |
| depositQueueItem                                    | 623             | 1289   | 623    | 2623    | 12      |
| depositStETH                                        | 24693           | 102861 | 108750 | 158785  | 5       |
| depositWstETH                                       | 24740           | 115876 | 125006 | 175041  | 5       |
| earlyAdoption                                       | 471             | 471    | 471    | 471     | 1       |
| getActiveNodeOperatorsCount                         | 382             | 382    | 382    | 382     | 2       |
| getNodeOperator                                     | 2435            | 9732   | 8435   | 18435   | 541     |
| getNodeOperatorIds                                  | 766             | 1222   | 1171   | 1923    | 8       |
| getNodeOperatorIsActive                             | 571             | 571    | 571    | 571     | 1       |
| getNodeOperatorSigningKeys                          | 796             | 2963   | 3714   | 3714    | 7       |
| getNodeOperatorSummary                              | 9897            | 13988  | 14271  | 15897   | 60      |
| getNodeOperatorsCount                               | 424             | 424    | 424    | 424     | 245     |
| getNonce                                            | 402             | 555    | 402    | 2402    | 78      |
| getStakingModuleSummary                             | 617             | 2742   | 2617   | 4617    | 16      |
| getType                                             | 349             | 349    | 349    | 349     | 1       |
| grantRole                                           | 27059           | 118554 | 118637 | 118637  | 1733    |
| hasRole                                             | 838             | 838    | 838    | 838     | 2       |
| initialize                                          | 142645          | 182778 | 182925 | 182925  | 277     |
| isPaused                                            | 428             | 828    | 428    | 2428    | 5       |
| isValidatorSlashed                                  | 628             | 628    | 628    | 628     | 1       |
| isValidatorWithdrawn                                | 617             | 617    | 617    | 617     | 1       |
| normalizeQueue                                      | 30299           | 54797  | 54797  | 79296   | 2       |
| obtainDepositData                                   | 24601           | 109495 | 111140 | 176065  | 58      |
| onExitedAndStuckValidatorsCountsUpdated             | 23721           | 23757  | 23757  | 23793   | 2       |
| onRewardsMinted                                     | 24021           | 45557  | 44957  | 67693   | 3       |
| onWithdrawalCredentialsChanged                      | 23861           | 25343  | 25084  | 27084   | 3       |
| pauseFor                                            | 24045           | 45469  | 47612  | 47612   | 11      |
| proposeNodeOperatorManagerAddressChange             | 24120           | 42555  | 53542  | 53542   | 9       |
| proposeNodeOperatorRewardAddressChange              | 24143           | 33436  | 36488  | 36488   | 10      |
| publicRelease                                       | 452             | 452    | 452    | 452     | 1       |
| queue                                               | 503             | 836    | 503    | 2503    | 6       |
| recoverERC20                                        | 58610           | 58610  | 58610  | 58610   | 1       |
| recoverEther                                        | 23792           | 26066  | 26066  | 28340   | 2       |
| recoverStETHShares                                  | 60928           | 60928  | 60928  | 60928   | 1       |
| removalCharge                                       | 408             | 1408   | 1408   | 2408    | 2       |
| removeKeys                                          | 24048           | 145626 | 172684 | 240695  | 15      |
| reportELRewardsStealingPenalty                      | 24429           | 134895 | 141497 | 154227  | 36      |
| requestRewardsETH                                   | 25109           | 50820  | 27332  | 100019  | 3       |
| resetNodeOperatorManagerAddress                     | 23734           | 31901  | 31384  | 38514   | 5       |
| resume                                              | 23787           | 26728  | 26728  | 29670   | 2       |
| revokeRole                                          | 40394           | 40394  | 40394  | 40394   | 1       |
| setRemovalCharge                                    | 24105           | 47123  | 47219  | 47231   | 241     |
| settleELRewardsStealingPenalty                      | 24806           | 93514  | 114049 | 163614  | 23      |
| submitInitialSlashing                               | 24182           | 98039  | 129890 | 134099  | 13      |
| submitWithdrawal                                    | 24429           | 121806 | 136218 | 235124  | 15      |
| unsafeUpdateValidatorsCount                         | 24320           | 61332  | 35971  | 160078  | 10      |
| updateExitedValidatorsCount                         | 24926           | 58622  | 47598  | 110326  | 11      |
| updateRefundedValidatorsCount                       | 24171           | 27755  | 27755  | 31339   | 2       |
| updateStuckValidatorsCount                          | 24948           | 73244  | 60665  | 138894  | 13      |
| updateTargetValidatorsLimits                        | 24390           | 126771 | 139015 | 210755  | 39      |


| src/CSVerifier.sol:CSVerifier contract |                 |       |        |        |         |
|----------------------------------------|-----------------|-------|--------|--------|---------|
| Function Name                          | min             | avg   | median | max    | # calls |
| BEACON_ROOTS                           | 304             | 304   | 304    | 304    | 21      |
| FIRST_SUPPORTED_SLOT                   | 215             | 215   | 215    | 215    | 4       |
| initialize                             | 66554           | 66554 | 66554  | 66554  | 17      |
| processHistoricalWithdrawalProof       | 80338           | 97759 | 87419  | 152939 | 5       |
| processSlashingProof                   | 48850           | 62681 | 55698  | 83497  | 3       |
| processWithdrawalProof                 | 56381           | 75183 | 74077  | 107647 | 9       |


| src/lib/AssetRecovererLib.sol:AssetRecovererLib contract |                 |       |        |       |         |
|----------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                            | min             | avg   | median | max   | # calls |
| recoverERC1155                                           | 38601           | 38601 | 38601  | 38601 | 1       |
| recoverERC20                                             | 36031           | 36031 | 36031  | 36031 | 4       |
| recoverERC721                                            | 43326           | 43326 | 43326  | 43326 | 1       |
| recoverEther                                             | 1793            | 20813 | 33493  | 33493 | 5       |




