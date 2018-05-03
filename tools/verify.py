"""
Script to run both pricer implementations and verify that their outputs are correct
"""
import os
from commands import getoutput
from sys import argv

TARGETS = (1, 200, 10000)

def run_pricer():
    for target in TARGETS:
        cmd = "./pricer %d < input_data/pricer.in > output_data/pricer.out.%d" % (target, target)
        print cmd
        out = getoutput(cmd)
        cmd = "experiments/ordermap/pricer %d < input_data/pricer.in > output_data/map.pricer.out.%d" % (target, target)
        print cmd
        out = getoutput(cmd)

def verify_outputs(fn_prefix=''):
    grade = True
    for target in TARGETS:
        cmd = "cksum output_reference/pricer.out.%d output_data/%spricer.out.%d" % (target, fn_prefix, target)
        out = getoutput(cmd)
        ref,mine = out.split('\n')
        ref_fields = ref.split()
        my_fields = mine.split()
        if not ref_fields[:2] == my_fields[:2]:
            print "FAILURE: File output_data/pricer.out.%d does not match output reference" % target
            grade = False
    if grade:
        print "SUCCESS: all target sizes match reference"


if __name__ == '__main__':
    if not os.path.exists('output_data'):
        os.mkdir('output_data')
    run_pricer()
    verify_outputs()
    print
    print "Now verify Ordermap"
    # Run test on tree-based ordermap output too
    verify_outputs('map.')

