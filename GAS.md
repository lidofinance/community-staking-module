| src/CSAccounting.sol:CSAccounting contract                  |                 |        |        |        |         |
|-------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                               | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                     | 296             | 296    | 296    | 296    | 187     |
| CSM                                                         | 306             | 306    | 306    | 306    | 1       |
| MANAGE_BOND_CURVES_ROLE                                     | 315             | 315    | 315    | 315    | 796     |
| MIN_BOND_LOCK_RETENTION_PERIOD                              | 295             | 295    | 295    | 295    | 1       |
| PAUSE_ROLE                                                  | 295             | 295    | 295    | 295    | 187     |
| RECOVERER_ROLE                                              | 273             | 273    | 273    | 273    | 12      |
| RESET_BOND_CURVE_ROLE                                       | 297             | 297    | 297    | 297    | 1       |
| RESUME_ROLE                                                 | 318             | 318    | 318    | 318    | 187     |
| SET_BOND_CURVE_ROLE                                         | 317             | 317    | 317    | 317    | 187     |
| addBondCurve                                                | 24304           | 101437 | 98880  | 305552 | 349     |
| chargeFee                                                   | 21781           | 48206  | 48206  | 74632  | 2       |
| chargeRecipient                                             | 447             | 447    | 447    | 447    | 1       |
| claimRewardsStETH                                           | 25053           | 79255  | 91060  | 100910 | 16      |
| claimRewardsUnstETH                                         | 25078           | 64092  | 66784  | 76634  | 16      |
| claimRewardsWstETH                                          | 25099           | 114792 | 152873 | 157278 | 16      |
| compensateLockedBondETH                                     | 47700           | 47700  | 47700  | 47700  | 1       |
| depositETH                                                  | 24172           | 111366 | 113317 | 113557 | 108     |
| depositStETH                                                | 25162           | 85548  | 104020 | 107939 | 8       |
| depositWstETH                                               | 25138           | 94477  | 121010 | 124650 | 7       |
| feeDistributor                                              | 426             | 1759   | 2426   | 2426   | 3       |
| getActualLockedBond                                         | 621             | 693    | 718    | 718    | 8       |
| getBondAmountByKeysCount                                    | 1131            | 1232   | 1224   | 1252   | 286     |
| getBondAmountByKeysCountWstETH(uint256,(uint256[],uint256)) | 3202            | 11139  | 14126  | 14126  | 11      |
| getBondAmountByKeysCountWstETH(uint256,uint256)             | 3509            | 8249   | 3537   | 22416  | 4       |
| getBondCurve                                                | 1914            | 11759  | 11914  | 11914  | 297     |
| getBondCurveId                                              | 516             | 516    | 516    | 516    | 2       |
| getBondLockRetentionPeriod                                  | 392             | 1725   | 2392   | 2392   | 3       |
| getBondShares                                               | 570             | 664    | 570    | 2570   | 106     |
| getBondSummary                                              | 12730           | 18113  | 15980  | 24480  | 12      |
| getBondSummaryShares                                        | 12666           | 18049  | 15916  | 24416  | 12      |
| getCurveInfo                                                | 1615            | 1779   | 1862   | 1862   | 3       |
| getLockedBondInfo                                           | 795             | 795    | 795    | 795    | 12      |
| getRequiredBondForNextKeys                                  | 6316            | 19411  | 17842  | 31122  | 45      |
| getRequiredBondForNextKeysWstETH                            | 21093           | 28346  | 24224  | 35226  | 20      |
| getUnbondedKeysCount                                        | 2536            | 11682  | 6720   | 25470  | 486     |
| getUnbondedKeysCountToEject                                 | 4033            | 7055   | 4475   | 13883  | 36      |
| grantRole                                                   | 29320           | 99870  | 118408 | 118408 | 1547    |
| initialize                                                  | 25958           | 491120 | 493394 | 493394 | 513     |
| isPaused                                                    | 429             | 829    | 429    | 2429   | 5       |
| lockBondETH                                                 | 21820           | 68627  | 70424  | 70448  | 27      |
| pauseFor                                                    | 23953           | 45388  | 47532  | 47532  | 11      |
| penalize                                                    | 21781           | 37978  | 37978  | 54176  | 2       |
| recoverERC20                                                | 24461           | 35858  | 24496  | 58617  | 3       |
| recoverEther                                                | 23749           | 37429  | 28419  | 60119  | 3       |
| recoverStETHShares                                          | 23727           | 43167  | 43167  | 62607  | 2       |
| releaseLockedBondETH                                        | 21842           | 26778  | 26778  | 31714  | 2       |
| resetBondCurve                                              | 23942           | 24826  | 24826  | 25710  | 2       |
| resume                                                      | 23760           | 26669  | 26669  | 29579  | 2       |
| setBondCurve                                                | 24103           | 48989  | 49985  | 49985  | 26      |
| setChargeRecipient                                          | 24012           | 26077  | 24016  | 30203  | 3       |
| setLockedBondRetentionPeriod                                | 30126           | 30126  | 30126  | 30126  | 1       |
| settleLockedBondETH                                         | 51013           | 51013  | 51013  | 51013  | 1       |
| totalBondShares                                             | 370             | 481    | 370    | 2370   | 54      |
| updateBondCurve                                             | 24410           | 37952  | 26751  | 62697  | 3       |


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
| grantRole                                          | 118386          | 118386 | 118386 | 118386 | 5       |
| hashLeaf                                           | 623             | 623    | 623    | 623    | 1       |
| initialize                                         | 24594           | 205566 | 229481 | 229481 | 24      |
| pendingSharesToDistribute                          | 1465            | 1465   | 1465   | 1465   | 2       |
| processOracleReport                                | 32129           | 76277  | 99923  | 99947  | 17      |
| recoverERC20                                       | 24424           | 35821  | 24459  | 58580  | 3       |
| recoverEther                                       | 23681           | 41866  | 41866  | 60051  | 2       |
| totalClaimableShares                               | 362             | 362    | 362    | 362    | 1       |
| treeCid                                            | 1275            | 2147   | 2147   | 3020   | 2       |
| treeRoot                                           | 384             | 1050   | 384    | 2384   | 3       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| CONTRACT_MANAGER_ROLE                    | 262             | 262    | 262    | 262    | 10      |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 262             | 262    | 262    | 262    | 10      |
| MANAGE_CONSENSUS_VERSION_ROLE            | 306             | 306    | 306    | 306    | 10      |
| PAUSE_ROLE                               | 285             | 285    | 285    | 285    | 10      |
| RESUME_ROLE                              | 285             | 285    | 285    | 285    | 10      |
| SUBMIT_DATA_ROLE                         | 262             | 262    | 262    | 262    | 18      |
| avgPerfLeewayBP                          | 405             | 405    | 405    | 405    | 1       |
| feeDistributor                           | 426             | 426    | 426    | 426    | 1       |
| getConsensusReport                       | 986             | 1945   | 1012   | 2986   | 21      |
| getConsensusVersion                      | 396             | 1486   | 2396   | 2396   | 11      |
| getLastProcessingRefSlot                 | 472             | 2309   | 2472   | 2472   | 37      |
| grantRole                                | 101264          | 115344 | 118364 | 118364 | 68      |
| initialize                               | 22903           | 224241 | 244375 | 244375 | 11      |
| pauseFor                                 | 47518           | 47518  | 47518  | 47518  | 2       |
| pauseUntil                               | 47534           | 47534  | 47534  | 47534  | 1       |
| resume                                   | 23526           | 26628  | 26628  | 29730  | 2       |
| setFeeDistributorContract                | 24018           | 27220  | 27220  | 30422  | 2       |
| setPerformanceLeeway                     | 23985           | 27044  | 27044  | 30104  | 2       |
| submitReportData                         | 25420           | 47493  | 35442  | 75592  | 5       |


