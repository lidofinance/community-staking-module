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
| addMember                                                       | 100193          | 120531 | 105051 | 156351 | 3       |
| getChainConfig                                                  | 346             | 346    | 346    | 346    | 2       |
| getConsensusState                                               | 4463            | 4463   | 4463   | 4463   | 1       |
| getCurrentFrame                                                 | 2618            | 2618   | 2618   | 2618   | 7       |
| getInitialRefSlot                                               | 3807            | 3807   | 3807   | 3807   | 2       |
| grantRole                                                       | 118213          | 118222 | 118225 | 118225 | 10      |
| submitReport                                                    | 118557          | 138076 | 138076 | 157595 | 2       |
| updateInitialEpoch                                              | 40549           | 40549  | 40549  | 40549  | 2       |


| src/CSAccounting.sol:CSAccounting contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                            | Deployment Size |        |        |        |         |
| 4933637                                    | 24500           |        |        |        |         |
| Function Name                              | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                        | 274             | 274    | 274    | 274    | 155     |
| RELEASE_BOND_LOCK_ROLE                     | 317             | 317    | 317    | 317    | 155     |
| addBondCurve                               | 121258          | 121258 | 121258 | 121258 | 5       |
| getActualLockedBond                        | 741             | 741    | 741    | 741    | 1       |
| getBondAmountByKeysCount                   | 1303            | 1397   | 1303   | 1566   | 144     |
| getBondAmountByKeysCountWstETH             | 14196           | 14196  | 14196  | 14196  | 2       |
| getBondCurve                               | 2204            | 15985  | 16300  | 16300  | 148     |
| getBondLockRetentionPeriod                 | 2413            | 2413   | 2413   | 2413   | 2       |
| getLockedBondInfo                          | 815             | 815    | 815    | 815    | 6       |
| getRequiredBondForNextKeys                 | 10109           | 33317  | 52609  | 53135  | 13      |
| getRequiredBondForNextKeysWstETH           | 59002           | 59002  | 59002  | 59002  | 2       |
| getUnbondedKeysCount                       | 7731            | 23816  | 15731  | 46231  | 234     |
| grantRole                                  | 118397          | 118397 | 118397 | 118397 | 310     |
| releaseLockedBondETH                       | 100620          | 100620 | 100620 | 100620 | 1       |


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


| src/CSFeeDistributor.sol:CSFeeDistributor contract |                 |       |        |       |         |
|----------------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                                    | Deployment Size |       |        |       |         |
| 497420                                             | 2724            |       |        |       |         |
| Function Name                                      | min             | avg   | median | max   | # calls |
| distributeFees                                     | 22284           | 48036 | 44613  | 92830 | 5       |
| distributedShares                                  | 504             | 1504  | 1504   | 2504  | 4       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                          | Deployment Size |        |        |        |         |
| 2492282                                  | 11630           |        |        |        |         |
| Function Name                            | min             | avg    | median | max    | # calls |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 305             | 305    | 305    | 305    | 2       |
| MANAGE_CONSENSUS_VERSION_ROLE            | 306             | 306    | 306    | 306    | 2       |
| PAUSE_ROLE                               | 284             | 284    | 284    | 284    | 2       |
| RESUME_ROLE                              | 284             | 284    | 284    | 284    | 2       |
| SUBMIT_DATA_ROLE                         | 306             | 306    | 306    | 306    | 3       |
| getConsensusReport                       | 903             | 1310   | 916    | 2903   | 10      |
| getConsensusVersion                      | 418             | 1751   | 2418   | 2418   | 3       |
| getLastProcessingRefSlot                 | 419             | 2169   | 2419   | 2419   | 8       |
| grantRole                                | 101147          | 115137 | 118247 | 118247 | 11      |
| initialize                               | 260549          | 260555 | 260555 | 260561 | 2       |
| submitReportData                         | 97119           | 97119  | 97119  | 97119  | 1       |
| treeCid                                  | 1292            | 1292   | 1292   | 1292   | 1       |
| treeRoot                                 | 385             | 385    | 385    | 385    | 1       |


