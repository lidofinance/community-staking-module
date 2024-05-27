| src/CSAccounting.sol:CSAccounting contract                          |                 |        |        |        |         |
|---------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                                       | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                             | 1007            | 1007   | 1007   | 1007   | 183     |
| ADD_BOND_CURVE_ROLE                                                 | 369             | 369    | 369    | 369    | 773     |
| MIN_BOND_LOCK_RETENTION_PERIOD                                      | 1195            | 1195   | 1195   | 1195   | 1       |
| PAUSE_ROLE                                                          | 523             | 523    | 523    | 523    | 183     |
| RECOVERER_ROLE                                                      | 1205            | 1205   | 1205   | 1205   | 12      |
| RESET_BOND_CURVE_ROLE                                               | 325             | 325    | 325    | 325    | 1       |
| RESUME_ROLE                                                         | 435             | 435    | 435    | 435    | 183     |
| SET_BOND_CURVE_ROLE                                                 | 567             | 567    | 567    | 567    | 183     |
| SET_DEFAULT_BOND_CURVE_ROLE                                         | 545             | 545    | 545    | 545    | 183     |
| addBondCurve                                                        | 25063           | 123224 | 121868 | 145006 | 338     |
| chargeFee                                                           | 22381           | 48972  | 48972  | 75563  | 2       |
| chargeRecipient                                                     | 1504            | 1504   | 1504   | 1504   | 1       |
| claimRewardsStETH                                                   | 26787           | 85164  | 97949  | 105697 | 16      |
| claimRewardsWstETH                                                  | 25885           | 118336 | 156595 | 158898 | 16      |
| compensateLockedBondETH                                             | 47773           | 47773  | 47773  | 47773  | 1       |
| defaultBondCurveId                                                  | 1638            | 1638   | 1638   | 1638   | 1       |
| depositETH                                                          | 24357           | 111534 | 113541 | 113781 | 105     |
| depositStETH                                                        | 25479           | 85940  | 104308 | 108512 | 8       |
| depositWstETH                                                       | 26557           | 95606  | 121936 | 125868 | 7       |
| feeDistributor                                                      | 425             | 1758   | 2425   | 2425   | 3       |
| getActualLockedBond                                                 | 1923            | 1995   | 2020   | 2020   | 8       |
| getBondAmountByKeysCount                                            | 1652            | 1906   | 1821   | 2084   | 283     |
| getBondAmountByKeysCountWstETH(uint256)                             | 5269            | 11108  | 5532   | 28100  | 4       |
| getBondAmountByKeysCountWstETH(uint256,(uint256,uint256[],uint256)) | 4121            | 12069  | 15051  | 15051  | 11      |
| getBondCurve                                                        | 2797            | 16540  | 16899  | 16899  | 297     |
| getBondLockRetentionPeriod                                          | 1654            | 2987   | 3654   | 3654   | 3       |
| getBondShares                                                       | 516             | 610    | 516    | 2516   | 106     |
| getBondSummary                                                      | 14752           | 23553  | 22104  | 30604  | 12      |
| getBondSummaryShares                                                | 14161           | 22962  | 21513  | 30013  | 12      |
| getCurveInfo                                                        | 3198            | 3198   | 3198   | 3198   | 1       |
| getLockedBondInfo                                                   | 1472            | 1472   | 1472   | 1472   | 13      |
| getRequiredBondForNextKeys                                          | 9949            | 25777  | 25093  | 37238  | 43      |
| getRequiredBondForNextKeysWstETH                                    | 23313           | 34470  | 30628  | 42232  | 20      |
| getUnbondedKeysCount                                                | 2698            | 14992  | 8676   | 31235  | 479     |
| getUnbondedKeysCountToEject                                         | 5653            | 10461  | 7247   | 19602  | 37      |
| grantRole                                                           | 29761           | 102403 | 118849 | 118849 | 1691    |
| initialize                                                          | 209167          | 534229 | 536195 | 536195 | 499     |
| isPaused                                                            | 1427            | 1827   | 1427   | 3427   | 5       |
| lockBondETH                                                         | 22991           | 69778  | 71574  | 71598  | 27      |
| pauseFor                                                            | 25465           | 46880  | 49022  | 49022  | 11      |
| penalize                                                            | 23019           | 35797  | 35797  | 48576  | 2       |
| recoverERC20                                                        | 25218           | 36645  | 25225  | 59492  | 3       |
| recoverEther                                                        | 24247           | 37823  | 28762  | 60462  | 3       |
| recoverStETHShares                                                  | 24313           | 43996  | 43996  | 63680  | 2       |
| releaseLockedBondETH                                                | 22969           | 27950  | 27950  | 32931  | 2       |
| requestRewardsETH                                                   | 25929           | 69003  | 72607  | 80355  | 16      |
| resetBondCurve                                                      | 24351           | 26268  | 26268  | 28185  | 2       |
| resume                                                              | 23795           | 26715  | 26715  | 29636  | 2       |
| setBondCurve                                                        | 25218           | 49881  | 51003  | 51003  | 23      |
| setChargeRecipient                                                  | 25418           | 27469  | 25447  | 31544  | 3       |
| setDefaultBondCurve                                                 | 25463           | 29575  | 29575  | 33688  | 2       |
| setLockedBondRetentionPeriod                                        | 30978           | 30978  | 30978  | 30978  | 1       |
| settleLockedBondETH                                                 | 44398           | 44398  | 44398  | 44398  | 1       |
| totalBondShares                                                     | 978             | 1089   | 978    | 2978   | 54      |


