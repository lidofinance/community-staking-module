| src/CSAccounting.sol:CSAccounting contract                          |                 |        |        |        |         |
|---------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                                       | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                             | 296             | 296    | 296    | 296    | 180     |
| ADD_BOND_CURVE_ROLE                                                 | 274             | 274    | 274    | 274    | 770     |
| MIN_BOND_LOCK_RETENTION_PERIOD                                      | 317             | 317    | 317    | 317    | 1       |
| PAUSE_ROLE                                                          | 339             | 339    | 339    | 339    | 180     |
| RECOVERER_ROLE                                                      | 295             | 295    | 295    | 295    | 12      |
| RESET_BOND_CURVE_ROLE                                               | 318             | 318    | 318    | 318    | 493     |
| RESUME_ROLE                                                         | 251             | 251    | 251    | 251    | 180     |
| SET_BOND_CURVE_ROLE                                                 | 274             | 274    | 274    | 274    | 672     |
| SET_DEFAULT_BOND_CURVE_ROLE                                         | 252             | 252    | 252    | 252    | 180     |
| addBondCurve                                                        | 24663           | 122829 | 121473 | 144611 | 338     |
| chargeFee                                                           | 21724           | 48212  | 48212  | 74700  | 2       |
| chargeRecipient                                                     | 404             | 404    | 404    | 404    | 1       |
| claimRewardsStETH                                                   | 25163           | 81978  | 96667  | 104479 | 16      |
| claimRewardsWstETH                                                  | 25098           | 118039 | 156398 | 158765 | 16      |
| compensateLockedBondETH                                             | 47658           | 47658  | 47658  | 47658  | 1       |
| defaultBondCurveId                                                  | 490             | 490    | 490    | 490    | 1       |
| depositETH                                                          | 24205           | 112199 | 113369 | 113609 | 104     |
| depositStETH                                                        | 25129           | 94160  | 103994 | 107913 | 7       |
| depositWstETH                                                       | 25193           | 105385 | 120216 | 123928 | 6       |
| feeDistributor                                                      | 404             | 1737   | 2404   | 2404   | 3       |
| getActualLockedBond                                                 | 621             | 741    | 782    | 782    | 8       |
| getBondAmountByKeysCount                                            | 1178            | 1430   | 1347   | 1610   | 275     |
| getBondAmountByKeysCountWstETH(uint256)                             | 3965            | 9804   | 4228   | 26796  | 4       |
| getBondAmountByKeysCountWstETH(uint256,(uint256,uint256[],uint256)) | 3386            | 10237  | 14266  | 14316  | 8       |
| getBondCurve                                                        | 2236            | 15966  | 16338  | 16338  | 286     |
| getBondLockRetentionPeriod                                          | 467             | 1800   | 2467   | 2467   | 3       |
| getBondShares                                                       | 604             | 642    | 604    | 2604   | 103     |
| getBondSummary                                                      | 13529           | 22282  | 20817  | 29317  | 12      |
| getBondSummaryShares                                                | 13512           | 22265  | 20800  | 29300  | 12      |
| getCurveInfo                                                        | 2217            | 2217   | 2217   | 2217   | 1       |
| getLockedBondInfo                                                   | 839             | 839    | 839    | 839    | 13      |
| getRequiredBondForNextKeys                                          | 8053            | 24872  | 23896  | 37342  | 43      |
| getRequiredBondForNextKeysWstETH                                    | 23153           | 34578  | 30404  | 43309  | 20      |
| getUnbondedKeysCount                                                | 2692            | 16711  | 9873   | 34373  | 473     |
| getUnbondedKeysCountToEject                                         | 4716            | 9052   | 5611   | 18665  | 37      |
| grantRole                                                           | 29592           | 108230 | 118680 | 118680 | 2657    |
| initialize                                                          | 207490          | 349421 | 350285 | 350285 | 496     |
| isPaused                                                            | 460             | 860    | 460    | 2460   | 5       |
| lockBondETH                                                         | 21826           | 68572  | 70367  | 70391  | 27      |
| pauseFor                                                            | 24065           | 45451  | 47590  | 47590  | 11      |
| penalize                                                            | 21744           | 34485  | 34485  | 47227  | 2       |
| recoverERC20                                                        | 24525           | 35901  | 24532  | 58647  | 3       |
| recoverEther                                                        | 23883           | 37459  | 28398  | 60098  | 3       |
| recoverStETHShares                                                  | 23839           | 43290  | 43290  | 62741  | 2       |
| releaseLockedBondETH                                                | 21804           | 26781  | 26781  | 31758  | 2       |
| requestRewardsETH                                                   | 25121           | 66826  | 72449  | 80261  | 16      |
| resetBondCurve                                                      | 24054           | 25945  | 25945  | 27836  | 2       |
| resume                                                              | 23851           | 26771  | 26771  | 29692  | 2       |
| setBondCurve                                                        | 24215           | 48846  | 49966  | 49966  | 23      |
| setChargeRecipient                                                  | 24104           | 26120  | 24107  | 30151  | 3       |
| setDefaultBondCurve                                                 | 24063           | 28174  | 28174  | 32286  | 2       |
| setLockedBondRetentionPeriod                                        | 30172           | 30172  | 30172  | 30172  | 1       |
| settleLockedBondETH                                                 | 44045           | 44045  | 44045  | 44045  | 1       |
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
| RECOVERER_ROLE                                     | 283             | 283    | 283    | 283    | 7       |
| distributeFees                                     | 22334           | 42675  | 27944  | 76317  | 6       |
| distributedShares                                  | 523             | 1523   | 1523   | 2523   | 4       |
| getFeesToDistribute                                | 1820            | 2820   | 2820   | 3820   | 2       |
| grantRole                                          | 118703          | 118703 | 118703 | 118703 | 15      |
| hashLeaf                                           | 678             | 678    | 678    | 678    | 1       |
| initialize                                         | 44500           | 131773 | 137592 | 137592 | 16      |
| pendingToDistribute                                | 1465            | 1465   | 1465   | 1465   | 1       |
| processOracleReport                                | 32689           | 68161  | 77452  | 77452  | 7       |
| recoverERC20                                       | 24463           | 35842  | 24486  | 58578  | 3       |
| recoverEther                                       | 23787           | 41909  | 41909  | 60032  | 2       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| CONTRACT_MANAGER_ROLE                    | 283             | 283    | 283    | 283    | 14      |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 261             | 261    | 261    | 261    | 14      |
| MANAGE_CONSENSUS_VERSION_ROLE            | 261             | 261    | 261    | 261    | 14      |
| PAUSE_ROLE                               | 262             | 262    | 262    | 262    | 14      |
| RESUME_ROLE                              | 262             | 262    | 262    | 262    | 14      |
| SUBMIT_DATA_ROLE                         | 284             | 284    | 284    | 284    | 27      |
| feeDistributor                           | 448             | 448    | 448    | 448    | 1       |
| getConsensusReport                       | 1041            | 1923   | 1079   | 3041   | 32      |
| getConsensusVersion                      | 427             | 1627   | 2427   | 2427   | 20      |
| getLastProcessingRefSlot                 | 494             | 2290   | 2494   | 2494   | 59      |
| grantRole                                | 101393          | 115318 | 118493 | 118493 | 97      |
| initialize                               | 23134           | 266931 | 284341 | 284353 | 15      |
| pauseFor                                 | 47614           | 47614  | 47614  | 47614  | 2       |
| pauseUntil                               | 47630           | 47630  | 47630  | 47630  | 1       |
| perfThresholdBP                          | 428             | 428    | 428    | 428    | 1       |
| resume                                   | 23535           | 26690  | 26690  | 29845  | 2       |
| setFeeDistributorContract                | 24081           | 27248  | 27248  | 30415  | 2       |
| setPerformanceThreshold                  | 24028           | 27048  | 27048  | 30068  | 2       |
| submitReportData                         | 25486           | 40971  | 44533  | 53601  | 8       |


