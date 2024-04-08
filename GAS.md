| src/CSAccounting.sol:CSAccounting contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 275             | 275    | 275    | 275    | 160     |
| RESET_BOND_CURVE_ROLE                      | 296             | 296    | 296    | 296    | 200     |
| SET_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 200     |
| addBondCurve                               | 121302          | 121302 | 121302 | 121302 | 5       |
| getActualLockedBond                        | 559             | 665    | 719    | 719    | 3       |
| getBondAmountByKeysCount                   | 1325            | 1421   | 1325   | 1588   | 145     |
| getBondAmountByKeysCountWstETH             | 14173           | 14173  | 14173  | 14173  | 2       |
| getBondCurve                               | 2226            | 16010  | 16322  | 16322  | 149     |
| getBondLockRetentionPeriod                 | 2413            | 2413   | 2413   | 2413   | 2       |
| getLockedBondInfo                          | 793             | 793    | 793    | 793    | 6       |
| getRequiredBondForNextKeys                 | 10108           | 33316  | 52608  | 53134  | 13      |
| getRequiredBondForNextKeysWstETH           | 59002           | 59002  | 59002  | 59002  | 2       |
| getUnbondedKeysCount                       | 7730            | 24192  | 15730  | 46230  | 238     |
| grantRole                                  | 118364          | 118367 | 118364 | 118376 | 560     |


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
| RECOVERER_ROLE                                     | 239             | 239    | 239    | 239    | 7       |
| distributeFees                                     | 22284           | 35884  | 27716  | 76223  | 5       |
| distributedShares                                  | 523             | 1523   | 1523   | 2523   | 4       |
| grantRole                                          | 118370          | 118370 | 118370 | 118370 | 11      |
| pendingToDistribute                                | 1454            | 1454   | 1454   | 1454   | 1       |
| processOracleReport                                | 57030           | 72234  | 77302  | 77302  | 4       |
| recoverERC20                                       | 24378           | 35738  | 24404  | 58434  | 3       |
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
| DEPOSIT_SIZE                            | 329             | 329    | 329    | 329     | 10      |
| EL_REWARDS_STEALING_FINE                | 306             | 306    | 306    | 306     | 5       |
| INITIALIZE_ROLE                         | 308             | 308    | 308    | 308     | 207     |
| INITIAL_SLASHING_PENALTY                | 352             | 352    | 352    | 352     | 3       |
| MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE  | 293             | 293    | 293    | 293     | 1       |
| MODULE_MANAGER_ROLE                     | 306             | 306    | 306    | 306     | 204     |
| PAUSE_ROLE                              | 307             | 307    | 307    | 307     | 161     |
| PENALIZE_ROLE                           | 307             | 307    | 307    | 307     | 160     |
| RECOVERER_ROLE                          | 283             | 283    | 283    | 283     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE | 327             | 327    | 327    | 327     | 162     |
| RESUME_ROLE                             | 286             | 286    | 286    | 286     | 161     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE | 306             | 306    | 306    | 306     | 162     |
| STAKING_ROUTER_ROLE                     | 360             | 360    | 360    | 360     | 183     |
| VERIFIER_ROLE                           | 327             | 327    | 327    | 327     | 164     |
| accounting                              | 448             | 448    | 448    | 448     | 1       |
| activatePublicRelease                   | 23726           | 46545  | 46677  | 46677   | 174     |
| addNodeOperatorETH                      | 26187           | 603727 | 547265 | 1072427 | 145     |
| addNodeOperatorStETH                    | 26995           | 367368 | 535297 | 539812  | 3       |
| addNodeOperatorWstETH                   | 26952           | 379372 | 553043 | 558122  | 3       |
| addValidatorKeysETH                     | 25615           | 229101 | 259021 | 313438  | 6       |
| addValidatorKeysStETH                   | 26351           | 171217 | 241387 | 245914  | 3       |
| addValidatorKeysWstETH                  | 26351           | 183287 | 259495 | 264016  | 3       |
| cancelELRewardsStealingPenalty          | 26275           | 90196  | 99844  | 134821  | 4       |
| cleanDepositQueue                       | 26282           | 36054  | 33812  | 53058   | 12      |
| confirmNodeOperatorManagerAddressChange | 23712           | 29037  | 29097  | 34186   | 5       |
| confirmNodeOperatorRewardAddressChange  | 23691           | 33081  | 33970  | 38918   | 6       |
| decreaseOperatorVettedKeys              | 24834           | 91390  | 107427 | 155121  | 15      |
| depositQueueItem                        | 624             | 1224   | 624    | 2624    | 10      |
| earlyAdoption                           | 449             | 449    | 449    | 449     | 1       |
| getNodeOperator                         | 2214            | 9844   | 8214   | 20214   | 276     |
| getNodeOperatorSigningKeys              | 841             | 2899   | 3616   | 3616    | 7       |
| getNodeOperatorSummary                  | 1496            | 5449   | 7496   | 7496    | 43      |
| getNodeOperatorsCount                   | 403             | 466    | 403    | 2403    | 313     |
| getNonce                                | 380             | 680    | 380    | 2380    | 40      |
| getStakingModuleSummary                 | 661             | 2794   | 2661   | 4661    | 15      |
| getType                                 | 427             | 427    | 427    | 427     | 1       |
| grantRole                               | 26965           | 51457  | 51473  | 51473   | 1546    |
| hasRole                                 | 748             | 748    | 748    | 748     | 2       |
| isPaused                                | 461             | 861    | 461    | 2461    | 5       |
| normalizeQueue                          | 30233           | 54712  | 54712  | 79191   | 2       |
| obtainDepositData                       | 24497           | 107126 | 96789  | 158584  | 43      |
| onExitedAndStuckValidatorsCountsUpdated | 23670           | 23703  | 23703  | 23736   | 2       |
| onRewardsMinted                         | 23986           | 32839  | 32839  | 41692   | 2       |
| onWithdrawalCredentialsChanged          | 23738           | 25224  | 24967  | 26967   | 3       |
| pauseFor                                | 23988           | 45359  | 47497  | 47497   | 11      |
| proposeNodeOperatorManagerAddressChange | 24165           | 42614  | 53604  | 53604   | 9       |
| proposeNodeOperatorRewardAddressChange  | 24166           | 33434  | 36483  | 36483   | 10      |
| publicRelease                           | 409             | 409    | 409    | 409     | 1       |
| queue                                   | 475             | 875    | 475    | 2475    | 5       |
| recoverERC20                            | 58415           | 58415  | 58415  | 58415   | 1       |
| recoverEther                            | 23703           | 25991  | 25991  | 28280   | 2       |
| recoverStETHShares                      | 62866           | 62866  | 62866  | 62866   | 1       |
| removalCharge                           | 386             | 1386   | 1386   | 2386    | 2       |
| removeKeys                              | 23982           | 145203 | 172223 | 240204  | 15      |
| reportELRewardsStealingPenalty          | 24283           | 120450 | 136747 | 146752  | 14      |
| resetNodeOperatorManagerAddress         | 23690           | 31835  | 31312  | 38442   | 5       |
| resume                                  | 23730           | 26642  | 26642  | 29555   | 2       |
| revokeRole                              | 29529           | 29529  | 29529  | 29529   | 1       |
| setAccounting                           | 24246           | 46365  | 46475  | 46475   | 203     |
| setEarlyAdoption                        | 23984           | 38612  | 46453  | 46453   | 8       |
| setRemovalCharge                        | 24026           | 47003  | 47146  | 47158   | 162     |
| settleELRewardsStealingPenalty          | 24646           | 67398  | 38696  | 112049  | 7       |
| submitInitialSlashing                   | 24058           | 97659  | 134113 | 135013  | 12      |
| submitWithdrawal                        | 24327           | 121321 | 140981 | 234701  | 14      |
| unsafeUpdateValidatorsCount             | 24263           | 61231  | 35920  | 159782  | 10      |
| updateExitedValidatorsCount             | 24789           | 58490  | 47467  | 110195  | 11      |
| updateRefundedValidatorsCount           | 24136           | 27723  | 27723  | 31310   | 2       |
| updateStuckValidatorsCount              | 24811           | 73011  | 60534  | 138474  | 13      |
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
| recoverEther                                             | 1816            | 17666 | 17666  | 33516 | 4       |




