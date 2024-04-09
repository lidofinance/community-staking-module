| src/CSAccounting.sol:CSAccounting contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 173     |
| INITIALIZE_ROLE                            | 318             | 318    | 318    | 318    | 173     |
| RESET_BOND_CURVE_ROLE                      | 296             | 296    | 296    | 296    | 213     |
| SET_BOND_CURVE_ROLE                        | 274             | 274    | 274    | 274    | 213     |
| addBondCurve                               | 121324          | 121324 | 121324 | 121324 | 5       |
| feeDistributor                             | 2428            | 2428   | 2428   | 2428   | 2       |
| getActualLockedBond                        | 581             | 687    | 741    | 741    | 3       |
| getBondAmountByKeysCount                   | 1347            | 1439   | 1347   | 1610   | 153     |
| getBondAmountByKeysCountWstETH             | 14195           | 14195  | 14195  | 14195  | 2       |
| getBondCurve                               | 2182            | 15981  | 16278  | 16278  | 157     |
| getBondLockRetentionPeriod                 | 2413            | 2413   | 2413   | 2413   | 2       |
| getLockedBondInfo                          | 815             | 815    | 815    | 815    | 7       |
| getRequiredBondForNextKeys                 | 10152           | 33360  | 52652  | 53178  | 13      |
| getRequiredBondForNextKeysWstETH           | 58979           | 58979  | 58979  | 58979  | 2       |
| getUnbondedKeysCount                       | 7730            | 24242  | 15730  | 46230  | 250     |
| grantRole                                  | 118386          | 118391 | 118386 | 118398 | 772     |
| setFeeDistributor                          | 47545           | 47545  | 47545  | 47545  | 173     |


| src/CSEarlyAdoption.sol:CSEarlyAdoption contract |                 |       |        |       |         |
|--------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                    | min             | avg   | median | max   | # calls |
| consume                                          | 24919           | 37973 | 29967  | 51280 | 7       |
| consumed                                         | 549             | 549   | 549    | 549   | 1       |
| curveId                                          | 284             | 1784  | 2284   | 2284  | 4       |
| isEligible                                       | 1378            | 1378  | 1378   | 1378  | 2       |
| module                                           | 358             | 358   | 358    | 358   | 1       |
| treeRoot                                         | 306             | 306   | 306    | 306   | 1       |


| src/CSFeeDistributor.sol:CSFeeDistributor contract |                 |        |        |        |         |
|----------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                      | min             | avg    | median | max    | # calls |
| ORACLE_ROLE                                        | 263             | 263    | 263    | 263    | 6       |
| RECOVERER_ROLE                                     | 283             | 283    | 283    | 283    | 7       |
| distributeFees                                     | 22284           | 35884  | 27716  | 76223  | 5       |
| distributedShares                                  | 523             | 1523   | 1523   | 2523   | 4       |
| grantRole                                          | 118370          | 118370 | 118370 | 118370 | 11      |
| pendingToDistribute                                | 1432            | 1432   | 1432   | 1432   | 1       |
| processOracleReport                                | 57008           | 72212  | 77280  | 77280  | 4       |
| recoverERC20                                       | 24356           | 35716  | 24382  | 58412  | 3       |
| recoverEther                                       | 23680           | 41818  | 41818  | 59957  | 2       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 284             | 284    | 284    | 284    | 2       |
| MANAGE_CONSENSUS_VERSION_ROLE            | 262             | 262    | 262    | 262    | 2       |
| PAUSE_ROLE                               | 285             | 285    | 285    | 285    | 2       |
| RESUME_ROLE                              | 285             | 285    | 285    | 285    | 2       |
| SUBMIT_DATA_ROLE                         | 262             | 262    | 262    | 262    | 3       |
| getConsensusReport                       | 903             | 1310   | 916    | 2903   | 10      |
| getConsensusVersion                      | 396             | 1729   | 2396   | 2396   | 3       |
| getLastProcessingRefSlot                 | 440             | 2190   | 2440   | 2440   | 8       |
| grantRole                                | 101103          | 115093 | 118203 | 118203 | 11      |
| initialize                               | 260571          | 260577 | 260577 | 260583 | 2       |
| submitReportData                         | 53030           | 53030  | 53030  | 53030  | 1       |