| src/CSModule.sol:CSModule contract                  |                 |        |        |         |         |
|-----------------------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                                       | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                                  | 327             | 327    | 327    | 327     | 1       |
| DEPOSIT_SIZE                                        | 373             | 373    | 373    | 373     | 13      |
| EL_REWARDS_STEALING_FINE                            | 306             | 306    | 306    | 306     | 23      |
| INITIAL_SLASHING_PENALTY                            | 439             | 439    | 439    | 439     | 4       |
| LIDO_LOCATOR                                        | 304             | 304    | 304    | 304     | 1       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 284             | 284    | 284    | 284     | 2       |
| MODULE_MANAGER_ROLE                                 | 283             | 283    | 283    | 283     | 319     |
| PAUSE_ROLE                                          | 307             | 307    | 307    | 307     | 278     |
| RECOVERER_ROLE                                      | 305             | 305    | 305    | 305     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 371             | 371    | 371    | 371     | 279     |
| RESUME_ROLE                                         | 307             | 307    | 307    | 307     | 278     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 351             | 351    | 351    | 351     | 279     |
| STAKING_ROUTER_ROLE                                 | 315             | 315    | 315    | 315     | 301     |
| VERIFIER_ROLE                                       | 260             | 260    | 260    | 260     | 281     |
| accounting                                          | 492             | 492    | 492    | 492     | 1       |
| activatePublicRelease                               | 23828           | 46620  | 46769  | 46769   | 294     |
| addNodeOperatorETH                                  | 26728           | 583319 | 542984 | 1169739 | 273     |
| addNodeOperatorStETH                                | 27557           | 324893 | 339493 | 535496  | 8       |
| addNodeOperatorWstETH                               | 27556           | 335172 | 348472 | 555399  | 8       |
| addValidatorKeysETH                                 | 25733           | 176201 | 247952 | 303050  | 12      |
| addValidatorKeysStETH                               | 26469           | 119896 | 75836  | 235696  | 6       |
| addValidatorKeysWstETH                              | 26447           | 129178 | 82307  | 253825  | 6       |
| cancelELRewardsStealingPenalty                      | 26298           | 84642  | 91179  | 129913  | 4       |
| claimRewardsStETH                                   | 25121           | 59299  | 60365  | 91347   | 4       |
| claimRewardsWstETH                                  | 25144           | 58727  | 59793  | 90180   | 4       |
| cleanDepositQueue                                   | 21654           | 35068  | 32833  | 53266   | 13      |
| compensateELRewardsStealingPenalty                  | 23725           | 106623 | 127045 | 148679  | 4       |
| confirmNodeOperatorManagerAddressChange             | 23683           | 29055  | 29107  | 34273   | 5       |
| confirmNodeOperatorRewardAddressChange              | 23771           | 35160  | 39080  | 39080   | 9       |
| decreaseOperatorVettedKeys                          | 24949           | 77846  | 89662  | 131640  | 22      |
| depositETH                                          | 23716           | 108706 | 113400 | 165436  | 8       |
| depositQueueItem                                    | 667             | 1333   | 667    | 2667    | 12      |
| depositStETH                                        | 24730           | 93630  | 96688  | 148724  | 5       |
| depositWstETH                                       | 24778           | 107051 | 113948 | 164970  | 5       |
| earlyAdoption                                       | 427             | 427    | 427    | 427     | 1       |
| getActiveNodeOperatorsCount                         | 446             | 446    | 446    | 446     | 2       |
| getNodeOperator                                     | 3898            | 11210  | 13898  | 13898   | 64      |
| getNodeOperatorActiveKeys                           | 946             | 3361   | 2946   | 4946    | 528     |
| getNodeOperatorIds                                  | 756             | 1212   | 1161   | 1913    | 8       |
| getNodeOperatorIsActive                             | 615             | 615    | 615    | 615     | 1       |
| getNodeOperatorRewardAddress                        | 715             | 1684   | 1592   | 2715    | 8       |
| getNodeOperatorSummary                              | 13678           | 14218  | 13892  | 15882   | 25      |
| getNodeOperatorsCount                               | 380             | 380    | 380    | 380     | 266     |
| getNonce                                            | 402             | 552    | 402    | 2402    | 80      |
| getSigningKeys                                      | 800             | 2965   | 3716   | 3716    | 7       |
| getSigningKeysWithSignatures                        | 869             | 3509   | 3402   | 6256    | 3       |
| getStakingModuleSummary                             | 705             | 2830   | 2705   | 4705    | 16      |
| getType                                             | 316             | 316    | 316    | 316     | 1       |
| grantRole                                           | 27125           | 118631 | 118703 | 118703  | 1999    |
| hasRole                                             | 794             | 794    | 794    | 794     | 2       |
| initialize                                          | 142644          | 182795 | 182924 | 182924  | 315     |
| isPaused                                            | 515             | 915    | 515    | 2515    | 5       |
| isValidatorSlashed                                  | 651             | 651    | 651    | 651     | 1       |
| isValidatorWithdrawn                                | 640             | 640    | 640    | 640     | 1       |
| keyRemovalCharge                                    | 361             | 1361   | 1361   | 2361    | 2       |
| normalizeQueue                                      | 30279           | 54777  | 54777  | 79276   | 2       |
| obtainDepositData                                   | 24601           | 109058 | 111140 | 176065  | 62      |
| onExitedAndStuckValidatorsCountsUpdated             | 23743           | 23779  | 23779  | 23815   | 2       |
| onRewardsMinted                                     | 24088           | 45645  | 45056  | 67792   | 3       |
| onWithdrawalCredentialsChanged                      | 23817           | 25299  | 25040  | 27040   | 3       |
| pauseFor                                            | 24067           | 45491  | 47634  | 47634   | 11      |
| proposeNodeOperatorManagerAddressChange             | 24202           | 42645  | 53633  | 53633   | 9       |
| proposeNodeOperatorRewardAddressChange              | 24225           | 34231  | 36579  | 36579   | 13      |
| publicRelease                                       | 474             | 474    | 474    | 474     | 1       |
| queue                                               | 525             | 858    | 525    | 2525    | 6       |
| recoverERC20                                        | 58558           | 58558  | 58558  | 58558   | 1       |
| recoverEther                                        | 23798           | 26076  | 26076  | 28355   | 2       |
| recoverStETHShares                                  | 60910           | 60910  | 60910  | 60910   | 1       |
| removeKeys                                          | 24019           | 133142 | 165051 | 234160  | 16      |
| reportELRewardsStealingPenalty                      | 24363           | 123563 | 129509 | 142239  | 36      |
| requestRewardsETH                                   | 25102           | 59259  | 60325  | 91286   | 4       |
| resetNodeOperatorManagerAddress                     | 23661           | 31913  | 31322  | 38642   | 5       |
| resume                                              | 23787           | 26728  | 26728  | 29670   | 2       |
| revokeRole                                          | 40394           | 40394  | 40394  | 40394   | 1       |
| setKeyRemovalCharge                                 | 24061           | 47092  | 47175  | 47187   | 279     |
| settleELRewardsStealingPenalty                      | 24740           | 84818  | 102266 | 140114  | 23      |
| submitInitialSlashing                               | 24204           | 89872  | 118085 | 122294  | 13      |
| submitWithdrawal                                    | 24341           | 114253 | 123862 | 224976  | 16      |
| unsafeUpdateValidatorsCount                         | 24342           | 59355  | 36017  | 150040  | 10      |
| updateExitedValidatorsCount                         | 24882           | 58578  | 47554  | 110282  | 11      |
| updateRefundedValidatorsCount                       | 24238           | 38158  | 35162  | 55074   | 3       |
| updateStuckValidatorsCount                          | 24904           | 68552  | 60621  | 126766  | 13      |
| updateTargetValidatorsLimits                        | 24413           | 114845 | 126977 | 200717  | 41      |


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




