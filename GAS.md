| src/CSAccounting.sol:CSAccounting contract                  |                 |        |        |        |         |
|-------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                               | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                     | 296             | 296    | 296    | 296    | 187     |
| CSM                                                         | 306             | 306    | 306    | 306    | 1       |
| MANAGE_BOND_CURVES_ROLE                                     | 337             | 337    | 337    | 337    | 796     |
| MIN_BOND_LOCK_RETENTION_PERIOD                              | 317             | 317    | 317    | 317    | 1       |
| PAUSE_ROLE                                                  | 317             | 317    | 317    | 317    | 187     |
| RECOVERER_ROLE                                              | 295             | 295    | 295    | 295    | 12      |
| RESET_BOND_CURVE_ROLE                                       | 274             | 274    | 274    | 274    | 1       |
| RESUME_ROLE                                                 | 340             | 340    | 340    | 340    | 187     |
| SET_BOND_CURVE_ROLE                                         | 339             | 339    | 339    | 339    | 187     |
| addBondCurve                                                | 24358           | 101491 | 98934  | 305606 | 349     |
| chargeFee                                                   | 21803           | 48145  | 48145  | 74487  | 2       |
| chargeRecipient                                             | 469             | 469    | 469    | 469    | 1       |
| claimRewardsStETH                                           | 25075           | 79039  | 90753  | 100603 | 16      |
| claimRewardsUnstETH                                         | 25055           | 63820  | 66470  | 76266  | 16      |
| claimRewardsWstETH                                          | 25121           | 114572 | 152560 | 156966 | 16      |
| compensateLockedBondETH                                     | 47498           | 47498  | 47498  | 47498  | 1       |
| depositETH                                                  | 24149           | 111142 | 113090 | 113330 | 108     |
| depositStETH                                                | 25184           | 85433  | 103849 | 107768 | 8       |
| depositWstETH                                               | 25115           | 94333  | 120818 | 124455 | 7       |
| feeDistributor                                              | 448             | 1781   | 2448   | 2448   | 3       |
| getActualLockedBond                                         | 675             | 747    | 772    | 772    | 8       |
| getBondAmountByKeysCount                                    | 1153            | 1254   | 1246   | 1274   | 286     |
| getBondAmountByKeysCountWstETH(uint256,(uint256[],uint256)) | 3224            | 11161  | 14148  | 14148  | 11      |
| getBondAmountByKeysCountWstETH(uint256,uint256)             | 3531            | 8271   | 3559   | 22438  | 4       |
| getBondCurve                                                | 1936            | 11781  | 11936  | 11936  | 297     |
| getBondCurveId                                              | 493             | 493    | 493    | 493    | 2       |
| getBondLockRetentionPeriod                                  | 401             | 1734   | 2401   | 2401   | 3       |
| getBondShares                                               | 547             | 641    | 547    | 2547   | 106     |
| getBondSummary                                              | 12712           | 18095  | 15962  | 24462  | 12      |
| getBondSummaryShares                                        | 12698           | 18081  | 15948  | 24448  | 12      |
| getCurveInfo                                                | 1637            | 1801   | 1884   | 1884   | 3       |
| getLockedBondInfo                                           | 817             | 817    | 817    | 817    | 12      |
| getRequiredBondForNextKeys                                  | 6320            | 19407  | 17824  | 31126  | 45      |
| getRequiredBondForNextKeysWstETH                            | 21075           | 28333  | 24206  | 35230  | 20      |
| getUnbondedKeysCount                                        | 2568            | 11735  | 6774   | 25524  | 486     |
| getUnbondedKeysCountToEject                                 | 4055            | 7092   | 4519   | 13905  | 36      |
| grantRole                                                   | 29393           | 99943  | 118481 | 118481 | 1547    |
| initialize                                                  | 25980           | 491083 | 493357 | 493357 | 513     |
| isPaused                                                    | 406             | 806    | 406    | 2406   | 5       |
| lockBondETH                                                 | 21797           | 68483  | 70275  | 70299  | 27      |
| pauseFor                                                    | 23962           | 45328  | 47465  | 47465  | 11      |
| penalize                                                    | 21803           | 37928  | 37928  | 54053  | 2       |
| recoverERC20                                                | 24515           | 35898  | 24550  | 58630  | 3       |
| recoverEther                                                | 23758           | 37362  | 28315  | 60015  | 3       |
| recoverStETHShares                                          | 23736           | 43155  | 43155  | 62575  | 2       |
| releaseLockedBondETH                                        | 21819           | 26708  | 26708  | 31597  | 2       |
| resetBondCurve                                              | 23951           | 24792  | 24792  | 25634  | 2       |
| resume                                                      | 23792           | 26701  | 26701  | 29611  | 2       |
| setBondCurve                                                | 24112           | 48933  | 49926  | 49926  | 26      |
| setChargeRecipient                                          | 24066           | 26103  | 24070  | 30173  | 3       |
| setLockedBondRetentionPeriod                                | 30121           | 30121  | 30121  | 30121  | 1       |
| settleLockedBondETH                                         | 50773           | 50773  | 50773  | 50773  | 1       |
| totalBondShares                                             | 347             | 458    | 347    | 2347   | 54      |
| updateBondCurve                                             | 24442           | 37984  | 26783  | 62729  | 3       |


