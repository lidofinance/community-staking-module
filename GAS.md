| src/CSAccounting.sol:CSAccounting contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 173     |
| INITIALIZE_ROLE                            | 296             | 296    | 296    | 296    | 173     |
| RESET_BOND_CURVE_ROLE                      | 296             | 296    | 296    | 296    | 213     |
| SET_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 213     |
| addBondCurve                               | 121324          | 121324 | 121324 | 121324 | 5       |
| feeDistributor                             | 2428            | 2428   | 2428   | 2428   | 2       |
| getActualLockedBond                        | 581             | 687    | 741    | 741    | 3       |
| getBondAmountByKeysCount                   | 1347            | 1439   | 1347   | 1610   | 153     |
| getBondAmountByKeysCountWstETH             | 14217           | 14217  | 14217  | 14217  | 2       |
| getBondCurve                               | 2182            | 15981  | 16278  | 16278  | 157     |
| getBondLockRetentionPeriod                 | 2370            | 2370   | 2370   | 2370   | 2       |
| getLockedBondInfo                          | 815             | 815    | 815    | 815    | 7       |
| getRequiredBondForNextKeys                 | 10108           | 33316  | 52608  | 53134  | 13      |
| getRequiredBondForNextKeysWstETH           | 58979           | 58979  | 58979  | 58979  | 2       |
| getUnbondedKeysCount                       | 7730            | 24242  | 15730  | 46230  | 250     |
| grantRole                                  | 118386          | 118391 | 118386 | 118398 | 772     |
| setFeeDistributor                          | 47567           | 47567  | 47567  | 47567  | 173     |


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
| EL_REWARDS_STEALING_FINE                | 328             | 328    | 328    | 328     | 7       |
| INITIALIZE_ROLE                         | 286             | 286    | 286    | 286     | 220     |
| INITIAL_SLASHING_PENALTY                | 352             | 352    | 352    | 352     | 3       |
| MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE  | 315             | 315    | 315    | 315     | 1       |
| MODULE_MANAGER_ROLE                     | 328             | 328    | 328    | 328     | 217     |
| PAUSE_ROLE                              | 285             | 285    | 285    | 285     | 174     |
| PENALIZE_ROLE                           | 284             | 284    | 284    | 284     | 173     |
| RECOVERER_ROLE                          | 305             | 305    | 305    | 305     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE | 308             | 308    | 308    | 308     | 175     |
| RESUME_ROLE                             | 329             | 329    | 329    | 329     | 174     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE | 284             | 284    | 284    | 284     | 175     |
| STAKING_ROUTER_ROLE                     | 315             | 315    | 315    | 315     | 197     |
| VERIFIER_ROLE                           | 327             | 327    | 327    | 327     | 177     |
| accounting                              | 470             | 470    | 470    | 470     | 1       |
| activatePublicRelease                   | 23726           | 46554  | 46677  | 46677   | 187     |
| addNodeOperatorETH                      | 26187           | 601087 | 547220 | 1072382 | 153     |
| addNodeOperatorStETH                    | 26973           | 367345 | 535274 | 539789  | 3       |
| addNodeOperatorWstETH                   | 26952           | 379386 | 553064 | 558143  | 3       |
| addValidatorKeysETH                     | 25615           | 229082 | 258998 | 313415  | 6       |
| addValidatorKeysStETH                   | 26373           | 171253 | 241430 | 245957  | 3       |
| addValidatorKeysWstETH                  | 26373           | 183308 | 259515 | 264036  | 3       |
| cancelELRewardsStealingPenalty          | 26253           | 89593  | 99047  | 134024  | 4       |
| claimRewardsStETH                       | 25070           | 45579  | 27287  | 84381   | 3       |
| claimRewardsWstETH                      | 25028           | 45167  | 27245  | 83230   | 3       |
| cleanDepositQueue                       | 26304           | 36076  | 33834  | 53080   | 12      |
| compensateELRewardsStealingPenalty      | 23644           | 109979 | 153147 | 153147  | 3       |
| confirmNodeOperatorManagerAddressChange | 23712           | 29037  | 29097  | 34186   | 5       |
| confirmNodeOperatorRewardAddressChange  | 23691           | 33081  | 33970  | 38918   | 6       |
| decreaseOperatorVettedKeys              | 24834           | 91390  | 107427 | 155121  | 15      |
| depositQueueItem                        | 624             | 1290   | 624    | 2624    | 12      |
| earlyAdoption                           | 427             | 427    | 427    | 427     | 1       |
| getNodeOperator                         | 2214            | 9973   | 8214   | 20214   | 291     |
| getNodeOperatorSigningKeys              | 819             | 2877   | 3594   | 3594    | 7       |
| getNodeOperatorSummary                  | 1515            | 5426   | 7515   | 7515    | 45      |
| getNodeOperatorsCount                   | 425             | 488    | 425    | 2425    | 314     |
| getNonce                                | 380             | 680    | 380    | 2380    | 40      |
| getStakingModuleSummary                 | 618             | 2751   | 2618   | 4618    | 15      |
| getType                                 | 427             | 427    | 427    | 427     | 1       |
| grantRole                               | 26943           | 51436  | 51451  | 51451   | 1664    |
| hasRole                                 | 725             | 725    | 725    | 725     | 2       |
| isPaused                                | 419             | 819    | 419    | 2419    | 5       |
| normalizeQueue                          | 30255           | 54734  | 54734  | 79213   | 2       |
| obtainDepositData                       | 24453           | 106299 | 96745  | 158540  | 47      |
| onExitedAndStuckValidatorsCountsUpdated | 23670           | 23703  | 23703  | 23736   | 2       |
| onRewardsMinted                         | 23964           | 46966  | 47099  | 69835   | 3       |
| onWithdrawalCredentialsChanged          | 23782           | 25268  | 25011  | 27011   | 3       |
| pauseFor                                | 23988           | 45359  | 47497  | 47497   | 11      |
| proposeNodeOperatorManagerAddressChange | 24143           | 42592  | 53582  | 53582   | 9       |
| proposeNodeOperatorRewardAddressChange  | 24166           | 33434  | 36483  | 36483   | 10      |
| publicRelease                           | 409             | 409    | 409    | 409     | 1       |
| queue                                   | 475             | 808    | 475    | 2475    | 6       |
| recoverERC20                            | 58414           | 58414  | 58414  | 58414   | 1       |
| recoverEther                            | 23703           | 25991  | 25991  | 28280   | 2       |
| recoverStETHShares                      | 62866           | 62866  | 62866  | 62866   | 1       |
| removalCharge                           | 386             | 1386   | 1386   | 2386    | 2       |
| removeKeys                              | 24026           | 145216 | 172224 | 240206  | 15      |
| reportELRewardsStealingPenalty          | 24306           | 122478 | 136018 | 146035  | 16      |
| requestRewardsETH                       | 25051           | 45546  | 27268  | 84320   | 3       |
| resetNodeOperatorManagerAddress         | 23690           | 31835  | 31312  | 38442   | 5       |
| resume                                  | 23730           | 26642  | 26642  | 29555   | 2       |
| revokeRole                              | 29529           | 29529  | 29529  | 29529   | 1       |
| setAccounting                           | 24268           | 46394  | 46497  | 46497   | 216     |
| setEarlyAdoption                        | 24006           | 38634  | 46475  | 46475   | 8       |
| setRemovalCharge                        | 24026           | 47013  | 47146  | 47158   | 175     |
| settleELRewardsStealingPenalty          | 24690           | 67441  | 38740  | 112093  | 7       |
| submitInitialSlashing                   | 24058           | 97644  | 134090 | 134990  | 12      |
| submitWithdrawal                        | 24327           | 121313 | 140970 | 234701  | 14      |
| unsafeUpdateValidatorsCount             | 24263           | 61236  | 35929  | 159791  | 10      |
| updateExitedValidatorsCount             | 24811           | 58512  | 47489  | 110217  | 11      |
| updateRefundedValidatorsCount           | 24092           | 27679  | 27679  | 31266   | 2       |
| updateStuckValidatorsCount              | 24788           | 72995  | 60520  | 138460  | 13      |
| updateTargetValidatorsLimits            | 24279           | 118175 | 137409 | 210329  | 19      |


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




