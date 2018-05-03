import time
from commands import getoutput

target = 200
for i in range(10):
    cmd = "cat input_data/pricer.in | ./pricer 200 > /dev/null"
    t0 = time.time()
    output = getoutput(cmd)
    print time.time() - t0
