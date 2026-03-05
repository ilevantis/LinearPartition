import numpy as np
import matplotlib.pyplot as plt


algos = {
    'EternaFold': 'eternafold', 
    'EternaFold (double)': 'eternafold_double', 
    'LinearPartition (contrafold)': 'linearpartition_c', 
    'LinearPartition (viennarna)': 'linearpartition_v', 
    'LinearPartition (eternafold)': 'linearpartition_e'
}

probs_matrices = []

for algo, file in algos.items():
    with open(f'output/MS2-{file}.txt', 'r') as f:
        lines = f.readlines()

    L = 835
    probs = np.zeros((L+1, L+1))

    if file in ['eternafold', 'eternafold_double']:        
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

    probs_matrices.append(probs)


fig, axes = plt.subplots(nrows=4, ncols=5, figsize=(15, 9), gridspec_kw={'height_ratios': [3, 1, 1, 1]})

for i, algo in enumerate(algos.keys()):
    axMat = axes[0, i]
    mat = axMat.matshow(probs_matrices[i] - probs_matrices[0], cmap='PiYG', vmin=-.5, vmax=.5)
    axMat.set_xticks([])
    axMat.set_yticks([])
    axMat.set_xlabel('$i$')
    axMat.set_ylabel('$j$')
    axMat.set_title(algo)

    axHist = axes[1, i]
    delta_p = (probs_matrices[i] - probs_matrices[0])[np.triu_indices(probs_matrices[0].shape[0])].flatten()
    axHist.hist(delta_p, np.linspace(-1, 1, 50) if i != 1 else np.linspace(-0.005, 0.005, 50))
    axHist.set_yscale('log')
    axHist.set_xlabel('$\\Delta p_{ij}$')
    axHist.set_ylim(0.5, 1e6)
    
    axHist2 = axes[2, i]
    axHist2.hist(np.sum(probs_matrices[i] + probs_matrices[i].T, axis=0), np.linspace(0, 1.2, 49))
    axHist2.axvspan(1, 1.1, color='red', alpha=0.3)
    axHist2.set_yscale('log')
    axHist2.set_xlabel(f'$p_i$')
    axHist2.set_xlim(-0.05, 1.1)
    axHist2.set_ylim(0.5, 1e3)
    
    axHist3 = axes[3, i]
    axHist3.hist(np.sum(probs_matrices[i] + probs_matrices[i].T, axis=0), np.linspace(0.995, 1.005, 49))
    axHist3.axvspan(1, 1.01, color='red', alpha=0.3)
    axHist3.set_yscale('log')
    axHist3.set_xlabel(f'$p_i$')
    axHist3.set_xlim(0.995, 1.005)
    axHist3.set_ylim(0.5, 1e2)


plt.tight_layout()
axCbar = fig.add_axes((0.999, 0.7, 0.01, 0.2))
axCbar.set_title('$\\Delta p_{ij}$')
fig.colorbar(mat, cax=axCbar)
plt.savefig('MS2_comparison.png', dpi=400, bbox_inches='tight')