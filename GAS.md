| src/CSAccounting.sol:CSAccounting contract                  |                 |        |        |        |         |
|-------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                               | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                     | 296             | 296    | 296    | 296    | 187     |
| CSM                                                         | 306             | 306    | 306    | 306    | 1       |
| MANAGE_BOND_CURVES_ROLE                                     | 337             | 337    | 337    | 337    | 796     |
| MIN_BOND_LOCK_RETENTION_PERIOD                              | 317             | 317    | 317    | 317    | 1       |
| PAUSE_ROLE                                                  | 339             | 339    | 339    | 339    | 187     |
| RECOVERER_ROLE                                              | 295             | 295    | 295    | 295    | 12      |
| RESET_BOND_CURVE_ROLE                                       | 274             | 274    | 274    | 274    | 1       |
| RESUME_ROLE                                                 | 251             | 251    | 251    | 251    | 187     |
| SET_BOND_CURVE_ROLE                                         | 252             | 252    | 252    | 252    | 187     |
| addBondCurve                                                | 24663           | 101792 | 99227  | 306502 | 349     |
| chargeFee                                                   | 21810           | 48175  | 48175  | 74541  | 2       |
| chargeRecipient                                             | 491             | 491    | 491    | 491    | 1       |
| claimRewardsStETH                                           | 25343           | 79780  | 91614  | 101465 | 16      |
| claimRewardsUnstETH                                         | 25323           | 64517  | 67226  | 77055  | 16      |
| claimRewardsWstETH                                          | 25300           | 115332 | 153505 | 157910 | 16      |
| compensateLockedBondETH                                     | 47582           | 47582  | 47582  | 47582  | 1       |
| depositETH                                                  | 24203           | 111210 | 113158 | 113398 | 108     |
| depositStETH                                                | 25127           | 85386  | 103792 | 107711 | 8       |
| depositWstETH                                               | 25147           | 94438  | 120937 | 124646 | 7       |
| feeDistributor                                              | 448             | 1781   | 2448   | 2448   | 3       |
| getActualLockedBond                                         | 653             | 725    | 750    | 750    | 8       |
| getBondAmountByKeysCount                                    | 1152            | 1392   | 1309   | 1566   | 286     |
| getBondAmountByKeysCountWstETH(uint256,(uint256[],uint256)) | 3325            | 11275  | 14255  | 14255  | 11      |
| getBondAmountByKeysCountWstETH(uint256,uint256)             | 3671            | 8510   | 3928   | 22514  | 4       |
| getBondCurve                                                | 1968            | 11813  | 11968  | 11968  | 297     |
| getBondCurveId                                              | 493             | 493    | 493    | 493    | 2       |
| getBondLockRetentionPeriod                                  | 379             | 1712   | 2379   | 2379   | 3       |
| getBondShares                                               | 527             | 621    | 527    | 2527   | 106     |
| getBondSummary                                              | 13106           | 18489  | 16356  | 24856  | 12      |
| getBondSummaryShares                                        | 13100           | 18483  | 16350  | 24850  | 12      |
| getCurveInfo                                                | 1691            | 1855   | 1938   | 1938   | 3       |
| getLockedBondInfo                                           | 839             | 839    | 839    | 839    | 12      |
| getRequiredBondForNextKeys                                  | 6942            | 20435  | 18989  | 31748  | 45      |
| getRequiredBondForNextKeysWstETH                            | 22407           | 29554  | 25519  | 36214  | 20      |
| getUnbondedKeysCount                                        | 2617            | 12173  | 7217   | 25967  | 486     |
| getUnbondedKeysCountToEject                                 | 4374            | 7452   | 4945   | 14221  | 36      |
| grantRole                                                   | 29592           | 100142 | 118680 | 118680 | 1547    |
| initialize                                                  | 26261           | 491817 | 494094 | 494094 | 513     |
| isPaused                                                    | 460             | 860    | 460    | 2460   | 5       |
| lockBondETH                                                 | 21870           | 68616  | 70411  | 70435  | 27      |
| pauseFor                                                    | 24043           | 45429  | 47568  | 47568  | 11      |
| penalize                                                    | 21766           | 38496  | 38496  | 55226  | 2       |
| recoverERC20                                                | 24503           | 35879  | 24510  | 58625  | 3       |
| recoverEther                                                | 23861           | 37437  | 28376  | 60076  | 3       |
| recoverStETHShares                                          | 23839           | 43274  | 43274  | 62710  | 2       |
| releaseLockedBondETH                                        | 21826           | 26776  | 26776  | 31726  | 2       |
| resetBondCurve                                              | 24054           | 24890  | 24890  | 25727  | 2       |
| resume                                                      | 23873           | 26793  | 26793  | 29714  | 2       |
| setBondCurve                                                | 24215           | 49026  | 50019  | 50019  | 26      |
| setChargeRecipient                                          | 24083           | 26138  | 24129  | 30202  | 3       |
| setLockedBondRetentionPeriod                                | 30160           | 30160  | 30160  | 30160  | 1       |
| settleLockedBondETH                                         | 51968           | 51968  | 51968  | 51968  | 1       |
| totalBondShares                                             | 401             | 512    | 401    | 2401   | 54      |
| updateBondCurve                                             | 24729           | 38217  | 26926  | 62996  | 3       |


