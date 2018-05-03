"""
Run both the Ordergrid and Ordermap pricers on a bunch of target sizes to gather
some performance statistics
"""
from time import time
import csv
import commands

targets= range(200, 10000 + 1, 200)
N = 5

fh = open('grid_vs_map_10000.csv', 'wb')
writer = csv.writer(fh)
writer.writerow(('target', 'grid_run_time', 'map_run_time'))

for target in targets:
    for i in range(N):
        print target, i
        grid_cmd = "./pricer %d < input_data/pricer.in > output_data/grid.pricer.out.%d" % (target, target)
        t0 = time()
        out = commands.getoutput(grid_cmd)
        grid_t_diff = time() - t0

        t0 = time()
        map_cmd = "experiments/ordermap/pricer %d < input_data/pricer.in > output_data/map.pricer.out.%d" % (target, target)
        out = commands.getoutput(map_cmd)
        writer.writerow((target, grid_t_diff, time() - t0))

fh.close()
