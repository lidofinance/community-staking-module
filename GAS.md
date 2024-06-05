| src/CSAccounting.sol:CSAccounting contract                  |                 |        |        |        |         |
|-------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                               | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                     | 1029            | 1029   | 1029   | 1029   | 184     |
| CSM                                                         | 1031            | 1031   | 1031   | 1031   | 1       |
| MANAGE_BOND_CURVES_ROLE                                     | 1755            | 1755   | 1755   | 1755   | 793     |
| MIN_BOND_LOCK_RETENTION_PERIOD                              | 1217            | 1217   | 1217   | 1217   | 1       |
| PAUSE_ROLE                                                  | 567             | 567    | 567    | 567    | 184     |
| RECOVERER_ROLE                                              | 1227            | 1227   | 1227   | 1227   | 12      |
| RESET_BOND_CURVE_ROLE                                       | 413             | 413    | 413    | 413    | 1       |
| RESUME_ROLE                                                 | 479             | 479    | 479    | 479    | 184     |
| SET_BOND_CURVE_ROLE                                         | 589             | 589    | 589    | 589    | 184     |
| addBondCurve                                                | 25129           | 101018 | 99696  | 122834 | 346     |
| chargeFee                                                   | 22403           | 48983  | 48983  | 75563  | 2       |
| chargeRecipient                                             | 1504            | 1504   | 1504   | 1504   | 1       |
| claimRewardsStETH                                           | 26765           | 81576  | 93550  | 103401 | 16      |
| claimRewardsUnstETH                                         | 26457           | 65966  | 68758  | 78608  | 16      |
| claimRewardsWstETH                                          | 25929           | 114824 | 152273 | 156679 | 16      |
| compensateLockedBondETH                                     | 47861           | 47861  | 47861  | 47861  | 1       |
| depositETH                                                  | 24399           | 111541 | 113549 | 113789 | 105     |
| depositStETH                                                | 25521           | 85949  | 104320 | 108524 | 8       |
| depositWstETH                                               | 26533           | 95546  | 121878 | 125810 | 7       |
| feeDistributor                                              | 469             | 1802   | 2469   | 2469   | 3       |
| getActualLockedBond                                         | 1967            | 2039   | 2064   | 2064   | 8       |
| getBondAmountByKeysCount                                    | 1185            | 1425   | 1342   | 1599   | 286     |
| getBondAmountByKeysCountWstETH(uint256,(uint256[],uint256)) | 4082            | 12032  | 15012  | 15012  | 11      |
| getBondAmountByKeysCountWstETH(uint256,uint256)             | 3626            | 8465   | 3883   | 22469  | 4       |
| getBondCurve                                                | 2558            | 12403  | 12558  | 12558  | 297     |
| getBondCurveId                                              | 544             | 544    | 544    | 544    | 2       |
| getBondLockRetentionPeriod                                  | 1698            | 3031   | 3698   | 3698   | 3       |
| getBondShares                                               | 560             | 654    | 560    | 2560   | 106     |
| getBondSummary                                              | 14489           | 19872  | 17739  | 26239  | 12      |
| getBondSummaryShares                                        | 13909           | 19292  | 17159  | 25659  | 12      |
| getCurveInfo                                                | 2707            | 2871   | 2954   | 2954   | 3       |
| getLockedBondInfo                                           | 1494            | 1494   | 1494   | 1494   | 12      |
| getRequiredBondForNextKeys                                  | 9186            | 22379  | 20334  | 33992  | 45      |
| getRequiredBondForNextKeysWstETH                            | 22801           | 30173  | 25913  | 37507  | 20      |
| getUnbondedKeysCount                                        | 2709            | 13249  | 8294   | 27044  | 483     |
| getUnbondedKeysCountToEject                                 | 5417            | 9094   | 6887   | 15264  | 36      |
| grantRole                                                   | 29805           | 100207 | 118893 | 118893 | 1532    |
| initialize                                                  | 27744           | 493467 | 495757 | 495757 | 510     |
| isPaused                                                    | 1449            | 1849   | 1449   | 3449   | 5       |
| lockBondETH                                                 | 23057           | 69844  | 71640  | 71664  | 27      |
| pauseFor                                                    | 25465           | 46880  | 49022  | 49022  | 11      |
| penalize                                                    | 23063           | 40220  | 40220  | 57378  | 2       |
| recoverERC20                                                | 25240           | 36667  | 25247  | 59514  | 3       |
| recoverEther                                                | 24291           | 37867  | 28806  | 60506  | 3       |
| recoverStETHShares                                          | 24379           | 44062  | 44062  | 63746  | 2       |
| releaseLockedBondETH                                        | 23013           | 27994  | 27994  | 32975  | 2       |
| resetBondCurve                                              | 24395           | 25251  | 25251  | 26108  | 2       |
| resume                                                      | 23817           | 26737  | 26737  | 29658  | 2       |
| setBondCurve                                                | 25240           | 49957  | 51081  | 51081  | 23      |
| setChargeRecipient                                          | 25416           | 27487  | 25462  | 31585  | 3       |
| setLockedBondRetentionPeriod                                | 30988           | 30988  | 30988  | 30988  | 1       |
| settleLockedBondETH                                         | 53200           | 53200  | 53200  | 53200  | 1       |
| totalBondShares                                             | 1022            | 1133   | 1022   | 3022   | 54      |
| updateBondCurve                                             | 24709           | 38200  | 26911  | 62981  | 3       |


