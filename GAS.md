| src/CSAccounting.sol:CSAccounting contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 275             | 275    | 275    | 275    | 161     |
| RESET_BOND_CURVE_ROLE                      | 296             | 296    | 296    | 296    | 201     |
| SET_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 201     |
| addBondCurve                               | 121302          | 121302 | 121302 | 121302 | 5       |
| getActualLockedBond                        | 559             | 665    | 719    | 719    | 3       |
| getBondAmountByKeysCount                   | 1325            | 1421   | 1325   | 1588   | 145     |
| getBondAmountByKeysCountWstETH             | 14173           | 14173  | 14173  | 14173  | 2       |
| getBondCurve                               | 2226            | 16010  | 16322  | 16322  | 149     |
| getBondLockRetentionPeriod                 | 2413            | 2413   | 2413   | 2413   | 2       |
| getLockedBondInfo                          | 793             | 793    | 793    | 793    | 6       |
| getRequiredBondForNextKeys                 | 10130           | 33338  | 52630  | 53156  | 13      |
| getRequiredBondForNextKeysWstETH           | 59024           | 59024  | 59024  | 59024  | 2       |
| getUnbondedKeysCount                       | 7752            | 24214  | 15752  | 46252  | 238     |
| grantRole                                  | 118364          | 118367 | 118364 | 118376 | 563     |


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
| ORACLE_ROLE                                        | 263             | 263    | 263    | 263    | 8       |
| RECOVERER_ROLE                                     | 261             | 261    | 261    | 261    | 3       |
| distributeFees                                     | 22284           | 35883  | 27710  | 76226  | 5       |
| distributedShares                                  | 523             | 1523   | 1523   | 2523   | 4       |
| grantRole                                          | 118348          | 118348 | 118348 | 118348 | 11      |
| processTreeData                                    | 85699           | 97249  | 101099 | 101099 | 4       |
| recoverERC20                                       | 24428           | 41443  | 41443  | 58458  | 2       |
| recoverStETHShares                                 | 39731           | 39731  | 39731  | 39731  | 1       |


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
| DEFAULT_ADMIN_ROLE                      | 327             | 327    | 327    | 327     | 1       |
| DEPOSIT_SIZE                            | 285             | 285    | 285    | 285     | 10      |
| EL_REWARDS_STEALING_FINE                | 328             | 328    | 328    | 328     | 5       |
| INITIALIZE_ROLE                         | 285             | 285    | 285    | 285     | 208     |
| INITIAL_SLASHING_PENALTY                | 352             | 352    | 352    | 352     | 3       |
| MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE  | 315             | 315    | 315    | 315     | 1       |
| MODULE_MANAGER_ROLE                     | 328             | 328    | 328    | 328     | 205     |
| PAUSE_ROLE                              | 329             | 329    | 329    | 329     | 162     |
| PENALIZE_ROLE                           | 284             | 284    | 284    | 284     | 161     |
| RECOVERER_ROLE                          | 305             | 305    | 305    | 305     | 5       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE | 286             | 286    | 286    | 286     | 163     |
| RESUME_ROLE                             | 308             | 308    | 308    | 308     | 162     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE | 328             | 328    | 328    | 328     | 163     |
| STAKING_ROUTER_ROLE                     | 315             | 315    | 315    | 315     | 184     |
| VERIFIER_ROLE                           | 327             | 327    | 327    | 327     | 165     |
| accounting                              | 470             | 470    | 470    | 470     | 1       |
| activatePublicRelease                   | 23726           | 46545  | 46677  | 46677   | 175     |
| addNodeOperatorETH                      | 26187           | 603792 | 547331 | 1072493 | 145     |
| addNodeOperatorStETH                    | 26952           | 367369 | 535320 | 539835  | 3       |
| addNodeOperatorWstETH                   | 26974           | 379438 | 553131 | 558210  | 3       |
| addValidatorKeysETH                     | 25615           | 229175 | 259109 | 313526  | 6       |
| addValidatorKeysStETH                   | 26373           | 171298 | 241497 | 246024  | 3       |
| addValidatorKeysWstETH                  | 26373           | 183368 | 259605 | 264126  | 3       |
| cancelELRewardsStealingPenalty          | 26233           | 90187  | 99846  | 134823  | 4       |
| cleanDepositQueue                       | 26304           | 36076  | 33834  | 53080   | 12      |
| confirmNodeOperatorManagerAddressChange | 23668           | 28993  | 29053  | 34142   | 5       |
| confirmNodeOperatorRewardAddressChange  | 23713           | 33103  | 33992  | 38940   | 6       |
| decreaseOperatorVettedKeys              | 24834           | 91409  | 107449 | 155165  | 15      |
| depositQueueItem                        | 646             | 1246   | 646    | 2646    | 10      |
| earlyAdoption                           | 471             | 471    | 471    | 471     | 1       |
| getNodeOperator                         | 2236            | 9866   | 8236   | 20236   | 276     |
| getNodeOperatorSigningKeys              | 796             | 2854   | 3571   | 3571    | 7       |
| getNodeOperatorSummary                  | 1515            | 5468   | 7515   | 7515    | 43      |
| getNodeOperatorsCount                   | 425             | 488    | 425    | 2425    | 313     |
| getNonce                                | 380             | 680    | 380    | 2380    | 40      |
| getStakingModuleSummary                 | 618             | 2751   | 2618   | 4618    | 15      |
| getType                                 | 383             | 383    | 383    | 383     | 1       |
| grantRole                               | 26942           | 51434  | 51450  | 51450   | 1556    |
| hasRole                                 | 725             | 725    | 725    | 725     | 2       |
| isPaused                                | 419             | 819    | 419    | 2419    | 5       |
| normalizeQueue                          | 30255           | 54734  | 54734  | 79213   | 2       |
| obtainDepositData                       | 24453           | 107082 | 96745  | 158540  | 43      |
| onExitedAndStuckValidatorsCountsUpdated | 23670           | 23703  | 23703  | 23736   | 2       |
| onRewardsMinted                         | 23942           | 32097  | 26177  | 46173   | 3       |
| onWithdrawalCredentialsChanged          | 23760           | 25246  | 24989  | 26989   | 3       |
| pauseFor                                | 23988           | 45359  | 47497  | 47497   | 11      |
| proposeNodeOperatorManagerAddressChange | 24187           | 42636  | 53626  | 53626   | 9       |
| proposeNodeOperatorRewardAddressChange  | 24143           | 33411  | 36460  | 36460   | 10      |
| publicRelease                           | 409             | 409    | 409    | 409     | 1       |
| queue                                   | 475             | 875    | 475    | 2475    | 5       |
| recoverERC20                            | 31840           | 48855  | 48855  | 65870   | 2       |
| recoverEther                            | 23740           | 26033  | 26033  | 28326   | 2       |
| recoverStETHShares                      | 69884           | 69884  | 69884  | 69884   | 1       |
| removalCharge                           | 408             | 1408   | 1408   | 2408    | 2       |
| removeKeys                              | 24004           | 145239 | 172258 | 240240  | 15      |
| reportELRewardsStealingPenalty          | 24305           | 120509 | 136813 | 146818  | 14      |
| resetNodeOperatorManagerAddress         | 23712           | 31857  | 31334  | 38464   | 5       |
| resume                                  | 23707           | 26619  | 26619  | 29532   | 2       |
| revokeRole                              | 29529           | 29529  | 29529  | 29529   | 1       |
| setAccounting                           | 24268           | 46388  | 46497  | 46497   | 204     |
| setEarlyAdoption                        | 24006           | 38634  | 46475  | 46475   | 8       |
| setRemovalCharge                        | 23981           | 46959  | 47101  | 47113   | 163     |
| settleELRewardsStealingPenalty          | 24668           | 67429  | 38718  | 112093  | 7       |
| submitInitialSlashing                   | 24058           | 97674  | 134135 | 135035  | 12      |
| submitWithdrawal                        | 24283           | 121293 | 140959 | 234679  | 14      |
| unsafeUpdateValidatorsCount             | 24263           | 61241  | 35929  | 159813  | 10      |
| updateExitedValidatorsCount             | 24811           | 58512  | 47489  | 110217  | 11      |
| updateRefundedValidatorsCount           | 24092           | 27679  | 27679  | 31266   | 2       |
| updateStuckValidatorsCount              | 24788           | 73003  | 60520  | 138482  | 13      |
| updateTargetValidatorsLimits            | 24279           | 118194 | 137431 | 210351  | 19      |


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
| recoverEther                                             | 1816            | 12382 | 1816   | 33516 | 3       |