| src/CSModule.sol:CSModule contract      |                 |        |        |         |         |
|-----------------------------------------|-----------------|--------|--------|---------|---------|
| Deployment Cost                         | Deployment Size |        |        |         |         |
| 4855751                                 | 22592           |        |        |         |         |
| Function Name                           | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                      | 283             | 283    | 283    | 283     | 1       |
| DEPOSIT_SIZE                            | 329             | 329    | 329    | 329     | 10      |
| EL_REWARDS_STEALING_FINE                | 306             | 306    | 306    | 306     | 1       |
| INITIAL_SLASHING_PENALTY                | 352             | 352    | 352    | 352     | 3       |
| MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE  | 316             | 316    | 316    | 316     | 1       |
| PAUSE_ROLE                              | 307             | 307    | 307    | 307     | 156     |
| PENALIZE_ROLE                           | 285             | 285    | 285    | 285     | 157     |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE | 327             | 327    | 327    | 327     | 157     |
| RESUME_ROLE                             | 286             | 286    | 286    | 286     | 156     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE | 328             | 328    | 328    | 328     | 157     |
| SET_ACCOUNTING_ROLE                     | 328             | 328    | 328    | 328     | 198     |
| SET_EARLY_ADOPTION_ROLE                 | 328             | 328    | 328    | 328     | 157     |
| SET_PUBLIC_RELEASE_TIMESTAMP_ROLE       | 284             | 284    | 284    | 284     | 157     |
| SET_REMOVAL_CHARGE_ROLE                 | 328             | 328    | 328    | 328     | 157     |
| SLASHING_SUBMITTER_ROLE                 | 284             | 284    | 284    | 284     | 155     |
| STAKING_ROUTER_ROLE                     | 283             | 283    | 283    | 283     | 176     |
| WITHDRAWAL_SUBMITTER_ROLE               | 327             | 327    | 327    | 327     | 157     |
| accounting                              | 448             | 448    | 448    | 448     | 1       |
| addNodeOperatorETH                      | 25946           | 603704 | 546518 | 1071680 | 144     |
| addNodeOperatorStETH                    | 25992           | 279563 | 279563 | 533135  | 2       |
| addNodeOperatorStETHWithPermit          | 26711           | 282685 | 282685 | 538659  | 2       |
| addNodeOperatorWstETH                   | 26012           | 291036 | 291036 | 556060  | 2       |
| addNodeOperatorWstETHWithPermit         | 26756           | 289385 | 289385 | 552015  | 2       |
| addValidatorKeysETH                     | 25615           | 229135 | 259061 | 313478  | 6       |
| addValidatorKeysStETH                   | 25618           | 133000 | 133000 | 240383  | 2       |
| addValidatorKeysStETHWithPermit         | 26351           | 136156 | 136156 | 245962  | 2       |
| addValidatorKeysWstETH                  | 25621           | 142045 | 142045 | 258469  | 2       |
| addValidatorKeysWstETHWithPermit        | 26351           | 145211 | 145211 | 264072  | 2       |
| cleanDepositQueue                       | 26304           | 36076  | 33834  | 53080   | 12      |
| confirmNodeOperatorManagerAddressChange | 23690           | 28997  | 29075  | 34072   | 5       |
| confirmNodeOperatorRewardAddressChange  | 23669           | 33009  | 33897  | 38795   | 6       |
| decreaseOperatorVettedKeys              | 24802           | 91370  | 107408 | 155115  | 15      |
| depositQueueItem                        | 623             | 1223   | 623    | 2623    | 10      |
| earlyAdoption                           | 449             | 449    | 449    | 449     | 1       |
| getNodeOperator                         | 2215            | 9740   | 8215   | 20215   | 274     |
| getNodeOperatorSigningKeys              | 841             | 2899   | 3616   | 3616    | 7       |
| getNodeOperatorSummary                  | 1532            | 5345   | 7532   | 7532    | 43      |
| getNodeOperatorsCount                   | 403             | 475    | 403    | 2403    | 305     |
| getNonce                                | 402             | 717    | 402    | 2402    | 38      |
| getStakingModuleSummary                 | 661             | 2911   | 2661   | 4661    | 16      |
| getType                                 | 427             | 427    | 427    | 427     | 1       |
| grantRole                               | 26966           | 51461  | 51474  | 51474   | 1920    |
| hasRole                                 | 726             | 726    | 726    | 726     | 2       |
| isPaused                                | 439             | 839    | 439    | 2439    | 5       |
| normalizeQueue                          | 30211           | 54732  | 54732  | 79253   | 2       |
| obtainDepositData                       | 24443           | 106934 | 102409 | 158530  | 38      |
| onExitedAndStuckValidatorsCountsUpdated | 23638           | 23671  | 23671  | 23704   | 2       |
| onRewardsMinted                         | 23890           | 23922  | 23922  | 23954   | 2       |
| onWithdrawalCredentialsChanged          | 23662           | 23695  | 23695  | 23728   | 2       |
| pauseFor                                | 23943           | 45884  | 47452  | 47452   | 15      |
| penalize                                | 24153           | 85516  | 102737 | 116864  | 8       |
| proposeNodeOperatorManagerAddressChange | 24166           | 42575  | 53532  | 53532   | 9       |
| proposeNodeOperatorRewardAddressChange  | 24145           | 33369  | 36389  | 36389   | 10      |
| publicReleaseTimestamp                  | 407             | 407    | 407    | 407     | 1       |
| queue                                   | 475             | 875    | 475    | 2475    | 5       |
| removalCharge                           | 2386            | 2386   | 2386   | 2386    | 1       |
| removeKeys                              | 23982           | 145221 | 172244 | 240225  | 15      |
| reportELRewardsStealingPenalty          | 24283           | 115353 | 136751 | 146756  | 10      |
| resetNodeOperatorManagerAddress         | 23668           | 31770  | 31290  | 38313   | 5       |
| resume                                  | 23730           | 26642  | 26642  | 29555   | 2       |
| revokeRole                              | 29530           | 29530  | 29530  | 29530   | 1       |
| setAccounting                           | 24274           | 46389  | 46503  | 46503   | 196     |
| setEarlyAdoption                        | 23989           | 38617  | 46458  | 46458   | 8       |
| setPublicReleaseTimestamp               | 23910           | 41674  | 47060  | 47060   | 8       |
| setRemovalCharge                        | 23982           | 46926  | 47073  | 47085   | 157     |
| settleELRewardsStealingPenalty          | 24646           | 59171  | 38651  | 109362  | 6       |
| submitInitialSlashing                   | 26179           | 104086 | 136874 | 137774  | 10      |
| submitWithdrawal                        | 24305           | 120944 | 140952 | 234767  | 14      |
| unsafeUpdateValidatorsCount             | 24253           | 58898  | 58898  | 93544   | 2       |
| updateExitedValidatorsCount             | 24757           | 56034  | 42947  | 110057  | 10      |
| updateRefundedValidatorsCount           | 24082           | 27669  | 27669  | 31256   | 2       |
| updateStuckValidatorsCount              | 24779           | 72960  | 60481  | 138413  | 13      |
| updateTargetValidatorsLimits            | 24292           | 118196 | 137426 | 210430  | 19      |


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