| src/CSEarlyAdoption.sol:CSEarlyAdoption contract |                 |       |        |       |         |
|--------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                    | min             | avg   | median | max   | # calls |
| CURVE_ID                                         | 238             | 238   | 238    | 238   | 4       |
| MODULE                                           | 217             | 217   | 217    | 217   | 1       |
| TREE_ROOT                                        | 216             | 216   | 216    | 216   | 1       |
| consume                                          | 22792           | 34363 | 25767  | 47074 | 7       |
| isConsumed                                       | 615             | 615   | 615    | 615   | 1       |
| verifyProof                                      | 1361            | 1361  | 1361   | 1361  | 2       |


| src/CSFeeDistributor.sol:CSFeeDistributor contract |                 |        |        |        |         |
|----------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                      | min             | avg    | median | max    | # calls |
| ACCOUNTING                                         | 481             | 481    | 481    | 481    | 1       |
| RECOVERER_ROLE                                     | 622             | 622    | 622    | 622    | 7       |
| STETH                                              | 745             | 745    | 745    | 745    | 1       |
| distributeFees                                     | 22300           | 42573  | 27795  | 76195  | 6       |
| distributedShares                                  | 963             | 1963   | 1963   | 2963   | 4       |
| getFeesToDistribute                                | 1774            | 2774   | 2774   | 3774   | 2       |
| grantRole                                          | 118674          | 118674 | 118674 | 118674 | 5       |
| hashLeaf                                           | 853             | 853    | 853    | 853    | 1       |
| initialize                                         | 24725           | 206078 | 230039 | 230039 | 24      |
| pendingSharesToDistribute                          | 2134            | 2134   | 2134   | 2134   | 2       |
| processOracleReport                                | 32923           | 77017  | 100633 | 100657 | 17      |
| recoverERC20                                       | 24784           | 36211  | 24791  | 59058  | 3       |
| recoverEther                                       | 23961           | 42068  | 42068  | 60176  | 2       |
| totalClaimableShares                               | 426             | 426    | 426    | 426    | 1       |
| treeCid                                            | 1715            | 2587   | 2587   | 3460   | 2       |
| treeRoot                                           | 315             | 981    | 315    | 2315   | 3       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| CONTRACT_MANAGER_ROLE                    | 776             | 776    | 776    | 776    | 10      |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 908             | 908    | 908    | 908    | 10      |
| MANAGE_CONSENSUS_VERSION_ROLE            | 754             | 754    | 754    | 754    | 10      |
| PAUSE_ROLE                               | 446             | 446    | 446    | 446    | 10      |
| RESUME_ROLE                              | 336             | 336    | 336    | 336    | 10      |
| SUBMIT_DATA_ROLE                         | 468             | 468    | 468    | 468    | 18      |
| avgPerfLeewayBP                          | 1130            | 1130   | 1130   | 1130   | 1       |
| feeDistributor                           | 403             | 403    | 403    | 403    | 1       |
| getConsensusReport                       | 1275            | 2238   | 1313   | 3275   | 21      |
| getConsensusVersion                      | 668             | 1758   | 2668   | 2668   | 11      |
| getLastProcessingRefSlot                 | 536             | 2373   | 2536   | 2536   | 37      |
| grantRole                                | 101618          | 115698 | 118718 | 118718 | 68      |
| initialize                               | 23452           | 225382 | 245575 | 245575 | 11      |
| pauseFor                                 | 48437           | 48437  | 48437  | 48437  | 2       |
| pauseUntil                               | 48210           | 48210  | 48210  | 48210  | 1       |
| resume                                   | 23466           | 26653  | 26653  | 29841  | 2       |
| setFeeDistributorContract                | 24850           | 28042  | 28042  | 31234  | 2       |
| setPerformanceLeeway                     | 24884           | 27904  | 27904  | 30924  | 2       |
| submitReportData                         | 25417           | 45442  | 35646  | 70367  | 5       |


