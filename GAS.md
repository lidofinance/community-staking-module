| src/CSAccounting.sol:CSAccounting contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 194     |
| INITIALIZE_ROLE                            | 296             | 296    | 296    | 296    | 194     |
| RESET_BOND_CURVE_ROLE                      | 296             | 296    | 296    | 296    | 234     |
| SET_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 234     |
| addBondCurve                               | 121336          | 127946 | 121336 | 144474 | 7       |
| feeDistributor                             | 2428            | 2428   | 2428   | 2428   | 2       |
| getActualLockedBond                        | 581             | 687    | 741    | 741    | 3       |
| getBondAmountByKeysCount                   | 1347            | 1432   | 1347   | 1610   | 175     |
| getBondAmountByKeysCountWstETH             | 14217           | 14217  | 14217  | 14217  | 2       |
| getBondCurve                               | 2182            | 15866  | 16278  | 16278  | 181     |
| getBondLockRetentionPeriod                 | 2370            | 2370   | 2370   | 2370   | 3       |
| getBondShares                              | 563             | 563    | 563    | 563    | 10      |
| getLockedBondInfo                          | 815             | 815    | 815    | 815    | 10      |
| getRequiredBondForNextKeys                 | 9959            | 31761  | 50459  | 51134  | 17      |
| getRequiredBondForNextKeysWstETH           | 56979           | 56979  | 56979  | 56979  | 2       |
| getUnbondedKeysCount                       | 7730            | 24566  | 15730  | 46230  | 312     |
| grantRole                                  | 118386          | 118391 | 118386 | 118398 | 856     |
| setBondCurve                               | 49830           | 49830  | 49830  | 49830  | 2       |
| setFeeDistributor                          | 47567           | 47567  | 47567  | 47567  | 194     |


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