| test/CSAccounting.t.sol:CSAccountingForTests contract               |                 |        |        |        |         |
|---------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                     | Deployment Size |        |        |        |         |
| 4979321                                                             | 24724           |        |        |        |         |
| Function Name                                                       | min             | avg    | median | max    | # calls |
| ADD_BOND_CURVE_ROLE                                                 | 252             | 252    | 252    | 252    | 217     |
| DEFAULT_ADMIN_ROLE                                                  | 272             | 272    | 272    | 272    | 2       |
| PAUSE_ROLE                                                          | 252             | 252    | 252    | 252    | 217     |
| RELEASE_BOND_LOCK_ROLE                                              | 317             | 317    | 317    | 317    | 217     |
| RESUME_ROLE                                                         | 274             | 274    | 274    | 274    | 217     |
| SET_BOND_CURVE_ROLE                                                 | 318             | 318    | 318    | 318    | 216     |
| SET_DEFAULT_BOND_CURVE_ROLE                                         | 274             | 274    | 274    | 274    | 217     |
| addBondCurve                                                        | 24534           | 120476 | 144462 | 144462 | 5       |
| chargeFee                                                           | 21788           | 48217  | 48217  | 74646  | 2       |
| chargeRecipient                                                     | 425             | 425    | 425    | 425    | 1       |
| claimExcessBondStETH                                                | 23970           | 74313  | 79064  | 100103 | 16      |
| claimExcessBondWstETH                                               | 23970           | 115646 | 152233 | 154450 | 12      |
| claimRewardsStETH                                                   | 25085           | 86587  | 102601 | 107618 | 14      |
| claimRewardsWstETH                                                  | 25040           | 122188 | 159590 | 161807 | 14      |
| compensateLockedBondETH                                             | 50719           | 50719  | 50719  | 50719  | 1       |
| defaultBondCurveId                                                  | 394             | 394    | 394    | 394    | 1       |
| depositETH                                                          | 24190           | 114347 | 116581 | 116814 | 136     |
| depositStETH                                                        | 24388           | 46139  | 27324  | 105523 | 4       |
| depositStETHWithPermit                                              | 25614           | 81632  | 107176 | 110834 | 6       |
| depositWstETH                                                       | 24410           | 50212  | 27346  | 121748 | 4       |
| depositWstETHWithPermit                                             | 25592           | 92413  | 123357 | 126997 | 6       |
| feeDistributor                                                      | 450             | 450    | 450    | 450    | 1       |
| getActualLockedBond                                                 | 719             | 719    | 719    | 719    | 3       |
| getBondAmountByKeysCountWstETH(uint256)                             | 3867            | 9706   | 4130   | 26698  | 4       |
| getBondAmountByKeysCountWstETH(uint256,(uint256,uint256[],uint256)) | 3266            | 6039   | 3397   | 14097  | 4       |
| getBondCurve                                                        | 2452            | 5684   | 4300   | 10300  | 3       |
| getBondShares                                                       | 519             | 545    | 519    | 2519   | 153     |
| getBondSummary                                                      | 14086           | 22835  | 21369  | 29869  | 12      |
| getBondSummaryShares                                                | 14017           | 22766  | 21300  | 29800  | 12      |
| getCurveInfo                                                        | 2137            | 2137   | 2137   | 2137   | 1       |
| getRequiredBondForNextKeys                                          | 17194           | 25717  | 24420  | 32920  | 15      |
| getRequiredBondForNextKeysWstETH                                    | 23565           | 32088  | 30791  | 39291  | 15      |
| getUnbondedKeysCount                                                | 3362            | 17416  | 21545  | 21575  | 12      |
| getUnbondedKeysCountToEject                                         | 5308            | 16917  | 19251  | 19251  | 12      |
| grantRole                                                           | 118363          | 118373 | 118375 | 118375 | 1296    |
| isPaused                                                            | 451             | 851    | 451    | 2451   | 5       |
| lockBondETH                                                         | 21804           | 58401  | 70601  | 70601  | 4       |
| pauseFor                                                            | 23958           | 45986  | 47455  | 47455  | 16      |
| penalize                                                            | 21767           | 34355  | 34355  | 46943  | 2       |
| releaseLockedBondETH                                                | 24147           | 31367  | 31367  | 38587  | 2       |
| requestExcessBondETH                                                | 23969           | 62771  | 73630  | 75847  | 14      |
| requestRewardsETH                                                   | 25065           | 70975  | 78326  | 83344  | 14      |
| resetBondCurve                                                      | 23862           | 24650  | 24650  | 25438  | 2       |
| resume                                                              | 23766           | 26672  | 26672  | 29579  | 2       |
| setBondCurve                                                        | 24068           | 41256  | 49851  | 49851  | 3       |
| setBondCurve_ForTest                                                | 166009          | 166009 | 166009 | 166009 | 24      |
| setBondLock_ForTest                                                 | 70213           | 70216  | 70213  | 70237  | 28      |
| setChargeRecipient                                                  | 24022           | 27061  | 27061  | 30101  | 2       |
| setDefaultBondCurve                                                 | 23978           | 28083  | 28083  | 32188  | 2       |
| setFeeDistributor                                                   | 24000           | 47197  | 47384  | 47384  | 218     |
| totalBondShares                                                     | 372             | 372    | 372    | 372    | 81      |


