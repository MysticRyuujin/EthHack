#!/usr/bin/python3
import multiprocessing
import psutil
import os
import time
import random
import requests
import sha3
from ecdsa import SigningKey, SECP256k1
from web3 import Web3

# Enphase URL & Password
enphaseURL = 'http://enphase.local/production.json'
enphasePassword = ''

# Our Ethereum Node(s) using WebScokets
ethNodes = ['ws://localhost:8546']

# Get NetPower from Enphase
def getNetPower():
    result = requests.get(url=enphaseURL,auth=requests.auth.HTTPBasicAuth('envoy',enphasePassword)).json()
    return int(result['consumption'][1]['wNow'])

# Returns the average over 6 readings (1 reading every 10 seconds / 6 readings = 1 minute average)
def getAverage(avg):
    avg = avg - (avg / 6)
    avg = avg + (getNetPower() / 6)
    return int(avg)

# The meat
def ethhack(netPower):
    web3 = []
    # Create Websocket Connection to each node in the list
    for node in ethNodes:
        web3.append(Web3(Web3.WebsocketProvider(node)))
    # Run forever!
    while True:
        # Check if there's at least 10 watts of extra power
        if netPower.value > -10:
            time.sleep(10)
            continue
        # Generate a random private / public key pair and get the address
        keccak = sha3.keccak_256()
        private = SigningKey.generate(curve=SECP256k1)
        public = private.get_verifying_key().to_string()
        keccak.update(public)
        address = Web3.toChecksumAddress("0x{}".format(keccak.hexdigest()[24:]))
        # Check the balance against a random Ethereum Node (load balancing!)
        try:
            balance = random.choice(web3).eth.getBalance(address)
        except:
            balance = -1
        # If the balance isn't 0 export it to a file so we can check or validate it later (usually this means a communication issue with node...)
        # If the balance is over 0 we found a real balance!?
        if balance != 0:
            if balance > 0:
                print("FOUND SOMETHING: {0}".format(address))
            with open(address+'.txt', 'w') as f:
                f.write("PRIVATE: {0}\nADDRESS: {1}\nBALANCE: {2}\n".format(private.to_string().hex(), address, balance))
            f.close()

# Start of the script
if __name__ == "__main__":
    # Freeze support if made into an execuable on Windows
    multiprocessing.freeze_support()
    # multiprocessing safe shared memory variable for power reading
    netPower = multiprocessing.Value('i',(getNetPower() * 6))
    # Spin up a process for each CPU core
    jobs = []
    for i in range(multiprocessing.cpu_count()):
        p = multiprocessing.Process(target=ethhack, args=(netPower,))
        jobs.append(p)
        p.start()
    # Set the priority of the child processes to the lowest setting (OS stability so I can use my PC)
    parent = psutil.Process()
    if os.name == 'nt':
        parent.nice(psutil.BELOW_NORMAL_PRIORITY_CLASS)
        for child in parent.children():
            child.nice(psutil.IDLE_PRIORITY_CLASS)
    else:
        parent.nice(10)
        for child in parent.children():
            child.nice(19)
    # Constantly update the current solar power output
    while True:
        netPower.value = getAverage(netPower.value)
        time.sleep(10)
