import json
from web3 import Web3

WEB3_PROVIDER = "http://localhost:8545"  # Replace with your actual Web3 provider URL
CSM_ADDRESS = "0xdA7dE2ECdDfccC6c3AF10108Db212ACBBf9EA83F"
REFERENCE_BLOCK = 22845716

with open("abi/csm_abi.json", "r") as file:
    CSM_ABI = file.read()

with open("sources/ea.json", "r") as file:
    EA_NOS = json.load(file)

def get_inactive_nos(reference_block):
    web3 = Web3(Web3.HTTPProvider(WEB3_PROVIDER))
    csm = web3.eth.contract(address=CSM_ADDRESS, abi=CSM_ABI, decode_tuples=True)

    inactive_ea_nos = []

    for no_id in EA_NOS:
        operator = csm.functions.getNodeOperator(no_id).call(block_identifier=reference_block)
        deposited = operator.totalDepositedKeys
        depositable = operator.depositableValidatorsCount
        exited = operator.totalExitedKeys
        active = deposited - exited

        if depositable == 0 and active == 0:
            inactive_ea_nos.append(no_id)

    with open('exclude/inactive.json', 'w') as f:
        json.dump(inactive_ea_nos, f)


if __name__ == "__main__":
    get_inactive_nos(REFERENCE_BLOCK)
