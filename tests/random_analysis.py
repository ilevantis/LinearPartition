import numpy as np
import uuid
import subprocess
import os
import glob
from collections import defaultdict

# Testing parameters
num_sequences = 100
L = 1000

algos = {
    'EternaFold': 'eternafold', 
    'LinearPartition (c)': 'linearpartition_c', 
    'LinearPartition (v)': 'linearpartition_v', 
    'LinearPartition (e)': 'linearpartition_e'
}

print(f'Testing {num_sequences} sequences with length {L} ...')

failures = defaultdict(lambda: [])
for i in range(num_sequences):
    seq = ''.join(np.random.choice(['A','C','G','U'], L))
    uid = str(uuid.uuid4().hex)
    
    print(f'\n{i+1} - {uid}')

    with open(f'input/{uid}.fasta', 'w') as f:
        print(f'>{uid}', file=f)
        print(seq, file=f)

    path = os.path.dirname(os.path.abspath(__file__))
    subprocess.call([f'{path}/fold', uid], stdout=open(os.devnull, 'wb'), stderr=open(os.devnull, 'wb'))
        
    success = True
    for algo, file in algos.items():
        with open(f'output/{uid}-{file}.txt', 'r') as f:
            lines = f.readlines()

        probs = np.zeros((L+1, L+1))

        if file == 'eternafold':        
            for line in lines:
                line = line.strip()
                if not line:
                    continue
                
                i, _, *ps = line.strip().split(' ')
                
                for j, p in [s.split(':') for s in ps]:
                    probs[int(i), int(j)] = float(p)

        else:
            for line in lines:
                line = line.strip()
                if not line:
                    continue

                i, j, p = line.split(' ')

                probs[int(i), int(j)] = float(p)
        
        probs += probs.T

        probs_sum = np.sum(probs, axis=0)
        corrupted_nucs = np.where(probs_sum > 1)[0]

        if(len(corrupted_nucs) == 0):
            print(f' {algo:<25} \t OK')
            # Remove files
        else:
            success = False
            failures[algo].append([uid, len(corrupted_nucs)])
            print(f' {algo:<25} \t Corrupted i:  ', corrupted_nucs, 'Corrupted p_i: ', probs_sum[corrupted_nucs])

    if success:
        for f in glob.glob(f'output/{uid}-*.txt'):
            os.remove(f)
        os.remove(f'input/{uid}.fasta')
       
print('\n*** SUMMARY ***')
print(f'Tested {num_sequences} sequences with length {L}')
for algo in algos:
    print(f'{algo:<25} {len(failures[algo])} failures')