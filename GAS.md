| src/CSAccounting.sol:CSAccounting contract                          |                 |        |        |        |         |
|---------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                                       | min             | avg    | median | max    | # calls |
| ACCOUNTING_MANAGER_ROLE                                             | 296             | 296    | 296    | 296    | 180     |
| ADD_BOND_CURVE_ROLE                                                 | 274             | 274    | 274    | 274    | 754     |
| MIN_BOND_LOCK_RETENTION_PERIOD                                      | 317             | 317    | 317    | 317    | 1       |
| PAUSE_ROLE                                                          | 339             | 339    | 339    | 339    | 180     |
| RECOVERER_ROLE                                                      | 327             | 327    | 327    | 327    | 12      |
| RESET_BOND_CURVE_ROLE                                               | 318             | 318    | 318    | 318    | 485     |
| RESUME_ROLE                                                         | 251             | 251    | 251    | 251    | 180     |
| SET_BOND_CURVE_ROLE                                                 | 274             | 274    | 274    | 274    | 664     |
| SET_DEFAULT_BOND_CURVE_ROLE                                         | 252             | 252    | 252    | 252    | 180     |
| addBondCurve                                                        | 24663           | 122862 | 121473 | 144611 | 330     |
| chargeFee                                                           | 21724           | 48146  | 48146  | 74568  | 2       |
| chargeRecipient                                                     | 404             | 404    | 404    | 404    | 1       |
| claimRewardsStETH                                                   | 25163           | 82221  | 96875  | 104687 | 16      |
| claimRewardsWstETH                                                  | 25098           | 118257 | 156625 | 158992 | 16      |
| compensateLockedBondETH                                             | 47658           | 47658  | 47658  | 47658  | 1       |
| defaultBondCurveId                                                  | 490             | 490    | 490    | 490    | 1       |
| depositETH                                                          | 24205           | 112166 | 113336 | 113576 | 104     |
| depositStETH                                                        | 25129           | 94093  | 103928 | 107847 | 7       |
| depositWstETH                                                       | 25193           | 105395 | 120228 | 123940 | 6       |
| feeDistributor                                                      | 404             | 1737   | 2404   | 2404   | 3       |
| getActualLockedBond                                                 | 621             | 741    | 782    | 782    | 8       |
| getBondAmountByKeysCount                                            | 1178            | 1430   | 1347   | 1610   | 269     |
| getBondAmountByKeysCountWstETH(uint256)                             | 3932            | 9771   | 4195   | 26763  | 4       |
| getBondAmountByKeysCountWstETH(uint256,(uint256,uint256[],uint256)) | 3353            | 10204  | 14233  | 14283  | 8       |
| getBondCurve                                                        | 2236            | 15958  | 16338  | 16338  | 280     |
| getBondLockRetentionPeriod                                          | 467             | 1800   | 2467   | 2467   | 3       |
| getBondShares                                                       | 604             | 642    | 604    | 2604   | 103     |
| getBondSummary                                                      | 14290           | 23043  | 21578  | 30078  | 12      |
| getBondSummaryShares                                                | 14273           | 23026  | 21561  | 30061  | 12      |
| getCurveInfo                                                        | 2217            | 2217   | 2217   | 2217   | 1       |
| getLockedBondInfo                                                   | 839             | 839    | 839    | 839    | 13      |
| getRequiredBondForNextKeys                                          | 10247           | 31035  | 24667  | 51536  | 43      |
| getRequiredBondForNextKeysWstETH                                    | 23890           | 38671  | 31142  | 57470  | 20      |
| getUnbondedKeysCount                                                | 3461            | 24815  | 16066  | 46566  | 463     |
| getUnbondedKeysCountToEject                                         | 5486            | 9289   | 7745   | 19435  | 73      |
| grantRole                                                           | 29592           | 108374 | 118680 | 118680 | 2625    |
| initialize                                                          | 207490          | 345156 | 346008 | 346008 | 488     |
| isPaused                                                            | 460             | 860    | 460    | 2460   | 5       |
| lockBondETH                                                         | 21826           | 68572  | 70367  | 70391  | 27      |
| pauseFor                                                            | 24065           | 45451  | 47590  | 47590  | 11      |
| penalize                                                            | 21744           | 34436  | 34436  | 47128  | 2       |
| recoverERC20                                                        | 24533           | 35912  | 24549  | 58655  | 3       |
| recoverEther                                                        | 23900           | 37470  | 28406  | 60106  | 3       |
| recoverStETHShares                                                  | 23856           | 43270  | 43270  | 62684  | 2       |
| releaseLockedBondETH                                                | 21804           | 26781  | 26781  | 31758  | 2       |
| requestRewardsETH                                                   | 25121           | 67090  | 72690  | 80502  | 16      |
| resetBondCurve                                                      | 24054           | 25945  | 25945  | 27836  | 2       |
| resume                                                              | 23851           | 26771  | 26771  | 29692  | 2       |
| setBondCurve                                                        | 24215           | 48846  | 49966  | 49966  | 23      |
| setChargeRecipient                                                  | 24104           | 26120  | 24107  | 30151  | 3       |
| setDefaultBondCurve                                                 | 24063           | 28174  | 28174  | 32286  | 2       |
| setLockedBondRetentionPeriod                                        | 30172           | 30172  | 30172  | 30172  | 1       |
| settleLockedBondETH                                                 | 43946           | 43946  | 43946  | 43946  | 1       |
| totalBondShares                                                     | 435             | 435    | 435    | 435    | 51      |


