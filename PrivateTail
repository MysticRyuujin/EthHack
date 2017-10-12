import os
import multiprocessing
import psutil
import sha3
from ecdsa import SigningKey, SECP256k1

# Put the part of the private key that you know here:
prefix = "3a1076bf45ab87712ad64ccb3b10217737f7faacbf2872e88fdd9a537d8fe2"

# Put your public address here:
address = "0x64CA3de4799345F7A76D938f60D6e27A40549c56"

missingchars = 64 - len(prefix)

def ethhack(integer):
    string = prefix + "{0:0{1}x}".format(integer, missingchars)
    testkey = bytearray.fromhex(string)
    keccak = sha3.keccak_256()
    private = SigningKey.from_string(testkey,curve=SECP256k1)
    public = private.get_verifying_key().to_string()
    keccak.update(public)
    pubaddress = "0x{}".format(keccak.hexdigest()[24:])
    if pubaddress.lower() == address.lower():
        print(string)


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

    [pool.apply_async(ethhack,args=(i,)) for i in range((16**missingchars))]
    pool.close()
    pool.join()
