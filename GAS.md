| src/CSAccounting.sol:CSAccounting contract                  |                 |        |        |        |         |
|-------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                               | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                     | 318             | 318    | 318    | 318    | 196     |
| CSM                                                         | 328             | 328    | 328    | 328    | 1       |
| MANAGE_BOND_CURVES_ROLE                                     | 337             | 337    | 337    | 337    | 825     |
| MIN_BOND_LOCK_RETENTION_PERIOD                              | 339             | 339    | 339    | 339    | 1       |
| PAUSE_ROLE                                                  | 317             | 317    | 317    | 317    | 196     |
| RECOVERER_ROLE                                              | 317             | 317    | 317    | 317    | 12      |
| RESET_BOND_CURVE_ROLE                                       | 274             | 274    | 274    | 274    | 1       |
| RESUME_ROLE                                                 | 340             | 340    | 340    | 340    | 196     |
| SET_BOND_CURVE_ROLE                                         | 252             | 252    | 252    | 252    | 196     |
| addBondCurve                                                | 24381           | 101198 | 98720  | 304023 | 357     |
| chargeFee                                                   | 21810           | 48156  | 48156  | 74502  | 2       |
| chargePenaltyRecipient                                      | 405             | 405    | 405    | 405    | 1       |
| claimRewardsStETH                                           | 25075           | 78952  | 90944  | 98806  | 16      |
| claimRewardsUnstETH                                         | 25055           | 87788  | 109574 | 111836 | 16      |
| claimRewardsWstETH                                          | 25032           | 116284 | 155685 | 158103 | 16      |
| compensateLockedBondETH                                     | 45539           | 45539  | 45539  | 45539  | 1       |
| depositETH                                                  | 24149           | 111139 | 113066 | 113306 | 109     |
| depositStETH                                                | 25095           | 97687  | 107222 | 134905 | 9       |
| depositWstETH                                               | 25115           | 101754 | 121787 | 146852 | 8       |
| feeDistributor                                              | 426             | 1759   | 2426   | 2426   | 3       |
| getActualLockedBond                                         | 669             | 741    | 778    | 778    | 9       |
| getBondAmountByKeysCount                                    | 1131            | 1359   | 1282   | 1524   | 294     |
| getBondAmountByKeysCountWstETH(uint256,(uint256[],uint256)) | 3315            | 11261  | 14239  | 14239  | 11      |
| getBondAmountByKeysCountWstETH(uint256,uint256)             | 3592            | 8425   | 3834   | 22441  | 4       |
| getBondCurve                                                | 1950            | 11704  | 11950  | 11950  | 308     |
| getBondCurveId                                              | 582             | 582    | 582    | 582    | 2       |
| getBondLockRetentionPeriod                                  | 369             | 1702   | 2369   | 2369   | 3       |
| getBondShares                                               | 525             | 684    | 525    | 2525   | 88      |
| getBondSummary                                              | 12945           | 18151  | 16183  | 24683  | 27      |
| getBondSummaryShares                                        | 4519            | 15547  | 16169  | 24669  | 15      |
| getCurveInfo                                                | 1651            | 1815   | 1898   | 1898   | 3       |
| getLockedBondInfo                                           | 804             | 804    | 804    | 804    | 14      |
| getRequiredBondForNextKeys                                  | 4340            | 16578  | 16343  | 29343  | 45      |
| getRequiredBondForNextKeysWstETH                            | 10844           | 19631  | 16975  | 33936  | 20      |
| getUnbondedKeysCount                                        | 2607            | 11598  | 6695   | 25457  | 499     |
| getUnbondedKeysCountToEject                                 | 3889            | 6914   | 4336   | 13744  | 36      |
| grantRole                                                   | 29393           | 100153 | 118481 | 118481 | 1612    |
| initialize                                                  | 25980           | 557215 | 559899 | 559899 | 534     |
| isPaused                                                    | 428             | 828    | 428    | 2428   | 5       |
| lockBondETH                                                 | 21782           | 47343  | 48323  | 48347  | 27      |
| pauseFor                                                    | 23963           | 45328  | 47465  | 47465  | 11      |
| penalize                                                    | 21766           | 37000  | 37000  | 52234  | 2       |
| pullFeeRewards                                              | 25153           | 43484  | 30449  | 74851  | 3       |
| recoverERC20                                                | 24430           | 36161  | 24464  | 59591  | 3       |
| recoverEther                                                | 23781           | 37601  | 28662  | 60362  | 3       |
| recoverStETHShares                                          | 23759           | 43609  | 43609  | 63459  | 2       |
| releaseLockedBondETH                                        | 21804           | 25677  | 25677  | 29550  | 2       |
| renewBurnerAllowance                                        | 52288           | 52288  | 52288  | 52288  | 1       |
| resetBondCurve                                              | 23974           | 24786  | 24328  | 26056  | 3       |
| resume                                                      | 23793           | 26702  | 26702  | 29611  | 2       |
| setBondCurve                                                | 24135           | 50756  | 52775  | 52775  | 27      |
| setChargePenaltyRecipient                                   | 24111           | 26148  | 24116  | 30218  | 3       |
| setLockedBondRetentionPeriod                                | 30096           | 30096  | 30096  | 30096  | 1       |
| settleLockedBondETH                                         | 25337           | 36148  | 36148  | 46959  | 2       |
| totalBondShares                                             | 369             | 577    | 369    | 2369   | 48      |
| updateBondCurve                                             | 24443           | 37745  | 26582  | 62211  | 3       |


