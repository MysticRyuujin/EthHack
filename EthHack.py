#!/usr/bin/python3

import sha3
from web3 import Web3, KeepAliveRPCProvider
from ecdsa import SigningKey, SECP256k1

web3 = Web3(KeepAliveRPCProvider(host='localhost', port='8545'))

while True:
    keccak = sha3.keccak_256()
    private = SigningKey.generate(curve=SECP256k1)
    public = private.get_verifying_key().to_string()
    keccak.update(public)
    address = "0x{}".format(keccak.hexdigest()[24:])
    balance = web3.eth.getBalance(address)
    if balance > 0:
        f = open(address, 'w')
        f.write("PRIVATE: {0}\nADDRESS: {1}\nBALANCE: {2}\n".format(private.to_string().hex(),address,balance))
        f.close()