| src/CSEarlyAdoption.sol:CSEarlyAdoption contract |                 |       |        |       |         |
|--------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                    | min             | avg   | median | max   | # calls |
| CURVE_ID                                         | 238             | 238   | 238    | 238   | 4       |
| MODULE                                           | 182             | 182   | 182    | 182   | 1       |
| TREE_ROOT                                        | 216             | 216   | 216    | 216   | 1       |
| consume                                          | 22780           | 34331 | 25728  | 47035 | 7       |
| isConsumed                                       | 615             | 615   | 615    | 615   | 1       |
| verifyProof                                      | 1322            | 1322  | 1322   | 1322  | 2       |


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
| addNodeOperatorETH                                  | 26839           | 436331 | 384189 | 1061691 | 281     |
| addNodeOperatorStETH                                | 27643           | 251141 | 281369 | 376639  | 8       |
| addNodeOperatorWstETH                               | 27665           | 274455 | 312703 | 397466  | 8       |
| addValidatorKeysETH                                 | 25733           | 167825 | 220922 | 275859  | 13      |
| addValidatorKeysStETH                               | 26447           | 117108 | 92975  | 208482  | 6       |
| addValidatorKeysWstETH                              | 26425           | 137671 | 136789 | 227553  | 6       |
| cancelELRewardsStealingPenalty                      | 26355           | 65757  | 76659  | 83357   | 4       |
| claimRewardsStETH                                   | 25180           | 48595  | 49142  | 70916   | 4       |
| claimRewardsUnstETH                                 | 25226           | 48631  | 49178  | 70942   | 4       |
| claimRewardsWstETH                                  | 25269           | 48115  | 48662  | 69867   | 4       |
| cleanDepositQueue                                   | 24678           | 40965  | 40928  | 61619   | 13      |
| compensateELRewardsStealingPenalty                  | 23738           | 79122  | 95351  | 102050  | 4       |
| confirmNodeOperatorManagerAddressChange             | 26989           | 29351  | 29135  | 32363   | 5       |
| confirmNodeOperatorRewardAddressChange              | 26830           | 30860  | 32161  | 32161   | 9       |
| decreaseVettedSigningKeysCount                      | 24894           | 63883  | 77818  | 98174   | 22      |
| depositETH                                          | 23773           | 90771  | 96578  | 118625  | 8       |
| depositQueue                                        | 524             | 857    | 524    | 2524    | 6       |
| depositQueueItem                                    | 689             | 1355   | 689    | 2689    | 12      |
| depositStETH                                        | 24743           | 74120  | 79796  | 101837  | 5       |
| depositWstETH                                       | 24702           | 90117  | 101101 | 118917  | 5       |
| earlyAdoption                                       | 427             | 427    | 427    | 427     | 1       |
| getActiveNodeOperatorsCount                         | 437             | 437    | 437    | 437     | 2       |
| getNodeOperator                                     | 2452            | 5547   | 6452   | 12452   | 73      |
| getNodeOperatorIds                                  | 813             | 1269   | 1218   | 1970    | 8       |
| getNodeOperatorIsActive                             | 581             | 581    | 581    | 581     | 1       |
| getNodeOperatorNonWithdrawnKeys                     | 724             | 831    | 724    | 2724    | 539     |
| getNodeOperatorSummary                              | 6580            | 6845   | 6753   | 7079    | 24      |
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
| removeKeys                                          | 24078           | 117377 | 141880 | 216437  | 17      |
| reportELRewardsStealingPenalty                      | 24341           | 113171 | 123557 | 124688  | 36      |
| resetNodeOperatorManagerAddress                     | 26928           | 31012  | 29362  | 36732   | 5       |
| resume                                              | 23787           | 29651  | 29670  | 29670   | 324     |
| revokeRole                                          | 40394           | 40394  | 40394  | 40394   | 1       |
| setKeyRemovalCharge                                 | 24061           | 27265  | 27274  | 30086   | 289     |
| settleELRewardsStealingPenalty                      | 24850           | 79603  | 93590  | 122174  | 22      |
| submitInitialSlashing                               | 24204           | 83516  | 111673 | 126506  | 14      |
| submitWithdrawal                                    | 24363           | 90504  | 105902 | 139944  | 17      |
| unsafeUpdateValidatorsCount                         | 24320           | 44459  | 39510  | 84110   | 12      |
| updateExitedValidatorsCount                         | 24992           | 41456  | 48592  | 58750   | 11      |
| updateRefundedValidatorsCount                       | 24184           | 24198  | 24196  | 24216   | 3       |
| updateStuckValidatorsCount                          | 24882           | 53620  | 48989  | 80233   | 14      |
| updateTargetValidatorsLimits                        | 24346           | 74035  | 72452  | 115487  | 41      |


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




