| lib/base-oracle/oracle/HashConsensus.sol:HashConsensus contract |                 |        |        |        |         |
|-----------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                 | Deployment Size |        |        |        |         |
| 3243314                                                         | 16051           |        |        |        |         |
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
| Deployment Cost                            | Deployment Size |        |        |        |         |
| 5186086                                    | 25688           |        |        |        |         |
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 275             | 275    | 275    | 275    | 168     |
| RESET_BOND_CURVE_ROLE                      | 296             | 296    | 296    | 296    | 210     |
| SET_BOND_CURVE_ROLE                        | 274             | 274    | 274    | 274    | 210     |
| addBondCurve                               | 121324          | 121324 | 121324 | 121324 | 5       |
| getActualLockedBond                        | 581             | 687    | 741    | 741    | 3       |
| getBondAmountByKeysCount                   | 1303            | 1395   | 1303   | 1566   | 153     |
| getBondAmountByKeysCountWstETH             | 14217           | 14217  | 14217  | 14217  | 2       |
| getBondCurve                               | 2204            | 16003  | 16300  | 16300  | 157     |
| getBondLockRetentionPeriod                 | 2370            | 2370   | 2370   | 2370   | 2       |
| getLockedBondInfo                          | 837             | 837    | 837    | 837    | 6       |
| getRequiredBondForNextKeys                 | 10197           | 33405  | 52697  | 53223  | 13      |
| getRequiredBondForNextKeysWstETH           | 59047           | 59047  | 59047  | 59047  | 2       |
| getUnbondedKeysCount                       | 7775            | 24005  | 15775  | 46275  | 249     |
| grantRole                                  | 118386          | 118389 | 118386 | 118398 | 588     |


| src/CSEarlyAdoption.sol:CSEarlyAdoption contract |                 |       |        |       |         |
|--------------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                                  | Deployment Size |       |        |       |         |
| 351780                                           | 1423            |       |        |       |         |
| Function Name                                    | min             | avg   | median | max   | # calls |
| consume                                          | 24919           | 37973 | 29967  | 51280 | 7       |
| consumed                                         | 549             | 549   | 549    | 549   | 1       |
| curveId                                          | 284             | 1784  | 2284   | 2284  | 4       |
| isEligible                                       | 1378            | 1378  | 1378   | 1378  | 2       |
| module                                           | 358             | 358   | 358    | 358   | 1       |
| treeRoot                                         | 306             | 306   | 306    | 306   | 1       |


