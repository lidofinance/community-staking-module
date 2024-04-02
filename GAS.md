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
| 5156888                                    | 25566           |        |        |        |         |
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 275             | 275    | 275    | 275    | 168     |
| addBondCurve                               | 121324          | 121324 | 121324 | 121324 | 5       |
| getActualLockedBond                        | 581             | 687    | 741    | 741    | 3       |
| getBondAmountByKeysCount                   | 1303            | 1397   | 1303   | 1566   | 151     |
| getBondAmountByKeysCountWstETH             | 14195           | 14195  | 14195  | 14195  | 2       |
| getBondCurve                               | 2204            | 16000  | 16300  | 16300  | 155     |
| getBondLockRetentionPeriod                 | 2370            | 2370   | 2370   | 2370   | 2       |
| getLockedBondInfo                          | 837             | 837    | 837    | 837    | 6       |
| getRequiredBondForNextKeys                 | 10153           | 33361  | 52653  | 53179  | 13      |
| getRequiredBondForNextKeysWstETH           | 59025           | 59025  | 59025  | 59025  | 2       |
| getUnbondedKeysCount                       | 7753            | 24012  | 15753  | 46253  | 246     |
| grantRole                                  | 118398          | 118398 | 118398 | 118398 | 168     |


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
| 5347521                                 | 24860           |        |        |         |         |
| Function Name                           | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                      | 283             | 283    | 283    | 283     | 1       |
| DEPOSIT_SIZE                            | 307             | 307    | 307    | 307     | 10      |
| EL_REWARDS_STEALING_FINE                | 328             | 328    | 328    | 328     | 4       |
| INITIAL_SLASHING_PENALTY                | 352             | 352    | 352    | 352     | 3       |
| MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE  | 293             | 293    | 293    | 293     | 1       |
| PAUSE_ROLE                              | 285             | 285    | 285    | 285     | 169     |
| PENALIZE_ROLE                           | 329             | 329    | 329    | 329     | 170     |
| RECOVERER_ROLE                          | 283             | 283    | 283    | 283     | 5       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE | 286             | 286    | 286    | 286     | 170     |
| RESUME_ROLE                             | 286             | 286    | 286    | 286     | 169     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE | 306             | 306    | 306    | 306     | 170     |
| SET_ACCOUNTING_ROLE                     | 306             | 306    | 306    | 306     | 213     |
| SET_EARLY_ADOPTION_ROLE                 | 285             | 285    | 285    | 285     | 170     |
| SET_PUBLIC_RELEASE_TIMESTAMP_ROLE       | 284             | 284    | 284    | 284     | 170     |
| SET_REMOVAL_CHARGE_ROLE                 | 328             | 328    | 328    | 328     | 170     |
| SLASHING_SUBMITTER_ROLE                 | 306             | 306    | 306    | 306     | 168     |
| STAKING_ROUTER_ROLE                     | 283             | 283    | 283    | 283     | 190     |
| WITHDRAWAL_SUBMITTER_ROLE               | 305             | 305    | 305    | 305     | 170     |
| accounting                              | 470             | 470    | 470    | 470     | 1       |
| addNodeOperatorETH                      | 26187           | 603642 | 547304 | 1072466 | 151     |
| addNodeOperatorStETH                    | 26190           | 280045 | 280045 | 533900  | 2       |
| addNodeOperatorStETHWithPermit          | 26946           | 283385 | 283385 | 539825  | 2       |
| addNodeOperatorWstETH                   | 26237           | 291533 | 291533 | 556829  | 2       |
| addNodeOperatorWstETHWithPermit         | 26946           | 290013 | 290013 | 553080  | 2       |
| addValidatorKeysETH                     | 25615           | 229206 | 259147 | 313564  | 6       |
| addValidatorKeysStETH                   | 25596           | 133021 | 133021 | 240447  | 2       |
| addValidatorKeysStETHWithPermit         | 26351           | 136210 | 136210 | 246069  | 2       |
| addValidatorKeysWstETH                  | 25643           | 142099 | 142099 | 258556  | 2       |
| addValidatorKeysWstETHWithPermit        | 26396           | 145266 | 145266 | 264137  | 2       |
| cancelELRewardsStealingPenalty          | 26275           | 90230  | 99889  | 134866  | 4       |
| cleanDepositQueue                       | 26304           | 36076  | 33834  | 53080   | 12      |
| confirmNodeOperatorManagerAddressChange | 23690           | 29015  | 29075  | 34164   | 5       |
| confirmNodeOperatorRewardAddressChange  | 23714           | 33104  | 33993  | 38941   | 6       |
| decreaseOperatorVettedKeys              | 24802           | 91378  | 107418 | 155135  | 15      |
| depositQueueItem                        | 645             | 1245   | 645    | 2645    | 10      |
| earlyAdoption                           | 471             | 471    | 471    | 471     | 1       |
| getNodeOperator                         | 2237            | 9851   | 8237   | 20237   | 285     |
| getNodeOperatorSigningKeys              | 819             | 2877   | 3594   | 3594    | 7       |
| getNodeOperatorSummary                  | 1515            | 5426   | 7515   | 7515    | 45      |
| getNodeOperatorsCount                   | 403             | 464    | 403    | 2403    | 323     |
| getNonce                                | 402             | 702    | 402    | 2402    | 40      |
| getStakingModuleSummary                 | 618             | 2868   | 2618   | 4618    | 16      |
| getType                                 | 383             | 383    | 383    | 383     | 1       |
| grantRole                               | 26965           | 51461  | 51473  | 51473   | 2082    |
| hasRole                                 | 747             | 747    | 747    | 747     | 2       |
| isPaused                                | 461             | 861    | 461    | 2461    | 5       |
| normalizeQueue                          | 30233           | 54754  | 54754  | 79275   | 2       |
| obtainDepositData                       | 24421           | 107296 | 102387 | 158508  | 42      |
| onExitedAndStuckValidatorsCountsUpdated | 23682           | 23715  | 23715  | 23748   | 2       |
| onRewardsMinted                         | 23932           | 32087  | 26167  | 46163   | 3       |
| onWithdrawalCredentialsChanged          | 23639           | 23672  | 23672  | 23705   | 2       |
| pauseFor                                | 23988           | 45929  | 47497  | 47497   | 15      |
| penalize                                | 24131           | 85525  | 102756 | 116883  | 8       |
| proposeNodeOperatorManagerAddressChange | 24143           | 42592  | 53582  | 53582   | 9       |
| proposeNodeOperatorRewardAddressChange  | 24166           | 33434  | 36483  | 36483   | 10      |
| publicReleaseTimestamp                  | 429             | 429    | 429    | 429     | 1       |
| queue                                   | 520             | 920    | 520    | 2520    | 5       |
| recoverERC20                            | 31840           | 48855  | 48855  | 65870   | 2       |
| recoverEther                            | 23740           | 26033  | 26033  | 28326   | 2       |
| recoverStETHShares                      | 69885           | 69885  | 69885  | 69885   | 1       |
| removalCharge                           | 2408            | 2408   | 2408   | 2408    | 1       |
| removeKeys                              | 24026           | 145232 | 172243 | 240224  | 15      |
| reportELRewardsStealingPenalty          | 24328           | 118999 | 136837 | 146842  | 12      |
| resetNodeOperatorManagerAddress         | 23668           | 31813  | 31290  | 38420   | 5       |
| resume                                  | 23707           | 26619  | 26619  | 29532   | 2       |
| revokeRole                              | 29529           | 29529  | 29529  | 29529   | 1       |
| setAccounting                           | 24268           | 46391  | 46497  | 46497   | 211     |
| setEarlyAdoption                        | 24028           | 38656  | 46497  | 46497   | 8       |
| setPublicReleaseTimestamp               | 23954           | 41718  | 47104  | 47104   | 8       |
| setRemovalCharge                        | 23982           | 46937  | 47073  | 47085   | 170     |
| settleELRewardsStealingPenalty          | 24690           | 59228  | 38696  | 109448  | 6       |
| submitInitialSlashing                   | 26157           | 104093 | 136893 | 137793  | 10      |
| submitWithdrawal                        | 24283           | 120935 | 140949 | 234764  | 14      |
| unsafeUpdateValidatorsCount             | 24231           | 61210  | 35897  | 159782  | 10      |
| updateExitedValidatorsCount             | 24779           | 58480  | 47457  | 110185  | 11      |
| updateRefundedValidatorsCount           | 24082           | 27669  | 27669  | 31256   | 2       |
| updateStuckValidatorsCount              | 24801           | 73017  | 60533  | 138496  | 13      |
| updateTargetValidatorsLimits            | 24292           | 118212 | 137445 | 210449  | 19      |


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


