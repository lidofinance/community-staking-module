| src/CSAccounting.sol:CSAccounting contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 192     |
| INITIALIZE_ROLE                            | 296             | 296    | 296    | 296    | 192     |
| RESET_BOND_CURVE_ROLE                      | 296             | 296    | 296    | 296    | 232     |
| SET_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 232     |
| addBondCurve                               | 121336          | 127946 | 121336 | 144474 | 7       |
| feeDistributor                             | 2428            | 2428   | 2428   | 2428   | 2       |
| getActualLockedBond                        | 581             | 687    | 741    | 741    | 3       |
| getBondAmountByKeysCount                   | 1347            | 1432   | 1347   | 1610   | 172     |
| getBondAmountByKeysCountWstETH             | 14217           | 14217  | 14217  | 14217  | 2       |
| getBondCurve                               | 2182            | 15859  | 16278  | 16278  | 178     |
| getBondLockRetentionPeriod                 | 2370            | 2370   | 2370   | 2370   | 2       |
| getBondShares                              | 563             | 563    | 563    | 563    | 10      |
| getLockedBondInfo                          | 815             | 815    | 815    | 815    | 8       |
| getRequiredBondForNextKeys                 | 9981            | 31783  | 50481  | 51156  | 17      |
| getRequiredBondForNextKeysWstETH           | 57001           | 57001  | 57001  | 57001  | 2       |
| getUnbondedKeysCount                       | 7752            | 24552  | 15752  | 46252  | 304     |
| grantRole                                  | 118386          | 118391 | 118386 | 118398 | 848     |
| setBondCurve                               | 49830           | 49830  | 49830  | 49830  | 2       |
| setFeeDistributor                          | 47567           | 47567  | 47567  | 47567  | 192     |


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
| DEFAULT_ADMIN_ROLE                      | 327             | 327    | 327    | 327     | 1       |
| DEPOSIT_SIZE                            | 307             | 307    | 307    | 307     | 10      |
| EL_REWARDS_STEALING_FINE                | 328             | 328    | 328    | 328     | 8       |
| INITIALIZE_ROLE                         | 308             | 308    | 308    | 308     | 239     |
| INITIAL_SLASHING_PENALTY                | 352             | 352    | 352    | 352     | 4       |
| MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE  | 315             | 315    | 315    | 315     | 1       |
| MODULE_MANAGER_ROLE                     | 328             | 328    | 328    | 328     | 236     |
| PAUSE_ROLE                              | 285             | 285    | 285    | 285     | 193     |
| PENALIZE_ROLE                           | 284             | 284    | 284    | 284     | 192     |
| RECOVERER_ROLE                          | 305             | 305    | 305    | 305     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE | 285             | 285    | 285    | 285     | 194     |
| RESUME_ROLE                             | 329             | 329    | 329    | 329     | 193     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE | 284             | 284    | 284    | 284     | 194     |
| STAKING_ROUTER_ROLE                     | 337             | 337    | 337    | 337     | 216     |
| VERIFIER_ROLE                           | 327             | 327    | 327    | 327     | 196     |
| accounting                              | 470             | 470    | 470    | 470     | 1       |
| activatePublicRelease                   | 23726           | 46565  | 46677  | 46677   | 206     |
| addNodeOperatorETH                      | 26187           | 594258 | 545679 | 1070841 | 172     |
| addNodeOperatorStETH                    | 26973           | 366318 | 533733 | 538248  | 3       |
| addNodeOperatorWstETH                   | 26952           | 378359 | 551523 | 556602  | 3       |
| addValidatorKeysETH                     | 25615           | 235394 | 257578 | 312258  | 8       |
| addValidatorKeysStETH                   | 26373           | 170486 | 240279 | 244806  | 3       |
| addValidatorKeysWstETH                  | 26373           | 182540 | 258364 | 262885  | 3       |
| cancelELRewardsStealingPenalty          | 26275           | 92387  | 101850 | 139575  | 4       |
| claimRewardsStETH                       | 25029           | 50590  | 27246  | 99496   | 3       |
| claimRewardsWstETH                      | 25050           | 50241  | 27267  | 98408   | 3       |
| cleanDepositQueue                       | 26326           | 36098  | 33856  | 53102   | 12      |
| compensateELRewardsStealingPenalty      | 23666           | 114367 | 137726 | 158351  | 4       |
| confirmNodeOperatorManagerAddressChange | 23668           | 28993  | 29053  | 34142   | 5       |
| confirmNodeOperatorRewardAddressChange  | 23713           | 33103  | 33992  | 38940   | 6       |
| decreaseOperatorVettedKeys              | 24834           | 91455  | 107502 | 155271  | 15      |
| depositETH                              | 23656           | 118635 | 125040 | 175075  | 8       |
| depositQueueItem                        | 668             | 1334   | 668    | 2668    | 12      |
| depositStETH                            | 24649           | 102450 | 108260 | 158295  | 5       |
| depositWstETH                           | 24696           | 115469 | 124527 | 174562  | 5       |
| earlyAdoption                           | 427             | 427    | 427    | 427     | 1       |
| getNodeOperator                         | 2236            | 10115  | 8236   | 18236   | 349     |
| getNodeOperatorSigningKeys              | 819             | 2877   | 3594   | 3594    | 7       |
| getNodeOperatorSummary                  | 1515            | 5426   | 7515   | 7515    | 45      |
| getNodeOperatorsCount                   | 425             | 436    | 425    | 2425    | 170     |
| getNonce                                | 380             | 537    | 380    | 2380    | 76      |
| getStakingModuleSummary                 | 618             | 2751   | 2618   | 4618    | 15      |
| getType                                 | 427             | 427    | 427    | 427     | 1       |
| grantRole                               | 26943           | 51437  | 51451  | 51451   | 1835    |
| hasRole                                 | 725             | 725    | 725    | 725     | 2       |
| isPaused                                | 419             | 819    | 419    | 2419    | 5       |
| normalizeQueue                          | 30255           | 54734  | 54734  | 79213   | 2       |
| obtainDepositData                       | 24453           | 106689 | 99007  | 158540  | 48      |
| onExitedAndStuckValidatorsCountsUpdated | 23670           | 23703  | 23703  | 23736   | 2       |
| onRewardsMinted                         | 23964           | 46966  | 47099  | 69835   | 3       |
| onWithdrawalCredentialsChanged          | 23782           | 25268  | 25011  | 27011   | 3       |
| pauseFor                                | 23988           | 45359  | 47497  | 47497   | 11      |
| proposeNodeOperatorManagerAddressChange | 24143           | 42592  | 53582  | 53582   | 9       |
| proposeNodeOperatorRewardAddressChange  | 24166           | 33434  | 36483  | 36483   | 10      |
| publicRelease                           | 409             | 409    | 409    | 409     | 1       |
| queue                                   | 520             | 853    | 520    | 2520    | 6       |
| recoverERC20                            | 58414           | 58414  | 58414  | 58414   | 1       |
| recoverEther                            | 23725           | 26013  | 26013  | 28302   | 2       |
| recoverStETHShares                      | 62845           | 62845  | 62845  | 62845   | 1       |
| removalCharge                           | 386             | 1386   | 1386   | 2386    | 2       |
| removeKeys                              | 24026           | 145267 | 172284 | 240265  | 15      |
| reportELRewardsStealingPenalty          | 24306           | 130671 | 141200 | 151217  | 23      |
| requestRewardsETH                       | 25051           | 50598  | 27268  | 99476   | 3       |
| resetNodeOperatorManagerAddress         | 23712           | 31857  | 31334  | 38464   | 5       |
| resume                                  | 23730           | 26642  | 26642  | 29555   | 2       |
| revokeRole                              | 29529           | 29529  | 29529  | 29529   | 1       |
| setAccounting                           | 24223           | 46357  | 46452  | 46452   | 235     |
| setEarlyAdoption                        | 24006           | 38634  | 46475  | 46475   | 8       |
| setRemovalCharge                        | 24003           | 47003  | 47123  | 47135   | 194     |
| settleELRewardsStealingPenalty          | 24690           | 78410  | 110065 | 123453  | 9       |
| submitInitialSlashing                   | 24058           | 97721  | 129484 | 133693  | 13      |
| submitWithdrawal                        | 24283           | 121154 | 140610 | 234731  | 14      |
| unsafeUpdateValidatorsCount             | 24263           | 61243  | 35929  | 159822  | 10      |
| updateExitedValidatorsCount             | 24811           | 58512  | 47489  | 110217  | 11      |
| updateRefundedValidatorsCount           | 24092           | 27679  | 27679  | 31266   | 2       |
| updateStuckValidatorsCount              | 24788           | 73014  | 60520  | 138535  | 13      |
| updateTargetValidatorsLimits            | 24279           | 118114 | 137483 | 210403  | 19      |


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




