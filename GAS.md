| src/CSAccounting.sol:CSAccounting contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 230     |
| INITIALIZE_ROLE                            | 296             | 296    | 296    | 296    | 230     |
| RESET_BOND_CURVE_ROLE                      | 296             | 296    | 296    | 296    | 270     |
| SET_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 270     |
| addBondCurve                               | 121336          | 127946 | 121336 | 144474 | 7       |
| feeDistributor                             | 2428            | 2428   | 2428   | 2428   | 2       |
| getActualLockedBond                        | 581             | 687    | 741    | 741    | 3       |
| getBondAmountByKeysCount                   | 1347            | 1429   | 1347   | 1610   | 234     |
| getBondAmountByKeysCountWstETH             | 14217           | 14217  | 14217  | 14217  | 2       |
| getBondCurve                               | 2182            | 15967  | 16278  | 16278  | 240     |
| getBondLockRetentionPeriod                 | 2370            | 2370   | 2370   | 2370   | 3       |
| getBondShares                              | 563             | 563    | 563    | 563    | 10      |
| getLockedBondInfo                          | 815             | 815    | 815    | 815    | 11      |
| getRequiredBondForNextKeys                 | 9959            | 31613  | 50459  | 51134  | 19      |
| getRequiredBondForNextKeysWstETH           | 56979           | 56979  | 56979  | 56979  | 2       |
| getUnbondedKeysCount                       | 7730            | 24164  | 15730  | 46230  | 391     |
| getUnbondedKeysCountToEject                | 7069            | 7428   | 7427   | 7486   | 51      |
| grantRole                                  | 118386          | 118391 | 118386 | 118398 | 1000    |
| setBondCurve                               | 49830           | 49830  | 49830  | 49830  | 2       |
| setFeeDistributor                          | 47567           | 47567  | 47567  | 47567  | 230     |


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
| ORACLE_ROLE                                        | 263             | 263    | 263    | 263    | 7       |
| RECOVERER_ROLE                                     | 283             | 283    | 283    | 283    | 7       |
| distributeFees                                     | 22284           | 35884  | 27716  | 76223  | 5       |
| distributedShares                                  | 523             | 1523   | 1523   | 2523   | 4       |
| grantRole                                          | 118370          | 118370 | 118370 | 118370 | 12      |
| pendingToDistribute                                | 1432            | 1432   | 1432   | 1432   | 1       |
| processOracleReport                                | 32516           | 64272  | 77280  | 77280  | 5       |
| recoverERC20                                       | 24356           | 35716  | 24382  | 58412  | 3       |
| recoverEther                                       | 23680           | 41818  | 41818  | 59957  | 2       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 284             | 284    | 284    | 284    | 12      |
| MANAGE_CONSENSUS_VERSION_ROLE            | 262             | 262    | 262    | 262    | 12      |
| MANAGE_FEE_DISTRIBUTOR_CONTRACT_ROLE     | 261             | 261    | 261    | 261    | 12      |
| PAUSE_ROLE                               | 285             | 285    | 285    | 285    | 12      |
| RESUME_ROLE                              | 285             | 285    | 285    | 285    | 12      |
| SUBMIT_DATA_ROLE                         | 262             | 262    | 262    | 262    | 27      |
| getConsensusReport                       | 903             | 1708   | 929    | 2903   | 30      |
| getConsensusVersion                      | 396             | 1596   | 2396   | 2396   | 20      |
| getLastProcessingRefSlot                 | 440             | 2229   | 2440   | 2440   | 57      |
| grantRole                                | 101103          | 114665 | 118203 | 118203 | 87      |
| initialize                               | 22907           | 242291 | 260571 | 260583 | 13      |
| pauseFor                                 | 47435           | 47435  | 47435  | 47435  | 2       |
| pauseUntil                               | 47451           | 47451  | 47451  | 47451  | 1       |
| resume                                   | 23520           | 26610  | 26610  | 29701  | 2       |
| setFeeDistributorContract                | 23966           | 27011  | 27011  | 30057  | 2       |
| submitReportData                         | 25414           | 40569  | 43980  | 53030  | 8       |


