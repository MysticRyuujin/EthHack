#!/usr/bin/python3
import sha3
import multiprocessing
import psutil
import os
from ecdsa import SigningKey, SECP256k1
from web3 import Web3, KeepAliveRPCProvider


# Point to an RPC node
ethNode = 'localhost'


def ethhack():
    web3 = Web3(KeepAliveRPCProvider(host=ethNode, port='8545', ssl=False))
    while True:
        keccak = sha3.keccak_256()
        private = SigningKey.generate(curve=SECP256k1)
        public = private.get_verifying_key().to_string()
        keccak.update(public)
        address = "0x{}".format(keccak.hexdigest()[24:])
        try:
            balance = web3.eth.getBalance(address)
        except:
            balance = -1
        if balance != 0:
            with open(address, 'w') as f:
                f.write("PRIVATE: {0}\nADDRESS: {1}\nBALANCE: {2}\n".format(private, address, balance))
            f.close()


if __name__ == "__main__":
    cores = multiprocessing.cpu_count()
    pool = multiprocessing.Pool(processes=cores)
    parent = psutil.Process()
    if os.name == 'nt':
        parent.nice(psutil.BELOW_NORMAL_PRIORITY_CLASS)
        for child in parent.children():
            child.nice(psutil.IDLE_PRIORITY_CLASS)
    else:
        parent.nice(10)
        for child in parent.children():
            child.nice(19)
    [pool.apply_async(ethhack) for i in range(cores)]
    pool.close()
    pool.join()