| src/CSEarlyAdoption.sol:CSEarlyAdoption contract |                 |       |        |       |         |
|--------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                    | min             | avg   | median | max   | # calls |
| CURVE_ID                                         | 238             | 238   | 238    | 238   | 4       |
| MODULE                                           | 217             | 217   | 217    | 217   | 1       |
| TREE_ROOT                                        | 216             | 216   | 216    | 216   | 1       |
| consume                                          | 22792           | 34363 | 25767  | 47074 | 7       |
| consumed                                         | 615             | 615   | 615    | 615   | 1       |
| isEligible                                       | 1361            | 1361  | 1361   | 1361  | 2       |


| src/CSFeeDistributor.sol:CSFeeDistributor contract |                 |        |        |        |         |
|----------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                      | min             | avg    | median | max    | # calls |
| RECOVERER_ROLE                                     | 644             | 644    | 644    | 644    | 7       |
| distributeFees                                     | 22300           | 42573  | 27795  | 76195  | 6       |
| distributedShares                                  | 963             | 1963   | 1963   | 2963   | 4       |
| getFeesToDistribute                                | 1774            | 2774   | 2774   | 3774   | 2       |
| grantRole                                          | 118674          | 118674 | 118674 | 118674 | 5       |
| hashLeaf                                           | 853             | 853    | 853    | 853    | 1       |
| initialize                                         | 45213           | 213238 | 230039 | 230039 | 22      |
| pendingToDistribute                                | 2068            | 2068   | 2068   | 2068   | 1       |
| processOracleReport                                | 32945           | 76781  | 98282  | 98306  | 15      |
| recoverERC20                                       | 24784           | 36211  | 24791  | 59058  | 3       |
| recoverEther                                       | 23961           | 42068  | 42068  | 60176  | 2       |
| treeCid                                            | 3460            | 3460   | 3460   | 3460   | 1       |
| treeRoot                                           | 315             | 1315   | 1315   | 2315   | 2       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| CONTRACT_MANAGER_ROLE                    | 798             | 798    | 798    | 798    | 10      |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 930             | 930    | 930    | 930    | 10      |
| MANAGE_CONSENSUS_VERSION_ROLE            | 776             | 776    | 776    | 776    | 10      |
| PAUSE_ROLE                               | 446             | 446    | 446    | 446    | 10      |
| RESUME_ROLE                              | 336             | 336    | 336    | 336    | 10      |
| SUBMIT_DATA_ROLE                         | 468             | 468    | 468    | 468    | 18      |
| feeDistributor                           | 403             | 403    | 403    | 403    | 1       |
| getConsensusReport                       | 1297            | 2260   | 1335   | 3297   | 21      |
| getConsensusVersion                      | 690             | 1780   | 2690   | 2690   | 11      |
| getLastProcessingRefSlot                 | 536             | 2373   | 2536   | 2536   | 37      |
| grantRole                                | 101618          | 115698 | 118718 | 118718 | 68      |
| initialize                               | 23474           | 225404 | 245597 | 245597 | 11      |
| pauseFor                                 | 48459           | 48459  | 48459  | 48459  | 2       |
| pauseUntil                               | 48232           | 48232  | 48232  | 48232  | 1       |
| perfThresholdBP                          | 580             | 580    | 580    | 580    | 1       |
| resume                                   | 23466           | 26653  | 26653  | 29841  | 2       |
| setFeeDistributorContract                | 24894           | 28086  | 28086  | 31278  | 2       |
| setPerformanceThreshold                  | 24730           | 27750  | 27750  | 30770  | 2       |
| submitReportData                         | 25417           | 45442  | 35646  | 70367  | 5       |


