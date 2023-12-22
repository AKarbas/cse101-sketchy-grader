#!/usr/bin/env python3

import re
from sys import argv, exit

def main():
  if len(argv) < 3:
    exit(1)
  
  outf = argv[1]
  expfs = argv[2:]
  best = 0
  for expf in expfs:
    for skip in [False, True]:
      score = check_outputs(outf, expf, skip)
      best = max(best, score)
#      print(f'{score:.1f}')
  print(f'{best:.1f}')


def check_outputs(outf, expf, skipone=False):
  try:
    outc, expc = readf(outf), readf(expf)
  except FileNotFoundError as f:
    return 0
  if skipone:
    outc = outc[1:]

  block_markers = [i for i in range(len(expc))
                   if expc[i][0] == 'b']
  # Remove escaped '\B's after processing markers.
  expc = [l[1:] if len(l) > 1 and l[:2] == '\b' else l
          for l in expc]
  total = 0
  for i in range(len(block_markers)):
    block_lines = (block_markers[i+1] - block_markers[i]
                   if i < (len(block_markers)-1)
                   else len(expc))
    olines = outc[:block_lines-1]
    outc = outc[block_lines-1:]
    elines = expc[:block_lines]
    expc = expc[block_lines:]
#    print(*olines, sep='\n', end='\n')
#    print('----')
#    print(*elines, sep='\n', end='\n')

    score = process_block(olines, elines)
    total += score
#    print(f'==== {score} ====')

  return total


def process_block(olines, elines):
  # Block marker: `B {u,o}r {u,o}c[ncols] [points]`
  bmparts = elines.pop(0).split()
  assert(bmparts[0] == 'b')
  orderedr = bmparts[1][0] == 'o'
  orderedc = bmparts[2][0] == 'o'
  nrows = len(elines)
  ncols = int(bmparts[2][2:]) if len(bmparts[2]) > 2 else None
  points = float(bmparts[3]) if len(bmparts) > 3 else 10.0

  alleparts = [tokenize(l) for l in elines]
  alloparts = [tokenize(l) for l in olines]
  if not orderedc:
    alleparts = [sorted(l) for l in alleparts]
    alloparts = [sorted(l) for l in alloparts]

  matches = 0
  for _ in range(nrows):
    eparts = alleparts.pop(0)

    alloparts_last_possible = 1 if orderedr else len(alloparts)
    for i in range(min(alloparts_last_possible, len(alloparts))):
      oparts = alloparts[i]

      if ncols is not None and len(oparts) != ncols:
        continue # no match
      if eparts != oparts:
        continue # no match

      # match
      alloparts.pop(i)
      matches += 1
      break

  score = points * (float(matches) / float(nrows))
  return score


def tokenize(line):
  return re.findall(r'\b(-1|[bwg]|\d+)\b', line)

  
def readf(fp):
  with open(fp, 'rt') as f:
    fc = [l.strip().lower() for l in f.readlines()]
  fc = [l for l in fc if (
          len(l.strip()) > 0
          and l.strip()[0] != '#'
          and any(c.isdigit() for c in l))]
  return fc


if __name__ == '__main__':
  main()