| src/CSModule.sol:CSModule contract                  |                 |        |        |         |         |
|-----------------------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                                       | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                                  | 1447            | 1447   | 1447   | 1447    | 1       |
| EL_REWARDS_STEALING_FINE                            | 1712            | 1712   | 1712   | 1712    | 24      |
| INITIAL_SLASHING_PENALTY                            | 1888            | 1888   | 1888   | 1888    | 4       |
| LIDO_LOCATOR                                        | 1977            | 1977   | 1977   | 1977    | 2       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 568             | 568    | 568    | 568     | 3       |
| MODULE_MANAGER_ROLE                                 | 1832            | 1832   | 1832   | 1832    | 329     |
| PAUSE_ROLE                                          | 468             | 468    | 468    | 468     | 287     |
| RECOVERER_ROLE                                      | 1590            | 1590   | 1590   | 1590    | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 1128            | 1128   | 1128   | 1128    | 288     |
| RESUME_ROLE                                         | 358             | 358    | 358    | 358     | 323     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 534             | 534    | 534    | 534     | 288     |
| STAKING_ROUTER_ROLE                                 | 1040            | 1040   | 1040   | 1040    | 310     |
| VERIFIER_ROLE                                       | 2030            | 2030   | 2030   | 2030    | 326     |
| accounting                                          | 1504            | 1504   | 1504   | 1504    | 1       |
| activatePublicRelease                               | 25423           | 31223  | 31255  | 31255   | 303     |
| addNodeOperatorETH                                  | 27981           | 440172 | 387804 | 1066300 | 281     |
| addNodeOperatorStETH                                | 28412           | 253622 | 283962 | 380386  | 8       |
| addNodeOperatorWstETH                               | 28940           | 278482 | 317077 | 402361  | 8       |
| addValidatorKeysETH                                 | 27493           | 172610 | 226794 | 281802  | 13      |
| addValidatorKeysStETH                               | 27457           | 120960 | 96762  | 214121  | 6       |
| addValidatorKeysWstETH                              | 27567           | 141255 | 140170 | 232569  | 6       |
| cancelELRewardsStealingPenalty                      | 26653           | 67857  | 79349  | 86079   | 4       |
| claimRewardsStETH                                   | 25881           | 52680  | 53751  | 77336   | 4       |
| claimRewardsUnstETH                                 | 25309           | 51954  | 53025  | 76456   | 4       |
| claimRewardsWstETH                                  | 25463           | 51231  | 52302  | 74856   | 4       |
| cleanDepositQueue                                   | 25314           | 41642  | 41600  | 62375   | 13      |
| compensateELRewardsStealingPenalty                  | 24374           | 80808  | 97375  | 104107  | 4       |
| confirmNodeOperatorManagerAddressChange             | 27649           | 30017  | 29795  | 33055   | 5       |
| confirmNodeOperatorRewardAddressChange              | 27258           | 31288  | 32589  | 32589   | 9       |
| decreaseVettedSigningKeysCount                      | 26346           | 66207  | 80393  | 101914  | 22      |
| depositETH                                          | 24166           | 92507  | 98498  | 120599  | 8       |
| depositQueue                                        | 2284            | 2617   | 2284   | 4284    | 6       |
| depositQueueItem                                    | 1193            | 1859   | 1193   | 3193    | 12      |
| depositStETH                                        | 26370           | 77097  | 82974  | 105069  | 5       |
| depositWstETH                                       | 24964           | 91738  | 102882 | 121197  | 5       |
| earlyAdoption                                       | 470             | 470    | 470    | 470     | 1       |
| getActiveNodeOperatorsCount                         | 1209            | 1209   | 1209   | 1209    | 2       |
| getNodeOperator                                     | 3239            | 6334   | 7239   | 13239   | 73      |
| getNodeOperatorIds                                  | 1075            | 1531   | 1480   | 2232    | 8       |
| getNodeOperatorIsActive                             | 1085            | 1085   | 1085   | 1085    | 1       |
| getNodeOperatorNonWithdrawnKeys                     | 1623            | 1730   | 1623   | 3623    | 539     |
| getNodeOperatorSummary                              | 9797            | 10062  | 9970   | 10296   | 24      |
| getNodeOperatorsCount                               | 1671            | 1671   | 1671   | 1671    | 274     |
| getNonce                                            | 1919            | 2072   | 1919   | 3919    | 78      |
| getSigningKeys                                      | 1174            | 3349   | 3726   | 4147    | 8       |
| getSigningKeysWithSignatures                        | 1004            | 3496   | 3267   | 6448    | 4       |
| getStakingModuleSummary                             | 1587            | 1587   | 1587   | 1587    | 20      |
| getType                                             | 224             | 224    | 224    | 224     | 2       |
| grantRole                                           | 27194           | 116261 | 118739 | 118739  | 2135    |
| hasRole                                             | 1786            | 1786   | 1786   | 1786    | 2       |
| initialize                                          | 26542           | 325890 | 328540 | 328540  | 327     |
| isPaused                                            | 1768            | 2101   | 1768   | 3768    | 6       |
| isValidatorSlashed                                  | 780             | 780    | 780    | 780     | 1       |
| isValidatorWithdrawn                                | 1055            | 1055   | 1055   | 1055    | 1       |
| keyRemovalCharge                                    | 2009            | 2675   | 2009   | 4009    | 3       |
| normalizeQueue                                      | 32827           | 48878  | 48878  | 64929   | 2       |
| obtainDepositData                                   | 26075           | 78142  | 70337  | 142538  | 66      |
| onExitedAndStuckValidatorsCountsUpdated             | 25485           | 25542  | 25542  | 25599   | 2       |
| onRewardsMinted                                     | 24989           | 46645  | 46106  | 68842   | 3       |
| onWithdrawalCredentialsChanged                      | 24851           | 25637  | 26031  | 26031   | 3       |
| pauseFor                                            | 25883           | 31753  | 32340  | 32340   | 11      |
| proposeNodeOperatorManagerAddressChange             | 28420           | 42762  | 52974  | 52974   | 11      |
| proposeNodeOperatorRewardAddressChange              | 27501           | 44536  | 52021  | 52021   | 15      |
| publicRelease                                       | 2097            | 2097   | 2097   | 2097    | 1       |
| recoverERC20                                        | 59631           | 59631  | 59631  | 59631   | 1       |
| recoverEther                                        | 24291           | 26548  | 26548  | 28806   | 2       |
| recoverStETHShares                                  | 61918           | 61918  | 61918  | 61918   | 1       |
| removeKeys                                          | 24909           | 121613 | 147171 | 220812  | 17      |
| reportELRewardsStealingPenalty                      | 24570           | 115570 | 126092 | 127223  | 36      |
| resetNodeOperatorManagerAddress                     | 27588           | 31685  | 30022  | 37424   | 5       |
| resume                                              | 23773           | 29595  | 29614  | 29614   | 324     |
| revokeRole                                          | 41621           | 41621  | 41621  | 41621   | 1       |
| setKeyRemovalCharge                                 | 25545           | 28707  | 28716  | 31528   | 289     |
| settleELRewardsStealingPenalty                      | 24947           | 81875  | 96387  | 127713  | 22      |
| submitInitialSlashing                               | 26042           | 87408  | 116734 | 131567  | 14      |
| submitWithdrawal                                    | 24834           | 92571  | 108784 | 141528  | 17      |
| unsafeUpdateValidatorsCount                         | 26126           | 46291  | 41096  | 86782   | 12      |
| updateExitedValidatorsCount                         | 26048           | 42534  | 49606  | 59912   | 11      |
| updateRefundedValidatorsCount                       | 25330           | 25358  | 25342  | 25404   | 3       |
| updateStuckValidatorsCount                          | 26070           | 55201  | 50191  | 82512   | 14      |
| updateTargetValidatorsLimits                        | 24300           | 74947  | 73441  | 116542  | 41      |


