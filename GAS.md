| src/CSAccounting.sol:CSAccounting contract                          |                 |        |        |        |         |
|---------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                                       | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                             | 296             | 296    | 296    | 296    | 180     |
| ADD_BOND_CURVE_ROLE                                                 | 274             | 274    | 274    | 274    | 770     |
| MIN_BOND_LOCK_RETENTION_PERIOD                                      | 317             | 317    | 317    | 317    | 1       |
| PAUSE_ROLE                                                          | 339             | 339    | 339    | 339    | 180     |
| RECOVERER_ROLE                                                      | 295             | 295    | 295    | 295    | 12      |
| RESET_BOND_CURVE_ROLE                                               | 318             | 318    | 318    | 318    | 1       |
| RESUME_ROLE                                                         | 251             | 251    | 251    | 251    | 180     |
| SET_BOND_CURVE_ROLE                                                 | 274             | 274    | 274    | 274    | 180     |
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
| getRequiredBondForNextKeys                                          | 8076            | 24887  | 23896  | 37365  | 43      |
| getRequiredBondForNextKeysWstETH                                    | 23153           | 34583  | 30404  | 43332  | 20      |
| getUnbondedKeysCount                                                | 2692            | 16734  | 9896   | 34396  | 473     |
| getUnbondedKeysCountToEject                                         | 4716            | 9067   | 5634   | 18665  | 37      |
| grantRole                                                           | 29592           | 102088 | 118680 | 118680 | 1673    |
| initialize                                                          | 207490          | 532481 | 534455 | 534467 | 496     |
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
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 284             | 284    | 284    | 284     | 2       |
| MODULE_MANAGER_ROLE                                 | 261             | 261    | 261    | 261     | 319     |
| PAUSE_ROLE                                          | 307             | 307    | 307    | 307     | 278     |
| RECOVERER_ROLE                                      | 305             | 305    | 305    | 305     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 349             | 349    | 349    | 349     | 279     |
| RESUME_ROLE                                         | 307             | 307    | 307    | 307     | 314     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 351             | 351    | 351    | 351     | 279     |
| STAKING_ROUTER_ROLE                                 | 293             | 293    | 293    | 293     | 301     |
| VERIFIER_ROLE                                       | 403             | 403    | 403    | 403     | 281     |
| accounting                                          | 492             | 492    | 492    | 492     | 1       |
| activatePublicRelease                               | 23806           | 46598  | 46747  | 46747   | 294     |
| addNodeOperatorETH                                  | 26728           | 583160 | 542865 | 1169074 | 273     |
| addNodeOperatorStETH                                | 27665           | 324924 | 339504 | 535485  | 8       |
| addNodeOperatorWstETH                               | 27556           | 335095 | 348375 | 555280  | 8       |
| addValidatorKeysETH                                 | 25733           | 176137 | 247856 | 302915  | 12      |
| addValidatorKeysStETH                               | 26469           | 119852 | 75805  | 235600  | 6       |
| addValidatorKeysWstETH                              | 26447           | 129133 | 82276  | 253729  | 6       |
| cancelELRewardsStealingPenalty                      | 26298           | 84610  | 91136  | 129870  | 4       |
| claimRewardsStETH                                   | 25099           | 59323  | 60389  | 91416   | 4       |
| claimRewardsWstETH                                  | 25144           | 58773  | 59839  | 90271   | 4       |
| cleanDepositQueue                                   | 21632           | 35046  | 32811  | 53244   | 13      |
| compensateELRewardsStealingPenalty                  | 23703           | 106569 | 126980 | 148614  | 4       |
| confirmNodeOperatorManagerAddressChange             | 23683           | 29055  | 29107  | 34273   | 5       |
| confirmNodeOperatorRewardAddressChange              | 23771           | 35160  | 39080  | 39080   | 9       |
| decreaseOperatorVettedKeys                          | 24927           | 77789  | 89597  | 131532  | 22      |
| depositETH                                          | 23716           | 108669 | 113357 | 165393  | 8       |
| depositQueueItem                                    | 667             | 1333   | 667    | 2667    | 12      |
| depositStETH                                        | 24708           | 93573  | 96623  | 148659  | 5       |
| depositWstETH                                       | 24778           | 107021 | 113913 | 164927  | 5       |
| earlyAdoption                                       | 427             | 427    | 427    | 427     | 1       |
| getActiveNodeOperatorsCount                         | 424             | 424    | 424    | 424     | 2       |
| getNodeOperator                                     | 3898            | 11116  | 13898  | 13898   | 64      |
| getNodeOperatorIds                                  | 756             | 1212   | 1161   | 1913    | 8       |
| getNodeOperatorIsActive                             | 615             | 615    | 615    | 615     | 1       |
| getNodeOperatorNonWithdrawnKeys                     | 969             | 3384   | 2969   | 4969    | 528     |
| getNodeOperatorRewardAddress                        | 826             | 1795   | 1703   | 2826    | 8       |
| getNodeOperatorSummary                              | 13701           | 14241  | 13915  | 15905   | 25      |
| getNodeOperatorsCount                               | 380             | 380    | 380    | 380     | 266     |
| getNonce                                            | 380             | 530    | 380    | 2380    | 80      |
| getSigningKeys                                      | 797             | 2871   | 3593   | 3593    | 7       |
| getSigningKeysWithSignatures                        | 866             | 3444   | 3333   | 6133    | 3       |
| getStakingModuleSummary                             | 705             | 2830   | 2705   | 4705    | 16      |
| getType                                             | 316             | 316    | 316    | 316     | 1       |
| grantRole                                           | 27125           | 104061 | 118703 | 118703  | 2035    |
| hasRole                                             | 794             | 794    | 794    | 794     | 2       |
| initialize                                          | 335123          | 395350 | 395543 | 395543  | 315     |
| isPaused                                            | 515             | 848    | 515    | 2515    | 6       |
| isValidatorSlashed                                  | 651             | 651    | 651    | 651     | 1       |
| isValidatorWithdrawn                                | 640             | 640    | 640    | 640     | 1       |
| keyRemovalCharge                                    | 471             | 1471   | 1471   | 2471    | 2       |
| normalizeQueue                                      | 30279           | 54777  | 54777  | 79276   | 2       |
| obtainDepositData                                   | 24601           | 108976 | 111076 | 175856  | 62      |
| onExitedAndStuckValidatorsCountsUpdated             | 23721           | 23757  | 23757  | 23793   | 2       |
| onRewardsMinted                                     | 24066           | 45623  | 45034  | 67770   | 3       |
| onWithdrawalCredentialsChanged                      | 23817           | 25299  | 25040  | 27040   | 3       |
| pauseFor                                            | 24045           | 29924  | 30512  | 30512   | 11      |
| proposeNodeOperatorManagerAddressChange             | 24180           | 42623  | 53611  | 53611   | 9       |
| proposeNodeOperatorRewardAddressChange              | 24225           | 34231  | 36579  | 36579   | 13      |
| publicRelease                                       | 452             | 452    | 452    | 452     | 1       |
| queue                                               | 503             | 836    | 503    | 2503    | 6       |
| recoverERC20                                        | 58536           | 58536  | 58536  | 58536   | 1       |
| recoverEther                                        | 23798           | 26076  | 26076  | 28355   | 2       |
| recoverStETHShares                                  | 60910           | 60910  | 60910  | 60910   | 1       |
| removeKeys                                          | 23997           | 133020 | 164911 | 233971  | 16      |
| reportELRewardsStealingPenalty                      | 24363           | 123530 | 129466 | 142196  | 36      |
| requestRewardsETH                                   | 25102           | 59305  | 60371  | 91377   | 4       |
| resetNodeOperatorManagerAddress                     | 23661           | 31913  | 31322  | 38642   | 5       |
| resume                                              | 23787           | 29651  | 29670  | 29670   | 315     |
| revokeRole                                          | 40376           | 40376  | 40376  | 40376   | 1       |
| setKeyRemovalCharge                                 | 24061           | 47092  | 47175  | 47187   | 279     |
| settleELRewardsStealingPenalty                      | 24740           | 84792  | 102223 | 140028  | 23      |
| submitInitialSlashing                               | 24236           | 89904  | 118140 | 122283  | 13      |
| submitWithdrawal                                    | 24373           | 114253 | 123851 | 224965  | 16      |
| unsafeUpdateValidatorsCount                         | 24320           | 59380  | 35995  | 150159  | 10      |
| updateExitedValidatorsCount                         | 24882           | 58525  | 47566  | 110094  | 11      |
| updateRefundedValidatorsCount                       | 24238           | 38158  | 35162  | 55074   | 3       |
| updateStuckValidatorsCount                          | 24904           | 69989  | 62717  | 128819  | 13      |
| updateTargetValidatorsLimits                        | 24413           | 114807 | 126934 | 200674  | 41      |


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