| src/CSEarlyAdoption.sol:CSEarlyAdoption contract |                 |       |        |       |         |
|--------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                    | min             | avg   | median | max   | # calls |
| CURVE_ID                                         | 347             | 347   | 347    | 347   | 1       |
| MODULE                                           | 374             | 374   | 374    | 374   | 1       |
| TREE_ROOT                                        | 325             | 325   | 325    | 325   | 1       |
| consume                                          | 22971           | 34906 | 26410  | 47785 | 7       |
| hashLeaf                                         | 1281            | 1281  | 1281   | 1281  | 1       |
| isConsumed                                       | 914             | 914   | 914    | 914   | 1       |
| verifyProof                                      | 2062            | 2062  | 2062   | 2062  | 2       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| CONTRACT_MANAGER_ROLE                    | 262             | 262    | 262    | 262    | 13      |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 239             | 239    | 239    | 239    | 13      |
| MANAGE_CONSENSUS_VERSION_ROLE            | 328             | 328    | 328    | 328    | 13      |
| PAUSE_ROLE                               | 262             | 262    | 262    | 262    | 13      |
| RECOVERER_ROLE                           | 305             | 305    | 305    | 305    | 1       |
| RESUME_ROLE                              | 262             | 262    | 262    | 262    | 13      |
| SUBMIT_DATA_ROLE                         | 284             | 284    | 284    | 284    | 24      |
| avgPerfLeewayBP                          | 405             | 405    | 405    | 405    | 1       |
| feeDistributor                           | 448             | 448    | 448    | 448    | 1       |
| getConsensusReport                       | 1018            | 2107   | 3018   | 3018   | 24      |
| getConsensusVersion                      | 396             | 1486   | 2396   | 2396   | 11      |
| getLastProcessingRefSlot                 | 494             | 2363   | 2494   | 2494   | 46      |
| getResumeSinceTimestamp                  | 462             | 462    | 462    | 462    | 1       |
| grantRole                                | 101382          | 115437 | 118482 | 118482 | 90      |
| initialize                               | 22903           | 228335 | 244138 | 244138 | 14      |
| pauseFor                                 | 47474           | 47474  | 47474  | 47474  | 2       |
| pauseUntil                               | 26181           | 40456  | 47490  | 47697  | 3       |
| recoverEther                             | 28633           | 28633  | 28633  | 28633  | 1       |
| resume                                   | 23503           | 26621  | 26621  | 29739  | 2       |
| setFeeDistributorContract                | 24050           | 27211  | 27211  | 30372  | 2       |
| setPerformanceLeeway                     | 24017           | 27037  | 27037  | 30057  | 2       |
| submitReportData                         | 25442           | 47501  | 35464  | 75579  | 5       |