| src/CSModule.sol:CSModule contract                  |                 |        |        |         |         |
|-----------------------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                                       | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                                  | 327             | 327    | 327    | 327     | 1       |
| DEPOSIT_SIZE                                        | 285             | 285    | 285    | 285     | 12      |
| EL_REWARDS_STEALING_FINE                            | 328             | 328    | 328    | 328     | 12      |
| INITIALIZE_ROLE                                     | 285             | 285    | 285    | 285     | 278     |
| INITIAL_SLASHING_PENALTY                            | 352             | 352    | 352    | 352     | 4       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 308             | 308    | 308    | 308     | 1       |
| MODULE_MANAGER_ROLE                                 | 328             | 328    | 328    | 328     | 274     |
| PAUSE_ROLE                                          | 285             | 285    | 285    | 285     | 231     |
| RECOVERER_ROLE                                      | 285             | 285    | 285    | 285     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 285             | 285    | 285    | 285     | 232     |
| RESUME_ROLE                                         | 329             | 329    | 329    | 329     | 231     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 284             | 284    | 284    | 284     | 232     |
| STAKING_ROUTER_ROLE                                 | 340             | 340    | 340    | 340     | 254     |
| VERIFIER_ROLE                                       | 327             | 327    | 327    | 327     | 234     |
| accounting                                          | 426             | 426    | 426    | 426     | 2       |
| activatePublicRelease                               | 23726           | 46498  | 46677  | 46677   | 245     |
| addNodeOperatorETH                                  | 26187           | 585741 | 545541 | 1171678 | 234     |
| addNodeOperatorStETH                                | 26973           | 366248 | 533629 | 538144  | 3       |
| addNodeOperatorWstETH                               | 26952           | 378289 | 551419 | 556498  | 3       |
| addValidatorKeysETH                                 | 25615           | 218719 | 257274 | 312217  | 9       |
| addValidatorKeysStETH                               | 26374           | 170482 | 240273 | 244800  | 3       |
| addValidatorKeysWstETH                              | 26373           | 182536 | 258357 | 262878  | 3       |
| cancelELRewardsStealingPenalty                      | 26275           | 92373  | 101831 | 139556  | 4       |
| claimRewardsStETH                                   | 25050           | 50597  | 27267  | 99476   | 3       |
| claimRewardsWstETH                                  | 25072           | 50250  | 27289  | 98389   | 3       |
| cleanDepositQueue                                   | 21603           | 34982  | 32752  | 53101   | 13      |
| compensateELRewardsStealingPenalty                  | 23665           | 114352 | 137706 | 158331  | 4       |
| confirmNodeOperatorManagerAddressChange             | 23712           | 29037  | 29097  | 34186   | 5       |
| confirmNodeOperatorRewardAddressChange              | 23669           | 33059  | 33948  | 38896   | 6       |
| decreaseOperatorVettedKeys                          | 24834           | 87441  | 101417 | 155251  | 22      |
| depositETH                                          | 23678           | 118641 | 125043 | 175078  | 8       |
| depositQueueItem                                    | 645             | 1311   | 645    | 2645    | 12      |
| depositStETH                                        | 24649           | 102462 | 108275 | 158310  | 5       |
| depositWstETH                                       | 24696           | 115481 | 124542 | 174577  | 5       |
| earlyAdoption                                       | 427             | 427    | 427    | 427     | 1       |
| getActiveNodeOperatorsCount                         | 426             | 426    | 426    | 426     | 2       |
| getNodeOperator                                     | 2214            | 9258   | 8214   | 18214   | 494     |
| getNodeOperatorIds                                  | 788             | 1238   | 1187   | 1933    | 8       |
| getNodeOperatorIsActive                             | 593             | 593    | 593    | 593     | 1       |
| getNodeOperatorSigningKeys                          | 819             | 2877   | 3594   | 3594    | 7       |
| getNodeOperatorSummary                              | 9522            | 13429  | 15522  | 15522   | 51      |
| getNodeOperatorsCount                               | 424             | 432    | 424    | 2424    | 233     |
| getNonce                                            | 380             | 533    | 380    | 2380    | 78      |
| getStakingModuleSummary                             | 639             | 2772   | 2639   | 4639    | 15      |
| getType                                             | 327             | 327    | 327    | 327     | 1       |
| grantRole                                           | 26943           | 51438  | 51451  | 51451   | 1948    |
| hasRole                                             | 726             | 726    | 726    | 726     | 2       |
| isPaused                                            | 418             | 818    | 418    | 2418    | 5       |
| isValidatorSlashed                                  | 651             | 651    | 651    | 651     | 1       |
| isValidatorWithdrawn                                | 617             | 617    | 617    | 617     | 1       |
| normalizeQueue                                      | 30235           | 54714  | 54714  | 79193   | 2       |
| obtainDepositData                                   | 24453           | 109094 | 109488 | 175598  | 54      |
| onExitedAndStuckValidatorsCountsUpdated             | 23670           | 23703  | 23703  | 23736   | 2       |
| onRewardsMinted                                     | 23963           | 46965  | 47098  | 69834   | 3       |
| onWithdrawalCredentialsChanged                      | 23781           | 25267  | 25010  | 27010   | 3       |
| pauseFor                                            | 23988           | 45359  | 47497  | 47497   | 11      |
| proposeNodeOperatorManagerAddressChange             | 24142           | 42591  | 53581  | 53581   | 9       |
| proposeNodeOperatorRewardAddressChange              | 24166           | 33434  | 36483  | 36483   | 10      |
| publicRelease                                       | 409             | 409    | 409    | 409     | 2       |
| queue                                               | 520             | 853    | 520    | 2520    | 6       |
| recoverERC20                                        | 58414           | 58414  | 58414  | 58414   | 1       |
| recoverEther                                        | 23747           | 26035  | 26035  | 28324   | 2       |
| recoverStETHShares                                  | 62867           | 62867  | 62867  | 62867   | 1       |
| removalCharge                                       | 386             | 1386   | 1386   | 2386    | 2       |
| removeKeys                                          | 24026           | 145254 | 172268 | 240250  | 15      |
| reportELRewardsStealingPenalty                      | 24327           | 131688 | 141190 | 151207  | 29      |
| requestRewardsETH                                   | 25051           | 50584  | 27268  | 99435   | 3       |
| resetNodeOperatorManagerAddress                     | 23690           | 31835  | 31312  | 38442   | 5       |
| resume                                              | 23730           | 26642  | 26642  | 29555   | 2       |
| revokeRole                                          | 29529           | 29529  | 29529  | 29529   | 1       |
| setAccounting                                       | 24226           | 46301  | 46455  | 46455   | 275     |
| setEarlyAdoption                                    | 24006           | 38634  | 46475  | 46475   | 8       |
| setRemovalCharge                                    | 24025           | 47045  | 47145  | 47157   | 232     |
| settleELRewardsStealingPenalty                      | 24668           | 85219  | 111468 | 162702  | 15      |
| submitInitialSlashing                               | 24058           | 97708  | 129465 | 133674  | 13      |
| submitWithdrawal                                    | 24305           | 121478 | 135793 | 234734  | 15      |
| unsafeUpdateValidatorsCount                         | 24263           | 61233  | 35920  | 159794  | 10      |
| updateExitedValidatorsCount                         | 24832           | 58533  | 47510  | 110238  | 11      |
| updateRefundedValidatorsCount                       | 24091           | 27678  | 27678  | 31265   | 2       |
| updateStuckValidatorsCount                          | 24788           | 72999  | 60511  | 138507  | 13      |
| updateTargetValidatorsLimits                        | 24310           | 119625 | 128091 | 210409  | 28      |


