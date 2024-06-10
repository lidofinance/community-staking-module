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
| addBondCurve                                                | 24641           | 101770 | 99205  | 306480 | 349     |
| chargeFee                                                   | 21788           | 48153  | 48153  | 74519  | 2       |
| chargeRecipient                                             | 469             | 469    | 469    | 469    | 1       |
| claimRewardsStETH                                           | 25343           | 79780  | 91614  | 101465 | 16      |
| claimRewardsUnstETH                                         | 25323           | 64517  | 67226  | 77055  | 16      |
| claimRewardsWstETH                                          | 25389           | 115380 | 153528 | 157933 | 16      |
| compensateLockedBondETH                                     | 47451           | 47451  | 47451  | 47451  | 1       |
| depositETH                                                  | 24181           | 111188 | 113136 | 113376 | 108     |
| depositStETH                                                | 25216           | 85475  | 103881 | 107800 | 8       |
| depositWstETH                                               | 25147           | 94391  | 120871 | 124580 | 7       |
| feeDistributor                                              | 448             | 1781   | 2448   | 2448   | 3       |
| getActualLockedBond                                         | 675             | 747    | 772    | 772    | 8       |
| getBondAmountByKeysCount                                    | 1152            | 1392   | 1309   | 1566   | 286     |
| getBondAmountByKeysCountWstETH(uint256,(uint256[],uint256)) | 3325            | 11275  | 14255  | 14255  | 11      |
| getBondAmountByKeysCountWstETH(uint256,uint256)             | 3671            | 8510   | 3928   | 22514  | 4       |
| getBondCurve                                                | 1968            | 11813  | 11968  | 11968  | 297     |
| getBondCurveId                                              | 493             | 493    | 493    | 493    | 2       |
| getBondLockRetentionPeriod                                  | 401             | 1734   | 2401   | 2401   | 3       |
| getBondShares                                               | 527             | 621    | 527    | 2527   | 106     |
| getBondSummary                                              | 13106           | 18489  | 16356  | 24856  | 12      |
| getBondSummaryShares                                        | 13100           | 18483  | 16350  | 24850  | 12      |
| getCurveInfo                                                | 1669            | 1833   | 1916   | 1916   | 3       |
| getLockedBondInfo                                           | 817             | 817    | 817    | 817    | 12      |
| getRequiredBondForNextKeys                                  | 6958            | 20459  | 19050  | 31764  | 45      |
| getRequiredBondForNextKeysWstETH                            | 22334           | 29500  | 25505  | 36141  | 20      |
| getUnbondedKeysCount                                        | 2617            | 12088  | 7141   | 25891  | 486     |
| getUnbondedKeysCountToEject                                 | 4304            | 7413   | 4886   | 14162  | 36      |
| grantRole                                                   | 29570           | 100120 | 118658 | 118658 | 1547    |
| initialize                                                  | 26261           | 491817 | 494094 | 494094 | 513     |
| isPaused                                                    | 438             | 838    | 438    | 2438   | 5       |
| lockBondETH                                                 | 21782           | 68459  | 70251  | 70275  | 27      |
| pauseFor                                                    | 24043           | 45429  | 47568  | 47568  | 11      |
| penalize                                                    | 21788           | 37965  | 37965  | 54143  | 2       |
| recoverERC20                                                | 24589           | 35965  | 24596  | 58711  | 3       |
| recoverEther                                                | 23839           | 37415  | 28354  | 60054  | 3       |
| recoverStETHShares                                          | 23817           | 43252  | 43252  | 62688  | 2       |
| releaseLockedBondETH                                        | 21804           | 26688  | 26688  | 31573  | 2       |
| resetBondCurve                                              | 24032           | 24868  | 24868  | 25705  | 2       |
| resume                                                      | 23873           | 26793  | 26793  | 29714  | 2       |
| setBondCurve                                                | 24193           | 49004  | 49997  | 49997  | 26      |
| setChargeRecipient                                          | 24105           | 26160  | 24151  | 30224  | 3       |
| setLockedBondRetentionPeriod                                | 30160           | 30160  | 30160  | 30160  | 1       |
| settleLockedBondETH                                         | 50863           | 50863  | 50863  | 50863  | 1       |
| totalBondShares                                             | 379             | 490    | 379    | 2379   | 54      |
| updateBondCurve                                             | 24729           | 38217  | 26926  | 62996  | 3       |


