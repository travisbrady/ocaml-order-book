# Script to run a bunch of target sizes through
# both the array-based and tree-based implementations
# and collect the number of iterations each call to compute_txn
# makes through its price_to_size data structure
# This requires that both src/ordergrid.ml and experiments/ordermap/ordermap.ml
# were compiled to print the iteration counts to stderr
import os
from commands import getoutput

TARGETS = [1, 200] + range(500, 10000+1, 500)
OUT_FN = 'iter_counts.csv'

def main():
    if os.path.exists(OUT_FN):
        os.unlink(OUT_FN)
    for target in TARGETS:
        grid_cmd = "./pricer %d < input_data/pricer.in > output_data/pricer.out.%d 2>>%s" % (target, target, OUT_FN)
        print grid_cmd
        out = getoutput(grid_cmd)
        map_cmd = "experiments/ordermap/pricer %d < input_data/pricer.in > output_data/map.pricer.out.%d 2>>%s" % (target, target, OUT_FN)
        print map_cmd
        out = getoutput(map_cmd)


if __name__ == '__main__':
    main()