| src/CSFeeDistributor.sol:CSFeeDistributor contract |                 |        |        |        |         |
|----------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                    | Deployment Size |        |        |        |         |
| 1271985                                            | 6368            |        |        |        |         |
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
| Deployment Cost                          | Deployment Size |        |        |        |         |
| 2641146                                  | 12323           |        |        |        |         |
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
| Deployment Cost                         | Deployment Size |        |        |         |         |
| 5311802                                 | 24695           |        |        |         |         |
| Function Name                           | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                      | 305             | 305    | 305    | 305     | 1       |
| DEPOSIT_SIZE                            | 307             | 307    | 307    | 307     | 10      |
| EL_REWARDS_STEALING_FINE                | 328             | 328    | 328    | 328     | 4       |
| INITIALIZE_ROLE                         | 308             | 308    | 308    | 308     | 217     |
| INITIAL_SLASHING_PENALTY                | 352             | 352    | 352    | 352     | 3       |
| MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE  | 315             | 315    | 315    | 315     | 1       |
| MODULE_MANAGER_ROLE                     | 328             | 328    | 328    | 328     | 172     |
| PAUSE_ROLE                              | 285             | 285    | 285    | 285     | 169     |
| PENALIZE_ROLE                           | 284             | 284    | 284    | 284     | 170     |
| RECOVERER_ROLE                          | 283             | 283    | 283    | 283     | 5       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE | 286             | 286    | 286    | 286     | 170     |
| RESUME_ROLE                             | 286             | 286    | 286    | 286     | 169     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE | 306             | 306    | 306    | 306     | 170     |
| STAKING_ROUTER_ROLE                     | 283             | 283    | 283    | 283     | 191     |
| VERIFIER_ROLE                           | 305             | 305    | 305    | 305     | 172     |
| accounting                              | 427             | 427    | 427    | 427     | 1       |
| addNodeOperatorETH                      | 26187           | 602890 | 547242 | 1072404 | 153     |
| addNodeOperatorStETH                    | 26190           | 280014 | 280014 | 533838  | 2       |
| addNodeOperatorStETHWithPermit          | 26946           | 283354 | 283354 | 539763  | 2       |
| addNodeOperatorWstETH                   | 26192           | 291468 | 291468 | 556744  | 2       |
| addNodeOperatorWstETHWithPermit         | 26946           | 290004 | 290004 | 553063  | 2       |
| addValidatorKeysETH                     | 25615           | 229191 | 259129 | 313546  | 6       |
| addValidatorKeysStETH                   | 25596           | 133012 | 133012 | 240429  | 2       |
| addValidatorKeysStETHWithPermit         | 26351           | 136201 | 136201 | 246051  | 2       |
| addValidatorKeysWstETH                  | 25643           | 142079 | 142079 | 258516  | 2       |
| addValidatorKeysWstETHWithPermit        | 26396           | 145258 | 145258 | 264120  | 2       |
| cancelELRewardsStealingPenalty          | 26275           | 90246  | 99911  | 134888  | 4       |
| cleanDepositQueue                       | 26304           | 36076  | 33834  | 53080   | 12      |
| confirmNodeOperatorManagerAddressChange | 23712           | 29037  | 29097  | 34186   | 5       |
| confirmNodeOperatorRewardAddressChange  | 23691           | 33081  | 33970  | 38918   | 6       |
| decreaseOperatorVettedKeys              | 24802           | 91397  | 107440 | 155179  | 15      |
| depositQueueItem                        | 624             | 1224   | 624    | 2624    | 10      |
| earlyAdoption                           | 471             | 471    | 471    | 471     | 1       |
| getNodeOperator                         | 2259            | 9884   | 8259   | 20259   | 288     |
| getNodeOperatorSigningKeys              | 819             | 2877   | 3594   | 3594    | 7       |
| getNodeOperatorSummary                  | 1515            | 5426   | 7515   | 7515    | 45      |
| getNodeOperatorsCount                   | 403             | 464    | 403    | 2403    | 327     |
| getNonce                                | 402             | 702    | 402    | 2402    | 40      |
| getStakingModuleSummary                 | 640             | 2890   | 2640   | 4640    | 16      |
| getType                                 | 383             | 383    | 383    | 383     | 1       |
| grantRole                               | 26965           | 51457  | 51473  | 51473   | 1582    |
| hasRole                                 | 769             | 769    | 769    | 769     | 2       |
| isPaused                                | 461             | 861    | 461    | 2461    | 5       |
| normalizeQueue                          | 30233           | 54712  | 54712  | 79191   | 2       |
| obtainDepositData                       | 24421           | 107050 | 96713  | 158508  | 43      |
| onExitedAndStuckValidatorsCountsUpdated | 23682           | 23715  | 23715  | 23748   | 2       |
| onRewardsMinted                         | 23954           | 32109  | 26189  | 46185   | 3       |
| onWithdrawalCredentialsChanged          | 23661           | 23694  | 23694  | 23727   | 2       |
| pauseFor                                | 23988           | 45929  | 47497  | 47497   | 15      |
| penalize                                | 24131           | 87230  | 105030 | 119157  | 8       |
| proposeNodeOperatorManagerAddressChange | 24165           | 42614  | 53604  | 53604   | 9       |
| proposeNodeOperatorRewardAddressChange  | 24166           | 33434  | 36483  | 36483   | 10      |
| publicReleaseTimestamp                  | 384             | 384    | 384    | 384     | 1       |
| queue                                   | 520             | 920    | 520    | 2520    | 5       |
| recoverERC20                            | 31862           | 48877  | 48877  | 65892   | 2       |
| recoverEther                            | 23718           | 26011  | 26011  | 28304   | 2       |
| recoverStETHShares                      | 69862           | 69862  | 69862  | 69862   | 1       |
| removalCharge                           | 2408            | 2408   | 2408   | 2408    | 1       |
| removeKeys                              | 23982           | 145205 | 172225 | 240207  | 15      |
| reportELRewardsStealingPenalty          | 24328           | 119017 | 136859 | 146864  | 12      |
| resetNodeOperatorManagerAddress         | 23690           | 31835  | 31312  | 38442   | 5       |
| resume                                  | 23707           | 26619  | 26619  | 29532   | 2       |
| revokeRole                              | 29529           | 29529  | 29529  | 29529   | 1       |
| setAccounting                           | 24268           | 46392  | 46497  | 46497   | 213     |
| setEarlyAdoption                        | 24006           | 38634  | 46475  | 46475   | 8       |
| setPublicReleaseTimestamp               | 23909           | 41673  | 47059  | 47059   | 8       |
| setRemovalCharge                        | 24026           | 46981  | 47117  | 47129   | 170     |
| settleELRewardsStealingPenalty          | 24690           | 59986  | 38696  | 111722  | 6       |
| submitInitialSlashing                   | 24058           | 101712 | 139167 | 140067  | 12      |
| submitWithdrawal                        | 24327           | 120989 | 141015 | 234746  | 14      |
| unsafeUpdateValidatorsCount             | 24231           | 61214  | 35897  | 159804  | 10      |
| updateExitedValidatorsCount             | 24801           | 58502  | 47479  | 110207  | 11      |
| updateRefundedValidatorsCount           | 24104           | 27691  | 27691  | 31278   | 2       |
| updateStuckValidatorsCount              | 24756           | 72980  | 60488  | 138473  | 13      |
| updateTargetValidatorsLimits            | 24292           | 118226 | 137467 | 210387  | 19      |


| src/CSVerifier.sol:CSVerifier contract |                 |        |        |        |         |
|----------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                        | Deployment Size |        |        |        |         |
| 1547301                                | 7449            |        |        |        |         |
| Function Name                          | min             | avg    | median | max    | # calls |
| BEACON_ROOTS                           | 260             | 260    | 260    | 260    | 3       |
| initialize                             | 66498           | 66498  | 66498  | 66498  | 3       |
| processHistoricalWithdrawalProof       | 152118          | 152118 | 152118 | 152118 | 1       |
| processSlashingProof                   | 83048           | 83048  | 83048  | 83048  | 1       |
| processWithdrawalProof                 | 107007          | 107007 | 107007 | 107007 | 1       |


| src/lib/AssetRecovererLib.sol:AssetRecovererLib contract |                 |       |        |       |         |
|----------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                                          | Deployment Size |       |        |       |         |
| 413472                                                   | 2118            |       |        |       |         |
| Function Name                                            | min             | avg   | median | max   | # calls |
| recoverERC1155                                           | 38590           | 38590 | 38590  | 38590 | 1       |
| recoverERC20                                             | 35969           | 35969 | 35969  | 35969 | 4       |
| recoverERC721                                            | 43274           | 43274 | 43274  | 43274 | 1       |
| recoverEther                                             | 1816            | 12382 | 1816   | 33516 | 3       |