| src/CSEarlyAdoption.sol:CSEarlyAdoption contract |                 |       |        |       |         |
|--------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                    | min             | avg   | median | max   | # calls |
| CURVE_ID                                         | 216             | 216   | 216    | 216   | 4       |
| MODULE                                           | 205             | 205   | 205    | 205   | 1       |
| TREE_ROOT                                        | 194             | 194   | 194    | 194   | 1       |
| consume                                          | 22803           | 34367 | 25769  | 47076 | 7       |
| isConsumed                                       | 593             | 593   | 593    | 593   | 1       |
| verifyProof                                      | 1318            | 1318  | 1318   | 1318  | 2       |


| src/CSFeeDistributor.sol:CSFeeDistributor contract |                 |        |        |        |         |
|----------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                      | min             | avg    | median | max    | # calls |
| ACCOUNTING                                         | 326             | 326    | 326    | 326    | 1       |
| RECOVERER_ROLE                                     | 305             | 305    | 305    | 305    | 7       |
| STETH                                              | 281             | 281    | 281    | 281    | 1       |
| distributeFees                                     | 22305           | 42510  | 27793  | 76005  | 6       |
| distributedShares                                  | 523             | 1523   | 1523   | 2523   | 4       |
| getFeesToDistribute                                | 1619            | 2619   | 2619   | 3619   | 2       |
| grantRole                                          | 118482          | 118482 | 118482 | 118482 | 5       |
| hashLeaf                                           | 623             | 623    | 623    | 623    | 1       |
| initialize                                         | 24594           | 205622 | 229545 | 229545 | 24      |
| pendingSharesToDistribute                          | 1487            | 1487   | 1487   | 1487   | 2       |
| processOracleReport                                | 32183           | 76269  | 99881  | 99905  | 17      |
| recoverERC20                                       | 24456           | 35839  | 24491  | 58571  | 3       |
| recoverEther                                       | 23713           | 41841  | 41841  | 59970  | 2       |
| totalClaimableShares                               | 362             | 362    | 362    | 362    | 1       |
| treeCid                                            | 1275            | 2147   | 2147   | 3020   | 2       |
| treeRoot                                           | 384             | 1050   | 384    | 2384   | 3       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| CONTRACT_MANAGER_ROLE                    | 262             | 262    | 262    | 262    | 10      |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 239             | 239    | 239    | 239    | 10      |
| MANAGE_CONSENSUS_VERSION_ROLE            | 328             | 328    | 328    | 328    | 10      |
| PAUSE_ROLE                               | 262             | 262    | 262    | 262    | 10      |
| RESUME_ROLE                              | 262             | 262    | 262    | 262    | 10      |
| SUBMIT_DATA_ROLE                         | 284             | 284    | 284    | 284    | 18      |
| avgPerfLeewayBP                          | 405             | 405    | 405    | 405    | 1       |
| feeDistributor                           | 448             | 448    | 448    | 448    | 1       |
| getConsensusReport                       | 1018            | 1977   | 1044   | 3018   | 21      |
| getConsensusVersion                      | 396             | 1486   | 2396   | 2396   | 11      |
| getLastProcessingRefSlot                 | 494             | 2331   | 2494   | 2494   | 37      |
| grantRole                                | 101382          | 115462 | 118482 | 118482 | 68      |
| initialize                               | 22903           | 224025 | 244138 | 244138 | 11      |
| pauseFor                                 | 47474           | 47474  | 47474  | 47474  | 2       |
| pauseUntil                               | 47490           | 47490  | 47490  | 47490  | 1       |
| resume                                   | 23503           | 26621  | 26621  | 29739  | 2       |
| setFeeDistributorContract                | 24050           | 27211  | 27211  | 30372  | 2       |
| setPerformanceLeeway                     | 24017           | 27037  | 27037  | 30057  | 2       |
| submitReportData                         | 25442           | 47501  | 35464  | 75579  | 5       |


