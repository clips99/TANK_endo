# 两地区 RANK 新凯恩斯 DSGE

每个地区一个代表性家庭，两地完全风险分担。正文低/高债务地区年化债务率为 **0.40/1.00**，季度债务本金与生产 GDP 比为 **1.60/4.00**。基准采用地方政府直接技术效应方案 A；Stackelberg 方案 B 扩大政府对本地私人部门最优响应的决策范围。

`code/` 是唯一正式代码和数值输出来源。`RANK_DSGE_endo.tex` 是完整、连续的单文件论文，正文、公式、表格、数值和附录直接写在其中；论文编译不需要预先生成 LaTeX 片段。

## 完整复现

环境：Windows、MATLAB R2026a、Dynare 7.0（默认位置 `C:/dynare/7.0/matlab`）和 XeLaTeX。

在 MATLAB 中执行：

```matlab
addpath('C:/Users/Chow/Desktop/codex/RANK_endo/code');
run_rank_all;
```

总入口运行各正式实验和 A/B 敏感性分析，并验证稳态、Jacobian 秩、BK 条件、有限实值路径、账户一致性及 OccBin 实际绑定状态。各实验运行脚本在求解、保存 CSV/MAT 结果后，直接调用对应的唯一正式绘图函数。路径根据脚本自身位置确定，可从 MATLAB Editor 或其他工作目录运行。

在项目根目录执行两遍：

```text
xelatex -interaction=nonstopmode -halt-on-error RANK_DSGE_endo.tex
```

论文中的数值来自已验证的 CSV/MAT 结果，直接保存在主 TeX 中。将来如有明确的模型或校准变更，应依据新结果同步更新正文和表格。

## 单独运行实验与正式图形

| 论文 Figure | 运行脚本（位于 `code/`） | 唯一绘图函数（位于同一实验目录） |
|---|---|---|
| 1 | `baseline/run_baseline.m` | `plot_baseline.m` |
| 2 | `debt_intensity/run_debt_intensity_experiment.m` | `plot_debt_intensity.m` |
| 3 | `scale_development/run_scale_development_experiment.m` | `plot_scale_development.m` |
| 4、11 | `demand_monetary/run_monetary_hawkishness_experiment.m` | `plot_demand_monetary.m` |
| 5 | `extension_scenarios/run_demand_regional_balance.m` | `plot_demand_regional_balance.m` |
| 6、7、9、10、13 | `policy_counterfactual/run_policy_counterfactual_experiment.m` | `plot_policy_counterfactual.m` |
| 8 | `stackelberg_B/robustness/sensitivity_sanity/run_ba_sensitivity_sanity.m` | `plot_stackelberg_irf_compare.m` |
| 12 | `extension_scenarios/run_extension_scenarios.m` | `plot_extension_scenarios.m` |

例如，单独运行基准：

```matlab
run('C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/run_baseline.m');
```

该脚本直接生成：

- `code/baseline/baseline_irf_comparison.pdf`
- `code/baseline/baseline_irf_comparison.png`

论文 `fig:baseline` 直接引用上述 PDF。所有 Figure 1–13 均使用对应实验生成的正式 PDF；Figure 6 由上下两个正式 PDF 组成，因此共计 14 对 PDF/PNG。每一对均从同一 MATLAB figure handle 导出，采用固定物理尺寸、矢量 PDF 和 600 dpi PNG。图号由 LaTeX 自动生成，原有图的文件名保持不变。

`code/plot_paper_figures.m` 仅用于批量调用表中相同的绘图函数，不含另一套图形实现。日常完整复现只需运行 `run_rank_all`，单独运行实验也会生成该实验的正式图。

## 需求冲击下的地区平衡规则配置实验（正文 Figure 5）

在 MATLAB 中将 `code/extension_scenarios` 加入路径后运行
`run_demand_regional_balance`；仅重画新实验图时运行
`plot_demand_regional_balance`。该独立入口位于现有扩展模块，复用 Dynare、
`audit_rank_solution` 和共享图形导出工具，不重跑或覆盖其他实验图。
输入是现有 `demand_monetary/negative_demand_baseline_policy.mod` 及其 MAT 结果。
原有参数保持不变，仅增加 `phi_reg={0,0.5,1,1.5,2}`；非线性地区 GDP 比值项
位于 Taylor rule 的 `(1-rho_r)` 平滑目标内，与既有地区平衡规则一致。

新实验文件均位于 `code/extension_scenarios`，使用 `demand_regional_balance_`
前缀：`moments.csv` 保存六个无条件矩，`irf_series.csv` 保存 40 季度负需求创新
响应，`status.csv` 和 `baseline_check.csv` 保存数值检查，`configuration.pdf/.png`
是唯一正式三面板图，分别展示配置权衡、债务服务差和公共投资差。原分离式
`tradeoff`、`mechanism` 图已停止生成并移除；机制 CSV 仍保留。各情景另保留生成的 MOD 和 Dynare MAT。
所有标准差列乘以 100；相关系数不缩放。`Y1/Y2/Y` 对应生产 GDP
`xloc1/xloc2/xagg`，`Pi/R` 对应 `pinfagg/r`，DS 沿用净实际债务服务负担口径，
IG 为公共投资。IRF 是模型变量的水平偏离，未乘以 100；正的 `ed` 经
`d=rho_d*d(-1)-ed` 产生负需求创新。KG 沿用 Dynare 的期末存量时点。
本实验只计算一阶矩和 IRF，不计算 CEV 或二阶福利。主 TeX 直接引用正式
`demand_regional_balance_configuration.pdf`；总 runner 和绘图 dispatcher 均调用同一实验入口。

## 原有论文数值结果与验证

- 全部模型逐项状态：`code/model_validation_status.csv`。
- 统一验证入口：`code/validate_all_models.m`。
- OccBin 实际路径检查：`code/policy_counterfactual/occbin_path_checks.csv`、`occbin_regime_history.csv`。
- 谷值比、转移改善比例等派生量：`code/summarize_rank_results.m` 生成 `code/numerical_summary.csv`。
- 基准稳态和参数：`code/baseline/baseline_steady_state.csv`、`baseline_parameters.csv`。
- 基准完整响应：`code/baseline/baseline_full_irf.csv`。
- 各实验的 `*_irf_series.csv`、`*_summary.csv`、`*_status.csv` 和 Dynare MAT 文件保存在对应实验目录。
- 需求冲击无条件矩与条件 CEV：`code/demand_monetary/negative_demand_policy_tradeoff_metrics.csv`、`negative_demand_policy_welfare_metrics.csv`。

基准系统为 78 个变量、78 条方程，24 个不稳定根对应 24 个前瞻变量；Stackelberg 系统为 86/86、32/32。原有 49 个模型的验证结果保留；新增 5 个地区平衡需求情景的结果见 `extension_scenarios/demand_regional_balance_status.csv`。完整复现入口的验证范围为 54 个模型。债务余额限额的实际绑定期由 OccBin 分段解确认，基准实验仅在第 2 季度绑定。

## 解释边界

平滑模型采用一阶扰动，OccBin 采用分段一阶解。稳态残差、一阶动态账户残差以及非线性方程代入近似路径的余项应分别解释。公共资本图使用 Dynare 期末存量，对应正文下一期资本。

地区与全国 CEV 是一次需求创新后的 40 期条件配置比较，不是完整二阶无条件福利。家庭合并净支出可由账户反推；模型没有单独指定中央/共同基金收入和资产的地区分配，因而不能把合并余项解释为唯一识别的独立地区税费或完整中央融资成本。