| src/CSModule.sol:CSModule contract                  |                 |        |        |         |         |
|-----------------------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                                       | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                                  | 328             | 328    | 328    | 328     | 1       |
| EL_REWARDS_STEALING_FINE                            | 284             | 284    | 284    | 284     | 24      |
| INITIAL_SLASHING_PENALTY                            | 327             | 327    | 327    | 327     | 4       |
| LIDO_LOCATOR                                        | 327             | 327    | 327    | 327     | 2       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 329             | 329    | 329    | 329     | 3       |
| MODULE_MANAGER_ROLE                                 | 306             | 306    | 306    | 306     | 329     |
| PAUSE_ROLE                                          | 308             | 308    | 308    | 308     | 287     |
| RECOVERER_ROLE                                      | 306             | 306    | 306    | 306     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 283             | 283    | 283    | 283     | 288     |
| RESUME_ROLE                                         | 330             | 330    | 330    | 330     | 323     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 329             | 329    | 329    | 329     | 288     |
| STAKING_ROUTER_ROLE                                 | 360             | 360    | 360    | 360     | 310     |
| VERIFIER_ROLE                                       | 327             | 327    | 327    | 327     | 326     |
| accounting                                          | 426             | 426    | 426    | 426     | 1       |
| activatePublicRelease                               | 23713           | 29549  | 29581  | 29581   | 303     |
| addNodeOperatorETH                                  | 26715           | 434376 | 382270 | 1059543 | 281     |
| addNodeOperatorStETH                                | 27519           | 250040 | 280226 | 374689  | 8       |
| addNodeOperatorWstETH                               | 27541           | 273198 | 311326 | 395412  | 8       |
| addValidatorKeysETH                                 | 25621           | 165875 | 218453 | 272932  | 13      |
| addValidatorKeysStETH                               | 26402           | 115926 | 92060  | 206049  | 6       |
| addValidatorKeysWstETH                              | 26380           | 136243 | 135586 | 224858  | 6       |
| cancelELRewardsStealingPenalty                      | 26299           | 65373  | 76196  | 82801   | 4       |
| claimRewardsStETH                                   | 25011           | 47932  | 48479  | 69759   | 4       |
| claimRewardsUnstETH                                 | 25012           | 47945  | 48493  | 69785   | 4       |
| claimRewardsWstETH                                  | 25033           | 47429  | 47977  | 68732   | 4       |
| cleanDepositQueue                                   | 24634           | 40912  | 40872  | 61551   | 13      |
| compensateELRewardsStealingPenalty                  | 23686           | 78777  | 94938  | 101546  | 4       |
| confirmNodeOperatorManagerAddressChange             | 26990           | 29348  | 29136  | 32343   | 5       |
| confirmNodeOperatorRewardAddressChange              | 26876           | 30906  | 32207  | 32207   | 9       |
| decreaseVettedSigningKeysCount                      | 24810           | 63462  | 77300  | 97222   | 22      |
| depositETH                                          | 23743           | 90441  | 96208  | 118231  | 8       |
| depositQueue                                        | 480             | 813    | 480    | 2480    | 6       |
| depositQueueItem                                    | 645             | 1311   | 645    | 2645    | 12      |
| depositStETH                                        | 24691           | 73823  | 79468  | 101485  | 5       |
| depositWstETH                                       | 24717           | 89821  | 100768 | 118477  | 5       |
| earlyAdoption                                       | 450             | 450    | 450    | 450     | 1       |
| getActiveNodeOperatorsCount                         | 448             | 448    | 448    | 448     | 2       |
| getNodeOperator                                     | 2469            | 5564   | 6469   | 12469   | 73      |
| getNodeOperatorIds                                  | 757             | 1208   | 1157   | 1901    | 8       |
| getNodeOperatorIsActive                             | 525             | 525    | 525    | 525     | 1       |
| getNodeOperatorNonWithdrawnKeys                     | 592             | 699    | 592    | 2592    | 539     |
| getNodeOperatorSummary                              | 6085            | 6230   | 6166   | 6392    | 24      |
| getNodeOperatorsCount                               | 404             | 404    | 404    | 404     | 274     |
| getNonce                                            | 425             | 578    | 425    | 2425    | 78      |
| getSigningKeys                                      | 693             | 2748   | 3086   | 3477    | 8       |
| getSigningKeysWithSignatures                        | 698             | 3119   | 2919   | 5941    | 4       |
| getStakingModuleSummary                             | 485             | 485    | 485    | 485     | 20      |
| getType                                             | 294             | 294    | 294    | 294     | 2       |
| grantRole                                           | 26948           | 115908 | 118386 | 118386  | 2135    |
| hasRole                                             | 751             | 751    | 751    | 751     | 2       |
| initialize                                          | 25053           | 323936 | 326582 | 326582  | 327     |
| isPaused                                            | 417             | 750    | 417    | 2417    | 6       |
| isValidatorSlashed                                  | 607             | 607    | 607    | 607     | 1       |
| isValidatorWithdrawn                                | 640             | 640    | 640    | 640     | 1       |
| keyRemovalCharge                                    | 383             | 1049   | 383    | 2383    | 3       |
| normalizeQueue                                      | 29509           | 45576  | 45576  | 61644   | 2       |
| obtainDepositData                                   | 24506           | 76378  | 68606  | 140375  | 66      |
| onExitedAndStuckValidatorsCountsUpdated             | 23673           | 23709  | 23709  | 23745   | 2       |
| onRewardsMinted                                     | 23951           | 42039  | 39716  | 62452   | 3       |
| onWithdrawalCredentialsChanged                      | 23747           | 24618  | 25054  | 25054   | 3       |
| pauseFor                                            | 23997           | 29887  | 30476  | 30476   | 11      |
| proposeNodeOperatorManagerAddressChange             | 27531           | 41873  | 52085  | 52085   | 11      |
| proposeNodeOperatorRewardAddressChange              | 27502           | 44537  | 52022  | 52022   | 15      |
| publicRelease                                       | 426             | 426    | 426    | 426     | 1       |
| recoverERC20                                        | 58558           | 58558  | 58558  | 58558   | 1       |
| recoverEther                                        | 23727           | 26062  | 26062  | 28397   | 2       |
| recoverStETHShares                                  | 55673           | 55673  | 55673  | 55673   | 1       |
| removeKeys                                          | 24101           | 117024 | 141383 | 215857  | 17      |
| reportELRewardsStealingPenalty                      | 24293           | 112699 | 123134 | 124018  | 36      |
| resetNodeOperatorManagerAddress                     | 26929           | 31005  | 29363  | 36712   | 5       |
| resume                                              | 23739           | 29540  | 29558  | 29558   | 324     |
| revokeRole                                          | 40140           | 40140  | 40140  | 40140   | 1       |
| setKeyRemovalCharge                                 | 24013           | 27302  | 27311  | 30123   | 289     |
| settleELRewardsStealingPenalty                      | 24465           | 78173  | 91754  | 119152  | 22      |
| submitInitialSlashing                               | 24089           | 82468  | 110186 | 124822  | 14      |
| submitWithdrawal                                    | 24315           | 89631  | 104316 | 139263  | 17      |
| unsafeUpdateValidatorsCount                         | 24272           | 44172  | 39268  | 83288   | 12      |
| updateExitedValidatorsCount                         | 24841           | 41155  | 48235  | 58061   | 11      |
| updateRefundedValidatorsCount                       | 24069           | 24083  | 24081  | 24101   | 3       |
| updateStuckValidatorsCount                          | 24798           | 53250  | 48576  | 79620   | 14      |
| updateTargetValidatorsLimits                        | 24253           | 73596  | 71965  | 115030  | 41      |


