| src/CSAccounting.sol:CSAccounting contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 193     |
| INITIALIZE_ROLE                            | 296             | 296    | 296    | 296    | 193     |
| RESET_BOND_CURVE_ROLE                      | 296             | 296    | 296    | 296    | 233     |
| SET_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 233     |
| addBondCurve                               | 121336          | 127946 | 121336 | 144474 | 7       |
| feeDistributor                             | 2428            | 2428   | 2428   | 2428   | 2       |
| getActualLockedBond                        | 581             | 687    | 741    | 741    | 3       |
| getBondAmountByKeysCount                   | 1347            | 1433   | 1347   | 1610   | 173     |
| getBondAmountByKeysCountWstETH             | 14217           | 14217  | 14217  | 14217  | 2       |
| getBondCurve                               | 2182            | 15861  | 16278  | 16278  | 179     |
| getBondLockRetentionPeriod                 | 2370            | 2370   | 2370   | 2370   | 2       |
| getBondShares                              | 563             | 563    | 563    | 563    | 10      |
| getLockedBondInfo                          | 815             | 815    | 815    | 815    | 8       |
| getRequiredBondForNextKeys                 | 10003           | 31805  | 50503  | 51178  | 17      |
| getRequiredBondForNextKeysWstETH           | 57023           | 57023  | 57023  | 57023  | 2       |
| getUnbondedKeysCount                       | 7774            | 24581  | 15774  | 46274  | 306     |
| grantRole                                  | 118386          | 118391 | 118386 | 118398 | 852     |
| setBondCurve                               | 49830           | 49830  | 49830  | 49830  | 2       |
| setFeeDistributor                          | 47567           | 47567  | 47567  | 47567  | 193     |


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
| DEFAULT_ADMIN_ROLE                      | 283             | 283    | 283    | 283     | 1       |
| DEPOSIT_SIZE                            | 307             | 307    | 307    | 307     | 12      |
| EL_REWARDS_STEALING_FINE                | 328             | 328    | 328    | 328     | 8       |
| INITIALIZE_ROLE                         | 308             | 308    | 308    | 308     | 240     |
| INITIAL_SLASHING_PENALTY                | 352             | 352    | 352    | 352     | 4       |
| MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE  | 315             | 315    | 315    | 315     | 1       |
| MODULE_MANAGER_ROLE                     | 328             | 328    | 328    | 328     | 237     |
| PAUSE_ROLE                              | 285             | 285    | 285    | 285     | 194     |
| RECOVERER_ROLE                          | 327             | 327    | 327    | 327     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE | 307             | 307    | 307    | 307     | 195     |
| RESUME_ROLE                             | 329             | 329    | 329    | 329     | 194     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE | 284             | 284    | 284    | 284     | 195     |
| STAKING_ROUTER_ROLE                     | 359             | 359    | 359    | 359     | 217     |
| VERIFIER_ROLE                           | 327             | 327    | 327    | 327     | 197     |
| accounting                              | 427             | 427    | 427    | 427     | 1       |
| activatePublicRelease                   | 23726           | 46566  | 46677  | 46677   | 207     |
| addNodeOperatorETH                      | 26187           | 594315 | 545701 | 1070863 | 173     |
| addNodeOperatorStETH                    | 26973           | 366332 | 533755 | 538270  | 3       |
| addNodeOperatorWstETH                   | 26952           | 378373 | 551545 | 556624  | 3       |
| addValidatorKeysETH                     | 25615           | 235433 | 257622 | 312302  | 8       |
| addValidatorKeysStETH                   | 26395           | 170537 | 240345 | 244872  | 3       |
| addValidatorKeysWstETH                  | 26395           | 182592 | 258430 | 262951  | 3       |
| cancelELRewardsStealingPenalty          | 26275           | 92404  | 101872 | 139597  | 4       |
| claimRewardsStETH                       | 25051           | 50627  | 27268  | 99562   | 3       |
| claimRewardsWstETH                      | 25050           | 50256  | 27267  | 98452   | 3       |
| cleanDepositQueue                       | 26281           | 36053  | 33811  | 53057   | 12      |
| compensateELRewardsStealingPenalty      | 23688           | 114405 | 137770 | 158395  | 4       |
| confirmNodeOperatorManagerAddressChange | 23690           | 29015  | 29075  | 34164   | 5       |
| confirmNodeOperatorRewardAddressChange  | 23713           | 33103  | 33992  | 38940   | 6       |
| decreaseOperatorVettedKeys              | 24834           | 91474  | 107524 | 155315  | 15      |
| depositETH                              | 23656           | 118654 | 125062 | 175097  | 8       |
| depositQueueItem                        | 623             | 1289   | 623    | 2623    | 12      |
| depositStETH                            | 24649           | 102467 | 108282 | 158317  | 5       |
| depositWstETH                           | 24696           | 115487 | 124549 | 174584  | 5       |
| earlyAdoption                           | 427             | 427    | 427    | 427     | 1       |
| getNodeOperator                         | 2258            | 10121  | 8258   | 18258   | 352     |
| getNodeOperatorSigningKeys              | 819             | 2877   | 3594   | 3594    | 7       |
| getNodeOperatorSummary                  | 1492            | 5403   | 7492   | 7492    | 45      |
| getNodeOperatorsCount                   | 380             | 391    | 380    | 2380    | 171     |
| getNonce                                | 380             | 533    | 380    | 2380    | 78      |
| getStakingModuleSummary                 | 640             | 2773   | 2640   | 4640    | 15      |
| getType                                 | 427             | 427    | 427    | 427     | 1       |
| grantRole                               | 26943           | 51436  | 51451  | 51451   | 1651    |
| hasRole                                 | 747             | 747    | 747    | 747     | 2       |
| isPaused                                | 441             | 841    | 441    | 2441    | 5       |
| normalizeQueue                          | 30213           | 54692  | 54692  | 79171   | 2       |
| obtainDepositData                       | 24453           | 106774 | 101269 | 158540  | 49      |
| onExitedAndStuckValidatorsCountsUpdated | 23670           | 23703  | 23703  | 23736   | 2       |
| onRewardsMinted                         | 23986           | 46988  | 47121  | 69857   | 3       |
| onWithdrawalCredentialsChanged          | 23737           | 25223  | 24966  | 26966   | 3       |
| pauseFor                                | 23988           | 45359  | 47497  | 47497   | 11      |
| proposeNodeOperatorManagerAddressChange | 24165           | 42614  | 53604  | 53604   | 9       |
| proposeNodeOperatorRewardAddressChange  | 24166           | 33434  | 36483  | 36483   | 10      |
| publicRelease                           | 409             | 409    | 409    | 409     | 1       |
| queue                                   | 520             | 853    | 520    | 2520    | 6       |
| recoverERC20                            | 58436           | 58436  | 58436  | 58436   | 1       |
| recoverEther                            | 23725           | 26013  | 26013  | 28302   | 2       |
| recoverStETHShares                      | 62845           | 62845  | 62845  | 62845   | 1       |
| removalCharge                           | 386             | 1386   | 1386   | 2386    | 2       |
| removeKeys                              | 23982           | 145240 | 172266 | 240248  | 15      |
| reportELRewardsStealingPenalty          | 24306           | 130691 | 141222 | 151239  | 23      |
| requestRewardsETH                       | 25051           | 50613  | 27268  | 99520   | 3       |
| resetNodeOperatorManagerAddress         | 23668           | 31813  | 31290  | 38420   | 5       |
| resume                                  | 23730           | 26642  | 26642  | 29555   | 2       |
| revokeRole                              | 29529           | 29529  | 29529  | 29529   | 1       |
| setAccounting                           | 24245           | 46379  | 46474  | 46474   | 236     |
| setEarlyAdoption                        | 24006           | 38634  | 46475  | 46475   | 8       |
| setRemovalCharge                        | 24003           | 47004  | 47123  | 47135   | 195     |
| settleELRewardsStealingPenalty          | 24690           | 78423  | 110087 | 123475  | 9       |
| submitInitialSlashing                   | 24058           | 97736  | 129506 | 133715  | 13      |
| submitWithdrawal                        | 24283           | 121486 | 135812 | 234753  | 15      |
| unsafeUpdateValidatorsCount             | 24263           | 61247  | 35929  | 159844  | 10      |
| updateExitedValidatorsCount             | 24788           | 58489  | 47466  | 110194  | 11      |
| updateRefundedValidatorsCount           | 24114           | 27701  | 27701  | 31288   | 2       |
| updateStuckValidatorsCount              | 24810           | 73044  | 60542  | 138579  | 13      |
| updateTargetValidatorsLimits            | 24301           | 118155 | 137527 | 210447  | 19      |


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