| src/CSModule.sol:CSModule contract                  |                 |        |        |         |         |
|-----------------------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                                       | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                                  | 328             | 328    | 328    | 328     | 1       |
| EL_REWARDS_STEALING_FINE                            | 306             | 306    | 306    | 306     | 24      |
| INITIAL_SLASHING_PENALTY                            | 327             | 327    | 327    | 327     | 4       |
| LIDO_LOCATOR                                        | 327             | 327    | 327    | 327     | 2       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 329             | 329    | 329    | 329     | 3       |
| MODULE_MANAGER_ROLE                                 | 306             | 306    | 306    | 306     | 329     |
| PAUSE_ROLE                                          | 285             | 285    | 285    | 285     | 287     |
| RECOVERER_ROLE                                      | 306             | 306    | 306    | 306     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 283             | 283    | 283    | 283     | 288     |
| RESUME_ROLE                                         | 330             | 330    | 330    | 330     | 323     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 351             | 351    | 351    | 351     | 288     |
| STAKING_ROUTER_ROLE                                 | 360             | 360    | 360    | 360     | 310     |
| VERIFIER_ROLE                                       | 327             | 327    | 327    | 327     | 326     |
| accounting                                          | 426             | 426    | 426    | 426     | 1       |
| activatePublicRelease                               | 23745           | 29587  | 29619  | 29619   | 303     |
| addNodeOperatorETH                                  | 26763           | 434130 | 382018 | 1059291 | 281     |
| addNodeOperatorStETH                                | 27567           | 249974 | 280124 | 374537  | 8       |
| addNodeOperatorWstETH                               | 27589           | 273104 | 311202 | 395195  | 8       |
| addValidatorKeysETH                                 | 25657           | 165620 | 218089 | 272568  | 13      |
| addValidatorKeysStETH                               | 26438           | 115775 | 91941  | 205785  | 6       |
| addValidatorKeysWstETH                              | 26416           | 136095 | 135446 | 224526  | 6       |
| cancelELRewardsStealingPenalty                      | 26343           | 65343  | 76129  | 82771   | 4       |
| claimRewardsStETH                                   | 25035           | 48021  | 48568  | 69913   | 4       |
| claimRewardsUnstETH                                 | 25058           | 48034  | 48581  | 69916   | 4       |
| claimRewardsWstETH                                  | 25057           | 47518  | 48066  | 68886   | 4       |
| cleanDepositQueue                                   | 24634           | 40912  | 40872  | 61551   | 13      |
| compensateELRewardsStealingPenalty                  | 23698           | 78713  | 94837  | 101481  | 4       |
| confirmNodeOperatorManagerAddressChange             | 27012           | 29370  | 29158  | 32365   | 5       |
| confirmNodeOperatorRewardAddressChange              | 26830           | 30860  | 32161  | 32161   | 9       |
| decreaseVettedSigningKeysCount                      | 24855           | 63504  | 77338  | 97253   | 22      |
| depositETH                                          | 23777           | 90326  | 96069  | 118116  | 8       |
| depositQueue                                        | 480             | 813    | 480    | 2480    | 6       |
| depositQueueItem                                    | 645             | 1311   | 645    | 2645    | 12      |
| depositStETH                                        | 24703           | 73755  | 79363  | 101404  | 5       |
| depositWstETH                                       | 24729           | 89742  | 100668 | 118375  | 5       |
| earlyAdoption                                       | 450             | 450    | 450    | 450     | 1       |
| getActiveNodeOperatorsCount                         | 460             | 460    | 460    | 460     | 2       |
| getNodeOperator                                     | 2469            | 5564   | 6469   | 12469   | 73      |
| getNodeOperatorIds                                  | 769             | 1226   | 1175   | 1925    | 8       |
| getNodeOperatorIsActive                             | 537             | 537    | 537    | 537     | 1       |
| getNodeOperatorNonWithdrawnKeys                     | 614             | 721    | 614    | 2614    | 539     |
| getNodeOperatorSummary                              | 6129            | 6274   | 6210   | 6436    | 24      |
| getNodeOperatorsCount                               | 416             | 416    | 416    | 416     | 274     |
| getNonce                                            | 425             | 578    | 425    | 2425    | 78      |
| getSigningKeys                                      | 693             | 2757   | 3098   | 3489    | 8       |
| getSigningKeysWithSignatures                        | 698             | 3131   | 2931   | 5965    | 4       |
| getStakingModuleSummary                             | 497             | 497    | 497    | 497     | 20      |
| getType                                             | 316             | 316    | 316    | 316     | 2       |
| grantRole                                           | 27012           | 116004 | 118482 | 118482  | 2135    |
| hasRole                                             | 783             | 783    | 783    | 783     | 2       |
| initialize                                          | 25099           | 323871 | 326516 | 326516  | 327     |
| isPaused                                            | 417             | 750    | 417    | 2417    | 6       |
| isValidatorSlashed                                  | 629             | 629    | 629    | 629     | 1       |
| isValidatorWithdrawn                                | 662             | 662    | 662    | 662     | 1       |
| keyRemovalCharge                                    | 383             | 1049   | 383    | 2383    | 3       |
| normalizeQueue                                      | 29509           | 45531  | 45531  | 61553   | 2       |
| obtainDepositData                                   | 24584           | 76406  | 68635  | 140331  | 66      |
| onExitedAndStuckValidatorsCountsUpdated             | 23705           | 23741  | 23741  | 23777   | 2       |
| onRewardsMinted                                     | 24005           | 42108  | 39792  | 62528   | 3       |
| onWithdrawalCredentialsChanged                      | 23779           | 24593  | 25001  | 25001   | 3       |
| pauseFor                                            | 24029           | 29849  | 30432  | 30432   | 11      |
| proposeNodeOperatorManagerAddressChange             | 27485           | 41827  | 52039  | 52039   | 11      |
| proposeNodeOperatorRewardAddressChange              | 27546           | 44581  | 52066  | 52066   | 15      |
| publicRelease                                       | 426             | 426    | 426    | 426     | 1       |
| recoverERC20                                        | 58549           | 58549  | 58549  | 58549   | 1       |
| recoverEther                                        | 23781           | 26059  | 26059  | 28338   | 2       |
| recoverStETHShares                                  | 55664           | 55664  | 55664  | 55664   | 1       |
| removeKeys                                          | 24078           | 116795 | 141026 | 215572  | 17      |
| reportELRewardsStealingPenalty                      | 24302           | 112536 | 122968 | 123852  | 36      |
| resetNodeOperatorManagerAddress                     | 26951           | 31027  | 29385  | 36734   | 5       |
| resume                                              | 23748           | 29549  | 29567  | 29567   | 324     |
| revokeRole                                          | 40217           | 40217  | 40217  | 40217   | 1       |
| setKeyRemovalCharge                                 | 24022           | 27226  | 27235  | 30047   | 289     |
| settleELRewardsStealingPenalty                      | 24521           | 77927  | 91471  | 118530  | 22      |
| submitInitialSlashing                               | 24121           | 82423  | 110087 | 124747  | 14      |
| submitWithdrawal                                    | 24324           | 89515  | 104096 | 139099  | 17      |
| unsafeUpdateValidatorsCount                         | 24304           | 44173  | 39282  | 83216   | 12      |
| updateExitedValidatorsCount                         | 24909           | 41188  | 48230  | 57983   | 11      |
| updateRefundedValidatorsCount                       | 24101           | 24115  | 24113  | 24133   | 3       |
| updateStuckValidatorsCount                          | 24866           | 53295  | 48583  | 79681   | 14      |
| updateTargetValidatorsLimits                        | 24307           | 73549  | 71898  | 114887  | 41      |