| src/CSVerifier.sol:CSVerifier contract |                 |       |        |        |         |
|----------------------------------------|-----------------|-------|--------|--------|---------|
| Function Name                          | min             | avg   | median | max    | # calls |
| BEACON_ROOTS                           | 260             | 260   | 260    | 260    | 21      |
| FIRST_SUPPORTED_SLOT                   | 226             | 226   | 226    | 226    | 4       |
| initialize                             | 66498           | 66498 | 66498  | 66498  | 17      |
| processHistoricalWithdrawalProof       | 80216           | 97451 | 87201  | 152118 | 5       |
| processSlashingProof                   | 48728           | 62430 | 55516  | 83048  | 3       |
| processWithdrawalProof                 | 56326           | 74945 | 73902  | 107007 | 9       |


| src/lib/AssetRecovererLib.sol:AssetRecovererLib contract |                 |       |        |       |         |
|----------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                            | min             | avg   | median | max   | # calls |
| recoverERC1155                                           | 38590           | 38590 | 38590  | 38590 | 1       |
| recoverERC20                                             | 35969           | 35969 | 35969  | 35969 | 4       |
| recoverERC721                                            | 43274           | 43274 | 43274  | 43274 | 1       |
| recoverEther                                             | 1816            | 20836 | 33516  | 33516 | 5       |




