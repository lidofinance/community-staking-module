import json
from web3 import Web3

PROVIDER_URL_MAINNET = "http://localhost:8545"  # Replace with your actual Web3 provider URL
CONTRACT_ADDRESS_HOODI = '0x79CEf36D84743222f37765204Bec41E92a93E59d'

with open("abi/csm_abi.json", "r") as file:
    CSM_ABI = file.read()

REFERENCE_BLOCK_HOODI = 761666


def main():
    with open("sources/non_sybil_operators.json", "r") as f:
        non_sybil = json.load(f)

    print(f"Total Non-Sybil Node Operators: {len(non_sybil)}")

    with open("sources/associated_operators.json", "r") as f:
        associated_operators = json.load(f)

    print(f"Total Associated Node Operators: {len(associated_operators)}")

    w3 = Web3(Web3.HTTPProvider(PROVIDER_URL_MAINNET))
    contract = w3.eth.contract(address=CONTRACT_ADDRESS_HOODI, abi=CSM_ABI, decode_tuples=True)

    final_addresses = []

    def extract_address(operator_id):
        """Extracts the address from the node operator based on permissions."""
        node_operator = contract.functions.getNodeOperator(int(operator_id)).call(block_identifier=REFERENCE_BLOCK_HOODI)
        return node_operator.managerAddress if node_operator.extendedManagerPermissions else node_operator.rewardAddress

    # Just take addresses from non-sybil operators
    for no_id in non_sybil:
        no_address = extract_address(no_id)
        final_addresses.append(no_address)
        print(f"Node Operator ID: {no_id}, Address: {no_address}")

    # For sybil operators, take addresses from the first associated operator in each group
    for cluster_group, associated_ids in associated_operators.items():
        first = associated_ids[0]  # Take the first associated operator
        no_address = extract_address(first)
        final_addresses.append(no_address)
        print(f"Cluster Group {cluster_group}, First Operator ID: {first}, Address: {no_address}")

    sorted_addresses = sorted(set(final_addresses), key=lambda x: final_addresses.index(x))

    with open("ics.csv", "w") as f:
        for address in sorted_addresses:
            f.write(f"{address}\n")

if __name__ == '__main__':
    main()
