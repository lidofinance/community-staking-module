# AssetRecoverer

[Git Source](https://github.com/lidofinance/community-staking-module/blob/8ce9441dce1001c93d75d065f051013ad5908976/src/abstract/AssetRecoverer.sol)

Assets can be sent only to the `msg.sender`

_Abstract contract providing mechanisms for recovering various asset types (ETH, ERC20, ERC721, ERC1155) from a contract.
This contract is designed to allow asset recovery by an authorized address by implementing the onlyRecovererRole guardian_

## Functions

### recoverEther

_Allows sender to recover Ether held by the contract
Emits an EtherRecovered event upon success_

```solidity
function recoverEther() external;
```

### recoverERC20

_Allows sender to recover ERC20 tokens held by the contract_

```solidity
function recoverERC20(address token, uint256 amount) external virtual;
```

**Parameters**

| Name     | Type      | Description                                                                                                                                                                        |
| -------- | --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `token`  | `address` | The address of the ERC20 token to recover Emits an ERC20Recovered event upon success Optionally, the inheriting contract can override this function to add additional restrictions |
| `amount` | `uint256` |                                                                                                                                                                                    |

### recoverERC721

_Allows sender to recover ERC721 tokens held by the contract_

```solidity
function recoverERC721(address token, uint256 tokenId) external;
```

**Parameters**

| Name      | Type      | Description                                                                             |
| --------- | --------- | --------------------------------------------------------------------------------------- |
| `token`   | `address` | The address of the ERC721 token to recover                                              |
| `tokenId` | `uint256` | The token ID of the ERC721 token to recover Emits an ERC721Recovered event upon success |

### recoverERC1155

_Allows sender to recover ERC1155 tokens held by the contract._

```solidity
function recoverERC1155(address token, uint256 tokenId) external;
```

**Parameters**

| Name      | Type      | Description                                                                                 |
| --------- | --------- | ------------------------------------------------------------------------------------------- |
| `token`   | `address` | The address of the ERC1155 token to recover.                                                |
| `tokenId` | `uint256` | The token ID of the ERC1155 token to recover. Emits an ERC1155Recovered event upon success. |

### \_onlyRecoverer

_Guardian to restrict access to the recover methods.
Should be implemented by the inheriting contract_

```solidity
function _onlyRecoverer() internal view virtual;
```