| src/CSModule.sol:CSModule contract                  |                 |        |        |         |         |
|-----------------------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                                       | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                                  | 305             | 305    | 305    | 305     | 1       |
| DEPOSIT_SIZE                                        | 285             | 285    | 285    | 285     | 12      |
| EL_REWARDS_STEALING_FINE                            | 328             | 328    | 328    | 328     | 12      |
| INITIALIZE_ROLE                                     | 285             | 285    | 285    | 285     | 241     |
| INITIAL_SLASHING_PENALTY                            | 352             | 352    | 352    | 352     | 4       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 308             | 308    | 308    | 308     | 1       |
| MODULE_MANAGER_ROLE                                 | 328             | 328    | 328    | 328     | 238     |
| PAUSE_ROLE                                          | 285             | 285    | 285    | 285     | 195     |
| RECOVERER_ROLE                                      | 285             | 285    | 285    | 285     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 329             | 329    | 329    | 329     | 196     |
| RESUME_ROLE                                         | 329             | 329    | 329    | 329     | 195     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 284             | 284    | 284    | 284     | 196     |
| STAKING_ROUTER_ROLE                                 | 318             | 318    | 318    | 318     | 218     |
| VERIFIER_ROLE                                       | 327             | 327    | 327    | 327     | 198     |
| accounting                                          | 449             | 449    | 449    | 449     | 1       |
| activatePublicRelease                               | 23726           | 46566  | 46677  | 46677   | 208     |
| addNodeOperatorETH                                  | 26187           | 592819 | 545541 | 1070703 | 175     |
| addNodeOperatorStETH                                | 26973           | 366226 | 533595 | 538110  | 3       |
| addNodeOperatorWstETH                               | 26952           | 378267 | 551385 | 556464  | 3       |
| addValidatorKeysETH                                 | 25615           | 235358 | 257537 | 312217  | 8       |
| addValidatorKeysStETH                               | 26352           | 170437 | 240217 | 244744  | 3       |
| addValidatorKeysWstETH                              | 26351           | 182491 | 258301 | 262822  | 3       |
| cancelELRewardsStealingPenalty                      | 26275           | 92373  | 101831 | 139556  | 4       |
| claimRewardsStETH                                   | 25028           | 50575  | 27245  | 99454   | 3       |
| claimRewardsWstETH                                  | 25072           | 50250  | 27289  | 98389   | 3       |
| cleanDepositQueue                                   | 26303           | 36075  | 33833  | 53079   | 12      |
| compensateELRewardsStealingPenalty                  | 23643           | 114330 | 137684 | 158309  | 4       |
| confirmNodeOperatorManagerAddressChange             | 23712           | 29037  | 29097  | 34186   | 5       |
| confirmNodeOperatorRewardAddressChange              | 23669           | 33059  | 33948  | 38896   | 6       |
| decreaseOperatorVettedKeys                          | 24834           | 91447  | 107492 | 155251  | 15      |
| depositETH                                          | 23678           | 118641 | 125043 | 175078  | 8       |
| depositQueueItem                                    | 645             | 1311   | 645    | 2645    | 12      |
| depositStETH                                        | 24649           | 102435 | 108241 | 158276  | 5       |
| depositWstETH                                       | 24696           | 115454 | 124508 | 174543  | 5       |
| earlyAdoption                                       | 427             | 427    | 427    | 427     | 1       |
| getNodeOperator                                     | 2214            | 10135  | 8214   | 18214   | 358     |
| getNodeOperatorSigningKeys                          | 819             | 2877   | 3594   | 3594    | 7       |
| getNodeOperatorSummary                              | 1511            | 5422   | 7511   | 7511    | 45      |
| getNodeOperatorsCount                               | 402             | 413    | 402    | 2402    | 173     |
| getNonce                                            | 380             | 533    | 380    | 2380    | 78      |
| getStakingModuleSummary                             | 617             | 2750   | 2617   | 4617    | 15      |
| getType                                             | 327             | 327    | 327    | 327     | 1       |
| grantRole                                           | 26943           | 51436  | 51451  | 51451   | 1659    |
| hasRole                                             | 769             | 769    | 769    | 769     | 2       |
| isPaused                                            | 418             | 818    | 418    | 2418    | 5       |
| normalizeQueue                                      | 30235           | 54714  | 54714  | 79193   | 2       |
| obtainDepositData                                   | 24453           | 106774 | 101269 | 158540  | 49      |
| onExitedAndStuckValidatorsCountsUpdated             | 23670           | 23703  | 23703  | 23736   | 2       |
| onRewardsMinted                                     | 23941           | 46943  | 47076  | 69812   | 3       |
| onWithdrawalCredentialsChanged                      | 23759           | 25245  | 24988  | 26988   | 3       |
| pauseFor                                            | 23988           | 45359  | 47497  | 47497   | 11      |
| proposeNodeOperatorManagerAddressChange             | 24187           | 42636  | 53626  | 53626   | 9       |
| proposeNodeOperatorRewardAddressChange              | 24166           | 33434  | 36483  | 36483   | 10      |
| publicRelease                                       | 409             | 409    | 409    | 409     | 1       |
| queue                                               | 520             | 853    | 520    | 2520    | 6       |
| recoverERC20                                        | 58392           | 58392  | 58392  | 58392   | 1       |
| recoverEther                                        | 23747           | 26035  | 26035  | 28324   | 2       |
| recoverStETHShares                                  | 62867           | 62867  | 62867  | 62867   | 1       |
| removalCharge                                       | 386             | 1386   | 1386   | 2386    | 2       |
| removeKeys                                          | 24004           | 145233 | 172251 | 240232  | 15      |
| reportELRewardsStealingPenalty                      | 24327           | 131062 | 141190 | 151207  | 25      |
| requestRewardsETH                                   | 25051           | 50584  | 27268  | 99435   | 3       |
| resetNodeOperatorManagerAddress                     | 23690           | 31835  | 31312  | 38442   | 5       |
| resume                                              | 23730           | 26642  | 26642  | 29555   | 2       |
| revokeRole                                          | 29529           | 29529  | 29529  | 29529   | 1       |
| setAccounting                                       | 24267           | 46402  | 46496  | 46496   | 237     |
| setEarlyAdoption                                    | 24006           | 38634  | 46475  | 46475   | 8       |
| setRemovalCharge                                    | 24025           | 47027  | 47145  | 47157   | 196     |
| settleELRewardsStealingPenalty                      | 24668           | 87533  | 111789 | 162702  | 10      |
| submitInitialSlashing                               | 24058           | 97708  | 129465 | 133674  | 13      |
| submitWithdrawal                                    | 24305           | 121478 | 135793 | 234734  | 15      |
| unsafeUpdateValidatorsCount                         | 24263           | 61233  | 35920  | 159794  | 10      |
| updateExitedValidatorsCount                         | 24810           | 58511  | 47488  | 110216  | 11      |
| updateRefundedValidatorsCount                       | 24136           | 27723  | 27723  | 31310   | 2       |
| updateStuckValidatorsCount                          | 24832           | 73043  | 60555  | 138551  | 13      |
| updateTargetValidatorsLimits                        | 24323           | 118142 | 137508 | 210428  | 19      |


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