| src/CSEarlyAdoption.sol:CSEarlyAdoption contract |                 |       |        |       |         |
|--------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                    | min             | avg   | median | max   | # calls |
| CURVE_ID                                         | 216             | 216   | 216    | 216   | 4       |
| MODULE                                           | 205             | 205   | 205    | 205   | 1       |
| TREE_ROOT                                        | 194             | 194   | 194    | 194   | 1       |
| consume                                          | 22803           | 34376 | 25781  | 47088 | 7       |
| isConsumed                                       | 593             | 593   | 593    | 593   | 1       |
| verifyProof                                      | 1330            | 1330  | 1330   | 1330  | 2       |


| src/CSFeeDistributor.sol:CSFeeDistributor contract |                 |        |        |        |         |
|----------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                      | min             | avg    | median | max    | # calls |
| ACCOUNTING                                         | 326             | 326    | 326    | 326    | 1       |
| RECOVERER_ROLE                                     | 305             | 305    | 305    | 305    | 7       |
| STETH                                              | 281             | 281    | 281    | 281    | 1       |
| distributeFees                                     | 22334           | 42546  | 27829  | 76044  | 6       |
| distributedShares                                  | 523             | 1523   | 1523   | 2523   | 4       |
| getFeesToDistribute                                | 1631            | 2631   | 2631   | 3631   | 2       |
| grantRole                                          | 118703          | 118703 | 118703 | 118703 | 5       |
| hashLeaf                                           | 635             | 635    | 635    | 635    | 1       |
| initialize                                         | 24600           | 205839 | 229791 | 229791 | 24      |
| pendingSharesToDistribute                          | 1487            | 1487   | 1487   | 1487   | 2       |
| processOracleReport                                | 32222           | 76308  | 99920  | 99944  | 17      |
| recoverERC20                                       | 24495           | 35882  | 24530  | 58622  | 3       |
| recoverEther                                       | 23752           | 41880  | 41880  | 60009  | 2       |
| totalClaimableShares                               | 362             | 362    | 362    | 362    | 1       |
| treeCid                                            | 1275            | 2147   | 2147   | 3020   | 2       |
| treeRoot                                           | 361             | 1027   | 361    | 2361   | 3       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| CONTRACT_MANAGER_ROLE                    | 239             | 239    | 239    | 239    | 10      |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 239             | 239    | 239    | 239    | 10      |
| MANAGE_CONSENSUS_VERSION_ROLE            | 328             | 328    | 328    | 328    | 10      |
| PAUSE_ROLE                               | 262             | 262    | 262    | 262    | 10      |
| RESUME_ROLE                              | 262             | 262    | 262    | 262    | 10      |
| SUBMIT_DATA_ROLE                         | 284             | 284    | 284    | 284    | 18      |
| avgPerfLeewayBP                          | 382             | 382    | 382    | 382    | 1       |
| feeDistributor                           | 448             | 448    | 448    | 448    | 1       |
| getConsensusReport                       | 1019            | 1982   | 1057   | 3019   | 21      |
| getConsensusVersion                      | 405             | 1495   | 2405   | 2405   | 11      |
| getLastProcessingRefSlot                 | 494             | 2331   | 2494   | 2494   | 37      |
| grantRole                                | 101559          | 115639 | 118659 | 118659 | 68      |
| initialize                               | 22947           | 224317 | 244454 | 244454 | 11      |
| pauseFor                                 | 47621           | 47621  | 47621  | 47621  | 2       |
| pauseUntil                               | 47637           | 47637  | 47637  | 47637  | 1       |
| resume                                   | 23535           | 26704  | 26704  | 29874  | 2       |
| setFeeDistributorContract                | 24066           | 27233  | 27233  | 30400  | 2       |
| setPerformanceLeeway                     | 24100           | 27120  | 27120  | 30140  | 2       |
| submitReportData                         | 25486           | 45488  | 35680  | 70394  | 5       |