| test/CSBondCore.t.sol:CSBondCoreTestable contract |                 |        |        |        |         |
|---------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                   | Deployment Size |        |        |        |         |
| 1057673                                           | 5445            |        |        |        |         |
| Function Name                                     | min             | avg    | median | max    | # calls |
| burn                                              | 37469           | 40584  | 37469  | 46814  | 3       |
| charge                                            | 58430           | 63222  | 58430  | 72808  | 3       |
| claimStETH                                        | 24659           | 54188  | 72049  | 73104  | 7       |
| claimWstETH                                       | 24535           | 82711  | 126300 | 126310 | 7       |
| depositETH                                        | 111129          | 111129 | 111129 | 111129 | 30      |
| depositStETH                                      | 99870           | 99870  | 99870  | 99870  | 1       |
| depositWstETH                                     | 116441          | 116441 | 116441 | 116441 | 1       |
| getBond                                           | 1548            | 1548   | 1548   | 1548   | 1       |
| getBondShares                                     | 450             | 450    | 450    | 450    | 50      |
| requestETH                                        | 24660           | 40268  | 47688  | 48743  | 7       |
| totalBondShares                                   | 349             | 349    | 349    | 349    | 27      |


| test/CSBondCurve.t.sol:CSBondCurveTestable contract           |                 |       |        |        |         |
|---------------------------------------------------------------|-----------------|-------|--------|--------|---------|
| Deployment Cost                                               | Deployment Size |       |        |        |         |
| 919179                                                        | 4459            |       |        |        |         |
| Function Name                                                 | min             | avg   | median | max    | # calls |
| addBondCurve                                                  | 22077           | 74034 | 72608  | 141984 | 8       |
| defaultBondCurveId                                            | 350             | 1350  | 1350   | 2350   | 6       |
| getBondAmountByKeysCount(uint256)                             | 2196            | 5414  | 2196   | 18027  | 5       |
| getBondAmountByKeysCount(uint256,(uint256,uint256[],uint256)) | 1080            | 1272  | 1249   | 1512   | 8       |
| getBondCurve                                                  | 2136            | 12530 | 14727  | 20727  | 3       |
| getCurveInfo                                                  | 1822            | 1883  | 1822   | 2069   | 4       |
| getKeysCountByBondAmount(uint256)                             | 2090            | 4598  | 2628   | 18090  | 8       |
| getKeysCountByBondAmount(uint256,(uint256,uint256[],uint256)) | 1163            | 1522  | 1580   | 1823   | 6       |
| resetBondCurve                                                | 25322           | 25322 | 25322  | 25322  | 1       |
| setBondCurve                                                  | 21731           | 35133 | 35669  | 47462  | 4       |
| setDefaultBondCurve                                           | 21593           | 25230 | 24782  | 29764  | 4       |


