| lib/base-oracle/oracle/HashConsensus.sol:HashConsensus contract |                 |        |        |        |         |
|-----------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                                   | min             | avg    | median | max    | # calls |
| DISABLE_CONSENSUS_ROLE                                          | 261             | 261    | 261    | 261    | 2       |
| MANAGE_FAST_LANE_CONFIG_ROLE                                    | 285             | 285    | 285    | 285    | 2       |
| MANAGE_FRAME_CONFIG_ROLE                                        | 263             | 263    | 263    | 263    | 2       |
| MANAGE_MEMBERS_AND_QUORUM_ROLE                                  | 283             | 283    | 283    | 283    | 2       |
| MANAGE_REPORT_PROCESSOR_ROLE                                    | 304             | 304    | 304    | 304    | 2       |
| addMember                                                       | 100214          | 120552 | 105072 | 156372 | 3       |
| getChainConfig                                                  | 346             | 346    | 346    | 346    | 2       |
| getConsensusState                                               | 4484            | 4484   | 4484   | 4484   | 1       |
| getCurrentFrame                                                 | 2618            | 2618   | 2618   | 2618   | 7       |
| getInitialRefSlot                                               | 3807            | 3807   | 3807   | 3807   | 2       |
| grantRole                                                       | 118213          | 118222 | 118225 | 118225 | 10      |
| submitReport                                                    | 118546          | 138070 | 138070 | 157594 | 2       |
| updateInitialEpoch                                              | 40570           | 40570  | 40570  | 40570  | 2       |


| src/CSAccounting.sol:CSAccounting contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 275             | 275    | 275    | 275    | 164     |
| RESET_BOND_CURVE_ROLE                      | 296             | 296    | 296    | 296    | 204     |
| SET_BOND_CURVE_ROLE                        | 274             | 274    | 274    | 274    | 204     |
| addBondCurve                               | 121324          | 121324 | 121324 | 121324 | 5       |
| getActualLockedBond                        | 581             | 687    | 741    | 741    | 3       |
| getBondAmountByKeysCount                   | 1303            | 1397   | 1303   | 1566   | 147     |
| getBondAmountByKeysCountWstETH             | 14217           | 14217  | 14217  | 14217  | 2       |
| getBondCurve                               | 2204            | 15992  | 16300  | 16300  | 151     |
| getBondLockRetentionPeriod                 | 2370            | 2370   | 2370   | 2370   | 2       |
| getLockedBondInfo                          | 837             | 837    | 837    | 837    | 6       |
| getRequiredBondForNextKeys                 | 10152           | 33360  | 52652  | 53178  | 13      |
| getRequiredBondForNextKeysWstETH           | 59002           | 59002  | 59002  | 59002  | 2       |
| getUnbondedKeysCount                       | 7730            | 24022  | 15730  | 46230  | 240     |
| grantRole                                  | 118386          | 118389 | 118386 | 118398 | 572     |


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
| RECOVERER_ROLE                                     | 261             | 261    | 261    | 261    | 3       |
| distributeFees                                     | 22306           | 48119  | 44639  | 93152  | 5       |
| distributedShares                                  | 523             | 1523   | 1523   | 2523   | 4       |
| grantRole                                          | 118348          | 118348 | 118348 | 118348 | 3       |
| receiveFees                                        | 73146           | 75588  | 75588  | 78030  | 2       |
| recoverERC20                                       | 24450           | 41465  | 41465  | 58480  | 2       |
| recoverStETHShares                                 | 39753           | 39753  | 39753  | 39753  | 1       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 262             | 262    | 262    | 262    | 2       |
| MANAGE_CONSENSUS_VERSION_ROLE            | 262             | 262    | 262    | 262    | 2       |
| PAUSE_ROLE                               | 285             | 285    | 285    | 285    | 2       |
| RESUME_ROLE                              | 307             | 307    | 307    | 307    | 2       |
| SUBMIT_DATA_ROLE                         | 262             | 262    | 262    | 262    | 3       |
| getConsensusReport                       | 948             | 1355   | 961    | 2948   | 10      |
| getConsensusVersion                      | 396             | 1729   | 2396   | 2396   | 3       |
| getLastProcessingRefSlot                 | 440             | 2190   | 2440   | 2440   | 8       |
| grantRole                                | 101103          | 115093 | 118203 | 118203 | 11      |
| initialize                               | 260549          | 260555 | 260555 | 260561 | 2       |
| submitReportData                         | 97163           | 97163  | 97163  | 97163  | 1       |
| treeCid                                  | 1292            | 1292   | 1292   | 1292   | 1       |
| treeRoot                                 | 363             | 363    | 363    | 363    | 1       |


