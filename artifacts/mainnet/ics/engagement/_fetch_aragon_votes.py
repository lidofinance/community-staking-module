import json
from collections import defaultdict

from web3 import Web3

RPC_URL = "http://localhost:8545/"
ARAGON_BLOCK_CUTOFF = 22773472 # TODO update

if __name__ == '__main__':
    w3 = Web3(Web3.HTTPProvider(RPC_URL))

    voting_address = Web3.to_checksum_address("0x2e59A20f205bB85a89C53f1936454680651E618e")
    voting_deployment_block = 11473216

    # event CastVote(uint256 indexed voteId, address indexed voter, bool supports, uint256 stake);
    abi = '[{"anonymous":false,"inputs":[{"indexed":true,"name":"voteId","type":"uint256"},{"indexed":true,"name":"voter","type":"address"},{"indexed":false,"name":"supports","type":"bool"},{"indexed":false,"name":"stake","type":"uint256"}],"name":"CastVote","type":"event"}]'
    contract = w3.eth.contract(address=voting_address, abi=abi, decode_tuples=True)
    logs = contract.events.CastVote().get_logs(
            fromBlock=voting_deployment_block,
            toBlock=ARAGON_BLOCK_CUTOFF
    )

    voters = defaultdict(set)
    for log in logs:
        # filter out votes with less than 100 LDO
        if log.args.stake >= 100 * 10**18:
            voters[log.args.voter.lower()].add(log.args.voteId)
    # filter out addresses that have voted only once
    voters = {v.lower() for v in voters if len(voters[v]) >= 2}

    with open("eligible_aragon_voters.csv", "w") as f:
        for address in sorted(voters):
            f.write(f"{address}\n")
