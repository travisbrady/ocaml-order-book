"""
Convert the pricer.in file to a simple length-prefixed binary encoding
"""
from struct import pack

#Example: 28800538 A b S 44.26 100
ADD_FMT =  ">"  # big endian
ADD_FMT += "c"  # order type, buy, sell or reduce (B, S or R)
ADD_FMT += "i"  # ts
ADD_FMT += "i"  # order id length
ADD_FMT += "s"  # order id
ADD_FMT += "i"  # price
ADD_FMT += "i"  # size

#Example: 28800744 R b 100
REDUCE_FMT  = ">" # big endian
REDUCE_FMT += "c" # order type
REDUCE_FMT += "i" # ts
REDUCE_FMT += "i" # order id length
REDUCE_FMT += "s" # order id
REDUCE_FMT += "i" # size

def encode(ordstr):
    fields = ordstr.split()
    if fields[1] == 'A':
        ts, _, oid, side, price, size = fields
        ts = int(ts)
        price = int(price.replace('.', ''))
        size = int(size)
        return pack(ADD_FMT, side, ts, len(oid), oid, price, size)
    elif fields[1] == 'R':
        ts, _, oid, size = fields
        ts = int(ts)
        size = int(size)
        return pack(REDUCE_FMT, 'R', ts, len(oid), oid, size)

def main():
    with file('input_data/pricer.bin', 'wb') as pricer_bin:
        for line in file('input_data/pricer.in'):
            packed = encode(line)
            pricer_bin.write(packed)

if __name__ == '__main__':
    main()