| src/CSVerifier.sol:CSVerifier contract |                 |       |        |        |         |
|----------------------------------------|-----------------|-------|--------|--------|---------|
| Function Name                          | min             | avg   | median | max    | # calls |
| BEACON_ROOTS                           | 270             | 270   | 270    | 270    | 21      |
| FIRST_SUPPORTED_SLOT                   | 371             | 371   | 371    | 371    | 5       |
| GI_FIRST_VALIDATOR                     | 194             | 194   | 194    | 194    | 1       |
| GI_FIRST_WITHDRAWAL                    | 304             | 304   | 304    | 304    | 1       |
| GI_HISTORICAL_SUMMARIES                | 238             | 238   | 238    | 238    | 1       |
| LOCATOR                                | 292             | 292   | 292    | 292    | 1       |
| MODULE                                 | 182             | 182   | 182    | 182    | 1       |
| SLOTS_PER_EPOCH                        | 415             | 415   | 415    | 415    | 1       |
| processHistoricalWithdrawalProof       | 73314           | 89118 | 80562  | 137445 | 5       |
| processSlashingProof                   | 48890           | 62236 | 55905  | 81913  | 3       |
| processWithdrawalProof                 | 56380           | 73128 | 70018  | 104102 | 9       |


| src/lib/AssetRecovererLib.sol:AssetRecovererLib contract |                 |       |        |       |         |
|----------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                            | min             | avg   | median | max   | # calls |
| recoverERC1155                                           | 39103           | 39103 | 39103  | 39103 | 1       |
| recoverERC20                                             | 36183           | 36183 | 36183  | 36183 | 4       |
| recoverERC721                                            | 43393           | 43393 | 43393  | 43393 | 1       |
| recoverEther                                             | 1793            | 20813 | 33493  | 33493 | 5       |




