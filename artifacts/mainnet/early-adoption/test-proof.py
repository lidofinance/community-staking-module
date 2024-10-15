import json
import http.client
import os
import urllib.parse

EA_ADDRESS = "0x3D5148ad93e2ae5DedD1f7A8B3C19E7F67F90c0E"


def main():
    proofs = json.load(open("merkle-proofs.json"))
    rpc_url = urllib.parse.urlparse(os.getenv("RPC_URL"))
    host, port = rpc_url.hostname, rpc_url.port
    addr_length = len(proofs.keys())
    current = 0
    if rpc_url.scheme == "https":
        conn = http.client.HTTPSConnection(host, port)
    else:
        conn = http.client.HTTPConnection(host, port)
    for addr, proof in proofs.items():
        headers = {'Content-type': 'application/json'}
        payload = json.dumps({
            "jsonrpc": "2.0",
            "method": "eth_call",
            "params": [{
                "to": EA_ADDRESS,
                "value": "0x0",
                "data": '0xe3486434' + addr[2:].zfill(64) + "0000000000000000000000000000000000000000000000000000000000000040" + hex(len(proof))[2:].zfill(64) +
                "".join([p[2:] for p in proof])
            }, "latest"],
            "id": 1
        })
        conn.request("POST", rpc_url.path, payload, headers)
        response = conn.getresponse()
        data = response.read().decode()
        assert data.endswith('01"}'), f"🚨 Check failed. Address: {addr}, Data: {data}"
        current += 1
        if current % 1000 == 0:
            print(f"Processed {current} of {addr_length} addresses ⏳")
    conn.close()
    print("All checks passed ✅")


if __name__ == "__main__":
    main()