| src/CSModule.sol:CSModule contract      |                 |        |        |         |         |
|-----------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                           | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                      | 305             | 305    | 305    | 305     | 1       |
| DEPOSIT_SIZE                            | 307             | 307    | 307    | 307     | 10      |
| EL_REWARDS_STEALING_FINE                | 306             | 306    | 306    | 306     | 7       |
| INITIALIZE_ROLE                         | 308             | 308    | 308    | 308     | 220     |
| INITIAL_SLASHING_PENALTY                | 395             | 395    | 395    | 395     | 3       |
| MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE  | 293             | 293    | 293    | 293     | 1       |
| MODULE_MANAGER_ROLE                     | 306             | 306    | 306    | 306     | 217     |
| PAUSE_ROLE                              | 285             | 285    | 285    | 285     | 174     |
| PENALIZE_ROLE                           | 307             | 307    | 307    | 307     | 173     |
| RECOVERER_ROLE                          | 283             | 283    | 283    | 283     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE | 286             | 286    | 286    | 286     | 175     |
| RESUME_ROLE                             | 329             | 329    | 329    | 329     | 174     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE | 306             | 306    | 306    | 306     | 175     |
| STAKING_ROUTER_ROLE                     | 315             | 315    | 315    | 315     | 197     |
| VERIFIER_ROLE                           | 327             | 327    | 327    | 327     | 177     |
| accounting                              | 448             | 448    | 448    | 448     | 1       |
| activatePublicRelease                   | 23704           | 46532  | 46655  | 46655   | 187     |
| addNodeOperatorETH                      | 26187           | 601088 | 547221 | 1072383 | 153     |
| addNodeOperatorStETH                    | 26973           | 367360 | 535297 | 539812  | 3       |
| addNodeOperatorWstETH                   | 26952           | 379372 | 553043 | 558122  | 3       |
| addValidatorKeysETH                     | 25615           | 229120 | 259043 | 313460  | 6       |
| addValidatorKeysStETH                   | 26351           | 171276 | 241475 | 246002  | 3       |
| addValidatorKeysWstETH                  | 26351           | 183286 | 259494 | 264015  | 3       |
| cancelELRewardsStealingPenalty          | 26275           | 89632  | 99092  | 134069  | 4       |
| claimRewardsStETH                       | 25046           | 45549  | 27263  | 84338   | 3       |
| claimRewardsWstETH                      | 25067           | 45213  | 27284  | 83290   | 3       |
| cleanDepositQueue                       | 26304           | 36076  | 33834  | 53080   | 12      |
| compensateELRewardsStealingPenalty      | 23644           | 109964 | 153124 | 153124  | 3       |
| confirmNodeOperatorManagerAddressChange | 23712           | 29037  | 29097  | 34186   | 5       |
| confirmNodeOperatorRewardAddressChange  | 23691           | 33081  | 33970  | 38918   | 6       |
| decreaseOperatorVettedKeys              | 24812           | 91368  | 107405 | 155099  | 15      |
| depositQueueItem                        | 624             | 1290   | 624    | 2624    | 12      |
| earlyAdoption                           | 427             | 427    | 427    | 427     | 1       |
| getNodeOperator                         | 2214            | 9973   | 8214   | 20214   | 291     |
| getNodeOperatorSigningKeys              | 819             | 2877   | 3594   | 3594    | 7       |
| getNodeOperatorSummary                  | 1493            | 5404   | 7493   | 7493    | 45      |
| getNodeOperatorsCount                   | 403             | 466    | 403    | 2403    | 314     |
| getNonce                                | 425             | 725    | 425    | 2425    | 40      |
| getStakingModuleSummary                 | 661             | 2794   | 2661   | 4661    | 15      |
| getType                                 | 427             | 427    | 427    | 427     | 1       |
| grantRole                               | 26943           | 51436  | 51451  | 51451   | 1664    |
| hasRole                                 | 770             | 770    | 770    | 770     | 2       |
| isPaused                                | 461             | 861    | 461    | 2461    | 5       |
| normalizeQueue                          | 30233           | 54712  | 54712  | 79191   | 2       |
| obtainDepositData                       | 24497           | 106343 | 96789  | 158584  | 47      |
| onExitedAndStuckValidatorsCountsUpdated | 23670           | 23703  | 23703  | 23736   | 2       |
| onRewardsMinted                         | 23942           | 46944  | 47077  | 69813   | 3       |
| onWithdrawalCredentialsChanged          | 23760           | 25246  | 24989  | 26989   | 3       |
| pauseFor                                | 23988           | 45359  | 47497  | 47497   | 11      |
| proposeNodeOperatorManagerAddressChange | 24187           | 42636  | 53626  | 53626   | 9       |
| proposeNodeOperatorRewardAddressChange  | 24166           | 33434  | 36483  | 36483   | 10      |
| publicRelease                           | 387             | 387    | 387    | 387     | 1       |
| queue                                   | 498             | 831    | 498    | 2498    | 6       |
| recoverERC20                            | 58392           | 58392  | 58392  | 58392   | 1       |
| recoverEther                            | 23703           | 25991  | 25991  | 28280   | 2       |
| recoverStETHShares                      | 62866           | 62866  | 62866  | 62866   | 1       |
| removalCharge                           | 386             | 1386   | 1386   | 2386    | 2       |
| removeKeys                              | 24004           | 145239 | 172258 | 240240  | 15      |
| reportELRewardsStealingPenalty          | 24306           | 122459 | 135996 | 146013  | 16      |
| requestRewardsETH                       | 25043           | 45538  | 27260  | 84311   | 3       |
| resetNodeOperatorManagerAddress         | 23690           | 31835  | 31312  | 38442   | 5       |
| resume                                  | 23730           | 26642  | 26642  | 29555   | 2       |
| revokeRole                              | 29507           | 29507  | 29507  | 29507   | 1       |
| setAccounting                           | 24268           | 46394  | 46497  | 46497   | 216     |
| setEarlyAdoption                        | 23984           | 38612  | 46453  | 46453   | 8       |
| setRemovalCharge                        | 24026           | 47013  | 47146  | 47158   | 175     |
| settleELRewardsStealingPenalty          | 24690           | 67407  | 38696  | 112071  | 7       |
| submitInitialSlashing                   | 24058           | 97644  | 134090 | 134990  | 12      |
| submitWithdrawal                        | 24327           | 121314 | 140970 | 234701  | 14      |
| unsafeUpdateValidatorsCount             | 24263           | 61236  | 35929  | 159791  | 10      |
| updateExitedValidatorsCount             | 24789           | 58490  | 47467  | 110195  | 11      |
| updateRefundedValidatorsCount           | 24136           | 27723  | 27723  | 31310   | 2       |
| updateStuckValidatorsCount              | 24811           | 73018  | 60543  | 138483  | 13      |
| updateTargetValidatorsLimits            | 24324           | 118220 | 137454 | 210374  | 19      |


| src/CSVerifier.sol:CSVerifier contract |                 |        |        |        |         |
|----------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                          | min             | avg    | median | max    | # calls |
| BEACON_ROOTS                           | 260             | 260    | 260    | 260    | 3       |
| initialize                             | 66498           | 66498  | 66498  | 66498  | 3       |
| processHistoricalWithdrawalProof       | 152118          | 152118 | 152118 | 152118 | 1       |
| processSlashingProof                   | 83048           | 83048  | 83048  | 83048  | 1       |
| processWithdrawalProof                 | 107007          | 107007 | 107007 | 107007 | 1       |


| src/lib/AssetRecovererLib.sol:AssetRecovererLib contract |                 |       |        |       |         |
|----------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                            | min             | avg   | median | max   | # calls |
| recoverERC1155                                           | 38590           | 38590 | 38590  | 38590 | 1       |
| recoverERC20                                             | 35969           | 35969 | 35969  | 35969 | 4       |
| recoverERC721                                            | 43274           | 43274 | 43274  | 43274 | 1       |
| recoverEther                                             | 1816            | 20836 | 33516  | 33516 | 5       |




