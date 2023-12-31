# calcium-from-force
This repository shows how tetanic and twitch force development in muscle can emerge from just two non-linear sets of dynamics.

Two sets of time constants are fit on experimental data of twitch and tetanus in human quadriceps. Source: https://pubmed.ncbi.nlm.nih.gov/1549641/. Each set of dynamics has two time constants: one for the rising phase, one for the decaying phase, for a total of 4 time constants. 

_fminsearch_ is used to find values for the 4 time constants that yield a minimal sum of squared errors (SSE) between model twitch and tetanus force and experimental twitch and tetanus force. Because the obtained values appear to depend on initial guess, the SSE-minimization was repeated for relatively large number of initial guesses (default: 100, see Fig. 1). The combination of time constants that yields the lowest SSE was then used in simulation (see Fig. 2).

## Figure 1: SSE (model vs. data) for 100 different initial guesses 
![picture](Fig1.jpg)

## Figure 2: Twitch and tetanus (model vs. data) for optimal time constants (minimal SSE)
![picture](Fig2.jpg)

## Conclusion
It appears that in order to predict twitch and tetanus forces, the first set of dynamics requires a fast rise and a slow decay while the second set of dynamics requires a slow rise and a fast decay. This in line with what we believe should be true for two sets of physiological dynamics in muscle:
- Calcium activation (fast rise, slow decay)
- Force facilitation (slow rise, fast decay)
