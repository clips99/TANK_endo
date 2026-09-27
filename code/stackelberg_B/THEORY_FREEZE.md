# Current government-scope specification decision

The main-text model is the two-region representative-household Scheme A. Scheme B remains a local-government decision-scope extension. Each region has its own representative household; complete interregional risk sharing is retained.

| Role | Model | Variables/equations |
|---|---|---:|
| Main text | `../baseline/RANK_two_region_baseline.mod` | 78/78 |
| Canonical A comparison | `robustness/scheme_A/RANK_two_region_scheme_A.mod` | 78/78 |
| Local-government extension B | `baseline/RANK_two_region_stackelberg.mod` | 86/86 |

All three use annual steady debt ratios 0.40/1.00. The canonical A and B comparison holds shared preferences, technology, pricing, monetary/fiscal parameters, non-shadow steady allocations, shock variance, perturbation order and horizon fixed. The substantive difference is whether local leaders internalize labor supply, private accumulation, private capital Euler and private investment optimality constraints. Household-type constraints and their multipliers are absent.

The leader treats aggregate prices, national policy, household marginal utility, and the quoted local debt rate as given. Four private-constraint multipliers per region add eight equations and variables in B. Private capital stationarity retains the forward conditional expectation required by predetermined capital. This is an open-loop, timeless-commitment local leader problem rather than a national Ramsey allocation.

The preregistered one-at-a-time design is unchanged: baseline, gamma_g in {0.05,0.15}, phi_i in {1.25,5}, chi_ig in {10,40}, and alpha in {0.40,0.50}; all non-varied parameters retain baseline values. The outcome window is quarters 1–12 and the full-path check covers 1–40. A cancellation guard switches away from unstable cumulative denominators. A 5% threshold screens economic materiality, not statistical significance; failed models or sign/order reversals would prevent freezing the decision.

Actual RANK batch `20260925_162512_557` passes all 18 structural runs, all nine comparison pairs, and all 81 registered summaries. Generated source hashes were reverified on 2026-09-27. A has static rank 78 and 24 unstable roots for 24 forward-looking variables; B has static rank 86 and 32 unstable roots for 32 forward-looking variables. Both pass Dynare order/rank conditions and diagnostics. Maximum residual across the sensitivity runs is 1.17239551400417e-13.

The maximum registered effective B-minus-A ratio is **2.06337954982484%**, occurring at `chiIG_low / ig / low_debt`. Cumulative signs and high-minus-low ordering are preserved. The maintained decision remains `FREEZE_A_AS_MAIN_BASELINE`. Baseline B slightly amplifies the cumulative regional investment, public-capital and output gaps; the exact new values are in `scheme_AB_decomposition_summary.csv`. This comparison identifies the increment from internalizing private responses; Scheme A already includes those responses in general equilibrium.

The symbolic check independently differentiates the reduced Lagrangian and passes 21/21 identities. The six multiplier steady-state equations per region are re-solved. See `README.md` for reproduction commands and the model-local validation CSVs for the numerical evidence. No unresolved numerical or algebraic failure remains in this module. `code/validate_all_models.m` performs the full-project accounting and structural checks.