| src/CSEarlyAdoption.sol:CSEarlyAdoption contract |                 |       |        |       |         |
|--------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                    | min             | avg   | median | max   | # calls |
| consume                                          | 24902           | 37953 | 29950  | 51257 | 7       |
| consumed                                         | 593             | 593   | 593    | 593   | 1       |
| curveId                                          | 261             | 1761  | 2261   | 2261  | 4       |
| isEligible                                       | 1422            | 1422  | 1422   | 1422  | 2       |
| module                                           | 402             | 402   | 402    | 402   | 1       |
| treeRoot                                         | 283             | 283   | 283    | 283   | 1       |


| src/CSFeeDistributor.sol:CSFeeDistributor contract |                 |        |        |        |         |
|----------------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                                      | min             | avg    | median | max    | # calls |
| ORACLE_ROLE                                        | 240             | 240    | 240    | 240    | 10      |
| RECOVERER_ROLE                                     | 315             | 315    | 315    | 315    | 7       |
| distributeFees                                     | 22334           | 42664  | 27944  | 76284  | 6       |
| distributedShares                                  | 523             | 1523   | 1523   | 2523   | 4       |
| getFeesToDistribute                                | 1820            | 2820   | 2820   | 3820   | 2       |
| grantRole                                          | 118703          | 118703 | 118703 | 118703 | 15      |
| hashLeaf                                           | 678             | 678    | 678    | 678    | 1       |
| initialize                                         | 44500           | 131773 | 137592 | 137592 | 16      |
| pendingToDistribute                                | 1432            | 1432   | 1432   | 1432   | 1       |
| processOracleReport                                | 32656           | 68128  | 77419  | 77419  | 7       |
| recoverERC20                                       | 24480           | 35853  | 24494  | 58586  | 3       |
| recoverEther                                       | 23804           | 41922  | 41922  | 60040  | 2       |


| src/CSFeeOracle.sol:CSFeeOracle contract |                 |        |        |        |         |
|------------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                            | min             | avg    | median | max    | # calls |
| MANAGE_CONSENSUS_CONTRACT_ROLE           | 261             | 261    | 261    | 261    | 12      |
| MANAGE_CONSENSUS_VERSION_ROLE            | 239             | 239    | 239    | 239    | 12      |
| MANAGE_FEE_DISTRIBUTOR_CONTRACT_ROLE     | 238             | 238    | 238    | 238    | 12      |
| PAUSE_ROLE                               | 262             | 262    | 262    | 262    | 12      |
| RESUME_ROLE                              | 262             | 262    | 262    | 262    | 12      |
| SUBMIT_DATA_ROLE                         | 284             | 284    | 284    | 284    | 27      |
| getConsensusReport                       | 1019            | 1826   | 1057   | 3019   | 30      |
| getConsensusVersion                      | 405             | 1605   | 2405   | 2405   | 20      |
| getLastProcessingRefSlot                 | 494             | 2283   | 2494   | 2494   | 57      |
| grantRole                                | 101393          | 114955 | 118493 | 118493 | 87      |
| initialize                               | 22935           | 242609 | 260913 | 260925 | 13      |
| pauseFor                                 | 47614           | 47614  | 47614  | 47614  | 2       |
| pauseUntil                               | 47608           | 47608  | 47608  | 47608  | 1       |
| resume                                   | 23535           | 26690  | 26690  | 29845  | 2       |
| setFeeDistributorContract                | 24081           | 27134  | 27134  | 30187  | 2       |
| submitReportData                         | 25486           | 40971  | 44533  | 53601  | 8       |