| src/CSModule.sol:CSModule contract                  |                 |        |        |         |         |
|-----------------------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                                       | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                                  | 306             | 306    | 306    | 306     | 1       |
| EL_REWARDS_STEALING_FINE                            | 284             | 284    | 284    | 284     | 20      |
| INITIAL_SLASHING_PENALTY                            | 305             | 305    | 305    | 305     | 6       |
| LIDO_LOCATOR                                        | 305             | 305    | 305    | 305     | 2       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 329             | 329    | 329    | 329     | 3       |
| MODULE_MANAGER_ROLE                                 | 284             | 284    | 284    | 284     | 341     |
| PAUSE_ROLE                                          | 285             | 285    | 285    | 285     | 299     |
| RECOVERER_ROLE                                      | 284             | 284    | 284    | 284     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 328             | 328    | 328    | 328     | 300     |
| RESUME_ROLE                                         | 330             | 330    | 330    | 330     | 335     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 351             | 351    | 351    | 351     | 300     |
| STAKING_ROUTER_ROLE                                 | 338             | 338    | 338    | 338     | 322     |
| VERIFIER_ROLE                                       | 305             | 305    | 305    | 305     | 338     |
| accounting                                          | 471             | 471    | 471    | 471     | 1       |
| activatePublicRelease                               | 23790           | 29742  | 29664  | 46764   | 311     |
| addNodeOperatorETH                                  | 26741           | 425733 | 379924 | 1056792 | 292     |
| addNodeOperatorStETH                                | 27545           | 275798 | 315627 | 396593  | 8       |
| addNodeOperatorWstETH                               | 27567           | 281970 | 322184 | 408936  | 8       |
| addValidatorKeysETH                                 | 25657           | 164096 | 217377 | 271760  | 13      |
| addValidatorKeysStETH                               | 26416           | 132455 | 117357 | 228026  | 6       |
| addValidatorKeysWstETH                              | 26394           | 138795 | 133867 | 246335  | 6       |
| cancelELRewardsStealingPenalty                      | 26343           | 64040  | 74302  | 81214   | 4       |
| claimRewardsStETH                                   | 25013           | 67665  | 68213  | 109224  | 4       |
| claimRewardsUnstETH                                 | 25058           | 74225  | 74773  | 122299  | 4       |
| claimRewardsWstETH                                  | 25057           | 97357  | 97905  | 168564  | 4       |
| cleanDepositQueue                                   | 24580           | 40876  | 40989  | 61392   | 13      |
| compensateELRewardsStealingPenalty                  | 23743           | 77525  | 93147  | 100063  | 4       |
| confirmNodeOperatorManagerAddressChange             | 26990           | 29348  | 29136  | 32343   | 5       |
| confirmNodeOperatorRewardAddressChange              | 26830           | 30860  | 32161  | 32161   | 9       |
| decreaseVettedSigningKeysCount                      | 24920           | 61861  | 78050  | 100612  | 20      |
| depositETH                                          | 23755           | 92487  | 95944  | 115432  | 14      |
| depositQueue                                        | 480             | 813    | 480    | 2480    | 6       |
| depositQueueItem                                    | 623             | 1289   | 623    | 2623    | 12      |
| depositStETH                                        | 24748           | 94105  | 106478 | 125960  | 5       |
| depositWstETH                                       | 24729           | 93066  | 100620 | 123158  | 5       |
| earlyAdoption                                       | 450             | 450    | 450    | 450     | 1       |
| getActiveNodeOperatorsCount                         | 438             | 438    | 438    | 438     | 2       |
| getNodeOperator                                     | 2512            | 5498   | 6512   | 12512   | 73      |
| getNodeOperatorIds                                  | 769             | 1225   | 1174   | 1926    | 8       |
| getNodeOperatorIsActive                             | 515             | 515    | 515    | 515     | 1       |
| getNodeOperatorNonWithdrawnKeys                     | 592             | 696    | 592    | 2592    | 555     |
| getNodeOperatorSummary                              | 5942            | 6068   | 6005   | 6226    | 24      |
| getNodeOperatorsCount                               | 460             | 473    | 460    | 2460    | 304     |
| getNonce                                            | 403             | 560    | 403    | 2403    | 76      |
| getResumeSinceTimestamp                             | 485             | 485    | 485    | 485     | 2       |
| getSigningKeys                                      | 692             | 2768   | 3112   | 3503    | 8       |
| getSigningKeysWithSignatures                        | 716             | 3157   | 2957   | 5998    | 4       |
| getStakingModuleSummary                             | 475             | 475    | 475    | 475     | 20      |
| getType                                             | 316             | 316    | 316    | 316     | 2       |
| grantRole                                           | 27012           | 116005 | 118482 | 118482  | 2219    |
| hasRole                                             | 761             | 761    | 761    | 761     | 2       |
| initialize                                          | 25089           | 323717 | 326506 | 326506  | 339     |
| isPaused                                            | 462             | 747    | 462    | 2462    | 7       |
| isValidatorSlashed                                  | 629             | 1129   | 629    | 2629    | 4       |
| isValidatorWithdrawn                                | 640             | 640    | 640    | 640     | 1       |
| keyRemovalCharge                                    | 426             | 926    | 426    | 2426    | 4       |
| normalizeQueue                                      | 29487           | 45509  | 45509  | 61531   | 2       |
| obtainDepositData                                   | 24562           | 78411  | 70081  | 161115  | 69      |
| onExitedAndStuckValidatorsCountsUpdated             | 23749           | 23785  | 23785  | 23821   | 2       |
| onRewardsMinted                                     | 23983           | 42071  | 39748  | 62484   | 3       |
| onWithdrawalCredentialsChanged                      | 23845           | 24659  | 25067  | 25067   | 3       |
| pauseFor                                            | 24007           | 29608  | 30410  | 30626   | 13      |
| proposeNodeOperatorManagerAddressChange             | 27463           | 41805  | 52017  | 52017   | 11      |
| proposeNodeOperatorRewardAddressChange              | 27546           | 44581  | 52066  | 52066   | 15      |
| publicRelease                                       | 404             | 404    | 404    | 404     | 1       |
| recoverERC20                                        | 59574           | 59574  | 59574  | 59574   | 1       |
| recoverEther                                        | 23759           | 26200  | 26200  | 28641   | 2       |
| recoverStETHShares                                  | 56504           | 56504  | 56504  | 56504   | 1       |
| removeKeys                                          | 24142           | 117494 | 142036 | 216380  | 17      |
| reportELRewardsStealingPenalty                      | 24302           | 91986  | 100480 | 101136  | 37      |
| resetNodeOperatorManagerAddress                     | 26929           | 31005  | 29363  | 36712   | 5       |
| resume                                              | 23748           | 29549  | 29567  | 29567   | 336     |
| revokeRole                                          | 40200           | 40200  | 40200  | 40200   | 1       |
| setKeyRemovalCharge                                 | 24000           | 27300  | 27589  | 30025   | 4       |
| settleELRewardsStealingPenalty                      | 24521           | 76659  | 89494  | 114624  | 23      |
| submitInitialSlashing                               | 24121           | 83170  | 106016 | 120082  | 13      |
| submitWithdrawal                                    | 24554           | 90380  | 103831 | 138068  | 17      |
| unsafeUpdateValidatorsCount                         | 24282           | 43257  | 38260  | 81115   | 12      |
| updateExitedValidatorsCount                         | 24887           | 40256  | 46208  | 55961   | 11      |
| updateRefundedValidatorsCount                       | 24146           | 24160  | 24158  | 24178   | 3       |
| updateStuckValidatorsCount                          | 24909           | 53066  | 48056  | 79074   | 14      |
| updateTargetValidatorsLimits                        | 24307           | 70817  | 71660  | 114078  | 43      |


