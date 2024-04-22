| src/CSAccounting.sol:CSAccounting contract                          |                 |        |        |        |         |
|---------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                                       | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                             | 296             | 296    | 296    | 296    | 180     |
| ADD_BOND_CURVE_ROLE                                                 | 274             | 274    | 274    | 274    | 754     |
| MIN_BOND_LOCK_RETENTION_PERIOD                                      | 317             | 317    | 317    | 317    | 1       |
| PAUSE_ROLE                                                          | 339             | 339    | 339    | 339    | 180     |
| RECOVERER_ROLE                                                      | 327             | 327    | 327    | 327    | 12      |
| RESET_BOND_CURVE_ROLE                                               | 318             | 318    | 318    | 318    | 485     |
| RESUME_ROLE                                                         | 251             | 251    | 251    | 251    | 180     |
| SET_BOND_CURVE_ROLE                                                 | 274             | 274    | 274    | 274    | 664     |
| SET_DEFAULT_BOND_CURVE_ROLE                                         | 252             | 252    | 252    | 252    | 180     |
| addBondCurve                                                        | 24663           | 122896 | 121473 | 144611 | 322     |
| chargeFee                                                           | 21724           | 48146  | 48146  | 74568  | 2       |
| chargeRecipient                                                     | 404             | 404    | 404    | 404    | 1       |
| claimRewardsStETH                                                   | 25163           | 82221  | 96875  | 104687 | 16      |
| claimRewardsWstETH                                                  | 25098           | 118257 | 156625 | 158992 | 16      |
| compensateLockedBondETH                                             | 47658           | 47658  | 47658  | 47658  | 1       |
| defaultBondCurveId                                                  | 490             | 490    | 490    | 490    | 1       |
| depositETH                                                          | 24205           | 112166 | 113336 | 113576 | 104     |
| depositStETH                                                        | 25129           | 94093  | 103928 | 107847 | 7       |
| depositWstETH                                                       | 25193           | 105395 | 120228 | 123940 | 6       |
| feeDistributor                                                      | 404             | 1737   | 2404   | 2404   | 3       |
| getActualLockedBond                                                 | 621             | 741    | 782    | 782    | 8       |
| getBondAmountByKeysCount                                            | 1178            | 1432   | 1347   | 1610   | 263     |
| getBondAmountByKeysCountWstETH(uint256)                             | 3932            | 9771   | 4195   | 26763  | 4       |
| getBondAmountByKeysCountWstETH(uint256,(uint256,uint256[],uint256)) | 3353            | 8845   | 8900   | 14283  | 6       |
| getBondCurve                                                        | 2236            | 15946  | 16338  | 16338  | 272     |
| getBondLockRetentionPeriod                                          | 467             | 1800   | 2467   | 2467   | 3       |
| getBondShares                                                       | 604             | 642    | 604    | 2604   | 103     |
| getBondSummary                                                      | 14290           | 23043  | 21578  | 30078  | 12      |
| getBondSummaryShares                                                | 14273           | 23026  | 21561  | 30061  | 12      |
| getCurveInfo                                                        | 2217            | 2217   | 2217   | 2217   | 1       |
| getLockedBondInfo                                                   | 839             | 839    | 839    | 839    | 13      |
| getRequiredBondForNextKeys                                          | 10291           | 31063  | 24667  | 51580  | 43      |
| getRequiredBondForNextKeysWstETH                                    | 23890           | 38682  | 31142  | 57514  | 20      |
| getUnbondedKeysCount                                                | 3461            | 24964  | 16110  | 46610  | 454     |
| getUnbondedKeysCountToEject                                         | 5486            | 9347   | 7789   | 19435  | 72      |
| grantRole                                                           | 29592           | 108522 | 118680 | 118680 | 2593    |
| initialize                                                          | 207490          | 345142 | 346008 | 346008 | 480     |
| isPaused                                                            | 460             | 860    | 460    | 2460   | 5       |
| lockBondETH                                                         | 21826           | 68572  | 70367  | 70391  | 27      |
| pauseFor                                                            | 24065           | 45451  | 47590  | 47590  | 11      |
| penalize                                                            | 21744           | 34436  | 34436  | 47128  | 2       |
| recoverERC20                                                        | 24533           | 35912  | 24549  | 58655  | 3       |
| recoverEther                                                        | 23900           | 37470  | 28406  | 60106  | 3       |
| recoverStETHShares                                                  | 23856           | 43270  | 43270  | 62684  | 2       |
| releaseLockedBondETH                                                | 21804           | 26781  | 26781  | 31758  | 2       |
| requestRewardsETH                                                   | 25121           | 67090  | 72690  | 80502  | 16      |
| resetBondCurve                                                      | 24054           | 25945  | 25945  | 27836  | 2       |
| resume                                                              | 23851           | 26771  | 26771  | 29692  | 2       |
| setBondCurve                                                        | 24215           | 48846  | 49966  | 49966  | 23      |
| setChargeRecipient                                                  | 24104           | 26120  | 24107  | 30151  | 3       |
| setDefaultBondCurve                                                 | 24063           | 28174  | 28174  | 32286  | 2       |
| setLockedBondRetentionPeriod                                        | 30172           | 30172  | 30172  | 30172  | 1       |
| settleLockedBondETH                                                 | 43946           | 43946  | 43946  | 43946  | 1       |
| totalBondShares                                                     | 435             | 435    | 435    | 435    | 51      |


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
| DEFAULT_ADMIN_ROLE                                  | 305             | 305    | 305    | 305     | 1       |
| DEPOSIT_SIZE                                        | 373             | 373    | 373    | 373     | 12      |
| EL_REWARDS_STEALING_FINE                            | 306             | 306    | 306    | 306     | 23      |
| INITIAL_SLASHING_PENALTY                            | 439             | 439    | 439    | 439     | 4       |
| LIDO_LOCATOR                                        | 304             | 304    | 304    | 304     | 1       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 306             | 306    | 306    | 306     | 2       |
| MODULE_MANAGER_ROLE                                 | 283             | 283    | 283    | 283     | 311     |
| PAUSE_ROLE                                          | 307             | 307    | 307    | 307     | 270     |
| RECOVERER_ROLE                                      | 337             | 337    | 337    | 337     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 263             | 263    | 263    | 263     | 263     |
| RESUME_ROLE                                         | 351             | 351    | 351    | 351     | 262     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 284             | 284    | 284    | 284     | 263     |
| STAKING_ROUTER_ROLE                                 | 337             | 337    | 337    | 337     | 285     |
| VERIFIER_ROLE                                       | 371             | 371    | 371    | 371     | 265     |
| accounting                                          | 492             | 492    | 492    | 492     | 1       |
| activatePublicRelease                               | 23806           | 46589  | 46747  | 46747   | 278     |
| addNodeOperatorETH                                  | 26317           | 587332 | 546425 | 1173192 | 263     |
| addNodeOperatorStETH                                | 27081           | 255891 | 145287 | 539034  | 6       |
| addNodeOperatorWstETH                               | 27104           | 261990 | 145310 | 557503  | 6       |
| addValidatorKeysETH                                 | 25733           | 187015 | 258370 | 313468  | 12      |
| addValidatorKeysStETH                               | 26469           | 130455 | 90048  | 246026  | 6       |
| addValidatorKeysWstETH                              | 26447           | 139744 | 96486  | 264255  | 6       |
| cancelELRewardsStealingPenalty                      | 26349           | 92864  | 102458 | 140192  | 4       |
| claimRewardsStETH                                   | 25128           | 50973  | 27351  | 100440  | 3       |
| claimRewardsWstETH                                  | 25064           | 50522  | 27287  | 99216   | 3       |
| cleanDepositQueue                                   | 21565           | 34979  | 32744  | 53177   | 13      |
| compensateELRewardsStealingPenalty                  | 23621           | 114690 | 138169 | 158803  | 4       |
| confirmNodeOperatorManagerAddressChange             | 23734           | 29098  | 29147  | 34315   | 5       |
| confirmNodeOperatorRewardAddressChange              | 23691           | 33112  | 33998  | 38991   | 6       |
| decreaseOperatorVettedKeys                          | 24927           | 87836  | 101877 | 156092  | 22      |
| depositETH                                          | 23656           | 119067 | 125535 | 175571  | 8       |
| depositQueueItem                                    | 601             | 1267   | 601    | 2601    | 12      |
| depositStETH                                        | 24693           | 102911 | 108813 | 158849  | 5       |
| depositWstETH                                       | 24696           | 115936 | 125092 | 175128  | 5       |
| earlyAdoption                                       | 449             | 449    | 449    | 449     | 1       |
| getActiveNodeOperatorsCount                         | 468             | 468    | 468    | 468     | 2       |
| getNodeOperator                                     | 2413            | 9780   | 8413   | 18413   | 566     |
| getNodeOperatorIds                                  | 822             | 1278   | 1227   | 1979    | 8       |
| getNodeOperatorIsActive                             | 549             | 549    | 549    | 549     | 1       |
| getNodeOperatorSummary                              | 10119           | 14210  | 14493  | 16119   | 60      |
| getNodeOperatorsCount                               | 380             | 380    | 380    | 380     | 258     |
| getNonce                                            | 380             | 533    | 380    | 2380    | 78      |
| getSigningKeys                                      | 840             | 3007   | 3758   | 3758    | 7       |
| getSigningKeysWithSignatures                        | 778             | 3419   | 3313   | 6167    | 3       |
| getStakingModuleSummary                             | 705             | 2830   | 2705   | 4705    | 16      |
| getType                                             | 316             | 316    | 316    | 316     | 1       |
| grantRole                                           | 27125           | 118629 | 118703 | 118703  | 1943    |
| hasRole                                             | 772             | 772    | 772    | 772     | 2       |
| initialize                                          | 142645          | 182793 | 182925 | 182925  | 307     |
| isPaused                                            | 515             | 915    | 515    | 2515    | 5       |
| isValidatorSlashed                                  | 651             | 651    | 651    | 651     | 1       |
| isValidatorWithdrawn                                | 662             | 662    | 662    | 662     | 1       |
| keyRemovalCharge                                    | 361             | 1361   | 1361   | 2361    | 2       |
| normalizeQueue                                      | 30255           | 54753  | 54753  | 79252   | 2       |
| obtainDepositData                                   | 24579           | 109473 | 111118 | 176043  | 58      |
| onExitedAndStuckValidatorsCountsUpdated             | 23721           | 23757  | 23757  | 23793   | 2       |
| onRewardsMinted                                     | 24088           | 45623  | 45023  | 67759   | 3       |
| onWithdrawalCredentialsChanged                      | 23817           | 25299  | 25040  | 27040   | 3       |
| pauseFor                                            | 24045           | 45469  | 47612  | 47612   | 11      |
| proposeNodeOperatorManagerAddressChange             | 24187           | 42622  | 53609  | 53609   | 9       |
| proposeNodeOperatorRewardAddressChange              | 24121           | 33414  | 36466  | 36466   | 10      |
| publicRelease                                       | 452             | 452    | 452    | 452     | 1       |
| queue                                               | 503             | 836    | 503    | 2503    | 6       |
| recoverERC20                                        | 58566           | 58566  | 58566  | 58566   | 1       |
| recoverEther                                        | 23881           | 26155  | 26155  | 28429   | 2       |
| recoverStETHShares                                  | 60906           | 60906  | 60906  | 60906   | 1       |
| removeKeys                                          | 24004           | 138395 | 172335 | 240635  | 16      |
| reportELRewardsStealingPenalty                      | 24407           | 135141 | 141766 | 154496  | 36      |
| requestRewardsETH                                   | 25087           | 50918  | 27310  | 100357  | 3       |
| resetNodeOperatorManagerAddress                     | 23712           | 31956  | 31362  | 38684   | 5       |
| resume                                              | 23787           | 26728  | 26728  | 29670   | 2       |
| revokeRole                                          | 40394           | 40394  | 40394  | 40394   | 1       |
| setKeyRemovalCharge                                 | 24061           | 47089  | 47175  | 47187   | 271     |
| settleELRewardsStealingPenalty                      | 24740           | 93757  | 114360 | 164302  | 23      |
| submitInitialSlashing                               | 24204           | 98223  | 130155 | 134364  | 13      |
| submitWithdrawal                                    | 24363           | 121877 | 136395 | 235167  | 15      |
| unsafeUpdateValidatorsCount                         | 24342           | 61376  | 35993  | 160209  | 10      |
| updateExitedValidatorsCount                         | 24992           | 58688  | 47664  | 110392  | 11      |
| updateRefundedValidatorsCount                       | 24216           | 28998  | 31384  | 31396   | 3       |
| updateStuckValidatorsCount                          | 24882           | 73220  | 60599  | 138937  | 13      |
| updateTargetValidatorsLimits                        | 24435           | 124873 | 139169 | 210909  | 41      |


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