| src/CSVerifier.sol:CSVerifier contract |                 |       |        |        |         |
|----------------------------------------|-----------------|-------|--------|--------|---------|
| Function Name                          | min             | avg   | median | max    | # calls |
| BEACON_ROOTS                           | 293             | 293   | 293    | 293    | 21      |
| FIRST_SUPPORTED_SLOT                   | 282             | 282   | 282    | 282    | 5       |
| GI_FIRST_VALIDATOR                     | 217             | 217   | 217    | 217    | 1       |
| GI_FIRST_WITHDRAWAL                    | 239             | 239   | 239    | 239    | 1       |
| GI_HISTORICAL_SUMMARIES                | 261             | 261   | 261    | 261    | 1       |
| LOCATOR                                | 227             | 227   | 227    | 227    | 1       |
| MODULE                                 | 205             | 205   | 205    | 205    | 1       |
| SLOTS_PER_EPOCH                        | 259             | 259   | 259    | 259    | 1       |
| processHistoricalWithdrawalProof       | 73146           | 88613 | 80221  | 135957 | 5       |
| processSlashingProof                   | 48722           | 61798 | 55564  | 81110  | 3       |
| processWithdrawalProof                 | 56367           | 72760 | 69792  | 102958 | 9       |


| src/lib/AssetRecovererLib.sol:AssetRecovererLib contract |                 |       |        |       |         |
|----------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                            | min             | avg   | median | max   | # calls |
| recoverERC1155                                           | 38601           | 38601 | 38601  | 38601 | 1       |
| recoverERC20                                             | 36019           | 36019 | 36019  | 36019 | 4       |
| recoverERC721                                            | 43302           | 43302 | 43302  | 43302 | 1       |
| recoverEther                                             | 1793            | 20813 | 33493  | 33493 | 5       |




