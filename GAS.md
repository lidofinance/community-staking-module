| src/CSAccounting.sol:CSAccounting contract                  |                 |        |        |        |         |
|-------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                               | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                     | 296             | 296    | 296    | 296    | 192     |
| CSM                                                         | 306             | 306    | 306    | 306    | 1       |
| MANAGE_BOND_CURVES_ROLE                                     | 337             | 337    | 337    | 337    | 821     |
| MIN_BOND_LOCK_RETENTION_PERIOD                              | 317             | 317    | 317    | 317    | 1       |
| PAUSE_ROLE                                                  | 317             | 317    | 317    | 317    | 192     |
| RECOVERER_ROLE                                              | 295             | 295    | 295    | 295    | 12      |
| RESET_BOND_CURVE_ROLE                                       | 274             | 274    | 274    | 274    | 1       |
| RESUME_ROLE                                                 | 340             | 340    | 340    | 340    | 192     |
| SET_BOND_CURVE_ROLE                                         | 339             | 339    | 339    | 339    | 192     |
| addBondCurve                                                | 24359           | 101176 | 98698  | 304001 | 357     |
| chargeFee                                                   | 21788           | 48134  | 48134  | 74480  | 2       |
| chargeRecipient                                             | 469             | 469    | 469    | 469    | 1       |
| claimRewardsStETH                                           | 25075           | 78946  | 90934  | 98816  | 16      |
| claimRewardsUnstETH                                         | 25055           | 63709  | 66568  | 74450  | 16      |
| claimRewardsWstETH                                          | 25121           | 116367 | 155764 | 158202 | 16      |
| compensateLockedBondETH                                     | 45461           | 45461  | 45461  | 45461  | 1       |
| depositETH                                                  | 24149           | 111139 | 113066 | 113306 | 109     |
| depositStETH                                                | 25184           | 97776  | 107311 | 134994 | 9       |
| depositWstETH                                               | 25115           | 101754 | 121787 | 146852 | 8       |
| feeDistributor                                              | 448             | 1781   | 2448   | 2448   | 3       |
| getActualLockedBond                                         | 681             | 767    | 810    | 810    | 9       |
| getBondAmountByKeysCount                                    | 1153            | 1382   | 1304   | 1546   | 294     |
| getBondAmountByKeysCountWstETH(uint256,(uint256[],uint256)) | 3293            | 11239  | 14217  | 14217  | 11      |
| getBondAmountByKeysCountWstETH(uint256,uint256)             | 3614            | 8447   | 3856   | 22463  | 4       |
| getBondCurve                                                | 1928            | 11682  | 11928  | 11928  | 308     |
| getBondCurveId                                              | 493             | 493    | 493    | 493    | 2       |
| getBondLockRetentionPeriod                                  | 369             | 1702   | 2369   | 2369   | 3       |
| getBondShares                                               | 547             | 706    | 547    | 2547   | 88      |
| getBondSummary                                              | 12955           | 18314  | 16173  | 24673  | 12      |
| getBondSummaryShares                                        | 12919           | 18278  | 16137  | 24637  | 12      |
| getCurveInfo                                                | 1629            | 1793   | 1876   | 1876   | 3       |
| getLockedBondInfo                                           | 782             | 782    | 782    | 782    | 14      |
| getRequiredBondForNextKeys                                  | 4791            | 18005  | 16422  | 29444  | 45      |
| getRequiredBondForNextKeysWstETH                            | 19616           | 26979  | 22837  | 33948  | 20      |
| getUnbondedKeysCount                                        | 2617            | 11685  | 6707   | 25489  | 502     |
| getUnbondedKeysCountToEject                                 | 3977            | 7017   | 4446   | 13832  | 36      |
| grantRole                                                   | 29393           | 99966  | 118481 | 118481 | 1592    |
| initialize                                                  | 25980           | 557195 | 559899 | 559899 | 530     |
| isPaused                                                    | 406             | 806    | 406    | 2406   | 5       |
| lockBondETH                                                 | 21782           | 47340  | 48320  | 48344  | 27      |
| pauseFor                                                    | 23963           | 45328  | 47465  | 47465  | 11      |
| penalize                                                    | 21788           | 38635  | 38635  | 55483  | 2       |
| pullFeeRewards                                              | 27530           | 49731  | 49731  | 71932  | 2       |
| recoverERC20                                                | 24516           | 35898  | 24550  | 58630  | 3       |
| recoverEther                                                | 23759           | 37363  | 28315  | 60015  | 3       |
| recoverStETHShares                                          | 23737           | 43156  | 43156  | 62575  | 2       |
| releaseLockedBondETH                                        | 21804           | 25682  | 25682  | 29560  | 2       |
| resetBondCurve                                              | 23952           | 24794  | 24794  | 25637  | 2       |
| resume                                                      | 23793           | 26702  | 26702  | 29611  | 2       |
| setBondCurve                                                | 24113           | 48865  | 49856  | 49856  | 26      |
| setChargeRecipient                                          | 24066           | 26107  | 24071  | 30184  | 3       |
| setLockedBondRetentionPeriod                                | 30063           | 30063  | 30063  | 30063  | 1       |
| settleLockedBondETH                                         | 25892           | 37945  | 37945  | 49998  | 2       |
| totalBondShares                                             | 347             | 555    | 347    | 2347   | 48      |
| updateBondCurve                                             | 24443           | 37745  | 26582  | 62211  | 3       |


