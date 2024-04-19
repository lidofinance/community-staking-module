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
| getRequiredBondForNextKeys                                          | 10437           | 29393  | 24667  | 51624  | 34      |
| getRequiredBondForNextKeysWstETH                                    | 23868           | 35358  | 31105  | 57536  | 17      |
| getUnbondedKeysCount                                                | 3461            | 25207  | 16154  | 46654  | 444     |
| getUnbondedKeysCountToEject                                         | 5486            | 9384   | 7833   | 19435  | 72      |
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
| DEFAULT_ADMIN_ROLE                                  | 260             | 260    | 260    | 260     | 1       |
| DEPOSIT_SIZE                                        | 307             | 307    | 307    | 307     | 12      |
| EL_REWARDS_STEALING_FINE                            | 306             | 306    | 306    | 306     | 23      |
| INITIAL_SLASHING_PENALTY                            | 439             | 439    | 439    | 439     | 4       |
| LIDO_LOCATOR                                        | 282             | 282    | 282    | 282     | 1       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 372             | 372    | 372    | 372     | 2       |
| MODULE_MANAGER_ROLE                                 | 283             | 283    | 283    | 283     | 284     |
| PAUSE_ROLE                                          | 262             | 262    | 262    | 262     | 243     |
| RECOVERER_ROLE                                      | 381             | 381    | 381    | 381     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 307             | 307    | 307    | 307     | 244     |
| RESUME_ROLE                                         | 373             | 373    | 373    | 373     | 243     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 306             | 306    | 306    | 306     | 244     |
| STAKING_ROUTER_ROLE                                 | 381             | 381    | 381    | 381     | 266     |
| VERIFIER_ROLE                                       | 371             | 371    | 371    | 371     | 246     |
| accounting                                          | 404             | 404    | 404    | 404     | 1       |
| activatePublicRelease                               | 23828           | 46599  | 46769  | 46769   | 259     |
| addNodeOperatorETH                                  | 26317           | 594041 | 546469 | 1173236 | 250     |
| addNodeOperatorStETH                                | 27103           | 366958 | 534603 | 539169  | 3       |
| addNodeOperatorWstETH                               | 27015           | 379006 | 552498 | 557505  | 3       |
| addValidatorKeysETH                                 | 25733           | 219806 | 258568 | 313556  | 9       |
| addValidatorKeysStETH                               | 26513           | 171463 | 241649 | 246227  | 3       |
| addValidatorKeysWstETH                              | 26491           | 183588 | 259841 | 264434  | 3       |
| cancelELRewardsStealingPenalty                      | 26371           | 92919  | 102524 | 140258  | 4       |
| claimRewardsStETH                                   | 25042           | 50916  | 27265  | 100442  | 3       |
| claimRewardsWstETH                                  | 25086           | 50573  | 27309  | 99326   | 3       |
| cleanDepositQueue                                   | 21609           | 35023  | 32788  | 53221   | 13      |
| compensateELRewardsStealingPenalty                  | 23665           | 114767 | 138257 | 158891  | 4       |
| confirmNodeOperatorManagerAddressChange             | 23645           | 28993  | 29058  | 34147   | 5       |
| confirmNodeOperatorRewardAddressChange              | 23713           | 33089  | 33975  | 38923   | 6       |
| decreaseOperatorVettedKeys                          | 24927           | 87872  | 101921 | 156180  | 22      |
| depositETH                                          | 23678           | 119127 | 125601 | 175637  | 8       |
| depositQueueItem                                    | 645             | 1311   | 645    | 2645    | 12      |
| depositStETH                                        | 24693           | 103002 | 108926 | 158962  | 5       |
| depositWstETH                                       | 24718           | 116048 | 125227 | 175263  | 5       |
| earlyAdoption                                       | 471             | 471    | 471    | 471     | 1       |
| getActiveNodeOperatorsCount                         | 382             | 382    | 382    | 382     | 2       |
| getNodeOperator                                     | 2457            | 9747   | 8457   | 18457   | 544     |
| getNodeOperatorIds                                  | 713             | 1169   | 1118   | 1870    | 8       |
| getNodeOperatorIsActive                             | 593             | 593    | 593    | 593     | 1       |
| getNodeOperatorSummary                              | 10076           | 14167  | 14450  | 16076   | 60      |
| getNodeOperatorsCount                               | 424             | 424    | 424    | 424     | 248     |
| getNonce                                            | 402             | 555    | 402    | 2402    | 78      |
| getSigningKeys                                      | 884             | 3051   | 3802   | 3802    | 7       |
| getSigningKeysWithSignatures                        | 800             | 3441   | 3335   | 6189    | 3       |
| getStakingModuleSummary                             | 617             | 2742   | 2617   | 4617    | 16      |
| getType                                             | 349             | 349    | 349    | 349     | 1       |
| grantRole                                           | 27059           | 118555 | 118637 | 118637  | 1754    |
| hasRole                                             | 838             | 838    | 838    | 838     | 2       |
| initialize                                          | 142645          | 182780 | 182925 | 182925  | 280     |
| isPaused                                            | 428             | 828    | 428    | 2428    | 5       |
| isValidatorSlashed                                  | 606             | 606    | 606    | 606     | 1       |
| isValidatorWithdrawn                                | 617             | 617    | 617    | 617     | 1       |
| normalizeQueue                                      | 30299           | 54797  | 54797  | 79296   | 2       |
| obtainDepositData                                   | 24601           | 109495 | 111140 | 176065  | 58      |
| onExitedAndStuckValidatorsCountsUpdated             | 23721           | 23757  | 23757  | 23793   | 2       |
| onRewardsMinted                                     | 24021           | 45556  | 44956  | 67692   | 3       |
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
| removeKeys                                          | 24048           | 145772 | 172852 | 240863  | 15      |
| reportELRewardsStealingPenalty                      | 24429           | 135205 | 141832 | 154562  | 36      |
| requestRewardsETH                                   | 25109           | 50969  | 27332  | 100467  | 3       |
| resetNodeOperatorManagerAddress                     | 23756           | 31923  | 31406  | 38536   | 5       |
| resume                                              | 23787           | 26728  | 26728  | 29670   | 2       |
| revokeRole                                          | 40394           | 40394  | 40394  | 40394   | 1       |
| setRemovalCharge                                    | 24105           | 47124  | 47219  | 47231   | 244     |
| settleELRewardsStealingPenalty                      | 24806           | 93888  | 114514 | 164544  | 23      |
| submitInitialSlashing                               | 24182           | 98262  | 130221 | 134430  | 13      |
| submitWithdrawal                                    | 24429           | 122008 | 136549 | 235321  | 15      |
| unsafeUpdateValidatorsCount                         | 24320           | 61372  | 35971  | 160275  | 10      |
| updateExitedValidatorsCount                         | 24926           | 58622  | 47598  | 110326  | 11      |
| updateRefundedValidatorsCount                       | 24171           | 27755  | 27755  | 31339   | 2       |
| updateStuckValidatorsCount                          | 24948           | 73320  | 60665  | 139091  | 13      |
| updateTargetValidatorsLimits                        | 24390           | 126953 | 139212 | 210952  | 39      |


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