| src/CSModule.sol:CSModule contract      |                 |        |        |         |         |
|-----------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                           | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                      | 283             | 283    | 283    | 283     | 1       |
| DEPOSIT_SIZE                            | 329             | 329    | 329    | 329     | 10      |
| EL_REWARDS_STEALING_FINE                | 306             | 306    | 306    | 306     | 5       |
| INITIALIZE_ROLE                         | 285             | 285    | 285    | 285     | 211     |
| INITIAL_SLASHING_PENALTY                | 352             | 352    | 352    | 352     | 3       |
| MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE  | 293             | 293    | 293    | 293     | 1       |
| MODULE_MANAGER_ROLE                     | 306             | 306    | 306    | 306     | 208     |
| PAUSE_ROLE                              | 307             | 307    | 307    | 307     | 165     |
| PENALIZE_ROLE                           | 307             | 307    | 307    | 307     | 164     |
| RECOVERER_ROLE                          | 328             | 328    | 328    | 328     | 5       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE | 286             | 286    | 286    | 286     | 166     |
| RESUME_ROLE                             | 286             | 286    | 286    | 286     | 165     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE | 328             | 328    | 328    | 328     | 166     |
| STAKING_ROUTER_ROLE                     | 283             | 283    | 283    | 283     | 187     |
| VERIFIER_ROLE                           | 305             | 305    | 305    | 305     | 168     |
| accounting                              | 470             | 470    | 470    | 470     | 1       |
| activatePublicRelease                   | 23726           | 46548  | 46677  | 46677   | 178     |
| addNodeOperatorETH                      | 26187           | 602878 | 547183 | 1072345 | 147     |
| addNodeOperatorStETH                    | 26235           | 280029 | 280029 | 533824  | 2       |
| addNodeOperatorStETHWithPermit          | 26946           | 283325 | 283325 | 539704  | 2       |
| addNodeOperatorWstETH                   | 26192           | 291438 | 291438 | 556685  | 2       |
| addNodeOperatorWstETHWithPermit         | 26988           | 290017 | 290017 | 553046  | 2       |
| addValidatorKeysETH                     | 25615           | 229101 | 259021 | 313438  | 6       |
| addValidatorKeysStETH                   | 25596           | 132958 | 132958 | 240321  | 2       |
| addValidatorKeysStETHWithPermit         | 26351           | 136147 | 136147 | 245943  | 2       |
| addValidatorKeysWstETH                  | 25643           | 142025 | 142025 | 258408  | 2       |
| addValidatorKeysWstETHWithPermit        | 26351           | 145159 | 145159 | 263967  | 2       |
| cancelELRewardsStealingPenalty          | 26233           | 90154  | 99802  | 134779  | 4       |
| cleanDepositQueue                       | 26304           | 36076  | 33834  | 53080   | 12      |
| confirmNodeOperatorManagerAddressChange | 23712           | 29037  | 29097  | 34186   | 5       |
| confirmNodeOperatorRewardAddressChange  | 23713           | 33103  | 33992  | 38940   | 6       |
| decreaseOperatorVettedKeys              | 24802           | 91358  | 107395 | 155089  | 15      |
| depositQueueItem                        | 646             | 1246   | 646    | 2646    | 10      |
| earlyAdoption                           | 471             | 471    | 471    | 471     | 1       |
| getNodeOperator                         | 2214            | 9832   | 8214   | 20214   | 278     |
| getNodeOperatorSigningKeys              | 841             | 2899   | 3616   | 3616    | 7       |
| getNodeOperatorSummary                  | 1493            | 5446   | 7493   | 7493    | 43      |
| getNodeOperatorsCount                   | 381             | 444    | 381    | 2381    | 317     |
| getNonce                                | 380             | 680    | 380    | 2380    | 40      |
| getStakingModuleSummary                 | 618             | 2751   | 2618   | 4618    | 15      |
| getType                                 | 383             | 383    | 383    | 383     | 1       |
| grantRole                               | 26965           | 51457  | 51473  | 51473   | 1583    |
| hasRole                                 | 747             | 747    | 747    | 747     | 2       |
| isPaused                                | 439             | 839    | 439    | 2439    | 5       |
| normalizeQueue                          | 30211           | 54690  | 54690  | 79169   | 2       |
| obtainDepositData                       | 24465           | 107094 | 96757  | 158552  | 43      |
| onExitedAndStuckValidatorsCountsUpdated | 23682           | 23715  | 23715  | 23748   | 2       |
| onRewardsMinted                         | 23954           | 32109  | 26189  | 46185   | 3       |
| onWithdrawalCredentialsChanged          | 23639           | 23672  | 23672  | 23705   | 2       |
| pauseFor                                | 23988           | 45929  | 47497  | 47497   | 15      |
| proposeNodeOperatorManagerAddressChange | 24165           | 42614  | 53604  | 53604   | 9       |
| proposeNodeOperatorRewardAddressChange  | 24166           | 33434  | 36483  | 36483   | 10      |
| publicRelease                           | 387             | 387    | 387    | 387     | 1       |
| queue                                   | 520             | 920    | 520    | 2520    | 5       |
| recoverERC20                            | 31862           | 48877  | 48877  | 65892   | 2       |
| recoverEther                            | 23740           | 26033  | 26033  | 28326   | 2       |
| recoverStETHShares                      | 69884           | 69884  | 69884  | 69884   | 1       |
| removalCharge                           | 2408            | 2408   | 2408   | 2408    | 1       |
| removeKeys                              | 23982           | 145174 | 172189 | 240171  | 15      |
| reportELRewardsStealingPenalty          | 24283           | 120450 | 136747 | 146752  | 14      |
| resetNodeOperatorManagerAddress         | 23690           | 31835  | 31312  | 38442   | 5       |
| resume                                  | 23707           | 26619  | 26619  | 29532   | 2       |
| revokeRole                              | 29529           | 29529  | 29529  | 29529   | 1       |
| setAccounting                           | 24268           | 46389  | 46497  | 46497   | 207     |
| setEarlyAdoption                        | 23984           | 38612  | 46453  | 46453   | 8       |
| setRemovalCharge                        | 23981           | 46931  | 47071  | 47083   | 166     |
| settleELRewardsStealingPenalty          | 24646           | 67374  | 38652  | 112050  | 7       |
| submitInitialSlashing                   | 24058           | 101332 | 139122 | 140022  | 12      |
| submitWithdrawal                        | 24283           | 120913 | 140926 | 234657  | 14      |
| unsafeUpdateValidatorsCount             | 24231           | 61205  | 35897  | 159759  | 10      |
| updateExitedValidatorsCount             | 24779           | 58480  | 47457  | 110185  | 11      |
| updateRefundedValidatorsCount           | 24082           | 27669  | 27669  | 31256   | 2       |
| updateStuckValidatorsCount              | 24801           | 73008  | 60533  | 138473  | 13      |
| updateTargetValidatorsLimits            | 24270           | 118166 | 137400 | 210320  | 19      |


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