| src/CSEarlyAdoption.sol:CSEarlyAdoption contract |                 |       |        |       |         |
|--------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                    | min             | avg   | median | max   | # calls |
| CURVE_ID                                         | 216             | 216   | 216    | 216   | 4       |
| MODULE                                           | 205             | 205   | 205    | 205   | 1       |
| TREE_ROOT                                        | 194             | 194   | 194    | 194   | 1       |
| consume                                          | 22803           | 34367 | 25769  | 47076 | 7       |
| hashLeaf                                         | 663             | 663   | 663    | 663   | 1       |
| isConsumed                                       | 593             | 593   | 593    | 593   | 1       |
| verifyProof                                      | 1318            | 1318  | 1318   | 1318  | 2       |


| src/CSFeeDistributor.sol:CSFeeDistributor contract |                 |        |        |        |         |
|----------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                      | min             | avg    | median | max    | # calls |
| ACCOUNTING                                         | 304             | 304    | 304    | 304    | 1       |
| ORACLE                                             | 261             | 261    | 261    | 261    | 1       |
| RECOVERER_ROLE                                     | 283             | 283    | 283    | 283    | 7       |
| STETH                                              | 281             | 281    | 281    | 281    | 1       |
| distributeFees                                     | 22335           | 40735  | 27867  | 76026  | 7       |
| distributedShares                                  | 523             | 1523   | 1523   | 2523   | 4       |
| getFeesToDistribute                                | 1597            | 2597   | 2597   | 3597   | 2       |
| grantRole                                          | 118460          | 118460 | 118460 | 118460 | 5       |
| hashLeaf                                           | 688             | 688    | 688    | 688    | 1       |
| initialize                                         | 24079           | 129197 | 137454 | 137454 | 25      |
| pendingSharesToDistribute                          | 1487            | 1487   | 1487   | 1487   | 2       |
| processOracleReport                                | 22774           | 72545  | 97609  | 97633  | 19      |
| recoverERC20                                       | 24434           | 35817  | 24469  | 58549  | 3       |
| recoverEther                                       | 23758           | 41886  | 41886  | 60015  | 2       |
| totalClaimableShares                               | 362             | 362    | 362    | 362    | 1       |
| treeCid                                            | 1275            | 2147   | 2147   | 3020   | 2       |
| treeRoot                                           | 362             | 1028   | 362    | 2362   | 3       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| CONTRACT_MANAGER_ROLE                    | 262             | 262    | 262    | 262    | 13      |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 239             | 239    | 239    | 239    | 13      |
| MANAGE_CONSENSUS_VERSION_ROLE            | 328             | 328    | 328    | 328    | 13      |
| PAUSE_ROLE                               | 262             | 262    | 262    | 262    | 13      |
| RECOVERER_ROLE                           | 305             | 305    | 305    | 305    | 1       |
| RESUME_ROLE                              | 262             | 262    | 262    | 262    | 13      |
| SUBMIT_DATA_ROLE                         | 284             | 284    | 284    | 284    | 24      |
| avgPerfLeewayBP                          | 405             | 405    | 405    | 405    | 1       |
| feeDistributor                           | 448             | 448    | 448    | 448    | 1       |
| getConsensusReport                       | 1018            | 2107   | 3018   | 3018   | 24      |
| getConsensusVersion                      | 396             | 1486   | 2396   | 2396   | 11      |
| getLastProcessingRefSlot                 | 494             | 2363   | 2494   | 2494   | 46      |
| getResumeSinceTimestamp                  | 462             | 462    | 462    | 462    | 1       |
| grantRole                                | 101382          | 115437 | 118482 | 118482 | 90      |
| initialize                               | 22903           | 228335 | 244138 | 244138 | 14      |
| pauseFor                                 | 47474           | 47474  | 47474  | 47474  | 2       |
| pauseUntil                               | 26181           | 40456  | 47490  | 47697  | 3       |
| recoverEther                             | 28308           | 28308  | 28308  | 28308  | 1       |
| resume                                   | 23503           | 26621  | 26621  | 29739  | 2       |
| setFeeDistributorContract                | 24050           | 27211  | 27211  | 30372  | 2       |
| setPerformanceLeeway                     | 24017           | 27037  | 27037  | 30057  | 2       |
| submitReportData                         | 25442           | 47501  | 35464  | 75579  | 5       |


