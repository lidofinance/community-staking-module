| src/CSAccounting.sol:CSAccounting contract                          |                 |        |        |        |         |
|---------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                                       | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                             | 274             | 274    | 274    | 274    | 183     |
| ADD_BOND_CURVE_ROLE                                                 | 340             | 340    | 340    | 340    | 771     |
| MIN_BOND_LOCK_RETENTION_PERIOD                                      | 295             | 295    | 295    | 295    | 1       |
| PAUSE_ROLE                                                          | 295             | 295    | 295    | 295    | 183     |
| RECOVERER_ROLE                                                      | 273             | 273    | 273    | 273    | 12      |
| RESET_BOND_CURVE_ROLE                                               | 296             | 296    | 296    | 296    | 1       |
| RESUME_ROLE                                                         | 296             | 296    | 296    | 296    | 183     |
| SET_BOND_CURVE_ROLE                                                 | 339             | 339    | 339    | 339    | 183     |
| SET_DEFAULT_BOND_CURVE_ROLE                                         | 317             | 317    | 317    | 317    | 183     |
| addBondCurve                                                        | 24597           | 122767 | 121407 | 144545 | 337     |
| chargeFee                                                           | 21788           | 48276  | 48276  | 74764  | 2       |
| chargeRecipient                                                     | 491             | 491    | 491    | 491    | 1       |
| claimRewardsStETH                                                   | 25365           | 81894  | 96480  | 104292 | 16      |
| claimRewardsWstETH                                                  | 25345           | 117972 | 156256 | 158623 | 16      |
| compensateLockedBondETH                                             | 47658           | 47658  | 47658  | 47658  | 1       |
| defaultBondCurveId                                                  | 468             | 468    | 468    | 468    | 1       |
| depositETH                                                          | 24250           | 111235 | 113239 | 113479 | 105     |
| depositStETH                                                        | 25174           | 85465  | 103869 | 107788 | 8       |
| depositWstETH                                                       | 25171           | 93798  | 120015 | 123727 | 7       |
| feeDistributor                                                      | 404             | 1737   | 2404   | 2404   | 3       |
| getActualLockedBond                                                 | 599             | 719    | 760    | 760    | 8       |
| getBondAmountByKeysCount                                            | 1112            | 1363   | 1281   | 1544   | 278     |
| getBondAmountByKeysCountWstETH(uint256)                             | 4032            | 9871   | 4295   | 26863  | 4       |
| getBondAmountByKeysCountWstETH(uint256,(uint256,uint256[],uint256)) | 3364            | 11312  | 14294  | 14294  | 11      |
| getBondCurve                                                        | 2259            | 15996  | 16361  | 16361  | 292     |
| getBondLockRetentionPeriod                                          | 445             | 1778   | 2445   | 2445   | 3       |
| getBondShares                                                       | 604             | 698    | 604    | 2604   | 106     |
| getBondSummary                                                      | 13507           | 22260  | 20795  | 29295  | 12      |
| getBondSummaryShares                                                | 13490           | 22243  | 20778  | 29278  | 12      |
| getCurveInfo                                                        | 2195            | 2195   | 2195   | 2195   | 1       |
| getLockedBondInfo                                                   | 817             | 817    | 817    | 817    | 13      |
| getRequiredBondForNextKeys                                          | 8143            | 24954  | 23963  | 37432  | 43      |
| getRequiredBondForNextKeysWstETH                                    | 23109           | 34539  | 30360  | 43288  | 20      |
| getUnbondedKeysCount                                                | 2692            | 16767  | 9896   | 34396  | 474     |
| getUnbondedKeysCountToEject                                         | 4694            | 9045   | 5612   | 18643  | 37      |
| grantRole                                                           | 29548           | 102223 | 118636 | 118636 | 1689    |
| initialize                                                          | 207490          | 532489 | 534455 | 534467 | 498     |
| isPaused                                                            | 438             | 838    | 438    | 2438   | 5       |
| lockBondETH                                                         | 21804           | 68550  | 70345  | 70369  | 27      |
| pauseFor                                                            | 24043           | 45429  | 47568  | 47568  | 11      |
| penalize                                                            | 21722           | 34463  | 34463  | 47205  | 2       |
| recoverERC20                                                        | 24589           | 35965  | 24596  | 58711  | 3       |
| recoverEther                                                        | 23817           | 37393  | 28332  | 60032  | 3       |
| recoverStETHShares                                                  | 23883           | 43334  | 43334  | 62785  | 2       |
| releaseLockedBondETH                                                | 21782           | 26759  | 26759  | 31736  | 2       |
| requestRewardsETH                                                   | 25300           | 66719  | 72239  | 80051  | 16      |
| resetBondCurve                                                      | 24010           | 25901  | 25901  | 27792  | 2       |
| resume                                                              | 23851           | 26771  | 26771  | 29692  | 2       |
| setBondCurve                                                        | 24193           | 48824  | 49944  | 49944  | 23      |
| setChargeRecipient                                                  | 24192           | 26208  | 24195  | 30239  | 3       |
| setDefaultBondCurve                                                 | 24041           | 28152  | 28152  | 32264  | 2       |
| setLockedBondRetentionPeriod                                        | 30150           | 30150  | 30150  | 30150  | 1       |
| settleLockedBondETH                                                 | 44001           | 44001  | 44001  | 44001  | 1       |
| totalBondShares                                                     | 480             | 591    | 480    | 2480   | 54      |


