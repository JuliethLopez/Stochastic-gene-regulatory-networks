# A study of stochastic gene regulatory networks

This study was based in Murrugarra paper, [Modeling stochasticity and variability in gene regulatory networks](https://dx.doi.org/10.1186%2F1687-4153-2012-5) and the Akman paper, [Dynamics of Gene Regulatory Networks with Stochastic Propensities](https://doi.org/10.1142/S1793524518500328) with the goal of make an applycation of Akman proposed model. Although initially was spected to use real data, this wasn't possible due that we couldn't obtain an enough large time serie of a simple specie like C.Elegans, Escherichia Coli or Yeast. Therefore, we simulated the data.

To have an idea of the model we'll expose an overwiew of the paper's models. Murrugarra paper bases its model in a Probabilistic Boolean Network, however is implement another model in which every node has associated to it two functions: (update note) the function that governs its evolution over time and (not update node) the identity function. The key difference to a PBN is the assignment of probabilities that govern which update is chosen. This is done because exists different biochemical processes, and they consider two functions because is not appropriate to represent it by the same due to propensities are different. It offers a finer analysis, natural setup for cell population simulations to study cell-to-cell variability. But consider only intrinsic noise (reactant molecules, reactions times, biological uncertainty), not extrinsic noise like: experimental rowdy (mesurament), latent variables (environmental conditions or noise celular environment). That is the principal difference with Akman paper, where is considered a Beta distribution for propensities with regulatory rules known. The parameters, α and β, of the beta distribution are used to have in mind the extrinsic noise.

In this repository we have put a code created in R program in which in possible to put **n** number genes with their activation or degradions propensities as well as the genes that are activated or degraded by each gene. With the code is possible to find the fixed states, the states taking in mind probabilities to pass from one to another state, and finally the code generates **m** simulations to add the last states a variance of probability changing states. Finally, it's important to remember that the propensities found in Gene Networks are not in fact seen as constant, rather they can be values that can be changed with a certain probability.
                                            
For open the **APLICATION.ipynb** in Binder you can use this button:
Binder: [![Binder](http://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/JuliethLopez/Stochastic-gene-regulatory-networks/main?filepath=APLICATION.ipynb)

For open all the repository in RStudio you can use the next button:
RStudio: [![Binder](http://mybinder.org/badge_logo.svg)](http://mybinder.org/v2/gh/JuliethLopez/Stochastic-gene-regulatory-networks/main?urlpath=rstudio)

## Authors:

- [Julieth Andrea López Castiblanco](https://github.com/JuliethLopez)
- [José Arbelo Ramos]() jose.arbelo2@upr.edu
- [Olcay Akman]()

### Collaborators:

- [Dan Hrozencik]()
- [David Jurado Blanco](https://github.com/davidjurado)