| src/CSModule.sol:CSModule contract                  |                 |        |        |         |         |
|-----------------------------------------------------|-----------------|--------|--------|---------|---------|
| Function Name                                       | min             | avg    | median | max     | # calls |
| DEFAULT_ADMIN_ROLE                                  | 305             | 305    | 305    | 305     | 1       |
| DEPOSIT_SIZE                                        | 373             | 373    | 373    | 373     | 12      |
| EL_REWARDS_STEALING_FINE                            | 306             | 306    | 306    | 306     | 23      |
| INITIAL_SLASHING_PENALTY                            | 439             | 439    | 439    | 439     | 4       |
| LIDO_LOCATOR                                        | 304             | 304    | 304    | 304     | 1       |
| MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE | 306             | 306    | 306    | 306     | 2       |
| MODULE_MANAGER_ROLE                                 | 283             | 283    | 283    | 283     | 311     |
| PAUSE_ROLE                                          | 307             | 307    | 307    | 307     | 270     |
| RECOVERER_ROLE                                      | 337             | 337    | 337    | 337     | 4       |
| REPORT_EL_REWARDS_STEALING_PENALTY_ROLE             | 349             | 349    | 349    | 349     | 271     |
| RESUME_ROLE                                         | 307             | 307    | 307    | 307     | 270     |
| SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE             | 351             | 351    | 351    | 351     | 271     |
| STAKING_ROUTER_ROLE                                 | 293             | 293    | 293    | 293     | 293     |
| VERIFIER_ROLE                                       | 260             | 260    | 260    | 260     | 273     |
| accounting                                          | 470             | 470    | 470    | 470     | 1       |
| activatePublicRelease                               | 23828           | 46615  | 46769  | 46769   | 286     |
| addNodeOperatorETH                                  | 26728           | 586881 | 546565 | 1173320 | 267     |
| addNodeOperatorStETH                                | 27665           | 326551 | 341085 | 539097  | 8       |
| addNodeOperatorWstETH                               | 27556           | 336751 | 349979 | 558992  | 8       |
| addValidatorKeysETH                                 | 25733           | 186949 | 258282 | 313380  | 12      |
| addValidatorKeysStETH                               | 26447           | 130381 | 89982  | 245916  | 6       |
| addValidatorKeysWstETH                              | 26425           | 139671 | 96420  | 264145  | 6       |
| cancelELRewardsStealingPenalty                      | 26305           | 92787  | 102370 | 140104  | 4       |
| claimRewardsStETH                                   | 25084           | 50899  | 27307  | 100308  | 3       |
| claimRewardsWstETH                                  | 25151           | 50580  | 27374  | 99215   | 3       |
| cleanDepositQueue                                   | 21654           | 35068  | 32833  | 53266   | 13      |
| compensateELRewardsStealingPenalty                  | 23710           | 114746 | 138214 | 158848  | 4       |
| confirmNodeOperatorManagerAddressChange             | 23690           | 29054  | 29103  | 34271   | 5       |
| confirmNodeOperatorRewardAddressChange              | 23647           | 33068  | 33954  | 38947   | 6       |
| decreaseOperatorVettedKeys                          | 24949           | 87822  | 101855 | 156026  | 22      |
| depositETH                                          | 23723           | 119095 | 125558 | 175594  | 8       |
| depositQueueItem                                    | 689             | 1355   | 689    | 2689    | 12      |
| depositStETH                                        | 24715           | 102898 | 108791 | 158827  | 5       |
| depositWstETH                                       | 24652           | 115857 | 125004 | 175040  | 5       |
| earlyAdoption                                       | 427             | 427    | 427    | 427     | 1       |
| getActiveNodeOperatorsCount                         | 424             | 424    | 424    | 424     | 2       |
| getNodeOperator                                     | 2369            | 9678   | 8369   | 18369   | 579     |
| getNodeOperatorIds                                  | 778             | 1234   | 1183   | 1935    | 8       |
| getNodeOperatorIsActive                             | 637             | 637    | 637    | 637     | 1       |
| getNodeOperatorSummary                              | 10075           | 14164  | 14449  | 16075   | 61      |
| getNodeOperatorsCount                               | 380             | 380    | 380    | 380     | 260     |
| getNonce                                            | 402             | 552    | 402    | 2402    | 80      |
| getSigningKeys                                      | 796             | 2963   | 3714   | 3714    | 7       |
| getSigningKeysWithSignatures                        | 865             | 3506   | 3400   | 6254    | 3       |
| getStakingModuleSummary                             | 683             | 2808   | 2683   | 4683    | 16      |
| getType                                             | 316             | 316    | 316    | 316     | 1       |
| grantRole                                           | 27125           | 118629 | 118703 | 118703  | 1943    |
| hasRole                                             | 772             | 772    | 772    | 772     | 2       |
| initialize                                          | 142645          | 182793 | 182925 | 182925  | 307     |
| isPaused                                            | 515             | 915    | 515    | 2515    | 5       |
| isValidatorSlashed                                  | 651             | 651    | 651    | 651     | 1       |
| isValidatorWithdrawn                                | 662             | 662    | 662    | 662     | 1       |
| keyRemovalCharge                                    | 361             | 1361   | 1361   | 2361    | 2       |
| normalizeQueue                                      | 30255           | 54753  | 54753  | 79252   | 2       |
| obtainDepositData                                   | 24601           | 109495 | 111140 | 176065  | 58      |
| onExitedAndStuckValidatorsCountsUpdated             | 23743           | 23779  | 23779  | 23815   | 2       |
| onRewardsMinted                                     | 24066           | 45601  | 45001  | 67737   | 3       |
| onWithdrawalCredentialsChanged                      | 23795           | 25277  | 25018  | 27018   | 3       |
| pauseFor                                            | 24067           | 45491  | 47634  | 47634   | 11      |
| proposeNodeOperatorManagerAddressChange             | 24165           | 42600  | 53587  | 53587   | 9       |
| proposeNodeOperatorRewardAddressChange              | 24210           | 33503  | 36555  | 36555   | 10      |
| publicRelease                                       | 474             | 474    | 474    | 474     | 1       |
| queue                                               | 525             | 858    | 525    | 2525    | 6       |
| recoverERC20                                        | 58544           | 58544  | 58544  | 58544   | 1       |
| recoverEther                                        | 23837           | 26111  | 26111  | 28385   | 2       |
| recoverStETHShares                                  | 60862           | 60862  | 60862  | 60862   | 1       |
| removeKeys                                          | 23982           | 138345 | 172276 | 240582  | 16      |
| reportELRewardsStealingPenalty                      | 24363           | 135055 | 141678 | 154408  | 36      |
| requestRewardsETH                                   | 25087           | 50888  | 27310  | 100269  | 3       |
| resetNodeOperatorManagerAddress                     | 23668           | 31912  | 31318  | 38640   | 5       |
| resume                                              | 23787           | 26728  | 26728  | 29670   | 2       |
| revokeRole                                          | 40394           | 40394  | 40394  | 40394   | 1       |
| setKeyRemovalCharge                                 | 24061           | 47089  | 47175  | 47187   | 271     |
| settleELRewardsStealingPenalty                      | 24740           | 93757  | 114360 | 164302  | 23      |
| submitInitialSlashing                               | 24204           | 98223  | 130155 | 134364  | 13      |
| submitWithdrawal                                    | 24363           | 121877 | 136395 | 235167  | 15      |
| unsafeUpdateValidatorsCount                         | 24342           | 61376  | 35993  | 160209  | 10      |
| updateExitedValidatorsCount                         | 24992           | 58688  | 47664  | 110392  | 11      |
| updateRefundedValidatorsCount                       | 24216           | 28998  | 31384  | 31396   | 3       |
| updateStuckValidatorsCount                          | 24882           | 73220  | 60599  | 138937  | 13      |
| updateTargetValidatorsLimits                        | 24435           | 124873 | 139169 | 210909  | 41      |