| test/CSBondLock.t.sol:CSBondLockTestable contract |                 |       |        |       |         |
|---------------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                                   | Deployment Size |       |        |       |         |
| 348677                                            | 1487            |       |        |       |         |
| Function Name                                     | min             | avg   | median | max   | # calls |
| MAX_BOND_LOCK_RETENTION_PERIOD                    | 228             | 228   | 228    | 228   | 1       |
| MIN_BOND_LOCK_RETENTION_PERIOD                    | 228             | 228   | 228    | 228   | 1       |
| getActualLockedBond                               | 539             | 619   | 619    | 699   | 2       |
| getBondLockRetentionPeriod                        | 323             | 1923  | 2323   | 2323  | 5       |
| getLockedBondInfo                                 | 730             | 730   | 730    | 730   | 8       |
| lock                                              | 21647           | 60165 | 70122  | 70134 | 12      |
| reduceAmount                                      | 23955           | 27302 | 26845  | 31566 | 4       |
| remove                                            | 26623           | 26623 | 26623  | 26623 | 1       |
| setBondLockRetentionPeriod                        | 21565           | 23586 | 21588  | 27607 | 3       |


| test/GIndex.t.sol:Library contract |                 |     |        |     |         |
|------------------------------------|-----------------|-----|--------|-----|---------|
| Deployment Cost                    | Deployment Size |     |        |     |         |
| 252612                             | 953             |     |        |     |         |
| Function Name                      | min             | avg | median | max | # calls |
| concat                             | 332             | 456 | 456    | 581 | 2       |
| shl                                | 518             | 518 | 518    | 518 | 4       |
| shr                                | 637             | 637 | 637    | 637 | 4       |


