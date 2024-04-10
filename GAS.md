| src/CSAccounting.sol:CSAccounting contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 202     |
| INITIALIZE_ROLE                            | 296             | 296    | 296    | 296    | 202     |
| RESET_BOND_CURVE_ROLE                      | 296             | 296    | 296    | 296    | 242     |
| SET_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 242     |
| addBondCurve                               | 121336          | 127946 | 121336 | 144474 | 7       |
| feeDistributor                             | 2428            | 2428   | 2428   | 2428   | 2       |
| getActualLockedBond                        | 581             | 687    | 741    | 741    | 3       |
| getBondAmountByKeysCount                   | 1347            | 1436   | 1347   | 1610   | 182     |
| getBondAmountByKeysCountWstETH             | 14217           | 14217  | 14217  | 14217  | 2       |
| getBondCurve                               | 2182            | 15881  | 16278  | 16278  | 188     |
| getBondLockRetentionPeriod                 | 2370            | 2370   | 2370   | 2370   | 2       |
| getBondShares                              | 563             | 563    | 563    | 563    | 10      |
| getLockedBondInfo                          | 815             | 815    | 815    | 815    | 8       |
| getRequiredBondForNextKeys                 | 10003           | 31805  | 50503  | 51178  | 17      |
| getRequiredBondForNextKeysWstETH           | 57023           | 57023  | 57023  | 57023  | 2       |
| getUnbondedKeysCount                       | 7774            | 25145  | 15774  | 46274  | 331     |
| getUnbondedKeysCountToEject                | 7113            | 7472   | 7471   | 7530   | 51      |
| grantRole                                  | 118386          | 118391 | 118386 | 118398 | 888     |
| setBondCurve                               | 49830           | 49830  | 49830  | 49830  | 2       |
| setFeeDistributor                          | 47567           | 47567  | 47567  | 47567  | 202     |


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
| DEPOSIT_SIZE                            | 307             | 307    | 307    | 307     | 12      |
| EL_REWARDS_STEALING_FINE                | 328             | 328    | 328    | 328     | 8       |
| INITIALIZE_ROLE                         | 308             | 308    | 308    | 308     | 249     |
| INITIAL_SLASHING_PENALTY                | 352             | 352    | 352    | 352     | 4       |
| MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE  | 315             | 315    | 315    | 315     | 1       |
| MODULE_MANAGER_ROLE                     | 328             | 328    | 328    | 328     | 246     |
| PAUSE_ROLE                              | 285             | 285    | 285    | 285     | 203     |
| RECOVERER_ROLE                          | 327             | 327    | 327    | 327     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE | 329             | 329    | 329    | 329     | 204     |
| RESUME_ROLE                             | 329             | 329    | 329    | 329     | 203     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE | 284             | 284    | 284    | 284     | 204     |
| STAKING_ROUTER_ROLE                     | 318             | 318    | 318    | 318     | 226     |
| VERIFIER_ROLE                           | 327             | 327    | 327    | 327     | 206     |
| accounting                              | 449             | 449    | 449    | 449     | 1       |
| activatePublicRelease                   | 23726           | 46570  | 46677  | 46677   | 216     |
| addNodeOperatorETH                      | 26187           | 594912 | 545701 | 1070863 | 182     |
| addNodeOperatorStETH                    | 26973           | 366355 | 533789 | 538304  | 3       |
| addNodeOperatorWstETH                   | 26952           | 378396 | 551579 | 556658  | 3       |
| addValidatorKeysETH                     | 25615           | 235433 | 257622 | 312302  | 8       |
| addValidatorKeysStETH                   | 26352           | 170517 | 240336 | 244863  | 3       |
| addValidatorKeysWstETH                  | 26351           | 182570 | 258420 | 262941  | 3       |
| cancelELRewardsStealingPenalty          | 26275           | 92404  | 101872 | 139597  | 4       |
| claimRewardsStETH                       | 25028           | 50604  | 27245  | 99539   | 3       |
| claimRewardsWstETH                      | 25050           | 50256  | 27267  | 98452   | 3       |
| cleanDepositQueue                       | 26303           | 36075  | 33833  | 53079   | 12      |
| compensateELRewardsStealingPenalty      | 23643           | 114360 | 137725 | 158350  | 4       |
| confirmNodeOperatorManagerAddressChange | 23690           | 29015  | 29075  | 34164   | 5       |
| confirmNodeOperatorRewardAddressChange  | 23713           | 33103  | 33992  | 38940   | 6       |
| decreaseOperatorVettedKeys              | 24834           | 91474  | 107524 | 155315  | 15      |
| depositETH                              | 23656           | 118654 | 125062 | 175097  | 8       |
| depositQueueItem                        | 623             | 1289   | 623    | 2623    | 12      |
| depositStETH                            | 24649           | 102495 | 108316 | 158351  | 5       |
| depositWstETH                           | 24696           | 115514 | 124583 | 174618  | 5       |
| earlyAdoption                           | 427             | 427    | 427    | 427     | 1       |
| getNodeOperator                         | 2258            | 9342   | 8258   | 18258   | 428     |
| getNodeOperatorSigningKeys              | 819             | 2877   | 3594   | 3594    | 7       |
| getNodeOperatorSummary                  | 9544            | 13451  | 15544  | 15544   | 51      |
| getNodeOperatorsCount                   | 402             | 413    | 402    | 2402    | 180     |
| getNonce                                | 380             | 533    | 380    | 2380    | 78      |
| getStakingModuleSummary                 | 617             | 2750   | 2617   | 4617    | 15      |
| getType                                 | 427             | 427    | 427    | 427     | 1       |
| grantRole                               | 26943           | 51436  | 51451  | 51451   | 1723    |
| hasRole                                 | 769             | 769    | 769    | 769     | 2       |
| isPaused                                | 441             | 841    | 441    | 2441    | 5       |
| normalizeQueue                          | 30213           | 54692  | 54692  | 79171   | 2       |
| obtainDepositData                       | 24453           | 107839 | 108094 | 158540  | 53      |
| onExitedAndStuckValidatorsCountsUpdated | 23670           | 23703  | 23703  | 23736   | 2       |
| onRewardsMinted                         | 23941           | 46943  | 47076  | 69812   | 3       |
| onWithdrawalCredentialsChanged          | 23759           | 25245  | 24988  | 26988   | 3       |
| pauseFor                                | 23988           | 45359  | 47497  | 47497   | 11      |
| proposeNodeOperatorManagerAddressChange | 24187           | 42636  | 53626  | 53626   | 9       |
| proposeNodeOperatorRewardAddressChange  | 24166           | 33434  | 36483  | 36483   | 10      |
| publicRelease                           | 409             | 409    | 409    | 409     | 1       |
| queue                                   | 520             | 853    | 520    | 2520    | 6       |
| recoverERC20                            | 58392           | 58392  | 58392  | 58392   | 1       |
| recoverEther                            | 23725           | 26013  | 26013  | 28302   | 2       |
| recoverStETHShares                      | 62845           | 62845  | 62845  | 62845   | 1       |
| removalCharge                           | 386             | 1386   | 1386   | 2386    | 2       |
| removeKeys                              | 24004           | 145261 | 172284 | 240265  | 15      |
| reportELRewardsStealingPenalty          | 24306           | 131424 | 141222 | 151239  | 27      |
| requestRewardsETH                       | 25051           | 50613  | 27268  | 99520   | 3       |
| resetNodeOperatorManagerAddress         | 23668           | 31813  | 31290  | 38420   | 5       |
| resume                                  | 23730           | 26642  | 26642  | 29555   | 2       |
| revokeRole                              | 29529           | 29529  | 29529  | 29529   | 1       |
| setAccounting                           | 24267           | 46405  | 46496  | 46496   | 245     |
| setEarlyAdoption                        | 24006           | 38634  | 46475  | 46475   | 8       |
| setRemovalCharge                        | 24003           | 47009  | 47123  | 47135   | 204     |
| settleELRewardsStealingPenalty          | 24690           | 86009  | 110408 | 123475  | 12      |
| submitInitialSlashing                   | 24058           | 97736  | 129506 | 133715  | 13      |
| submitWithdrawal                        | 24283           | 121486 | 135812 | 234753  | 15      |
| unsafeUpdateValidatorsCount             | 24263           | 61247  | 35929  | 159844  | 10      |
| updateExitedValidatorsCount             | 24810           | 58511  | 47488  | 110216  | 11      |
| updateRefundedValidatorsCount           | 24136           | 27723  | 27723  | 31310   | 2       |
| updateStuckValidatorsCount              | 24832           | 73066  | 60564  | 138601  | 13      |
| updateTargetValidatorsLimits            | 24355           | 119707 | 128177 | 210495  | 28      |


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




