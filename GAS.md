| src/CSAccounting.sol:CSAccounting contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 275             | 275    | 275    | 275    | 161     |
| INITIALIZE_ROLE                            | 296             | 296    | 296    | 296    | 161     |
| RESET_BOND_CURVE_ROLE                      | 296             | 296    | 296    | 296    | 201     |
| SET_BOND_CURVE_ROLE                        | 252             | 252    | 252    | 252    | 201     |
| addBondCurve                               | 121302          | 121302 | 121302 | 121302 | 5       |
| feeDistributor                             | 2450            | 2450   | 2450   | 2450   | 2       |
| getActualLockedBond                        | 559             | 665    | 719    | 719    | 3       |
| getBondAmountByKeysCount                   | 1325            | 1421   | 1325   | 1588   | 145     |
| getBondAmountByKeysCountWstETH             | 14173           | 14173  | 14173  | 14173  | 2       |
| getBondCurve                               | 2226            | 16010  | 16322  | 16322  | 149     |
| getBondLockRetentionPeriod                 | 2413            | 2413   | 2413   | 2413   | 2       |
| getLockedBondInfo                          | 793             | 793    | 793    | 793    | 6       |
| getRequiredBondForNextKeys                 | 10108           | 33316  | 52608  | 53134  | 13      |
| getRequiredBondForNextKeysWstETH           | 59002           | 59002  | 59002  | 59002  | 2       |
| getUnbondedKeysCount                       | 7730            | 24192  | 15730  | 46230  | 238     |
| grantRole                                  | 118364          | 118369 | 118364 | 118376 | 724     |
| setFeeDistributor                          | 47523           | 47523  | 47523  | 47523  | 161     |


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
| EL_REWARDS_STEALING_FINE                | 306             | 306    | 306    | 306     | 5       |
| INITIALIZE_ROLE                         | 286             | 286    | 286    | 286     | 208     |
| INITIAL_SLASHING_PENALTY                | 352             | 352    | 352    | 352     | 3       |
| MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE  | 293             | 293    | 293    | 293     | 1       |
| MODULE_MANAGER_ROLE                     | 306             | 306    | 306    | 306     | 205     |
| PAUSE_ROLE                              | 285             | 285    | 285    | 285     | 162     |
| PENALIZE_ROLE                           | 307             | 307    | 307    | 307     | 161     |
| RECOVERER_ROLE                          | 283             | 283    | 283    | 283     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE | 327             | 327    | 327    | 327     | 163     |
| RESUME_ROLE                             | 329             | 329    | 329    | 329     | 162     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE | 284             | 284    | 284    | 284     | 163     |
| STAKING_ROUTER_ROLE                     | 360             | 360    | 360    | 360     | 185     |
| VERIFIER_ROLE                           | 327             | 327    | 327    | 327     | 165     |
| accounting                              | 448             | 448    | 448    | 448     | 1       |
| activatePublicRelease                   | 23726           | 46545  | 46677  | 46677   | 175     |
| addNodeOperatorETH                      | 26187           | 603727 | 547265 | 1072427 | 145     |
| addNodeOperatorStETH                    | 26973           | 367346 | 535275 | 539790  | 3       |
| addNodeOperatorWstETH                   | 26996           | 379416 | 553087 | 558166  | 3       |
| addValidatorKeysETH                     | 25615           | 229101 | 259021 | 313438  | 6       |
| addValidatorKeysStETH                   | 26351           | 171217 | 241387 | 245914  | 3       |
| addValidatorKeysWstETH                  | 26351           | 183287 | 259495 | 264016  | 3       |
| cancelELRewardsStealingPenalty          | 26253           | 90174  | 99822  | 134799  | 4       |
| cleanDepositQueue                       | 26282           | 36054  | 33812  | 53058   | 12      |
| confirmNodeOperatorManagerAddressChange | 23712           | 29037  | 29097  | 34186   | 5       |
| confirmNodeOperatorRewardAddressChange  | 23669           | 33059  | 33948  | 38896   | 6       |
| decreaseOperatorVettedKeys              | 24834           | 91390  | 107427 | 155121  | 15      |
| depositQueueItem                        | 624             | 1224   | 624    | 2624    | 10      |
| earlyAdoption                           | 427             | 427    | 427    | 427     | 1       |
| getNodeOperator                         | 2214            | 9844   | 8214   | 20214   | 276     |
| getNodeOperatorSigningKeys              | 819             | 2877   | 3594   | 3594    | 7       |
| getNodeOperatorSummary                  | 1493            | 5446   | 7493   | 7493    | 43      |
| getNodeOperatorsCount                   | 403             | 466    | 403    | 2403    | 313     |
| getNonce                                | 380             | 680    | 380    | 2380    | 40      |
| getStakingModuleSummary                 | 661             | 2794   | 2661   | 4661    | 15      |
| getType                                 | 405             | 405    | 405    | 405     | 1       |
| grantRole                               | 26943           | 51435  | 51451  | 51451   | 1556    |
| hasRole                                 | 748             | 748    | 748    | 748     | 2       |
| isPaused                                | 461             | 861    | 461    | 2461    | 5       |
| normalizeQueue                          | 30233           | 54712  | 54712  | 79191   | 2       |
| obtainDepositData                       | 24497           | 107126 | 96789  | 158584  | 43      |
| onExitedAndStuckValidatorsCountsUpdated | 23670           | 23703  | 23703  | 23736   | 2       |
| onRewardsMinted                         | 23986           | 47002  | 47143  | 69879   | 3       |
| onWithdrawalCredentialsChanged          | 23738           | 25224  | 24967  | 26967   | 3       |
| pauseFor                                | 23988           | 45359  | 47497  | 47497   | 11      |
| proposeNodeOperatorManagerAddressChange | 24165           | 42614  | 53604  | 53604   | 9       |
| proposeNodeOperatorRewardAddressChange  | 24144           | 33412  | 36461  | 36461   | 10      |
| publicRelease                           | 409             | 409    | 409    | 409     | 1       |
| queue                                   | 475             | 875    | 475    | 2475    | 5       |
| recoverERC20                            | 58415           | 58415  | 58415  | 58415   | 1       |
| recoverEther                            | 23747           | 26035  | 26035  | 28324   | 2       |
| recoverStETHShares                      | 62866           | 62866  | 62866  | 62866   | 1       |
| removalCharge                           | 386             | 1386   | 1386   | 2386    | 2       |
| removeKeys                              | 23982           | 145203 | 172223 | 240204  | 15      |
| reportELRewardsStealingPenalty          | 24306           | 120473 | 136770 | 146775  | 14      |
| resetNodeOperatorManagerAddress         | 23690           | 31835  | 31312  | 38442   | 5       |
| resume                                  | 23730           | 26642  | 26642  | 29555   | 2       |
| revokeRole                              | 29529           | 29529  | 29529  | 29529   | 1       |
| setAccounting                           | 24246           | 46366  | 46475  | 46475   | 204     |
| setEarlyAdoption                        | 23984           | 38612  | 46453  | 46453   | 8       |
| setRemovalCharge                        | 24004           | 46982  | 47124  | 47136   | 163     |
| settleELRewardsStealingPenalty          | 24690           | 67441  | 38740  | 112093  | 7       |
| submitInitialSlashing                   | 24058           | 97659  | 134113 | 135013  | 12      |
| submitWithdrawal                        | 24305           | 121299 | 140959 | 234679  | 14      |
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