| src/CSModule.sol:CSModule contract                  |                 |        |        |         |         |
|-----------------------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                                       | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                                  | 1469            | 1469   | 1469   | 1469    | 1       |
| EL_REWARDS_STEALING_FINE                            | 1734            | 1734   | 1734   | 1734    | 24      |
| INITIAL_SLASHING_PENALTY                            | 1956            | 1956   | 1956   | 1956    | 4       |
| LIDO_LOCATOR                                        | 1977            | 1977   | 1977   | 1977    | 2       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 568             | 568    | 568    | 568     | 3       |
| MODULE_MANAGER_ROLE                                 | 1832            | 1832   | 1832   | 1832    | 320     |
| PAUSE_ROLE                                          | 490             | 490    | 490    | 490     | 278     |
| RECOVERER_ROLE                                      | 1612            | 1612   | 1612   | 1612    | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 1150            | 1150   | 1150   | 1150    | 279     |
| RESUME_ROLE                                         | 380             | 380    | 380    | 380     | 314     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 534             | 534    | 534    | 534     | 279     |
| STAKING_ROUTER_ROLE                                 | 1062            | 1062   | 1062   | 1062    | 301     |
| VERIFIER_ROLE                                       | 2030            | 2030   | 2030   | 2030    | 282     |
| accounting                                          | 1526            | 1526   | 1526   | 1526    | 1       |
| activatePublicRelease                               | 25423           | 31222  | 31255  | 31255   | 294     |
| addNodeOperatorETH                                  | 28003           | 445536 | 393065 | 1071568 | 278     |
| addNodeOperatorStETH                                | 28434           | 258085 | 289028 | 385643  | 8       |
| addNodeOperatorWstETH                               | 28962           | 282621 | 321774 | 407248  | 8       |
| addValidatorKeysETH                                 | 27493           | 176016 | 231834 | 286964  | 12      |
| addValidatorKeysStETH                               | 27479           | 125501 | 101547 | 219289  | 6       |
| addValidatorKeysWstETH                              | 27589           | 145401 | 144981 | 237763  | 6       |
| cancelELRewardsStealingPenalty                      | 26653           | 71108  | 83681  | 90417   | 4       |
| claimRewardsStETH                                   | 25903           | 55105  | 56177  | 82165   | 4       |
| claimRewardsWstETH                                  | 25463           | 53596  | 54667  | 79586   | 4       |
| cleanDepositQueue                                   | 25336           | 41613  | 41591  | 62263   | 13      |
| compensateELRewardsStealingPenalty                  | 24396           | 84038  | 101673 | 108411  | 4       |
| confirmNodeOperatorManagerAddressChange             | 24398           | 29806  | 29846  | 35097   | 5       |
| confirmNodeOperatorRewardAddressChange              | 24090           | 32311  | 34635  | 34635   | 9       |
| decreaseVettedSigningKeysCount                      | 26368           | 69251  | 84797  | 106700  | 22      |
| depositETH                                          | 24188           | 95835  | 102898 | 125002  | 8       |
| depositQueue                                        | 2284            | 2617   | 2284   | 4284    | 6       |
| depositQueueItem                                    | 1215            | 1881   | 1215   | 3215    | 12      |
| depositStETH                                        | 26370           | 80596  | 87348  | 109443  | 5       |
| depositWstETH                                       | 24964           | 94760  | 106437 | 125641  | 5       |
| earlyAdoption                                       | 492             | 492    | 492    | 492     | 1       |
| getActiveNodeOperatorsCount                         | 1231            | 1231   | 1231   | 1231    | 2       |
| getNodeOperator                                     | 3363            | 6304   | 7363   | 7363    | 68      |
| getNodeOperatorIds                                  | 1075            | 1531   | 1480   | 2232    | 8       |
| getNodeOperatorIsActive                             | 1107            | 1107   | 1107   | 1107    | 1       |
| getNodeOperatorNonWithdrawnKeys                     | 1645            | 1749   | 1645   | 3645    | 534     |
| getNodeOperatorSummary                              | 10187           | 10460  | 10367  | 10698   | 25      |
| getNodeOperatorsCount                               | 1693            | 1693   | 1693   | 1693    | 271     |
| getNonce                                            | 1919            | 2069   | 1919   | 3919    | 80      |
| getSigningKeys                                      | 1196            | 3396   | 4169   | 4169    | 7       |
| getSigningKeysWithSignatures                        | 1004            | 3660   | 3530   | 6448    | 3       |
| getStakingModuleSummary                             | 1609            | 1609   | 1609   | 1609    | 20      |
| getType                                             | 246             | 246    | 246    | 246     | 2       |
| grantRole                                           | 27216           | 104117 | 118761 | 118761  | 2036    |
| hasRole                                             | 1808            | 1808   | 1808   | 1808    | 3       |
| initialize                                          | 359204          | 419419 | 419612 | 419612  | 315     |
| isPaused                                            | 1790            | 2123   | 1790   | 3790    | 6       |
| isValidatorSlashed                                  | 802             | 802    | 802    | 802     | 1       |
| isValidatorWithdrawn                                | 1077            | 1077   | 1077   | 1077    | 1       |
| keyRemovalCharge                                    | 2009            | 2675   | 2009   | 4009    | 3       |
| normalizeQueue                                      | 30662           | 46713  | 46713  | 62764   | 2       |
| obtainDepositData                                   | 26075           | 78266  | 70337  | 142538  | 65      |
| onExitedAndStuckValidatorsCountsUpdated             | 25485           | 25542  | 25542  | 25599   | 2       |
| onRewardsMinted                                     | 25011           | 46638  | 46084  | 68820   | 3       |
| onWithdrawalCredentialsChanged                      | 24873           | 25659  | 26053  | 26053   | 3       |
| pauseFor                                            | 25883           | 31753  | 32340  | 32340   | 11      |
| proposeNodeOperatorManagerAddressChange             | 25114           | 43628  | 54627  | 54627   | 9       |
| proposeNodeOperatorRewardAddressChange              | 24190           | 46078  | 53691  | 53691   | 13      |
| publicRelease                                       | 2097            | 2097   | 2097   | 2097    | 1       |
| recoverERC20                                        | 59653           | 59653  | 59653  | 59653   | 1       |
| recoverEther                                        | 24291           | 26548  | 26548  | 28806   | 2       |
| recoverStETHShares                                  | 61940           | 61940  | 61940  | 61940   | 1       |
| removeKeys                                          | 24931           | 124624 | 151575 | 224335  | 17      |
| reportELRewardsStealingPenalty                      | 24592           | 119182 | 130418 | 131561  | 36      |
| requestRewardsETH                                   | 25067           | 53840  | 54912  | 80471   | 4       |
| resetNodeOperatorManagerAddress                     | 24376           | 32694  | 32090  | 39483   | 5       |
| resume                                              | 23773           | 29595  | 29614  | 29614   | 315     |
| revokeRole                                          | 41621           | 41621  | 41621  | 41621   | 1       |
| setKeyRemovalCharge                                 | 25567           | 28729  | 28738  | 31550   | 280     |
| settleELRewardsStealingPenalty                      | 24969           | 76944  | 92065  | 119525  | 23      |
| submitInitialSlashing                               | 26042           | 84284  | 112352 | 127197  | 14      |
| submitWithdrawal                                    | 24834           | 92820  | 105152 | 145910  | 17      |
| unsafeUpdateValidatorsCount                         | 26126           | 47021  | 41096  | 91164   | 12      |
| updateExitedValidatorsCount                         | 26070           | 42556  | 49628  | 59934   | 11      |
| updateRefundedValidatorsCount                       | 25426           | 34327  | 37372  | 40184   | 3       |
| updateStuckValidatorsCount                          | 26092           | 57294  | 50213  | 86916   | 13      |
| updateTargetValidatorsLimits                        | 24300           | 78901  | 77823  | 120924  | 41      |