| test/Math.t.sol:Library contract |                 |     |        |     |         |
|----------------------------------|-----------------|-----|--------|-----|---------|
| Deployment Cost                  | Deployment Size |     |        |     |         |
| 120711                           | 342             |     |        |     |         |
| Function Name                    | min             | avg | median | max | # calls |
| log2                             | 240             | 240 | 240    | 240 | 1       |


| test/SSZ.t.sol:Library contract |                 |       |        |       |         |
|---------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                 | Deployment Size |       |        |       |         |
| 138471                          | 423             |       |        |       |         |
| Function Name                   | min             | avg   | median | max   | # calls |
| verifyProof                     | 22613           | 24083 | 24418  | 24775 | 9       |


| test/ValidatorCountsReport.t.sol:ReportCaller contract |                 |       |        |       |         |
|--------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                                        | Deployment Size |       |        |       |         |
| 280077                                                 | 1080            |       |        |       |         |
| Function Name                                          | min             | avg   | median | max   | # calls |
| count                                                  | 639             | 639   | 639    | 639   | 1       |
| next                                                   | 23875           | 23893 | 23893  | 23911 | 2       |
| validate                                               | 955             | 1036  | 1050   | 1089  | 4       |


| test/helpers/MerkleTree.sol:MerkleTree contract |                 |        |        |        |         |
|-------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                 | Deployment Size |        |        |        |         |
| 692567                                          | 2987            |        |        |        |         |
| Function Name                                   | min             | avg    | median | max    | # calls |
| getProof                                        | 1753            | 3753   | 3753   | 5753   | 14      |
| hashLeaf                                        | 799             | 801    | 799    | 811    | 36      |
| pushLeaf                                        | 231333          | 231333 | 231334 | 231334 | 16      |
| root                                            | 933             | 5902   | 8933   | 8933   | 18      |