| src/CSModule.sol:CSModule contract                  |                 |        |        |         |         |
|-----------------------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                                       | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                                  | 305             | 305    | 305    | 305     | 1       |
| EL_REWARDS_STEALING_FINE                            | 306             | 306    | 306    | 306     | 24      |
| INITIAL_SLASHING_PENALTY                            | 371             | 371    | 371    | 371     | 4       |
| LIDO_LOCATOR                                        | 304             | 304    | 304    | 304     | 2       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 306             | 306    | 306    | 306     | 3       |
| MODULE_MANAGER_ROLE                                 | 283             | 283    | 283    | 283     | 329     |
| PAUSE_ROLE                                          | 285             | 285    | 285    | 285     | 287     |
| RECOVERER_ROLE                                      | 283             | 283    | 283    | 283     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 327             | 327    | 327    | 327     | 288     |
| RESUME_ROLE                                         | 307             | 307    | 307    | 307     | 323     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 351             | 351    | 351    | 351     | 288     |
| STAKING_ROUTER_ROLE                                 | 404             | 404    | 404    | 404     | 310     |
| VERIFIER_ROLE                                       | 371             | 371    | 371    | 371     | 326     |
| accounting                                          | 470             | 470    | 470    | 470     | 1       |
| activatePublicRelease                               | 23828           | 29670  | 29702  | 29702   | 303     |
| addNodeOperatorETH                                  | 26839           | 435141 | 382968 | 1060470 | 281     |
| addNodeOperatorStETH                                | 27643           | 250619 | 280859 | 375529  | 8       |
| addNodeOperatorWstETH                               | 27665           | 273806 | 312038 | 396201  | 8       |
| addValidatorKeysETH                                 | 25733           | 167083 | 219717 | 274654  | 13      |
| addValidatorKeysStETH                               | 26447           | 116796 | 93080  | 207388  | 6       |
| addValidatorKeysWstETH                              | 26425           | 137166 | 136650 | 226215  | 6       |
| cancelELRewardsStealingPenalty                      | 26355           | 65568  | 76395  | 83128   | 4       |
| claimRewardsStETH                                   | 25180           | 48557  | 49104  | 70840   | 4       |
| claimRewardsUnstETH                                 | 25226           | 48593  | 49140  | 70866   | 4       |
| claimRewardsWstETH                                  | 25269           | 48121  | 48669  | 69880   | 4       |
| cleanDepositQueue                                   | 24678           | 40965  | 40928  | 61619   | 13      |
| compensateELRewardsStealingPenalty                  | 23738           | 78949  | 95109  | 101843  | 4       |
| confirmNodeOperatorManagerAddressChange             | 26989           | 29351  | 29135  | 32363   | 5       |
| confirmNodeOperatorRewardAddressChange              | 26830           | 30860  | 32161  | 32161   | 9       |
| decreaseVettedSigningKeysCount                      | 24894           | 63825  | 77742  | 98022   | 22      |
| depositETH                                          | 23773           | 90685  | 96480  | 118527  | 8       |
| depositQueue                                        | 524             | 857    | 524    | 2524    | 6       |
| depositQueueItem                                    | 689             | 1355   | 689    | 2689    | 12      |
| depositStETH                                        | 24743           | 74130  | 79809  | 101850  | 5       |
| depositWstETH                                       | 24702           | 90020  | 100988 | 118775  | 5       |
| earlyAdoption                                       | 427             | 427    | 427    | 427     | 1       |
| getActiveNodeOperatorsCount                         | 437             | 437    | 437    | 437     | 2       |
| getNodeOperator                                     | 2452            | 5547   | 6452   | 12452   | 73      |
| getNodeOperatorIds                                  | 813             | 1269   | 1218   | 1970    | 8       |
| getNodeOperatorIsActive                             | 581             | 581    | 581    | 581     | 1       |
| getNodeOperatorNonWithdrawnKeys                     | 724             | 831    | 724    | 2724    | 539     |
| getNodeOperatorSummary                              | 6510            | 6816   | 6753   | 7009    | 24      |
| getNodeOperatorsCount                               | 393             | 393    | 393    | 393     | 274     |
| getNonce                                            | 402             | 555    | 402    | 2402    | 78      |
| getSigningKeys                                      | 670             | 2734   | 3075   | 3466    | 8       |
| getSigningKeysWithSignatures                        | 742             | 3175   | 2975   | 6009    | 4       |
| getStakingModuleSummary                             | 541             | 541    | 541    | 541     | 20      |
| getType                                             | 316             | 316    | 316    | 316     | 2       |
| grantRole                                           | 27125           | 116225 | 118703 | 118703  | 2135    |
| hasRole                                             | 772             | 772    | 772    | 772     | 2       |
| initialize                                          | 25099           | 324216 | 326864 | 326864  | 327     |
| isPaused                                            | 493             | 826    | 493    | 2493    | 6       |
| isValidatorSlashed                                  | 629             | 629    | 629    | 629     | 1       |
| isValidatorWithdrawn                                | 662             | 662    | 662    | 662     | 1       |
| keyRemovalCharge                                    | 360             | 1026   | 360    | 2360    | 3       |
| normalizeQueue                                      | 29486           | 45531  | 45531  | 61576   | 2       |
| obtainDepositData                                   | 24623           | 76454  | 68680  | 140388  | 66      |
| onExitedAndStuckValidatorsCountsUpdated             | 23721           | 23757  | 23757  | 23793   | 2       |
| onRewardsMinted                                     | 24044           | 42147  | 39831  | 62567   | 3       |
| onWithdrawalCredentialsChanged                      | 23795           | 24609  | 25017  | 25017   | 3       |
| pauseFor                                            | 24045           | 29924  | 30512  | 30512   | 11      |
| proposeNodeOperatorManagerAddressChange             | 27485           | 41827  | 52039  | 52039   | 11      |
| proposeNodeOperatorRewardAddressChange              | 27546           | 44581  | 52066  | 52066   | 15      |
| publicRelease                                       | 470             | 470    | 470    | 470     | 1       |
| recoverERC20                                        | 58644           | 58644  | 58644  | 58644   | 1       |
| recoverEther                                        | 23820           | 26098  | 26098  | 28377   | 2       |
| recoverStETHShares                                  | 55680           | 55680  | 55680  | 55680   | 1       |
| removeKeys                                          | 24078           | 117314 | 141782 | 216359  | 17      |
| reportELRewardsStealingPenalty                      | 24341           | 112900 | 123251 | 124382  | 36      |
| resetNodeOperatorManagerAddress                     | 26928           | 31012  | 29362  | 36732   | 5       |
| resume                                              | 23787           | 29651  | 29670  | 29670   | 324     |
| revokeRole                                          | 40394           | 40394  | 40394  | 40394   | 1       |
| setKeyRemovalCharge                                 | 24061           | 27265  | 27274  | 30086   | 289     |
| settleELRewardsStealingPenalty                      | 24850           | 78635  | 92317  | 119628  | 22      |
| submitInitialSlashing                               | 24204           | 82742  | 110444 | 125277  | 14      |
| submitWithdrawal                                    | 24363           | 89856  | 104504 | 139629  | 17      |
| unsafeUpdateValidatorsCount                         | 24320           | 44279  | 39338  | 83690   | 12      |
| updateExitedValidatorsCount                         | 24992           | 41269  | 48311  | 58062   | 11      |
| updateRefundedValidatorsCount                       | 24184           | 24198  | 24196  | 24216   | 3       |
| updateStuckValidatorsCount                          | 24882           | 53508  | 48692  | 80157   | 14      |
| updateTargetValidatorsLimits                        | 24346           | 73966  | 72376  | 115411  | 41      |