| src/CSVerifier.sol:CSVerifier contract |                 |       |        |        |         |
|----------------------------------------|-----------------|-------|--------|--------|---------|
| Function Name                          | min             | avg   | median | max    | # calls |
| BEACON_ROOTS                           | 304             | 304   | 304    | 304    | 21      |
| FIRST_SUPPORTED_SLOT                   | 215             | 215   | 215    | 215    | 4       |
| initialize                             | 66554           | 66554 | 66554  | 66554  | 17      |
| processHistoricalWithdrawalProof       | 80338           | 97759 | 87419  | 152939 | 5       |
| processSlashingProof                   | 48850           | 62681 | 55698  | 83497  | 3       |
| processWithdrawalProof                 | 56381           | 75183 | 74077  | 107647 | 9       |


| src/lib/AssetRecovererLib.sol:AssetRecovererLib contract |                 |       |        |       |         |
|----------------------------------------------------------|-----------------|-------|--------|-------|---------|
| Function Name                                            | min             | avg   | median | max   | # calls |
| recoverERC1155                                           | 38601           | 38601 | 38601  | 38601 | 1       |
| recoverERC20                                             | 36031           | 36031 | 36031  | 36031 | 4       |
| recoverERC721                                            | 43326           | 43326 | 43326  | 43326 | 1       |
| recoverEther                                             | 1793            | 20813 | 33493  | 33493 | 5       |