| test/helpers/mocks/LidoLocatorMock.sol:LidoLocatorMock contract |                 |      |        |      |         |
|-----------------------------------------------------------------|-----------------|------|--------|------|---------|
| Deployment Cost                                                 | Deployment Size |      |        |      |         |
| 257695                                                          | 844             |      |        |      |         |
| Function Name                                                   | min             | avg  | median | max  | # calls |
| burner                                                          | 2364            | 2364 | 2364   | 2364 | 445     |
| elRewardsVault                                                  | 2363            | 2363 | 2363   | 2363 | 1       |
| lido                                                            | 2330            | 2330 | 2330   | 2330 | 444     |
| withdrawalQueue                                                 | 341             | 2231 | 2341   | 2341 | 474     |


| test/helpers/mocks/LidoMock.sol:LidoMock contract |                 |       |        |       |         |
|---------------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                                   | Deployment Size |       |        |       |         |
| 512566                                            | 2140            |       |        |       |         |
| Function Name                                     | min             | avg   | median | max   | # calls |
| allowance                                         | 0               | 257   | 257    | 514   | 6       |
| balanceOf                                         | 1020            | 1868  | 1020   | 3020  | 33      |
| getPooledEthByShares                              | 658             | 1282  | 658    | 4658  | 621     |
| getSharesByPooledEth                              | 657             | 2035  | 657    | 4657  | 412     |
| mintShares                                        | 49313           | 66494 | 66533  | 66533 | 447     |
| sharesOf                                          | 611             | 1092  | 611    | 2611  | 79      |
| submit                                            | 37448           | 43555 | 37448  | 54548 | 56      |


| test/helpers/mocks/OracleMock.sol:OracleMock contract |                 |       |        |       |         |
|-------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                                       | Deployment Size |       |        |       |         |
| 877137                                                | 3696            |       |        |       |         |
| Function Name                                         | min             | avg   | median | max   | # calls |
| hashLeaf                                              | 1990            | 1990  | 1990   | 1990  | 4       |
| merkleTree                                            | 357             | 357   | 357    | 357   | 5       |
| treeRoot                                              | 7546            | 12463 | 14103  | 14103 | 4       |


| test/helpers/mocks/Stub.sol:Stub contract |                 |     |        |     |         |
|-------------------------------------------|-----------------|-----|--------|-----|---------|
| Deployment Cost                           | Deployment Size |     |        |     |         |
| 59277                                     | 53              |     |        |     |         |
| Function Name                             | min             | avg | median | max | # calls |
| getNodeOperator                           | 0               | 0   | 0      | 0   | 156     |
| getNodeOperatorSigningKeys                | 0               | 0   | 0      | 0   | 3       |
| getNodeOperatorsCount                     | 0               | 0   | 0      | 0   | 234     |
| withdrawalVault                           | 0               | 0   | 0      | 0   | 2       |


| test/helpers/mocks/WithdrawalQueueMock.sol:WithdrawalQueueMock contract |                 |     |        |     |         |
|-------------------------------------------------------------------------|-----------------|-----|--------|-----|---------|
| Deployment Cost                                                         | Deployment Size |     |        |     |         |
| 76135                                                                   | 132             |     |        |     |         |
| Function Name                                                           | min             | avg | median | max | # calls |
| MIN_STETH_WITHDRAWAL_AMOUNT                                             | 160             | 160 | 160    | 160 | 21      |


| test/helpers/mocks/WstETHMock.sol:WstETHMock contract |                 |        |        |        |         |
|-------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                       | Deployment Size |        |        |        |         |
| 547391                                                | 2352            |        |        |        |         |
| Function Name                                         | min             | avg    | median | max    | # calls |
| allowance                                             | 0               | 235    | 235    | 470    | 6       |
| balanceOf                                             | 546             | 1117   | 546    | 2546   | 56      |
| getStETHByWstETH                                      | 1484            | 1484   | 1484   | 1484   | 3       |
| getWstETHByStETH                                      | 1450            | 3394   | 3450   | 9950   | 72      |
| wrap                                                  | 100226          | 100715 | 100238 | 105026 | 10      |




