# EthHack
Brute Force Ethereum Addresses with Python

Script assumes you are running a local Geth RPC node that is fully sync'd

Create a folder in your home directory called EthHack and a sub folder called Results

Run Script

The script is single threaded so ideally you'd want to run it 2-8x per CPU core and let the system handle the rest. Perhaps a bash script to launch multiple instances in the background?

A Python multiprocessing verson would be simple enough to write but it's a lot more work for basically zero gain...