| src/CSEarlyAdoption.sol:CSEarlyAdoption contract |                 |       |        |       |         |
|--------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                    | min             | avg   | median | max   | # calls |
| CURVE_ID                                         | 238             | 238   | 238    | 238   | 4       |
| MODULE                                           | 182             | 182   | 182    | 182   | 1       |
| TREE_ROOT                                        | 216             | 216   | 216    | 216   | 1       |
| consume                                          | 22780           | 34331 | 25728  | 47035 | 7       |
| consumed                                         | 615             | 615   | 615    | 615   | 1       |
| isEligible                                       | 1322            | 1322  | 1322   | 1322  | 2       |


| src/CSFeeDistributor.sol:CSFeeDistributor contract |                 |        |        |        |         |
|----------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                      | min             | avg    | median | max    | # calls |
| RECOVERER_ROLE                                     | 305             | 305    | 305    | 305    | 7       |
| distributeFees                                     | 22334           | 42675  | 27944  | 76317  | 6       |
| distributedShares                                  | 523             | 1523   | 1523   | 2523   | 4       |
| getFeesToDistribute                                | 1842            | 2842   | 2842   | 3842   | 2       |
| grantRole                                          | 118703          | 118703 | 118703 | 118703 | 5       |
| hashLeaf                                           | 700             | 700    | 700    | 700    | 1       |
| initialize                                         | 44993           | 212973 | 229769 | 229769 | 22      |
| pendingToDistribute                                | 1487            | 1487   | 1487   | 1487   | 1       |
| processOracleReport                                | 32222           | 76050  | 97547  | 97571  | 15      |
| recoverERC20                                       | 24485           | 35864  | 24508  | 58600  | 3       |
| recoverEther                                       | 23809           | 41931  | 41931  | 60054  | 2       |
| treeCid                                            | 3020            | 3020   | 3020   | 3020   | 1       |
| treeRoot                                           | 361             | 1361   | 1361   | 2361   | 2       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| CONTRACT_MANAGER_ROLE                    | 261             | 261    | 261    | 261    | 10      |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 261             | 261    | 261    | 261    | 10      |
| MANAGE_CONSENSUS_VERSION_ROLE            | 239             | 239    | 239    | 239    | 10      |
| PAUSE_ROLE                               | 262             | 262    | 262    | 262    | 10      |
| RESUME_ROLE                              | 262             | 262    | 262    | 262    | 10      |
| SUBMIT_DATA_ROLE                         | 284             | 284    | 284    | 284    | 18      |
| feeDistributor                           | 448             | 448    | 448    | 448    | 1       |
| getConsensusReport                       | 1041            | 2004   | 1079   | 3041   | 21      |
| getConsensusVersion                      | 427             | 1517   | 2427   | 2427   | 11      |
| getLastProcessingRefSlot                 | 494             | 2331   | 2494   | 2494   | 37      |
| grantRole                                | 101559          | 115639 | 118659 | 118659 | 68      |
| initialize                               | 22969           | 224339 | 244476 | 244476 | 11      |
| pauseFor                                 | 47643           | 47643  | 47643  | 47643  | 2       |
| pauseUntil                               | 47659           | 47659  | 47659  | 47659  | 1       |
| perfThresholdBP                          | 428             | 428    | 428    | 428    | 1       |
| resume                                   | 23535           | 26704  | 26704  | 29874  | 2       |
| setFeeDistributorContract                | 24110           | 27277  | 27277  | 30444  | 2       |
| setPerformanceThreshold                  | 24057           | 27077  | 27077  | 30097  | 2       |
| submitReportData                         | 25486           | 45488  | 35680  | 70394  | 5       |


