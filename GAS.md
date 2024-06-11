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
| addBondCurve                                                | 24358           | 101566 | 99009  | 305681 | 349     |
| chargeFee                                                   | 21803           | 48240  | 48240  | 74678  | 2       |
| chargeRecipient                                             | 469             | 469    | 469    | 469    | 1       |
| claimRewardsStETH                                           | 25075           | 79647  | 91515  | 101365 | 16      |
| claimRewardsUnstETH                                         | 25055           | 64439  | 67194  | 77044  | 16      |
| claimRewardsWstETH                                          | 25121           | 115196 | 153348 | 157753 | 16      |
| compensateLockedBondETH                                     | 47773           | 47773  | 47773  | 47773  | 1       |
| depositETH                                                  | 24149           | 111343 | 113294 | 113534 | 108     |
| depositStETH                                                | 25184           | 85578  | 104042 | 107961 | 8       |
| depositWstETH                                               | 25115           | 94469  | 121008 | 124648 | 7       |
| feeDistributor                                              | 448             | 1781   | 2448   | 2448   | 3       |
| getActualLockedBond                                         | 675             | 747    | 772    | 772    | 8       |
| getBondAmountByKeysCount                                    | 1153            | 1393   | 1310   | 1567   | 286     |
| getBondAmountByKeysCountWstETH(uint256,(uint256[],uint256)) | 3288            | 11234  | 14212  | 14212  | 11      |
| getBondAmountByKeysCountWstETH(uint256,uint256)             | 3595            | 8434   | 3852   | 22438  | 4       |
| getBondCurve                                                | 1936            | 11781  | 11936  | 11936  | 297     |
| getBondCurveId                                              | 493             | 493    | 493    | 493    | 2       |
| getBondLockRetentionPeriod                                  | 401             | 1734   | 2401   | 2401   | 3       |
| getBondShares                                               | 547             | 641    | 547    | 2547   | 106     |
| getBondSummary                                              | 13077           | 18460  | 16327  | 24827  | 12      |
| getBondSummaryShares                                        | 13063           | 18446  | 16313  | 24813  | 12      |
| getCurveInfo                                                | 1637            | 1801   | 1884   | 1884   | 3       |
| getLockedBondInfo                                           | 817             | 817    | 817    | 817    | 12      |
| getRequiredBondForNextKeys                                  | 6891            | 20393  | 18989  | 31697  | 45      |
| getRequiredBondForNextKeysWstETH                            | 22229           | 29390  | 25371  | 36030  | 20      |
| getUnbondedKeysCount                                        | 2637            | 12070  | 7123   | 25873  | 486     |
| getUnbondedKeysCountToEject                                 | 4292            | 7397   | 4868   | 14150  | 36      |
| grantRole                                                   | 29393           | 99943  | 118481 | 118481 | 1547    |
| initialize                                                  | 25980           | 491344 | 493619 | 493619 | 513     |
| isPaused                                                    | 406             | 806    | 406    | 2406   | 5       |
| lockBondETH                                                 | 21797           | 68666  | 70465  | 70489  | 27      |
| pauseFor                                                    | 23962           | 45397  | 47541  | 47541  | 11      |
| penalize                                                    | 21803           | 38023  | 38023  | 54244  | 2       |
| recoverERC20                                                | 24515           | 35926  | 24550  | 58715  | 3       |
| recoverEther                                                | 23758           | 37422  | 28405  | 60105  | 3       |
| recoverStETHShares                                          | 23736           | 43198  | 43198  | 62660  | 2       |
| releaseLockedBondETH                                        | 21819           | 26803  | 26803  | 31787  | 2       |
| resetBondCurve                                              | 23951           | 24835  | 24835  | 25719  | 2       |
| resume                                                      | 23792           | 26701  | 26701  | 29611  | 2       |
| setBondCurve                                                | 24112           | 48998  | 49994  | 49994  | 26      |
| setChargeRecipient                                          | 24066           | 26131  | 24070  | 30257  | 3       |
| setLockedBondRetentionPeriod                                | 30212           | 30212  | 30212  | 30212  | 1       |
| settleLockedBondETH                                         | 51145           | 51145  | 51145  | 51145  | 1       |
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
| distributeFees                                     | 22305           | 42538  | 27793  | 76090  | 6       |
| distributedShares                                  | 523             | 1523   | 1523   | 2523   | 4       |
| getFeesToDistribute                                | 1619            | 2619   | 2619   | 3619   | 2       |
| grantRole                                          | 118482          | 118482 | 118482 | 118482 | 5       |
| hashLeaf                                           | 623             | 623    | 623    | 623    | 1       |
| initialize                                         | 24594           | 205622 | 229545 | 229545 | 24      |
| pendingSharesToDistribute                          | 1487            | 1487   | 1487   | 1487   | 2       |
| processOracleReport                                | 32183           | 76331  | 99977  | 100001 | 17      |
| recoverERC20                                       | 24456           | 35867  | 24491  | 58656  | 3       |
| recoverEther                                       | 23713           | 41886  | 41886  | 60060  | 2       |
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
| initialize                               | 22903           | 224257 | 244393 | 244393 | 11      |
| pauseFor                                 | 47550           | 47550  | 47550  | 47550  | 2       |
| pauseUntil                               | 47566           | 47566  | 47566  | 47566  | 1       |
| resume                                   | 23503           | 26621  | 26621  | 29739  | 2       |
| setFeeDistributorContract                | 24050           | 27252  | 27252  | 30454  | 2       |
| setPerformanceLeeway                     | 24017           | 27076  | 27076  | 30136  | 2       |
| submitReportData                         | 25442           | 47540  | 35464  | 75678  | 5       |


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
| addNodeOperatorETH                                  | 26763           | 435311 | 383145 | 1060647 | 281     |
| addNodeOperatorStETH                                | 27567           | 250655 | 280926 | 375653  | 8       |
| addNodeOperatorWstETH                               | 27589           | 273783 | 312003 | 396308  | 8       |
| addValidatorKeysETH                                 | 25657           | 167208 | 219947 | 274884  | 13      |
| addValidatorKeysStETH                               | 26438           | 116925 | 93160  | 207632  | 6       |
| addValidatorKeysWstETH                              | 26416           | 137211 | 136662 | 226373  | 6       |
| cancelELRewardsStealingPenalty                      | 26339           | 65754  | 76651  | 83375   | 4       |
| claimRewardsStETH                                   | 25035           | 48315  | 48863  | 70502   | 4       |
| claimRewardsUnstETH                                 | 25058           | 48328  | 48876  | 70505   | 4       |
| claimRewardsWstETH                                  | 25057           | 47813  | 48360  | 69475   | 4       |
| cleanDepositQueue                                   | 24634           | 40912  | 40872  | 61551   | 13      |
| compensateELRewardsStealingPenalty                  | 23694           | 79126  | 95361  | 102088  | 4       |
| confirmNodeOperatorManagerAddressChange             | 27012           | 29370  | 29158  | 32365   | 5       |
| confirmNodeOperatorRewardAddressChange              | 26830           | 30860  | 32161  | 32161   | 9       |
| decreaseVettedSigningKeysCount                      | 24855           | 63847  | 77782  | 98141   | 22      |
| depositETH                                          | 23773           | 90808  | 96620  | 118667  | 8       |
| depositQueue                                        | 480             | 813    | 480    | 2480    | 6       |
| depositQueueItem                                    | 645             | 1311   | 645    | 2645    | 12      |
| depositStETH                                        | 24699           | 74186  | 79903  | 101944  | 5       |
| depositWstETH                                       | 24725           | 90107  | 101097 | 118912  | 5       |
| earlyAdoption                                       | 450             | 450    | 450    | 450     | 1       |
| getActiveNodeOperatorsCount                         | 460             | 460    | 460    | 460     | 2       |
| getNodeOperator                                     | 2469            | 5564   | 6469   | 12469   | 73      |
| getNodeOperatorIds                                  | 769             | 1226   | 1175   | 1925    | 8       |
| getNodeOperatorIsActive                             | 537             | 537    | 537    | 537     | 1       |
| getNodeOperatorNonWithdrawnKeys                     | 718             | 825    | 718    | 2718    | 539     |
| getNodeOperatorSummary                              | 6449            | 6677   | 6559   | 6938    | 24      |
| getNodeOperatorsCount                               | 416             | 416    | 416    | 416     | 274     |
| getNonce                                            | 425             | 578    | 425    | 2425    | 78      |
| getSigningKeys                                      | 693             | 2757   | 3098   | 3489    | 8       |
| getSigningKeysWithSignatures                        | 698             | 3131   | 2931   | 5965    | 4       |
| getStakingModuleSummary                             | 497             | 497    | 497    | 497     | 20      |
| getType                                             | 316             | 316    | 316    | 316     | 2       |
| grantRole                                           | 27012           | 116004 | 118482 | 118482  | 2135    |
| hasRole                                             | 783             | 783    | 783    | 783     | 2       |
| initialize                                          | 25099           | 324045 | 326692 | 326692  | 327     |
| isPaused                                            | 417             | 750    | 417    | 2417    | 6       |
| isValidatorSlashed                                  | 629             | 629    | 629    | 629     | 1       |
| isValidatorWithdrawn                                | 662             | 662    | 662    | 662     | 1       |
| keyRemovalCharge                                    | 383             | 1049   | 383    | 2383    | 3       |
| normalizeQueue                                      | 29509           | 45576  | 45576  | 61644   | 2       |
| obtainDepositData                                   | 24584           | 76503  | 68732  | 140525  | 66      |
| onExitedAndStuckValidatorsCountsUpdated             | 23705           | 23741  | 23741  | 23777   | 2       |
| onRewardsMinted                                     | 24005           | 42108  | 39792  | 62528   | 3       |
| onWithdrawalCredentialsChanged                      | 23779           | 24650  | 25086  | 25086   | 3       |
| pauseFor                                            | 24029           | 29919  | 30508  | 30508   | 11      |
| proposeNodeOperatorManagerAddressChange             | 27485           | 41827  | 52039  | 52039   | 11      |
| proposeNodeOperatorRewardAddressChange              | 27546           | 44581  | 52066  | 52066   | 15      |
| publicRelease                                       | 426             | 426    | 426    | 426     | 1       |
| recoverERC20                                        | 58634           | 58634  | 58634  | 58634   | 1       |
| recoverEther                                        | 23781           | 26104  | 26104  | 28428   | 2       |
| recoverStETHShares                                  | 55749           | 55749  | 55749  | 55749   | 1       |
| removeKeys                                          | 24078           | 117577 | 142202 | 216695  | 17      |
| reportELRewardsStealingPenalty                      | 24302           | 113157 | 123524 | 124649  | 36      |
| resetNodeOperatorManagerAddress                     | 26951           | 31027  | 29385  | 36734   | 5       |
| resume                                              | 23748           | 29549  | 29567  | 29567   | 324     |
| revokeRole                                          | 40217           | 40217  | 40217  | 40217   | 1       |
| setKeyRemovalCharge                                 | 24022           | 27311  | 27320  | 30132   | 289     |
| settleELRewardsStealingPenalty                      | 24521           | 78655  | 92356  | 119954  | 22      |
| submitInitialSlashing                               | 24121           | 82762  | 110518 | 125351  | 14      |
| submitWithdrawal                                    | 24324           | 89969  | 104714 | 139777  | 17      |
| unsafeUpdateValidatorsCount                         | 24304           | 44323  | 39371  | 83844   | 12      |
| updateExitedValidatorsCount                         | 24909           | 41238  | 48325  | 58173   | 11      |
| updateRefundedValidatorsCount                       | 24101           | 24115  | 24113  | 24133   | 3       |
| updateStuckValidatorsCount                          | 24866           | 53544  | 48767  | 80214   | 14      |
| updateTargetValidatorsLimits                        | 24307           | 74093  | 72518  | 115598  | 41      |


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
| processHistoricalWithdrawalProof       | 73146           | 88655 | 80221  | 136165 | 5       |
| processSlashingProof                   | 48722           | 61798 | 55564  | 81110  | 3       |
| processWithdrawalProof                 | 56367           | 72818 | 69792  | 103166 | 9       |


| src/lib/AssetRecovererLib.sol:AssetRecovererLib contract |                 |       |        |       |         |
|----------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                            | min             | avg   | median | max   | # calls |
| recoverERC1155                                           | 38732           | 38732 | 38732  | 38732 | 1       |
| recoverERC20                                             | 36104           | 36104 | 36104  | 36104 | 4       |
| recoverERC721                                            | 43398           | 43398 | 43398  | 43398 | 1       |
| recoverEther                                             | 1883            | 20903 | 33583  | 33583 | 5       |