| src/CSVerifier.sol:CSVerifier contract |                 |       |        |        |         |
|----------------------------------------|-----------------|-------|--------|--------|---------|
| Function Name                          | min             | avg   | median | max    | # calls |
| BEACON_ROOTS                           | 304             | 304   | 304    | 304    | 27      |
| FIRST_SUPPORTED_SLOT                   | 260             | 260   | 260    | 260    | 8       |
| GI_FIRST_VALIDATOR_CURR                | 228             | 228   | 228    | 228    | 2       |
| GI_FIRST_VALIDATOR_PREV                | 250             | 250   | 250    | 250    | 2       |
| GI_FIRST_WITHDRAWAL_CURR               | 207             | 207   | 207    | 207    | 2       |
| GI_FIRST_WITHDRAWAL_PREV               | 227             | 227   | 227    | 227    | 2       |
| GI_HISTORICAL_SUMMARIES                | 206             | 206   | 206    | 206    | 2       |
| LOCATOR                                | 238             | 238   | 238    | 238    | 2       |
| MODULE                                 | 261             | 261   | 261    | 261    | 2       |
| PIVOT_SLOT                             | 282             | 282   | 282    | 282    | 2       |
| SLOTS_PER_EPOCH                        | 281             | 281   | 281    | 281    | 2       |
| processHistoricalWithdrawalProof       | 72640           | 88485 | 79856  | 136548 | 10      |
| processSlashingProof                   | 48742           | 61915 | 55610  | 81395  | 3       |
| processWithdrawalProof                 | 56410           | 72894 | 69622  | 103498 | 9       |