| src/CSModule.sol:CSModule contract                  |                 |        |        |         |         |
|-----------------------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                                       | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                                  | 327             | 327    | 327    | 327     | 1       |
| DEPOSIT_SIZE                                        | 373             | 373    | 373    | 373     | 13      |
| EL_REWARDS_STEALING_FINE                            | 306             | 306    | 306    | 306     | 23      |
| INITIAL_SLASHING_PENALTY                            | 417             | 417    | 417    | 417     | 4       |
| LIDO_LOCATOR                                        | 282             | 282    | 282    | 282     | 1       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 306             | 306    | 306    | 306     | 2       |
| MODULE_MANAGER_ROLE                                 | 261             | 261    | 261    | 261     | 319     |
| PAUSE_ROLE                                          | 307             | 307    | 307    | 307     | 277     |
| RECOVERER_ROLE                                      | 305             | 305    | 305    | 305     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 349             | 349    | 349    | 349     | 278     |
| RESUME_ROLE                                         | 307             | 307    | 307    | 307     | 313     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 351             | 351    | 351    | 351     | 278     |
| STAKING_ROUTER_ROLE                                 | 293             | 293    | 293    | 293     | 300     |
| VERIFIER_ROLE                                       | 403             | 403    | 403    | 403     | 280     |
| accounting                                          | 492             | 492    | 492    | 492     | 1       |
| activatePublicRelease                               | 23806           | 46597  | 46747  | 46747   | 293     |
| addNodeOperatorETH                                  | 26728           | 542467 | 498252 | 1141561 | 273     |
| addNodeOperatorStETH                                | 27665           | 317045 | 350195 | 490865  | 8       |
| addNodeOperatorWstETH                               | 27556           | 339535 | 380468 | 510628  | 8       |
| addValidatorKeysETH                                 | 25733           | 184924 | 247628 | 302687  | 12      |
| addValidatorKeysStETH                               | 26469           | 131131 | 102251 | 235362  | 6       |
| addValidatorKeysWstETH                              | 26447           | 150499 | 144933 | 253304  | 6       |
| cancelELRewardsStealingPenalty                      | 26320           | 84544  | 91077  | 129702  | 4       |
| claimRewardsStETH                                   | 25099           | 58875  | 59941  | 90520   | 4       |
| claimRewardsWstETH                                  | 25166           | 58369  | 59435  | 89442   | 4       |
| cleanDepositQueue                                   | 21654           | 35068  | 32833  | 53266   | 13      |
| compensateELRewardsStealingPenalty                  | 23725           | 106520 | 126943 | 148468  | 4       |
| confirmNodeOperatorManagerAddressChange             | 23705           | 29077  | 29129  | 34295   | 5       |
| confirmNodeOperatorRewardAddressChange              | 23662           | 31851  | 34171  | 34171   | 9       |
| decreaseOperatorVettedKeys                          | 24927           | 77659  | 89469  | 131277  | 22      |
| depositETH                                          | 23738           | 108594 | 113300 | 165117  | 8       |
| depositQueueItem                                    | 689             | 1355   | 689    | 2689    | 12      |
| depositStETH                                        | 24708           | 93470  | 96549  | 148366  | 5       |
| depositWstETH                                       | 24667           | 106778 | 113704 | 164447  | 5       |
| earlyAdoption                                       | 427             | 427    | 427    | 427     | 1       |
| getActiveNodeOperatorsCount                         | 424             | 424    | 424    | 424     | 2       |
| getNodeOperator                                     | 3662            | 12380  | 15662  | 15662   | 64      |
| getNodeOperatorIds                                  | 778             | 1234   | 1183   | 1935    | 8       |
| getNodeOperatorIsActive                             | 546             | 546    | 546    | 546     | 1       |
| getNodeOperatorNonWithdrawnKeys                     | 969             | 3384   | 2969   | 4969    | 529     |
| getNodeOperatorSummary                              | 13679           | 14219  | 13893  | 15883   | 25      |
| getNodeOperatorsCount                               | 380             | 380    | 380    | 380     | 266     |
| getNonce                                            | 380             | 530    | 380    | 2380    | 80      |
| getSigningKeys                                      | 819             | 2893   | 3615   | 3615    | 7       |
| getSigningKeysWithSignatures                        | 888             | 3466   | 3355   | 6155    | 3       |
| getStakingModuleSummary                             | 705             | 2830   | 2705   | 4705    | 16      |
| getType                                             | 316             | 316    | 316    | 316     | 1       |
| grantRole                                           | 27125           | 104061 | 118703 | 118703  | 2029    |
| hasRole                                             | 794             | 794    | 794    | 794     | 2       |
| initialize                                          | 335123          | 395349 | 395543 | 395543  | 314     |
| isPaused                                            | 515             | 848    | 515    | 2515    | 6       |
| isValidatorSlashed                                  | 651             | 651    | 651    | 651     | 1       |
| isValidatorWithdrawn                                | 662             | 662    | 662    | 662     | 1       |
| keyRemovalCharge                                    | 471             | 1471   | 1471   | 2471    | 2       |
| normalizeQueue                                      | 30279           | 54777  | 54777  | 79276   | 2       |
| obtainDepositData                                   | 24601           | 108898 | 110995 | 175775  | 62      |
| onExitedAndStuckValidatorsCountsUpdated             | 23721           | 23757  | 23757  | 23793   | 2       |
| onRewardsMinted                                     | 24066           | 45623  | 45034  | 67770   | 3       |
| onWithdrawalCredentialsChanged                      | 23817           | 25299  | 25040  | 27040   | 3       |
| pauseFor                                            | 24045           | 29924  | 30512  | 30512   | 11      |
| proposeNodeOperatorManagerAddressChange             | 24180           | 42623  | 53611  | 53611   | 9       |
| proposeNodeOperatorRewardAddressChange              | 24225           | 46070  | 53679  | 53679   | 13      |
| publicRelease                                       | 452             | 452    | 452    | 452     | 1       |
| queue                                               | 503             | 836    | 503    | 2503    | 6       |
| recoverERC20                                        | 58536           | 58536  | 58536  | 58536   | 1       |
| recoverEther                                        | 23820           | 26098  | 26098  | 28377   | 2       |
| recoverStETHShares                                  | 60932           | 60932  | 60932  | 60932   | 1       |
| removeKeys                                          | 23997           | 132462 | 163692 | 233887  | 17      |
| reportELRewardsStealingPenalty                      | 24363           | 123419 | 129276 | 142016  | 36      |
| requestRewardsETH                                   | 25102           | 58845  | 59911  | 90458   | 4       |
| resetNodeOperatorManagerAddress                     | 23683           | 31935  | 31344  | 38664   | 5       |
| resume                                              | 23787           | 29651  | 29670  | 29670   | 314     |
| revokeRole                                          | 40376           | 40376  | 40376  | 40376   | 1       |
| setKeyRemovalCharge                                 | 24061           | 47013  | 47175  | 47187   | 279     |
| settleELRewardsStealingPenalty                      | 24740           | 84745  | 102186 | 139954  | 23      |
| submitInitialSlashing                               | 24236           | 89891  | 118169 | 122093  | 13      |
| submitWithdrawal                                    | 24395           | 114234 | 123913 | 224829  | 16      |
| unsafeUpdateValidatorsCount                         | 24320           | 59352  | 35914  | 150132  | 10      |
| updateExitedValidatorsCount                         | 24882           | 58473  | 47485  | 110013  | 11      |
| updateRefundedValidatorsCount                       | 24238           | 38104  | 35081  | 54993   | 3       |
| updateStuckValidatorsCount                          | 24904           | 69926  | 62636  | 128651  | 13      |
| updateTargetValidatorsLimits                        | 24435           | 114742 | 126936 | 200538  | 41      |


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




