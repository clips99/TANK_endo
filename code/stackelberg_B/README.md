# Two-region representative-household government-scope comparison

The maintained model has one representative household in each region, complete interregional risk sharing, and annual steady debt ratios 0.40/1.00. Scheme A internalizes the direct public-capital technology effect. Scheme B additionally internalizes four local private implementability constraints: labor supply, private capital accumulation, capital Euler, and investment optimality. Both models retain private general-equilibrium responses.

## Reproduction

Use MATLAB with Optimization Toolbox and Dynare 7.0 (`C:/dynare/7.0/matlab`). From the project root, run in this order:

```matlab
run('code/stackelberg_B/steady_state/solve_stackelberg_ss.m');
addpath('code/stackelberg_B/baseline');
run_stackelberg_baseline();
addpath('code/stackelberg_B/robustness/scheme_A');
run_scheme_A();
compare_scheme_A_B();
addpath('code/stackelberg_B/robustness/sensitivity_sanity');
run_ba_sensitivity_sanity();
```

The steady-state script writes full-precision freshly solved multiplier targets to the canonical B model. `prototype/local_stackelberg_ss.m` independently exposes the one-region six-equation solver's numerical diagnostics. The symmetric two-region multiplier Jacobian consists of two six-dimensional blocks and has rank 12.

Run `derivation/symbolic_check.py` with Python and the external dependency SymPy 1.14.0 for the independent Lagrangian differentiation check. Install SymPy in your Python environment using `python -m pip install sympy==1.14.0`. The check verifies 21/21 algebraic identities and the retained history-tree conditioning of the forward private-capital FOC.

## Maintained equations and interpretation

`baseline/RANK_two_region_stackelberg.mod` has 86 endogenous variables and 86 equations. `robustness/scheme_A/RANK_two_region_scheme_A.mod` has 78/78. The B addition is exactly four private-constraint multipliers and their four stationarity conditions per region. In code, `muR_j` is the unique representative-household labor-constraint multiplier, corresponding to the paper's `nu_N`; it is not a household-type weight.

The reduced leader expression is `Theta_j = muR_j * lam_j`, and labor stationarity is `M_N + muR * chi_n * varphi * N^(varphi-1) = 0`. Aggregate prices, national policy and regional household marginal-utility paths remain given to the local leader. The quoted debt rate remains taken as given when choosing debt; there is no competitive zero-profit interpretation of the quotation rule. The government problem retains the prior timeless-commitment interpretation of lagged private Euler/investment multipliers. Private capital chosen today uses the forward conditional-expectation FOC.

Steady consumption follows the resource constraint. The representative labor condition calibrates `chi_n`. Central transfers follow each local government's budget without household-type transfers. Neither the cross-region asset-market structure nor any other structural parameter was changed to make responses resemble previous results.

## Current verified results

The numerical batch was executed on 2026-09-25 and its 18 generated model hashes were reverified on 2026-09-27.

| Model | Variables/equations | Max static residual | Static rank | Unstable/forward roots | BK |
|---|---:|---:|---:|---:|---|
| A | 78/78 | 4.44e-16 | 78 | 24/24 | PASS |
| B | 86/86 | 3.20e-14 | 86 | 32/32 | PASS |

Both pass `model_diagnostics`, IRF integrity and their steady-state shadow-price checks. The monetary shock standard deviation is 0.0025, approximation order is one, and the IRF horizon is 40 quarters. The nine sensitivity scenarios yield 18/18 passing structural runs and 9/9 comparable pairs. The largest registered effective B-minus-A ratio is 0.0206337954982484, for `chiIG_low / ig / low_debt`; all cumulative signs and regional orderings are preserved. The registered 5% screen continues to support Scheme A as the main-text specification.

Common steady allocations: `Y=1`, `IG=0.12`, `KG=4.8`, `C=0.512913669064749`, `N=0.108259193121186`. Debt is `B1=1.6`, `B2=4`; residual transfers are `Z1=0.156161616161616`, `Z2=0.180404040404041`. B multipliers per region are `LambdaG=QG=4.36893203883495`, `muR=-0.167717916947058`, `muK=0`, `muQ=-94.3689320388348`, `muI=-2.35922330097087`.

Authoritative evidence:

- `validation/` and `robustness/scheme_A/validation/`: equation counts, residuals, static Jacobian, eigenvalues, BK, diagnostics, and captured Dynare output.
- `baseline/baseline_status.csv`: prespecified direction checks for the debt-service/fiscal-space/public-investment/public-capital/output sequence.
- `robustness/scheme_A/scheme_AB_decomposition_summary.csv`: normalized cumulative comparisons and descriptive peaks.
- `robustness/sensitivity_sanity/sensitivity_run_manifest.csv`: all 18 actual run IDs, source hashes and validation results.
- `robustness/sensitivity_sanity/sensitivity_acceptance.csv`: all completeness, comparability, direction and materiality gates.

`run_ba_sensitivity_sanity` directly calls `plot_stackelberg_irf_compare` after writing all numerical results. This is the sole appendix C.2 figure function. It reads the frozen baseline A/B MAT results, normalizes each region by its own steady state, and plots the high-minus-low gaps for public investment, public capital and production GDP in one row. It cross-checks the existing IRF and cumulative-result CSVs without changing them. The paper includes `figure_AB_irf_compare.pdf`; vector PDF and 600 dpi PNG come from one figure handle. The former four-parameter sensitivity figure is retired, while all numerical sensitivity results and Table 4 remain available. Whole-project accounting and model validation are performed by `code/validate_all_models.m`.

All runners resolve inputs and outputs from their own file locations. The Dynare runners temporarily use the model directory for generated packages and restore the caller's working directory on success or failure. No particular launch directory is required.
