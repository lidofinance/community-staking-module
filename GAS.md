| src/CSAccounting.sol:CSAccounting contract                          |                 |        |        |        |         |
|---------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                                       | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                             | 274             | 274    | 274    | 274    | 180     |
| ADD_BOND_CURVE_ROLE                                                 | 252             | 252    | 252    | 252    | 678     |
| MIN_BOND_LOCK_RETENTION_PERIOD                                      | 295             | 295    | 295    | 295    | 1       |
| PAUSE_ROLE                                                          | 317             | 317    | 317    | 317    | 180     |
| RECOVERER_ROLE                                                      | 305             | 305    | 305    | 305    | 12      |
| RESET_BOND_CURVE_ROLE                                               | 318             | 318    | 318    | 318    | 447     |
| RESUME_ROLE                                                         | 318             | 318    | 318    | 318    | 180     |
| SET_BOND_CURVE_ROLE                                                 | 252             | 252    | 252    | 252    | 626     |
| SET_DEFAULT_BOND_CURVE_ROLE                                         | 339             | 339    | 339    | 339    | 180     |
| addBondCurve                                                        | 24641           | 122977 | 121407 | 144545 | 292     |
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
| getBondAmountByKeysCount                                            | 1325            | 1407   | 1325   | 1588   | 239     |
| getBondAmountByKeysCountWstETH(uint256)                             | 3889            | 9728   | 4152   | 26720  | 4       |
| getBondAmountByKeysCountWstETH(uint256,(uint256,uint256[],uint256)) | 3309            | 8801   | 8856   | 14239  | 6       |
| getBondCurve                                                        | 2226            | 15893  | 16322  | 16322  | 248     |
| getBondLockRetentionPeriod                                          | 413             | 1746   | 2413   | 2413   | 3       |
| getBondShares                                                       | 563             | 601    | 563    | 2563   | 103     |
| getBondSummary                                                      | 14092           | 22841  | 21375  | 29875  | 12      |
| getBondSummaryShares                                                | 14067           | 22816  | 21350  | 29850  | 12      |
| getCurveInfo                                                        | 2158            | 2158   | 2158   | 2158   | 1       |
| getLockedBondInfo                                                   | 815             | 815    | 815    | 815    | 13      |
| getRequiredBondForNextKeys                                          | 10252           | 29198  | 24470  | 51427  | 34      |
| getRequiredBondForNextKeysWstETH                                    | 23593           | 35073  | 30819  | 57250  | 17      |
| getUnbondedKeysCount                                                | 3368            | 24104  | 15979  | 46479  | 408     |
| getUnbondedKeysCountToEject                                         | 5335            | 9442   | 7676   | 19278  | 63      |
| grantRole                                                           | 29570           | 109088 | 118658 | 118658 | 2473    |
| initialize                                                          | 207352          | 344947 | 345871 | 345871 | 450     |
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
| EL_REWARDS_STEALING_FINE                            | 306             | 306    | 306    | 306     | 13      |
| INITIAL_SLASHING_PENALTY                            | 439             | 439    | 439    | 439     | 4       |
| LIDO_LOCATOR                                        | 282             | 282    | 282    | 282     | 1       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 372             | 372    | 372    | 372     | 2       |
| MODULE_MANAGER_ROLE                                 | 283             | 283    | 283    | 283     | 273     |
| PAUSE_ROLE                                          | 262             | 262    | 262    | 262     | 232     |
| RECOVERER_ROLE                                      | 381             | 381    | 381    | 381     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 307             | 307    | 307    | 307     | 233     |
| RESUME_ROLE                                         | 373             | 373    | 373    | 373     | 232     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 306             | 306    | 306    | 306     | 233     |
| STAKING_ROUTER_ROLE                                 | 381             | 381    | 381    | 381     | 255     |
| VERIFIER_ROLE                                       | 371             | 371    | 371    | 371     | 235     |
| accounting                                          | 404             | 404    | 404    | 404     | 1       |
| activatePublicRelease                               | 23828           | 46592  | 46769  | 46769   | 248     |
| addNodeOperatorETH                                  | 26317           | 587734 | 546194 | 1172961 | 239     |
| addNodeOperatorStETH                                | 27103           | 366834 | 534417 | 538983  | 3       |
| addNodeOperatorWstETH                               | 27015           | 378837 | 552245 | 557252  | 3       |
| addValidatorKeysETH                                 | 25733           | 219451 | 258134 | 313122  | 9       |
| addValidatorKeysStETH                               | 26513           | 171233 | 241304 | 245882  | 3       |
| addValidatorKeysWstETH                              | 26491           | 183254 | 259340 | 263933  | 3       |
| cancelELRewardsStealingPenalty                      | 26371           | 92650  | 102169 | 139894  | 4       |
| claimRewardsStETH                                   | 25042           | 50776  | 27265  | 100022  | 3       |
| claimRewardsWstETH                                  | 25086           | 50433  | 27309  | 98906   | 3       |
| cleanDepositQueue                                   | 21609           | 35023  | 32788  | 53221   | 13      |
| compensateELRewardsStealingPenalty                  | 23665           | 114515 | 137924 | 158549  | 4       |
| confirmNodeOperatorManagerAddressChange             | 23645           | 28993  | 29058  | 34147   | 5       |
| confirmNodeOperatorRewardAddressChange              | 23713           | 33089  | 33975  | 38923   | 6       |
| decreaseOperatorVettedKeys                          | 24927           | 87734  | 101752 | 155842  | 22      |
| depositETH                                          | 23678           | 118921 | 125364 | 175399  | 8       |
| depositQueueItem                                    | 645             | 1311   | 645    | 2645    | 12      |
| depositStETH                                        | 24693           | 102883 | 108778 | 158813  | 5       |
| depositWstETH                                       | 24718           | 115876 | 125012 | 175047  | 5       |
| earlyAdoption                                       | 471             | 471    | 471    | 471     | 1       |
| getActiveNodeOperatorsCount                         | 382             | 382    | 382    | 382     | 2       |
| getNodeOperator                                     | 2457            | 9491   | 8457   | 18457   | 499     |
| getNodeOperatorIds                                  | 713             | 1169   | 1118   | 1870    | 8       |
| getNodeOperatorIsActive                             | 593             | 593    | 593    | 593     | 1       |
| getNodeOperatorSummary                              | 9758            | 13665  | 15758  | 15758   | 51      |
| getNodeOperatorsCount                               | 424             | 424    | 424    | 424     | 237     |
| getNonce                                            | 402             | 555    | 402    | 2402    | 78      |
| getSigningKeys                                      | 884             | 3051   | 3802   | 3802    | 7       |
| getSigningKeysWithSignatures                        | 800             | 3441   | 3335   | 6189    | 3       |
| getStakingModuleSummary                             | 617             | 2742   | 2617   | 4617    | 16      |
| getType                                             | 349             | 349    | 349    | 349     | 1       |
| grantRole                                           | 27059           | 118551 | 118637 | 118637  | 1677    |
| hasRole                                             | 838             | 838    | 838    | 838     | 2       |
| initialize                                          | 142645          | 182774 | 182925 | 182925  | 269     |
| isPaused                                            | 428             | 828    | 428    | 2428    | 5       |
| isValidatorSlashed                                  | 606             | 606    | 606    | 606     | 1       |
| isValidatorWithdrawn                                | 617             | 617    | 617    | 617     | 1       |
| normalizeQueue                                      | 30299           | 54797  | 54797  | 79296   | 2       |
| obtainDepositData                                   | 24601           | 109373 | 109761 | 176065  | 54      |
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
| recoverStETHShares                                  | 60818           | 60818  | 60818  | 60818   | 1       |
| removalCharge                                       | 408             | 1408   | 1408   | 2408    | 2       |
| removeKeys                                          | 24048           | 145646 | 172707 | 240717  | 15      |
| reportELRewardsStealingPenalty                      | 24429           | 132007 | 141525 | 151542  | 29      |
| requestRewardsETH                                   | 25109           | 50836  | 27332  | 100069  | 3       |
| resetNodeOperatorManagerAddress                     | 23756           | 31923  | 31406  | 38536   | 5       |
| resume                                              | 23787           | 26728  | 26728  | 29670   | 2       |
| revokeRole                                          | 40394           | 40394  | 40394  | 40394   | 1       |
| setRemovalCharge                                    | 24105           | 47119  | 47219  | 47231   | 233     |
| settleELRewardsStealingPenalty                      | 24806           | 83369  | 108012 | 163670  | 16      |
| submitInitialSlashing                               | 24182           | 98058  | 129918 | 134127  | 13      |
| submitWithdrawal                                    | 24429           | 121827 | 136246 | 235152  | 15      |
| unsafeUpdateValidatorsCount                         | 24320           | 61338  | 35971  | 160106  | 10      |
| updateExitedValidatorsCount                         | 24926           | 58622  | 47598  | 110326  | 11      |
| updateRefundedValidatorsCount                       | 24171           | 27755  | 27755  | 31339   | 2       |
| updateStuckValidatorsCount                          | 24948           | 73255  | 60665  | 138922  | 13      |
| updateTargetValidatorsLimits                        | 24390           | 119934 | 128426 | 210783  | 28      |


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




