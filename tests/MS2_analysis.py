import numpy as np
import os 
import subprocess

algos = {
    'EternaFold': 'eternafold', 
    'LinearPartition (contrafold)': 'linearpartition_c', 
    'LinearPartition (viennarna)': 'linearpartition_v', 
    'LinearPartition (eternafold)': 'linearpartition_e'
}

path = os.path.dirname(os.path.abspath(__file__))
subprocess.call([f'{path}/fold', 'MS2'], stdout=open(os.devnull, 'wb'), stderr=open(os.devnull, 'wb'))

for algo, file in algos.items():
    with open(f'output/MS2-{file}.txt', 'r') as f:
        lines = f.readlines()

    L = 835
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

    print(f'***** {algo} *****\n')

    for nuc in [571, 572]:
        # print(f'Nucleotide {nuc}')
        print('  i \t j \t p_ij')

        nuc_probs = probs[nuc,:]
        nonzero_probs = np.where(nuc_probs > 0)[0]

        for i in nonzero_probs:
            print(f'  {nuc} \t {i} \t {nuc_probs[i]}')
        
        print(f'---------------------------\n  p_{nuc} = {np.sum(nuc_probs)} \n')

    probs_sum = np.sum(probs, axis=0)
    corrupted_nucs = np.where(probs_sum > 1)[0]
    print('\nCorrupted i:  ', corrupted_nucs)
    print('Corrupted p_i: ', probs_sum[corrupted_nucs], '\n\n')