| src/lib/AssetRecovererLib.sol:AssetRecovererLib contract |                 |       |        |       |         |
|----------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                            | min             | avg   | median | max   | # calls |
| recoverERC1155                                           | 42352           | 42352 | 42352  | 42352 | 1       |
| recoverERC20                                             | 37066           | 37208 | 37066  | 37634 | 4       |
| recoverERC721                                            | 44697           | 44697 | 44697  | 44697 | 1       |
| recoverEther                                             | 2118            | 17968 | 17968  | 33818 | 6       |


| src/lib/base-oracle/HashConsensus.sol:HashConsensus contract |                 |        |        |        |         |
|--------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                                | min             | avg    | median | max    | # calls |
| DISABLE_CONSENSUS_ROLE                                       | 283             | 283    | 283    | 283    | 13      |
| MANAGE_FAST_LANE_CONFIG_ROLE                                 | 262             | 262    | 262    | 262    | 13      |
| MANAGE_FRAME_CONFIG_ROLE                                     | 263             | 263    | 263    | 263    | 13      |
| MANAGE_MEMBERS_AND_QUORUM_ROLE                               | 305             | 305    | 305    | 305    | 13      |
| MANAGE_REPORT_PROCESSOR_ROLE                                 | 326             | 326    | 326    | 326    | 13      |
| addMember                                                    | 100336          | 120696 | 105226 | 156526 | 24      |
| getChainConfig                                               | 323             | 323    | 323    | 323    | 13      |
| getConsensusState                                            | 4566            | 4566   | 4566   | 4566   | 3       |
| getCurrentFrame                                              | 2618            | 2618   | 2618   | 2618   | 11      |
| getInitialRefSlot                                            | 3784            | 3784   | 3784   | 3784   | 13      |
| getIsMember                                                  | 2682            | 2682   | 2682   | 2682   | 3       |
| grantRole                                                    | 118492          | 118501 | 118504 | 118504 | 65      |
| submitReport                                                 | 135796          | 146722 | 146722 | 157649 | 6       |
| updateInitialEpoch                                           | 40703           | 40703  | 40703  | 40703  | 13      |


| src/lib/proxy/OssifiableProxy.sol:OssifiableProxy contract |                 |       |        |       |         |
|------------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                              | min             | avg   | median | max   | # calls |
| proxy__changeAdmin                                         | 24224           | 25927 | 24258  | 29300 | 3       |
| proxy__getAdmin                                            | 601             | 1601  | 1601   | 2601  | 2       |
| proxy__getImplementation                                   | 679             | 1345  | 679    | 2679  | 3       |
| proxy__getIsOssified                                       | 578             | 978   | 578    | 2578  | 5       |
| proxy__ossify                                              | 23573           | 24270 | 24542  | 24542 | 7       |
| proxy__upgradeTo                                           | 24202           | 27242 | 24236  | 33289 | 3       |
| proxy__upgradeToAndCall                                    | 25029           | 36333 | 25063  | 58908 | 3       |
| receive                                                    | 26823           | 26823 | 26823  | 26823 | 1       |
| version                                                    | 1009            | 4259  | 4259   | 7509  | 2       |