| src/CSVerifier.sol:CSVerifier contract |                 |       |        |        |         |
|----------------------------------------|-----------------|-------|--------|--------|---------|
| Function Name                          | min             | avg   | median | max    | # calls |
| BEACON_ROOTS                           | 271             | 271   | 271    | 271    | 21      |
| FIRST_SUPPORTED_SLOT                   | 282             | 282   | 282    | 282    | 5       |
| GI_FIRST_VALIDATOR                     | 240             | 240   | 240    | 240    | 1       |
| GI_FIRST_WITHDRAWAL                    | 239             | 239   | 239    | 239    | 1       |
| GI_HISTORICAL_SUMMARIES                | 239             | 239   | 239    | 239    | 1       |
| LOCATOR                                | 227             | 227   | 227    | 227    | 1       |
| MODULE                                 | 228             | 228   | 228    | 228    | 1       |
| SLOTS_PER_EPOCH                        | 259             | 259   | 259    | 259    | 1       |
| processHistoricalWithdrawalProof       | 73146           | 88613 | 80221  | 135957 | 5       |
| processSlashingProof                   | 48722           | 61798 | 55564  | 81110  | 3       |
| processWithdrawalProof                 | 56345           | 72738 | 69770  | 102936 | 9       |


| src/lib/AssetRecovererLib.sol:AssetRecovererLib contract |                 |       |        |       |         |
|----------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                            | min             | avg   | median | max   | # calls |
| recoverERC1155                                           | 38733           | 38733 | 38733  | 38733 | 1       |
| recoverERC20                                             | 36060           | 36060 | 36060  | 36060 | 4       |
| recoverERC721                                            | 43376           | 43376 | 43376  | 43376 | 1       |
| recoverEther                                             | 1906            | 20926 | 33606  | 33606 | 5       |