| src/CSVerifier.sol:CSVerifier contract |                 |       |        |        |         |
|----------------------------------------|-----------------|-------|--------|--------|---------|
| Function Name                          | min             | avg   | median | max    | # calls |
| BEACON_ROOTS                           | 281             | 281   | 281    | 281    | 21      |
| FIRST_SUPPORTED_SLOT                   | 349             | 349   | 349    | 349    | 4       |
| initialize                             | 66531           | 66531 | 66531  | 66531  | 17      |
| processHistoricalWithdrawalProof       | 80484           | 98174 | 87732  | 154095 | 5       |
| processSlashingProof                   | 48996           | 63081 | 56011  | 84236  | 3       |
| processWithdrawalProof                 | 56394           | 75474 | 74293  | 108513 | 9       |


| src/lib/AssetRecovererLib.sol:AssetRecovererLib contract |                 |       |        |       |         |
|----------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                            | min             | avg   | median | max   | # calls |
| recoverERC1155                                           | 39103           | 39103 | 39103  | 39103 | 1       |
| recoverERC20                                             | 36183           | 36183 | 36183  | 36183 | 4       |
| recoverERC721                                            | 43393           | 43393 | 43393  | 43393 | 1       |
| recoverEther                                             | 1793            | 20813 | 33493  | 33493 | 5       |




