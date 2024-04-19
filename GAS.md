| src/CSAccounting.sol:CSAccounting contract                          |                 |        |        |        |         |
|---------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                                       | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                             | 296             | 296    | 296    | 296    | 180     |
| ADD_BOND_CURVE_ROLE                                                 | 274             | 274    | 274    | 274    | 700     |
| MIN_BOND_LOCK_RETENTION_PERIOD                                      | 317             | 317    | 317    | 317    | 1       |
| PAUSE_ROLE                                                          | 339             | 339    | 339    | 339    | 180     |
| RECOVERER_ROLE                                                      | 327             | 327    | 327    | 327    | 12      |
| RESET_BOND_CURVE_ROLE                                               | 318             | 318    | 318    | 318    | 458     |
| RESUME_ROLE                                                         | 251             | 251    | 251    | 251    | 180     |
| SET_BOND_CURVE_ROLE                                                 | 274             | 274    | 274    | 274    | 637     |
| SET_DEFAULT_BOND_CURVE_ROLE                                         | 252             | 252    | 252    | 252    | 180     |
| addBondCurve                                                        | 24663           | 122986 | 121473 | 144611 | 303     |
| chargeFee                                                           | 21724           | 48244  | 48244  | 74765  | 2       |
| chargeRecipient                                                     | 404             | 404    | 404    | 404    | 1       |
| claimRewardsStETH                                                   | 25163           | 82344  | 97072  | 104884 | 16      |
| claimRewardsWstETH                                                  | 25098           | 118327 | 156737 | 159104 | 16      |
| compensateLockedBondETH                                             | 47658           | 47658  | 47658  | 47658  | 1       |
| defaultBondCurveId                                                  | 490             | 490    | 490    | 490    | 1       |
| depositETH                                                          | 24205           | 112166 | 113336 | 113576 | 104     |
| depositStETH                                                        | 25129           | 94152  | 103997 | 107916 | 7       |
| depositWstETH                                                       | 25193           | 105453 | 120297 | 124009 | 6       |
| feeDistributor                                                      | 404             | 1737   | 2404   | 2404   | 3       |
| getActualLockedBond                                                 | 621             | 741    | 782    | 782    | 8       |
| getBondAmountByKeysCount                                            | 1347            | 1437   | 1347   | 1610   | 250     |
| getBondAmountByKeysCountWstETH(uint256)                             | 3910            | 9749   | 4173   | 26741  | 4       |
| getBondAmountByKeysCountWstETH(uint256,(uint256,uint256[],uint256)) | 3331            | 8823   | 8878   | 14261  | 6       |
| getBondCurve                                                        | 2236            | 15927  | 16338  | 16338  | 259     |
| getBondLockRetentionPeriod                                          | 467             | 1800   | 2467   | 2467   | 3       |
| getBondShares                                                       | 604             | 642    | 604    | 2604   | 103     |
| getBondSummary                                                      | 14290           | 23043  | 21578  | 30078  | 12      |
| getBondSummaryShares                                                | 14273           | 23026  | 21561  | 30061  | 12      |
| getCurveInfo                                                        | 2217            | 2217   | 2217   | 2217   | 1       |
| getLockedBondInfo                                                   | 839             | 839    | 839    | 839    | 13      |
| getRequiredBondForNextKeys                                          | 10393           | 29368  | 24667  | 51580  | 34      |
| getRequiredBondForNextKeysWstETH                                    | 23868           | 35353  | 31105  | 57492  | 17      |
| getUnbondedKeysCount                                                | 3461            | 25164  | 16110  | 46610  | 444     |
| getUnbondedKeysCountToEject                                         | 5486            | 9347   | 7789   | 19435  | 72      |
| grantRole                                                           | 29592           | 108888 | 118680 | 118680 | 2517    |
| initialize                                                          | 207490          | 345106 | 346008 | 346008 | 461     |
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
| DEFAULT_ADMIN_ROLE                                  | 327             | 327    | 327    | 327     | 1       |
| DEPOSIT_SIZE                                        | 285             | 285    | 285    | 285     | 12      |
| EL_REWARDS_STEALING_FINE                            | 284             | 284    | 284    | 284     | 23      |
| INITIAL_SLASHING_PENALTY                            | 417             | 417    | 417    | 417     | 4       |
| LIDO_LOCATOR                                        | 282             | 282    | 282    | 282     | 1       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 350             | 350    | 350    | 350     | 2       |
| MODULE_MANAGER_ROLE                                 | 261             | 261    | 261    | 261     | 284     |
| PAUSE_ROLE                                          | 351             | 351    | 351    | 351     | 243     |
| RECOVERER_ROLE                                      | 337             | 337    | 337    | 337     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 263             | 263    | 263    | 263     | 244     |
| RESUME_ROLE                                         | 351             | 351    | 351    | 351     | 243     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 284             | 284    | 284    | 284     | 244     |
| STAKING_ROUTER_ROLE                                 | 337             | 337    | 337    | 337     | 266     |
| VERIFIER_ROLE                                       | 371             | 371    | 371    | 371     | 246     |
| accounting                                          | 492             | 492    | 492    | 492     | 1       |
| activatePublicRelease                               | 23806           | 46577  | 46747  | 46747   | 259     |
| addNodeOperatorETH                                  | 26317           | 593998 | 546425 | 1173192 | 250     |
| addNodeOperatorStETH                                | 27081           | 366907 | 534537 | 539103  | 3       |
| addNodeOperatorWstETH                               | 27104           | 379065 | 552543 | 557550  | 3       |
| addValidatorKeysETH                                 | 25733           | 219733 | 258480 | 313468  | 9       |
| addValidatorKeysStETH                               | 26469           | 171360 | 241517 | 246095  | 3       |
| addValidatorKeysWstETH                              | 26447           | 183486 | 259709 | 264302  | 3       |
| cancelELRewardsStealingPenalty                      | 26349           | 92864  | 102458 | 140192  | 4       |
| claimRewardsStETH                                   | 25128           | 50973  | 27351  | 100440  | 3       |
| claimRewardsWstETH                                  | 25064           | 50522  | 27287  | 99216   | 3       |
| cleanDepositQueue                                   | 21565           | 34979  | 32744  | 53177   | 13      |
| compensateELRewardsStealingPenalty                  | 23621           | 114690 | 138169 | 158803  | 4       |
| confirmNodeOperatorManagerAddressChange             | 23734           | 29082  | 29147  | 34236   | 5       |
| confirmNodeOperatorRewardAddressChange              | 23691           | 33067  | 33953  | 38901   | 6       |
| decreaseOperatorVettedKeys                          | 24927           | 87836  | 101877 | 156092  | 22      |
| depositETH                                          | 23656           | 119067 | 125535 | 175571  | 8       |
| depositQueueItem                                    | 601             | 1267   | 601    | 2601    | 12      |
| depositStETH                                        | 24693           | 102967 | 108882 | 158918  | 5       |
| depositWstETH                                       | 24696           | 115991 | 125161 | 175197  | 5       |
| earlyAdoption                                       | 449             | 449    | 449    | 449     | 1       |
| getActiveNodeOperatorsCount                         | 468             | 468    | 468    | 468     | 2       |
| getNodeOperator                                     | 2413            | 9703   | 8413   | 18413   | 544     |
| getNodeOperatorIds                                  | 822             | 1278   | 1227   | 1979    | 8       |
| getNodeOperatorIsActive                             | 549             | 549    | 549    | 549     | 1       |
| getNodeOperatorSummary                              | 10119           | 14210  | 14493  | 16119   | 60      |
| getNodeOperatorsCount                               | 380             | 380    | 380    | 380     | 248     |
| getNonce                                            | 380             | 533    | 380    | 2380    | 78      |
| getSigningKeys                                      | 840             | 3007   | 3758   | 3758    | 7       |
| getSigningKeysWithSignatures                        | 778             | 3419   | 3313   | 6167    | 3       |
| getStakingModuleSummary                             | 705             | 2830   | 2705   | 4705    | 16      |
| getType                                             | 316             | 316    | 316    | 316     | 1       |
| grantRole                                           | 27169           | 118665 | 118747 | 118747  | 1754    |
| hasRole                                             | 794             | 794    | 794    | 794     | 2       |
| initialize                                          | 142623          | 182758 | 182903 | 182903  | 280     |
| isPaused                                            | 515             | 915    | 515    | 2515    | 5       |
| isValidatorSlashed                                  | 584             | 584    | 584    | 584     | 1       |
| isValidatorWithdrawn                                | 595             | 595    | 595    | 595     | 1       |
| keyRemovalCharge                                    | 471             | 1471   | 1471   | 2471    | 2       |
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
| removeKeys                                          | 24004           | 145699 | 172782 | 240792  | 15      |
| reportELRewardsStealingPenalty                      | 24407           | 135141 | 141766 | 154496  | 36      |
| requestRewardsETH                                   | 25087           | 50918  | 27310  | 100357  | 3       |
| resetNodeOperatorManagerAddress                     | 23712           | 31879  | 31362  | 38492   | 5       |
| resume                                              | 23787           | 26728  | 26728  | 29670   | 2       |
| revokeRole                                          | 40376           | 40376  | 40376  | 40376   | 1       |
| setKeyRemovalCharge                                 | 24039           | 47058  | 47153  | 47165   | 244     |
| settleELRewardsStealingPenalty                      | 24784           | 93834  | 114448 | 164434  | 23      |
| submitInitialSlashing                               | 24182           | 98231  | 130177 | 134386  | 13      |
| submitWithdrawal                                    | 24407           | 121953 | 136483 | 235255  | 15      |
| unsafeUpdateValidatorsCount                         | 24320           | 61363  | 35971  | 160231  | 10      |
| updateExitedValidatorsCount                         | 24882           | 58578  | 47554  | 110282  | 11      |
| updateRefundedValidatorsCount                       | 24238           | 27822  | 27822  | 31406   | 2       |
| updateStuckValidatorsCount                          | 24904           | 73259  | 60621  | 139003  | 13      |
| updateTargetValidatorsLimits                        | 24479           | 127001 | 139257 | 210997  | 39      |


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