| src/CSModule.sol:CSModule contract                  |                 |        |        |         |         |
|-----------------------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                                       | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                                  | 328             | 328    | 328    | 328     | 1       |
| EL_REWARDS_STEALING_FINE                            | 306             | 306    | 306    | 306     | 20      |
| INITIAL_SLASHING_PENALTY                            | 327             | 327    | 327    | 327     | 4       |
| LIDO_LOCATOR                                        | 327             | 327    | 327    | 327     | 2       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 329             | 329    | 329    | 329     | 3       |
| MODULE_MANAGER_ROLE                                 | 306             | 306    | 306    | 306     | 341     |
| PAUSE_ROLE                                          | 285             | 285    | 285    | 285     | 299     |
| RECOVERER_ROLE                                      | 306             | 306    | 306    | 306     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 283             | 283    | 283    | 283     | 300     |
| RESUME_ROLE                                         | 330             | 330    | 330    | 330     | 335     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 351             | 351    | 351    | 351     | 300     |
| STAKING_ROUTER_ROLE                                 | 360             | 360    | 360    | 360     | 322     |
| VERIFIER_ROLE                                       | 327             | 327    | 327    | 327     | 338     |
| accounting                                          | 426             | 426    | 426    | 426     | 1       |
| activatePublicRelease                               | 23745           | 29697  | 29619  | 46719   | 311     |
| addNodeOperatorETH                                  | 26763           | 431329 | 383059 | 1059927 | 292     |
| addNodeOperatorStETH                                | 27567           | 270292 | 307744 | 399817  | 8       |
| addNodeOperatorWstETH                               | 27589           | 276348 | 314168 | 412027  | 8       |
| addValidatorKeysETH                                 | 25657           | 164751 | 217791 | 272174  | 13      |
| addValidatorKeysStETH                               | 26438           | 132740 | 117569 | 228551  | 6       |
| addValidatorKeysWstETH                              | 26416           | 138932 | 133901 | 246682  | 6       |
| cancelELRewardsStealingPenalty                      | 26343           | 65360  | 75632  | 83832   | 4       |
| claimRewardsStETH                                   | 25035           | 67699  | 68247  | 109270  | 4       |
| claimRewardsUnstETH                                 | 25058           | 55539  | 56087  | 84927   | 4       |
| claimRewardsWstETH                                  | 25057           | 97414  | 97961  | 168677  | 4       |
| cleanDepositQueue                                   | 24602           | 40694  | 40745  | 60882   | 13      |
| compensateELRewardsStealingPenalty                  | 23698           | 78730  | 94341  | 102542  | 4       |
| confirmNodeOperatorManagerAddressChange             | 27012           | 29370  | 29158  | 32365   | 5       |
| confirmNodeOperatorRewardAddressChange              | 26830           | 30860  | 32161  | 32161   | 9       |
| decreaseVettedSigningKeysCount                      | 24855           | 63174  | 78852  | 100281  | 23      |
| depositETH                                          | 23777           | 92664  | 95978  | 117489  | 14      |
| depositQueue                                        | 480             | 813    | 480    | 2480    | 6       |
| depositQueueItem                                    | 645             | 1311   | 645    | 2645    | 12      |
| depositStETH                                        | 24703           | 94545  | 106534 | 128039  | 5       |
| depositWstETH                                       | 24729           | 93398  | 100630 | 123170  | 5       |
| earlyAdoption                                       | 450             | 450    | 450    | 450     | 1       |
| getActiveNodeOperatorsCount                         | 460             | 460    | 460    | 460     | 2       |
| getNodeOperator                                     | 2469            | 5564   | 6469   | 12469   | 73      |
| getNodeOperatorIds                                  | 769             | 1225   | 1174   | 1926    | 8       |
| getNodeOperatorIsActive                             | 537             | 537    | 537    | 537     | 1       |
| getNodeOperatorNonWithdrawnKeys                     | 614             | 718    | 614    | 2614    | 555     |
| getNodeOperatorSummary                              | 6074            | 6200   | 6137   | 6358    | 24      |
| getNodeOperatorsCount                               | 416             | 416    | 416    | 416     | 279     |
| getNonce                                            | 425             | 578    | 425    | 2425    | 78      |
| getResumeSinceTimestamp                             | 419             | 419    | 419    | 419     | 1       |
| getSigningKeys                                      | 714             | 2790   | 3134   | 3525    | 8       |
| getSigningKeysWithSignatures                        | 716             | 3157   | 2957   | 5998    | 4       |
| getStakingModuleSummary                             | 497             | 497    | 497    | 497     | 20      |
| getType                                             | 316             | 316    | 316    | 316     | 2       |
| grantRole                                           | 27012           | 116005 | 118482 | 118482  | 2219    |
| hasRole                                             | 783             | 783    | 783    | 783     | 2       |
| initialize                                          | 25099           | 323727 | 326516 | 326516  | 339     |
| isPaused                                            | 417             | 702    | 417    | 2417    | 7       |
| isValidatorSlashed                                  | 629             | 629    | 629    | 629     | 1       |
| isValidatorWithdrawn                                | 662             | 662    | 662    | 662     | 1       |
| keyRemovalCharge                                    | 383             | 1049   | 383    | 2383    | 3       |
| normalizeQueue                                      | 29509           | 45533  | 45533  | 61557   | 2       |
| obtainDepositData                                   | 24584           | 78416  | 70083  | 143227  | 67      |
| onExitedAndStuckValidatorsCountsUpdated             | 23705           | 23741  | 23741  | 23777   | 2       |
| onRewardsMinted                                     | 24005           | 42108  | 39792  | 62528   | 3       |
| onWithdrawalCredentialsChanged                      | 23779           | 24593  | 25001  | 25001   | 3       |
| pauseFor                                            | 24029           | 29630  | 30432  | 30648   | 13      |
| proposeNodeOperatorManagerAddressChange             | 27485           | 41827  | 52039  | 52039   | 11      |
| proposeNodeOperatorRewardAddressChange              | 27546           | 44581  | 52066  | 52066   | 15      |
| publicRelease                                       | 426             | 426    | 426    | 426     | 1       |
| recoverERC20                                        | 58549           | 58549  | 58549  | 58549   | 1       |
| recoverEther                                        | 23781           | 26059  | 26059  | 28338   | 2       |
| recoverStETHShares                                  | 55664           | 55664  | 55664  | 55664   | 1       |
| removeKeys                                          | 24078           | 117478 | 142038 | 216381  | 17      |
| reportELRewardsStealingPenalty                      | 24302           | 93351  | 102512 | 103373  | 37      |
| resetNodeOperatorManagerAddress                     | 26951           | 31027  | 29385  | 36734   | 5       |
| resume                                              | 23748           | 29549  | 29567  | 29567   | 336     |
| revokeRole                                          | 40217           | 40217  | 40217  | 40217   | 1       |
| setKeyRemovalCharge                                 | 24022           | 27226  | 27235  | 30047   | 301     |
| settleELRewardsStealingPenalty                      | 24521           | 79185  | 92426  | 118488  | 23      |
| submitInitialSlashing                               | 24121           | 83371  | 111468 | 127537  | 14      |
| submitWithdrawal                                    | 24324           | 90396  | 105482 | 140468  | 17      |
| unsafeUpdateValidatorsCount                         | 24304           | 44282  | 39282  | 83149   | 12      |
| updateExitedValidatorsCount                         | 24909           | 41188  | 48230  | 57983   | 11      |
| updateRefundedValidatorsCount                       | 24101           | 24115  | 24113  | 24133   | 3       |
| updateStuckValidatorsCount                          | 24866           | 53885  | 50016  | 81046   | 14      |
| updateTargetValidatorsLimits                        | 24307           | 71912  | 71877  | 116302  | 43      |


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
| processHistoricalWithdrawalProof       | 73146           | 88631 | 80221  | 136047 | 5       |
| processSlashingProof                   | 48722           | 61798 | 55564  | 81110  | 3       |
| processWithdrawalProof                 | 56367           | 72758 | 69690  | 103049 | 9       |


| src/lib/AssetRecovererLib.sol:AssetRecovererLib contract |                 |       |        |       |         |
|----------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                            | min             | avg   | median | max   | # calls |
| recoverERC1155                                           | 38601           | 38601 | 38601  | 38601 | 1       |
| recoverERC20                                             | 36019           | 36019 | 36019  | 36019 | 4       |
| recoverERC721                                            | 43302           | 43302 | 43302  | 43302 | 1       |
| recoverEther                                             | 1793            | 17643 | 17643  | 33493 | 6       |