| src/CSVerifier.sol:CSVerifier contract |                 |       |        |        |         |
|----------------------------------------|-----------------|-------|--------|--------|---------|
| Function Name                          | min             | avg   | median | max    | # calls |
| BEACON_ROOTS                           | 293             | 293   | 293    | 293    | 21      |
| FIRST_SUPPORTED_SLOT                   | 259             | 259   | 259    | 259    | 5       |
| GI_FIRST_VALIDATOR                     | 217             | 217   | 217    | 217    | 1       |
| GI_FIRST_WITHDRAWAL                    | 216             | 216   | 216    | 216    | 1       |
| GI_HISTORICAL_SUMMARIES                | 261             | 261   | 261    | 261    | 1       |
| LOCATOR                                | 204             | 204   | 204    | 204    | 1       |
| MODULE                                 | 205             | 205   | 205    | 205    | 1       |
| SLOTS_PER_EPOCH                        | 303             | 303   | 303    | 303    | 1       |
| processHistoricalWithdrawalProof       | 73190           | 88723 | 80271  | 136302 | 5       |
| processSlashingProof                   | 48766           | 61855 | 55614  | 81187  | 3       |
| processWithdrawalProof                 | 56367           | 72832 | 69793  | 103227 | 9       |


| src/lib/AssetRecovererLib.sol:AssetRecovererLib contract |                 |       |        |       |         |
|----------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                            | min             | avg   | median | max   | # calls |
| recoverERC1155                                           | 38601           | 38601 | 38601  | 38601 | 1       |
| recoverERC20                                             | 36031           | 36031 | 36031  | 36031 | 4       |
| recoverERC721                                            | 43326           | 43326 | 43326  | 43326 | 1       |
| recoverEther                                             | 1793            | 20813 | 33493  | 33493 | 5       |




