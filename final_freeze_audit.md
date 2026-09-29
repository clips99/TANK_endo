# RANK_endo 最终理论冻结审计（final freeze audit）

审计日期：2026-09-28。冻结对象：当前 `RANK_DSGE_endo.tex`、`theory_code_consistency_audit.md` 和当前正式 `code/`。本轮只新增本报告；未修复任何问题，未修改正式论文、模型、MATLAB 程序、参数、CSV、MAT、图件或既有编译产物。所有临时解析脚本、证据及本轮 XeLaTeX 输出位于 `C:/Windows/TEMP/rank_final_freeze_20260928/`。

## 1. Executive conclusion

**最终判定：PASS；BLOCKER = 0；MINOR = 4。** 四项 MINOR 为一项可选的状态价格核公式展示和三处段落排版警告，完整清单见第 13 节。没有发现核心理论、时点、价格单位、账户闭合、论文—代码或论文—当前数值结果的冲突。

认证限于论文现在明确声明的模型：核心逐期方程、局部确定性稳态及其随机一阶/OccBin 实施、预先承诺且对家庭不可操纵的一次性状态结算、相容的初始保险财富，以及直接施加的资产特定缩约需求楔子。**不将这个结论扩大为 ζ 已完成深层微观结构识别、金融分配唯一识别、任意固定税费/初始财富都可实施、全球最优性，或完整福利与最优政策结论。**

本轮重新读取当前 TeX 和全部 54 份 `.mod`，逐式审查代数、价格换算、条件期望及 Dynare 时点，并重新构造稳态和金融账户存在性证明。旧报告只提供待复核线索与版本记录；没有运行已有 validation，也没有用“方程数等于变量数”、旧 PASS 标志或模型能运行代替理论检查。

与上一份理论审计的区别：其 78/86 核心等式一致结论保持；家庭实施、ζ 的认证边界、OccBin KKT 和 timeless 初始边界的展示缺口已经补齐；三项旧倍率已经纠正。这是重新检查当前文件后的结论变化，不是沿用上轮修复的自我声明。

## 2. Core 78/86 equation consistency result

| 系统 | 内生变量 | 各状态逐期方程 | 当前核验结果 |
|---|---:|---:|---|
| 基准 A | 78 | 78 | 78 条全部唯一对应；PASS |
| Stackelberg B | 86 | 86 | 86 条全部唯一对应；PASS |
| 严格债务限额 OccBin | 79 | 79 | 两个 regime 各 79 条；PASS |

正式基准为 `code/baseline/RANK_two_region_baseline.mod`；B 为 `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod`；OccBin 为 `code/policy_counterfactual/policy_cf_strict_debt_cap.mod`。**附录 F1 给出重新定位的 A01–A78、B01–B86 完整逐方程 mapping**：当前 TeX label/行、经济来源、独立核验式、当前 `.mod`/行、结论。通用地区式分别展开为两行，未把一条代码等式重复计数。

54 份模型包括 36 份同结构 A、7 份只改变地区平衡 Taylor 项的 A、10 份 B、1 份 OccBin。A 的 10 个局部 `#` 表达式、B 的 32 个局部表达式均核对；标签、空白差异不当作经济差异。A/B 共用 76 条等式，B 替换两地区 KG Euler，增加每地区 K/N/q/I 四条驻点条件。OccBin 源文本有 80 条候选等式，其中两条互斥，所以每个实际 regime 是 79 条。

| 模块 | 独立核验要点 | 判定 |
|---|---|---|
| 家庭 | 边际效用、风险分担价格方向、带楔子消费条件、劳动、K 积累、资本 Euler、投资当前与未来边际项 | PASS |
| CES | 支出最小化需求、零利润指数；需求代回即得到 CES 技术式，后者不额外增加动态约束 | PASS |
| 四个相对价格 | 三动态与交叉恒等式；第四动态冗余，初始交叉恒等式相容 | PASS |
| 中间品 | 生产中的 V 分母、工资/租金中的 Q 与 V、GDP 为 QYM、利润与要素收入恰加总为 GDP | PASS |
| Calvo | P1/P2 未来通胀幂分别为 ε、ε−1；Λ 已包含在递归定义内；重置价、指数和离散度一致 | PASS |
| 地方政府 | 当前/未来公共投资成本导数、债务成本导数、KG 收益、取价债务 Euler、预算与积累 | PASS |
| 报价与拨付 | 债务比年化因子抵消；不把总体报价斜率加入单个取价政府 FOC；Z 使用当前 DS 与滞后 B/Y | PASS |
| 全国与政策 | 相对价格换算方向、GDP/吸收/通胀、标准及地区平衡 Taylor、MP 和 ζ 过程 | PASS |
| Stackelberg | 四约束、四乘子、五组驻点式及所有历史/未来项 | PASS |

### 稳态及 timing 的重新计算

从零通胀、零楔子、零稳态调整成本及校准值独立计算：

\[
R=1/\beta,\quad MC=(\epsilon_p-1)/\epsilon_p,\quad R_K=1/\beta-(1-\delta_K),\quad
K/Y=\alpha MC/R_K,
\]
\[
I=\delta_KK,\quad KG=IG/\delta_G,\quad C=D-I-G-IG,\quad
N=[Y_M/(A KG^{\gamma_G}K^\alpha)]^{1/(1-\alpha)},\quad
\chi_N=C^{-\sigma}W/N^\varphi.
\]

政府 A 乘子由 IG 与 KG 两条件联合求得；Z 由地方预算求得。B 的 timeless 条件在 x=1 下先给 νK=0、νI=δKνQ，再用 S-KG/S-K/S-N 的三条线性条件求 ΛG、νN、νQ。没有将 MATLAB 稳态程序或旧审计数值作为新计算的答案。

| 变量 | 本轮独立值 | 对照 |
|---|---:|---|
| R | 1.010101010101010 | 附录 B、`.mod`、原 MAT 一致 |
| MC | 0.833333333333333 | 同上 |
| RK | 0.035101010101010 | 同上 |
| K/Y | 10.683453237410045 | 同上 |
| I | 0.267086330935251 | 同上 |
| KG | 4.800000000000000 | 同上 |
| C | 0.512913669064749 | 同上 |
| N | 0.108259193121186 | 同上 |
| χN | 48.90978102504051 | 同上 |
| B1 / B2 | 1.600000000 / 4.000000000 | 年化目标 0.40 / 1.00 |
| DS1 / DS2 | 0.016161616161616 / 0.040404040404041 | 与 GDP 归一化一致 |
| Z1 / Z2 | 0.156161616161616 / 0.180404040404041 | 附录及代码一致 |
| A 的 ΛG=qG | 0.623111782477340 | 分母 0.033100000000000 |
| 中央余额 | −0.048282828282828 | 共同价格单位 |
| B 的 ΛG=qG | 4.368932038834934 | timeless 稳态 |
| B 的 νN / νK | −0.167717916947058 / 0 | 对应 muR / muK |
| B 的 νQ / νI | −94.36893203883436 / −2.359223300970859 | 历史乘子非零 |

将独立构造的全部 78/86 变量代入当前原始 `.mod` 方程，A/B 最大绝对残差均为 1.78×10⁻¹⁴；与各自 `.mod steady_state_model` 及原 MAT 的最大差分别为 1.25×10⁻¹⁴、4.13×10⁻¹³；A 与 CSV 最大差为 5.51×10⁻¹⁴。差异为浮点运算/序列化尺度，未发现稳态改变。当前 MATLAB 稳态检查文件与这些解析关系一致，但本轮没有执行它。

| 论文变量 | 决策/信息时点 | Dynare 对应 |
|---|---|---|
| K_t、KG_t | 期初既定存量 | 54 份模型都声明 k1,k2,kg1,kg2 为 predetermined |
| K_{t+1}、KG_{t+1} | 本期选择、下期投产 | 源码 k(+1)、kg(+1)；原 IRF 输出为本期形成的期末资本 |
| B_{t−1}、RB_{t−1} | 旧本金与既定合同 | b(-1)、rb(-1) |
| Π_t | 本期实现的价格平减 | pinf 当期 |
| B_t、RB_t | 本期期末融资及下期偿付合同 | b、rb 当期；债务 Euler 使用 pinf(+1) |
| I_t/I_{t−1}、IG_t/IG_{t−1} | 当期选择除以既有投资 | inv/inv(-1)、ig/ig(-1) |
| νQ,t−1、νI,t−1 | 继承的承诺历史 | muQ(-1)、muI(-1)，稳态偏差零不等于水平零 |

所有含未来随机支付的等式均按时点 t 的条件期望解释；本期已知系数移出期望不改变方程。TVC 的资本项用当期决定的下一期存量；认证不等于证明任意非线性大冲击路径的全球终端性质。

## 3. Household financial implementation verdict

**PASS，条件性可实施；没有新增非冗余配置约束。** 当前定位：TeX L105–136（预算、支付、定价、初始财富、市场边界），L472（中央结算），L499–506（合并账户），L1150–1156、L1524、L1677–1680（识别边界和冗余说明）。

收入明确包括 WN、RK·K、企业利润 ΩM，以及金融/状态依赖净结算。消费、私人投资和这些实物收入均以本地最终品计价，统一乘 p_j=P_j/P 转为共同价格单位。预算为

\[
p_j(C_j+I_j)+\mathcal A_j=p_j(W_jN_j+RK_jK_j+\Omega_{M,j}-\mathcal T_j)+a_j.
\]

正 T 是家庭净支付。政策/中介净现金流并入 T，保险购买与兑现则由 A 与 a 单列；没有既计入 T 又计入 a 的同一项。文本明确涵盖新融资、本金兑付等完整净金融流量，不仅是利差。

**资产时点。** L107 的 a_t 是本期到期净支付，A_t 是本期买入期末组合的当期市值，A_t=E_t[M^C_{t,t+1}a_{t+1}]。令 h_t=p_t(C_t+I_t−Y_t+T_t)，收入恒等式 WN+RK K+ΩM=Y 将预算化为 a_t=h_t+A_t。因此有限期迭代精确给出

\[
a_0=E_0\sum_{t=0}^{T}\mathcal M^C_{0,t}h_t
 +E_0[\mathcal M^C_{0,T}\mathcal A_T].
\]

当前 TVC 正是最后一项趋零，得到 L122–123 的初始财富 PV 公式。E[M_{0,T}A_T]=E[M_{0,T+1}a_{T+1}]，没有少一期间的贴现。逐状态 Σs a=0 推出组合市值 Σs A=0，而不是反过来只用市值清算推断逐状态清算。

**风险分担。** 由 Λ2=ξ12Λ1(P2/P1) 可得 Λ2/p2=ξ12Λ1/p1。于是存在共同正保险核

\[
\mathcal M^C_{t,t+1}
=\beta\frac{\Lambda^j_{t+1}/p^j_{t+1}}{\Lambda^j_t/p^j_t}.
\]

这个等式是本次审计的构造性证明，不是增添到正式论文或 Dynare 的条件。它对两地区相同；再把未来本地收入转回共同单位，恰好恢复资本与企业使用的 βΛ'/Λ 核。故本地资本与风险分担可同时存在，不要求两地实物资本、租金或 qK 相等。L107 未显式写出这个等式仅记为 M01 展示项。

**资源及金融对手账的独立证明。** CES 零利润和中间品市场清算给

\[
\sum_js_jP_jD_j=\sum_js_jP_{M,j}Y_{M,j}=\sum_js_jP_jY_j,
\quad\text{即全国 }D=Y.
\]

记 F_j=G_j+IG_j+ΦI_j+ΦB_j，J_j=RB_{j,t−1}B_{j,t−1}/Π_j。地方预算是 F_j=τL Y_j+Z_j+B_j−J_j；中央余额是 S^C=Σs p(θTτY Y_j−Z_j)。所以

\[
\sum s p F=\tau_Y Y-S^C+\sum s p(B-J),
\]
\[
\sum s p(C+I)=(1-\tau_Y)Y+S^C+\sum s p(J-B),
\]

恰好是当前 TeX L501–503。中央—地方的 Z 在合并时抵消；新债是私人资金用途，旧债偿付是私人现金流入；中介内部融资负债在私人部门合并中抵消；保险购买与到期支付各自全国零和。ΦI、ΦB 是已有公共实物资源成本，计入 F 一次；私人安装损失已由同一 I 形成较少资本，不再另加资源需求。没有遗漏对手方向、重复最终品需求或反向价格换算。

**冗余不是假定。** 对任一已有核心配置，在家庭优化前可选择一个逐历史预承诺支付表，其均衡取值为 T_j=Y_j−C_j−I_j，并取 a_j=A_j=0。此处右侧是承诺的历史值，不能随单个家庭偏离而重新计算。该构造同时满足逐期预算、清算、TVC、初始财富相容和全国财政总量；也可以在 T 与零和保险支付间重新分配，并选择相应初始净头寸。论文 L105、L126、L1677 明确采取这类外生结算及相容财富约定，未同时任意固定 T 和 a0。因此新增预算解释既有配置的金融实施，而不再限制核心 78/86 配置解。若未来另外固定不相容税费表或保险头寸，则 PV 预算可能成为额外约束，那不属于当前模型。

## 4. zeta verdict

**PASS，认证其缩约定位和文本一致性，不认证未给出的深层金融结构。** 全文扫描 ζ、需求/偏好冲击、无风险、完备市场、流动性、金融摩擦、便利收益和 Euler 楔子；关键文字在 L128、L136、L846、L1492、L1680。

- ζ 明确是 asset-specific reduced-form financial/intertemporal-demand wedge，直接作用于 policy-rate-related 无风险消费条件。
- 原 Euler 保持 Λ=βE[Λ'R/Π']exp(−ζ)，没有从标准无摩擦完备市场预算中声称推出它。
- ζ 不是一般时间偏好冲击；按设定不直接进入资本 Euler、风险分担或 Calvo 基本核。
- 具体中介、流动性服务和交易摩擦结构不作结构识别。
- L128 与 L1492 明确不赋予内部保险合约对政策相关流动资产的无约束转换和复制权。

反证边界也重新核对：基本名义核下带楔子式意味着 E[M^N R]=exp(ζ)。如果另行假定 R 是可在同一无摩擦证券市场以价格 1 自由复制的普通债券，则会与 E[M^N R]=1 冲突；**当前论文已经排除该额外交易假设**，未在其他位置重新引入它。资产市场配置安排与这个缩约政策条件并存，不等于已经建立一个完整中介优化模型。

## 5. OccBin verdict

**PASS。** TeX L753、L758、L762–774 对应 `policy_cf_strict_debt_cap.mod` L294–302、L329–331：

\[
B_t^2\leq B^2_{\max}=1.002\bar B^2=4.008,
\]
\[
\Lambda^2_{G,t}[1-\varphi_B(B_t^2/\bar Y^2-\bar b^2)]
=\beta_G E_t[\Lambda^2_{G,t+1}R^2_{B,t}/\Pi^2_{t+1}]+\xi_t,
\]
\[
\xi_t\geq0,\quad B^2_{\max}-B_t^2\geq0,\quad
\xi_t(B^2_{\max}-B_t^2)=0.
\]

最大化问题加 ξ(cap−B)，导数中是 −ξ，移项后位于债务 KKT 右侧正号。slack 加 ξ=0；binding 加 B=cap；含 ξ 的同一债务 KKT 在两状态都保留，binding 没有额外强制无约束债务 Euler。约束对象是实际余额 b2，不是年化债务率 dann2。切换阈值 1e−6、−1e−8 属数值容差，不是不同经济上限。

直接读取原 MAT 的 `oo_.occbin.simul.regime_history`：regime=[0,1,0]、regimestart=[1,2,3]。40×79 的 piecewise 原路径只在 Q2 绑定；Q1/Q2/Q3 的 B2 为 4.00474051850073 / 4.008 / 4.00458542484918，Q2 ξ=0.49013727294276155。与 CSV 的 B/ξ 最大差 5.33×10⁻¹⁵；最小 slack=0，最小 ξ=−3.07×10⁻¹⁷，max|ξ(cap−B)|=5.29×10⁻¹⁸。浮点尺度的负乘子不构成经济互补违背。

## 6. Stackelberg timeless verdict

**PASS。** L333、L1207、L1217–1229 恰为四项私人可实施性约束：劳动供给、私人资本积累、资本 Euler、私人投资 FOC；对应 νN/νK/νQ/νI（代码 muR/muK/muQ/muI）。Λ 路径由统一资产市场/家庭均衡决定并为单个领导者给定，没有第五项消费 Euler 约束或对应乘子。

S-KG、S-K、S-N、S-q、S-I 的当前位置是 L1264–1337。重新对历史节点拉格朗日函数求导，未来 KG/K 的收益取 E_t；劳动和 q 的历史项带 β/βG；投资条件保留当前/下期资本积累、当前/历史/下期投资 FOC 对 I 的所有导数。附录 F2 保留逐项导数来源；没有只比较 FOC 字符串。

新增边界 L1245–1254 为

\[
H_0=-\frac{\beta}{\beta_G}m_0
\{\nu_{Q,-1}[RK_0+(1-\delta_K)q_{K,0}]
+\nu_{I,-1}q_{K,0}B_I(x_0)\}.
\]

对 N0、qK0、I0 求导，分别恢复原 S-N 的历史租金项、S-q 的两项历史项、S-I 的历史 B'_I/I−1 项。K0、KG0、I−1 为继承初值，其余省略项不涉及当期自由选择。故该边界没有增加逐期约束，也没有改变原五组 FOC。

归档 `stoch_simul` 围绕非零承诺乘子稳态计算；历史“偏差为零”意味着水平等于稳态值，不意味着 νQ,−1=νI,−1=0。当前文本明确采用 timeless-commitment IRF，区别于 t=0 首次宣布承诺后、需另设历史承诺条件的转轨。二者未被混同。

## 7. DS/FS verdict

**PASS。** L266 给清楚的债务计价及合同时间；L411–432 给 DS/FS 定义、分解及用途；L527 给动态说明。代码 ds 是**率**：

\[
DS_t=\frac{(RB_{t-1}/\Pi_t-1)B_{t-1}}{Y_t}.
\]

其分子是净实际债务服务额，可分为 [(RB−1)/Π]B− 与 (1/Π−1)B−，分别为实际票息与相对上期实际本金的重估；不能仅称普通利息。本稿没有作这种误称。

地方预算严格推出 IG+ΦI+ΦB=FS+(B−B−)。FS 因而是**维持上期实际债务本金余额 B_t=B_{t−1} 的计量口径下**，当期用于公共投资及相关成本的可用财政资源。文本明确区别固定名义本金，并不施加 B_t=B_{t−1} 的动态限制，也不把它称为完整跨期财政空间。

全文没有含糊的“本金滚动”“固定本金”或 rollover。现有“滚动融资/续作”是债务融资的描述，受到 L266 和 L427 的时点/实值口径限定，不是固定名义本金假设。

## 8. Stale-text scan

| 搜索对象 | 当前全文结果 | 判断 |
|---|---|---|
| TANK/HANK、两类家庭、HtM | 两类家庭见 L75 文献背景；当前结构一直为每地区一个代表性家庭 | 无错误残留 |
| λ 作为家庭类型份额 | 无；Λ、ΛG 是不同乘子，其他希腊系数有定义 | 无错误残留 |
| 0.35、35%、错误基准债务率 | 无；基准 0.40/1.00；实验变化明确标注 | 无错误残留 |
| 三倍、接近三倍、约三倍 | 零命中 | 已纠正 |
| Stackelberg 消费第五约束 | 无；L128/136/1492 的“跨期消费条件”属于家庭讨论 | 已纠正 |
| CEV、welfare ranking、optimal φreg | L737 等为明确“不计算/不识别/不作完整排序”的边界 | 非错误肯定性结论 |
| Reff、R_eff、旧政府敏感性指标 | 无错误残留 | PASS |
| 旧图表编号/失效引用 | 引用全部解析到现有标签；图6双 label 指向同一组合图，不是遗留图 | PASS |

正文与附录对中央融资、税费/头寸非唯一性和配置比较边界保持一致。没有将一个局部缓冲结果写成完整福利或最优政策结论。

## 9. Numerical-text consistency

**PASS；没有数字—归档结果冲突。** 使用当前全期 CSV 与原始 MAT 只读交叉核对，未生成 IRF 或图。基准 52 个 CSV 响应字段与 MAT `oo_.irfs` 最大差 9.95×10⁻¹⁷；全部五个地区平衡政策点的矩与原 MAT 协方差直接计算最大差 2.00×10⁻¹⁵。详情见附录 F3。

| 当前文字位置 | 重新计算的关键结果 | 判定 |
|---|---|---|
| L616、L629 基准 | DS 2.562830367054；FS 2.516635588977；IG 2.480323820360；正文 2.56/2.52/2.48 | PASS |
| L635–644 债务强度 | 对称情景地区差最大 2.04e−14；非对称 DS/IG/KG 峰谷为 Q2/Q8/Q22，幅度随债务强度增加 | PASS |
| L648、L1167–1200 规模发展 | r=1,1.5,2；s1=.5,.5505102572,.5857864376；单位 GDP 比为 1,√1.5,√2；双边进口=.075；表中响应按自身稳态标准化 | PASS |
| L667–704 Figure 4 | 30 个真实节点；各六节点线全国通胀波动下降、地区差波动上升；五个表格节点均正确舍入，通胀降幅53.0533%→53.1% | PASS |
| L722、L735、L739 地区平衡 | φreg 0→2：地区差−33.9875%、通胀+63.1762%、GDP+22.6472%、DS差+21.1738%、IG差−32.7537%；相关性 .951657645→.988789902 | PASS |
| 同上 0→.5 | 地区差−12.1631%、通胀+18.1098%、GDP+6.80948%；φreg=0 与原标准需求基准 steady/var/全部 IRF 逐位相同 | PASS |
| L774、L813 债务限额 | 仅 Q2 实际绑定；政策差 IG/Y 谷 Q2、KG 谷 Q7；首次转正 Q9/Q7/Q20 | PASS |
| L784、L830 转移反馈 | Z增量峰=.001198528565181，Q3；IG/KG谷值幅度改善21.7849%/21.9335%；Q40 KG=−.01147815785 | PASS |
| L661、L1344–1363 A/B | 前12期累计地区差的 B−A：IG −.000436140188、KG −.000075571606、GDP −.000013730714 | PASS |
| L1421–1464 扩展 | 六个原 MAT 的40期响应支持当前方向限定；联合风险+转移下GDP地区差40期均正，IG仅前中期为正；弱联系存在路径交叉，文字未声称全期单调 | PASS |
| L1483 货币区域规则 | GDP差L2 .002067534272→.001267813272；最大GDP差 .000547427696→.000334543470；全国通胀L2 .002060719687→.003473781321 | PASS |

合理舍入并非矛盾：L629 “约第22季度”对应低地区 KG 谷 Q23、高地区 Q22；规模表的 .8125/.8875 三位小数显示；这类近似没有被误写为未经舍入的精确值。敏感性 81 项比较另由原序列重算，符号/高低排序保持，最大有效比约 .0206337955，未依赖旧分类 PASS 字段。

## 10. Symbol/unit audit

新增/修改说明中的符号及原核心相关符号逐项如下。

| 符号 | 含义与单位 | 时点/区别 | 结论 |
|---|---|---|---|
| p_t^j | P_t^j/P_t，无量纲价格换算因子 | 本地实值乘 p 后为全国共同实值 | PASS |
| a_t^j | 本期到期保险净支付，共同价格单位 | 不同于大写 A_t^j（TFP） | PASS |
| 𝒜_t^j | 期末保险组合当期市值，共同价格单位 | 不是下期支付；不同于函数 𝒜_I(x) | PASS |
| 𝓜^C_{t,t+1}、𝓜^C_{0,T} | 一期/累计共同实值状态价格密度 | 条件期望已含概率；显式边际效用式为 M01 可选展示 | PASS/MINOR |
| 𝒯_t^j | 非扭曲一次性净支付，本地最终品单位 | 正为家庭付出，优化时给定，不是自身选择的可微残差函数 | PASS |
| 𝒯_net^j | 稳态合并净支出残差 | 含保险/金融分配，不能等同唯一地区税收 | PASS |
| Z_t^j | 中央给地方转移，本地实值 | 与家庭 𝒯 不同账户，合并抵消 | PASS |
| S_t^C | 全国共同价格下中央净余额 | 正为中央收入超支出；负为缺口 | PASS |
| ΩM、附录的 P̄^j | 企业利润、本地实值 | 后者在 L1156 明确定义，非全国价格 P_t | PASS |
| Λ_t^j | 家庭消费边际效用 | 共同财富边际价值是 Λ/p，不与政府乘子混用 | PASS |
| ΛG,t^j | 政府预算影子价值 | 不是家庭 Λ | PASS |
| qK,t^j | 家庭私人资本影子价格 | 已除去家庭预算乘子；资本约束乘子为 ΛqK | PASS |
| qG,t^j | 政府资本约束影子价值 | 未按ΛG归一，稳态 qG=ΛG不等于qK=1 | PASS |
| ξ12 | 风险分担常数，无量纲 | 固定跨地区配置权重，与相容初始财富/结算关联 | PASS |
| ξ_t | OccBin 余额上限的当期价值乘子 | 时变非负，对应 xicap2；不是 ξ12 | PASS |
| H0、m0 | 继承承诺边界、Λ0/Λ−1 | 不是新增财政支出或消费Euler | PASS |
| B、RB、Π | 本地实际债务本金、总名义回报因子、总通胀 | RB·B/Π 才是偿付期本地实值，不混用名义金额 | PASS |
| s_j、υ_j | 地区测度、稳态GDP价格指数权重 | 一般不同；本例同为.5仅属基准 | PASS |

所有新增符号均在首次相关公式前后定义；没有具有不同经济含义却无法由字体、下标或时间下标区分的符号冲突。新增账户公式的全部项均为共同价格单位，核心资源式的全部项均为本地最终品单位。

## 11. LaTeX audit

使用本机 `E:/texlive/2026/bin/windows/xelatex.exe` 对当前源文件执行**顺序双遍** `-interaction=nonstopmode -halt-on-error -file-line-error`，`-output-directory` 指向本轮 TEMP 目录；两遍 exit code 均为 0，生成 61 页 PDF。未覆盖项目中的 PDF/aux/log/out/synctex，也未通过编辑器触发项目内自动编译。

| 检查 | 结果 |
|---|---|
| undefined references / citations | 0 / 0 |
| multiply-defined / duplicate equation labels | 0 / 0 |
| 缺失图件 | 0；14 个 includegraphics 路径均存在 |
| 标签及引用 | 150 个 label 唯一；全部 ref/eqref/cite 有定义 |
| 公式编号 | PDF 中连续 (1)–(139)，无断号或重复编号；正文交叉引用不计为新公式编号 |
| 图编号 | 连续1–13；图6由两个图文件组成，并有两个不同label指向同一个caption，合法且非重复定义 |
| 表编号 | 连续1–6 |
| 附录 | A–E 顺序正确；gov_derivation=A、steady_state=B、scale_development=C.1、extension_conditions=C.5、computation=E 均解析 |
| 新增公式编号 | 家庭预算(2)、初始财富(4)、合并账户(55)、KKT(61)、互补(62)、继承边界(81) |
| 重跑引用警告 / Overfull | 0 / 0 |
| Underfull | 4条警告、3个段落位置，逐项列为 M02–M04 |

原有 86 个 display-math 环境内容保持不变，新增 6 个环境；这与动态等式78/86是不同计数。静态标签检查、第二遍日志与 PDF 文字提取相互核对，不只依赖编译返回码。

## 12. Source hash/integrity result

本轮开始即对项目内除 `.git` 外全部 **2809 个文件**逐件计算 SHA-256。完成时对同一集合逐件复算：**既有文件修改0、删除0；唯一新增为本报告。** 正式图件及已有编译产物也纳入本轮全文件检查。

正式模型/程序/数据覆盖：54 `.mod`、1933 `.m`（含生成文件）、195 CSV、54 MAT，合计2236文件。全部与上一轮文字修改前 `before_hashes.json` 逐件相同。

与原理论审计 `source_hashes.json` 比较：其2183项包含TeX、54 `.mod`、1933 `.m`、195 CSV，唯一差异为预期修改的 `RANK_DSGE_endo.tex`。**更早的这份清单没有 MAT 哈希**；54 MAT 的历史一致性证据来自下一次文字修复前的快照，而非虚构一个不存在的更早记录。

与文字修复前的2245项快照比较，除 TeX 外，项目根目录的 `.aux`、`.log`、`.out`、`.pdf`、`.synctex.gz` 也在本轮开始前已有变化。因此可严格确认的是“核心源码/程序/数值均未改变，论文源只有TeX预期改变”；不能字面声称所有项目文件中唯有TeX改变。这5项是论文编译产物的历史差异，不是本轮审计造成，也不影响代码/数值认证；本轮保留其原字节。

当前论文 SHA-256：`0ef3b51062dc851cba6f17b49e89ba9d5a1eaa37cf4454805b8f249f33fae4ed`。原理论审计论文哈希为 `cdf22463906c295e0b9447150b0484d85044bdeae54538ae82570d622c305bcc`；重新比较确认旧有核心公式未变。

以下清单摘要按规范化相对路径排序，将每项写为 `路径<TAB>逐文件SHA256<LF>` 后再计算SHA-256；它不代替已完成的逐文件比较。

| 范围 | 文件数 | 哈希清单摘要 |
|---|---:|---|
| `.mod` |54|`7718c6cf6be54436d652c6411dabf655059bdf25d75012f7760d9b73431d283d`|
| `.m` |1933|`9e2797914c1fad1b0bd10311160201b2eca6226232ee28e649be8cab096d1b3a`|
| CSV |195|`a5591f7fcdd6b7b1b83b04fd0b17e7b46f20c8fae6c3d108fc0b0fe619d3db99`|
| MAT |54|`28328748e7e9afbaf3255198ebb7f8baa483b21468f2f5846b175e9433a3cad3`|
| 四类合计 |2236|`72055d7e6f8dbd68b8d4e179cd667ff2667384150c7ede44a3255058f0431e7d`|

没有运行正式 MATLAB 入口、validation、Dynare 仿真或绘图脚本。原 MAT 通过临时只读解析器读取；不执行 MAT 中的代码。一次只读 MATLAB load 的环境启动尝试失败，后续纯读取已取得所需原数据，不构成证据缺口。

## 13. Complete list of MINOR items

| ID | exact location | 问题与影响 | 是否阻止冻结 |
|---|---|---|---|
| M01 | TeX L107（关联L131） | 已定义共同保险状态价格核，但没有显式展示 β(Λ'/p')/(Λ/p)。该式可由现有风险分担关系构造，详见第3节；属于非实质符号展示，非缺少非冗余约束 | 否 |
| M02 | TeX L698–699；本轮log L1022、L1032 | 同一图注段落2条 Underfull hbox，badness10000、1163；段落间距松散，无内容缺失或Overfull | 否 |
| M03 | TeX L1147–1149；本轮log L1059 | 稳态账户说明段落 Underfull hbox，badness1264 | 否 |
| M04 | TeX L1406–1416；本轮log L1084 | 图11及相关说明附近 Underfull hbox，badness1681 | 否 |

以上均未修改。正常数值舍入已经在第9节和附录F3解释，不另视为待整改缺陷。预期论文源差异、历史编译产物差异和更早MAT快照范围在第12节如实列示，不伪装为理论错误或未发生的修改。

## 14. Complete list of BLOCKER items

**无。BLOCKER = 0。**

没有发现 paper equation != `.mod`、时点/条件期望错误、价格单位冲突、家庭金融流量不闭合、新增预算暗加配置限制、ζ 重新引入自由复制套利假设、OccBin KKT/regime 错配、timeless 边界不一致，或当前数值文字与归档结果矛盾。没有任何核心 `.mod` 需要为本轮冻结而修改。

---

## 附录 F1. 最新版逐方程 mapping 与模型文件范围

以下所有 PASS 均指上述已披露的缩约/局部实施范围；A02/B02 尤其不是“无摩擦Euler已微观推导”的认证。行号为当前源文件行号。

### F1.A

| Eq/region | Current TeX label/line | Economic origin | Independently checked form | Current code/line | Result |
|---|---|---|---|---|---|
| A01 / 1 | `a1` L1494 | 消费边际效用 | $\Lambda^1=(C^1)^{-\sigma}$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L181 | PASS |
| A02 / 1 | `a2` L1495 | 模型施加的资产特定缩约均衡楔子 | $\Lambda^1=\beta e^{-\zeta}E_t[\Lambda^1_+R/\Pi^1_+]$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L182 | PASS |
| A03 / 1 | `a5` L1498 | 效用/工资边际条件 | $\chi_N(N^j)^\varphi=\Lambda^j W^j$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L183 | PASS |
| A04 / 1 | `a10` L1499 | 安装技术 | $K^j_+=(1-\delta_K)K^j+[1-S(x^j)]I^j$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L184 | PASS |
| A05 / 1 | `a11` L1504 | 选择下一期资本 | $q_K^j=\beta E_t[m^j_+(R^j_{K,+}+(1-\delta_K)q^j_{K,+})]$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L185 | PASS |
| A06 / 1 | `a12` L1516 | 相邻两期安装边际效应 | $1=q_K^j A_I(x^j)+\beta E_t[m^j_+q^j_{K,+}B_I(x^j_+)]$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L186 | PASS |
| A07 / 2 | `a3` L1496 | 消费边际效用 | $\Lambda^2=(C^2)^{-\sigma}$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L190 | PASS |
| A08 / 2 | `a4` L1497 | 相同状态价格 | $\Lambda^2=\xi_{12}\Lambda^1Q_1^1/Q_1^2$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L191 | PASS |
| A09 / 2 | `a5` L1498 | 效用/工资边际条件 | $\chi_N(N^j)^\varphi=\Lambda^j W^j$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L192 | PASS |
| A10 / 2 | `a10` L1499 | 安装技术 | $K^j_+=(1-\delta_K)K^j+[1-S(x^j)]I^j$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L193 | PASS |
| A11 / 2 | `a11` L1504 | 选择下一期资本 | $q_K^j=\beta E_t[m^j_+(R^j_{K,+}+(1-\delta_K)q^j_{K,+})]$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L194 | PASS |
| A12 / 2 | `a12` L1516 | 相邻两期安装边际效应 | $1=q_K^j A_I(x^j)+\beta E_t[m^j_+q^j_{K,+}B_I(x^j_+)]$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L195 | PASS |
| A13 / 1 | `a13` L1529 | 成本最小化/零利润 | $1=[\omega_j(Q_j^j)^{1-\eta}+(1-\omega_j)(Q_{-j}^j)^{1-\eta}]^{1/(1-\eta)}$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L199 | PASS |
| A14 / 1 | `a14` L1530 | 本地品需求 FOC | $M_j^j=\omega_j(Q_j^j)^{-\eta}D^j$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L200 | PASS |
| A15 / 1 | `a15` L1531 | 外地品需求 FOC | $M_{-j}^j=(1-\omega_j)(Q_{-j}^j)^{-\eta}D^j$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L201 | PASS |
| A16 / 2 | `a13` L1529 | 成本最小化/零利润 | $1=[\omega_j(Q_j^j)^{1-\eta}+(1-\omega_j)(Q_{-j}^j)^{1-\eta}]^{1/(1-\eta)}$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L203 | PASS |
| A17 / 2 | `a14` L1530 | 本地品需求 FOC | $M_j^j=\omega_j(Q_j^j)^{-\eta}D^j$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L204 | PASS |
| A18 / 2 | `a15` L1531 | 外地品需求 FOC | $M_{-j}^j=(1-\omega_j)(Q_{-j}^j)^{-\eta}D^j$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L205 | PASS |
| A19 / — | `a16` L1537 | 价格定义第一条 | $Q_{1,t}^1/Q_{1,t-1}^1=\Pi_{M,t}^1/\Pi_t^1$；j=— | `code/baseline/RANK_two_region_baseline.mod` L207 | PASS |
| A20 / — | `a16` L1537 | 价格定义第二条 | $Q_{2,t}^1/Q_{2,t-1}^1=\Pi_{M,t}^2/\Pi_t^1$；j=— | `code/baseline/RANK_two_region_baseline.mod` L208 | PASS |
| A21 / — | `a16` L1537 | 价格定义第三条 | $Q_{1,t}^2/Q_{1,t-1}^2=\Pi_{M,t}^1/\Pi_t^2$；j=— | `code/baseline/RANK_two_region_baseline.mod` L209 | PASS |
| A22 / — | `a16q` L1538 | 同一组名义价格 | $Q_1^1Q_2^2=Q_1^2Q_2^1$；j=— | `code/baseline/RANK_two_region_baseline.mod` L210 | PASS |
| A23 / 1 | `a17` L1544 | 外生过程（无创新） | $\log(A^j/\bar A^j)=\rho_A\log(A^j_-/\bar A^j)$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L213 | PASS |
| A24 / 1 | `a18` L1545 | 品种技术积分 | $Y_M^j=A^j(K_G^j)^{\gamma_G}(K^j)^\alpha(N^j)^{1-\alpha}/V^j$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L214 | PASS |
| A25 / 1 | `a19` L1547 | 企业劳动成本最小化 | $W^j=(1-\alpha)Q_j^jMC^jY_M^jV^j/N^j$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L215 | PASS |
| A26 / 1 | `a20` L1548 | 企业资本成本最小化 | $R_K^j=\alpha Q_j^jMC^jY_M^jV^j/K^j$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L216 | PASS |
| A27 / 1 | `a21` L1549 | 来源地市场清算 | $s_jY_M^j=s_1M_j^1+s_2M_j^2$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L217 | PASS |
| A28 / 1 | `a22` L1550 | Calvo 价格分布 | $1=(1-\theta_p)(p_*^j)^{1-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p-1}$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L218 | PASS |
| A29 / 1 | `a23` L1551 | 重置价格 FOC 的成本项 | $\mathcal P_1^j=\Lambda^jQ_j^jMC^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p}\mathcal P_{1,+}^j]$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L219 | PASS |
| A30 / 1 | `a24` L1552 | 重置价格 FOC 的收入项 | $\mathcal P_2^j=\Lambda^jQ_j^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p-1}\mathcal P_{2,+}^j]$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L221 | PASS |
| A31 / 1 | `a25` L1553 | 垄断加成 FOC | $p_*^j=\epsilon_p\mathcal P_1^j/[(\epsilon_p-1)\mathcal P_2^j]$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L223 | PASS |
| A32 / 1 | `a26` L1554 | 相对价格负 ε 次幂积分 | $V^j=(1-\theta_p)(p_*^j)^{-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p}V^j_-$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L224 | PASS |
| A33 / 2 | `a17` L1544 | 外生过程（无创新） | $\log(A^j/\bar A^j)=\rho_A\log(A^j_-/\bar A^j)$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L226 | PASS |
| A34 / 2 | `a18` L1545 | 品种技术积分 | $Y_M^j=A^j(K_G^j)^{\gamma_G}(K^j)^\alpha(N^j)^{1-\alpha}/V^j$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L227 | PASS |
| A35 / 2 | `a19` L1547 | 企业劳动成本最小化 | $W^j=(1-\alpha)Q_j^jMC^jY_M^jV^j/N^j$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L228 | PASS |
| A36 / 2 | `a20` L1548 | 企业资本成本最小化 | $R_K^j=\alpha Q_j^jMC^jY_M^jV^j/K^j$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L229 | PASS |
| A37 / 2 | `a21` L1549 | 来源地市场清算 | $s_jY_M^j=s_1M_j^1+s_2M_j^2$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L230 | PASS |
| A38 / 2 | `a22` L1550 | Calvo 价格分布 | $1=(1-\theta_p)(p_*^j)^{1-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p-1}$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L231 | PASS |
| A39 / 2 | `a23` L1551 | 重置价格 FOC 的成本项 | $\mathcal P_1^j=\Lambda^jQ_j^jMC^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p}\mathcal P_{1,+}^j]$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L232 | PASS |
| A40 / 2 | `a24` L1552 | 重置价格 FOC 的收入项 | $\mathcal P_2^j=\Lambda^jQ_j^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p-1}\mathcal P_{2,+}^j]$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L234 | PASS |
| A41 / 2 | `a25` L1553 | 垄断加成 FOC | $p_*^j=\epsilon_p\mathcal P_1^j/[(\epsilon_p-1)\mathcal P_2^j]$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L236 | PASS |
| A42 / 2 | `a26` L1554 | 相对价格负 ε 次幂积分 | $V^j=(1-\theta_p)(p_*^j)^{-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p}V^j_-$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L237 | PASS |
| A43 / 1 | `a18x` L1546 | 生产地价值 | $Y^j=Q_j^jY_M^j$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L241 | PASS |
| A44 / 2 | `a18x` L1546 | 生产地价值 | $Y^j=Q_j^jY_M^j$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L242 | PASS |
| A45 / 1 | `a26d` L1571 | 四倍季度 GDP | $d^{j,ann}=B^j/(4Y^j)$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L252 | PASS |
| A46 / 1 | `a27` L1573 | 净实际债务服务定义 | $DS^j=(R^j_{B,-}/\Pi^j-1)B^j_-/Y^j$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L253 | PASS |
| A47 / 1 | `a28` L1577 | 预算移项 | $FS^j=\tau_LY^j+Z^j-G^j-(R^j_{B,-}/\Pi^j-1)B^j_-$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L254 | PASS |
| A48 / 1 | `a29` L1580 | 公共调整资源成本 | $\Phi_I^j=\chi_I(g^j-1)^2I_G^j/2$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L256 | PASS |
| A49 / 1 | `a30` L1583 | 债务管理资源成本 | $\Phi_B^j=\varphi_B(B^j/\bar Y^j-\bar b^j)^2\bar Y^j/2$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L257 | PASS |
| A50 / 1 | `a31` L1590 | 原子化取价报价制度 | $R_B^j/R=\exp\{\mu_B[(B^j/Y^j)/\bar b^j-1]\}$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L258 | PASS |
| A51 / 1 | `a34` L1609 | 政府对 IG 求导 G-IG | $\Lambda_G^j[1+\chi_I(g^j-1)g^j+\chi_I(g^j-1)^2/2]=q_G^j+\beta_GE_t[\Lambda^j_{G,+}\chi_I(g^j_+-1)(g^j_+)^2]$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L259 | PASS |
| A52 / 1 | `a35` L1615 | 政府对 KG+ 求导 G-KG | $q_G^j=\beta_GE_t[(1-\delta_G)q^j_{G,+}+\gamma_G(\omega_Y+\Lambda^j_{G,+}\tau_LY^j_+)/K^j_{G,+}]$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L262 | PASS |
| A53 / 1 | `a37` L1623 | 政府对 B 求导 G-B | $\Lambda_G^j[1-\varphi_B(B^j/\bar Y^j-\bar b^j)]=\beta_GE_t[\Lambda^j_{G,+}R_B^j/\Pi^j_+]$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L265 | PASS |
| A54 / 1 | `a33` L1596 | 公共资本技术 | $K^j_{G,+}=(1-\delta_G)K_G^j+I_G^j$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L267 | PASS |
| A55 / 1 | `a32` L1594 | 地方逐期预算 | $B^j=R^j_{B,-}B^j_-/\Pi^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j-\tau_LY^j-Z^j$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L268 | PASS |
| A56 / 1 | `a38` L1625 | 外生政府消费规则 | $\log(G^j/\bar G^j)=\rho_G\log(G^j_-/\bar G^j)$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L270 | PASS |
| A57 / 1 | `a40z` L1633 | 给定拨付规则 | $\log(Z^j/\bar Z^j)=\rho_Z\log(Z^j_-/\bar Z^j)+\phi_{Z,DS}(DS^j/\overline{DS}^j-1)+\phi_{Z,B}[(B^j_-/Y^j_-)/\bar b^j-1]$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L271 | PASS |
| A58 / 2 | `a26d` L1571 | 四倍季度 GDP | $d^{j,ann}=B^j/(4Y^j)$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L275 | PASS |
| A59 / 2 | `a27` L1573 | 净实际债务服务定义 | $DS^j=(R^j_{B,-}/\Pi^j-1)B^j_-/Y^j$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L276 | PASS |
| A60 / 2 | `a28` L1577 | 预算移项 | $FS^j=\tau_LY^j+Z^j-G^j-(R^j_{B,-}/\Pi^j-1)B^j_-$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L277 | PASS |
| A61 / 2 | `a29` L1580 | 公共调整资源成本 | $\Phi_I^j=\chi_I(g^j-1)^2I_G^j/2$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L279 | PASS |
| A62 / 2 | `a30` L1583 | 债务管理资源成本 | $\Phi_B^j=\varphi_B(B^j/\bar Y^j-\bar b^j)^2\bar Y^j/2$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L280 | PASS |
| A63 / 2 | `a31` L1590 | 原子化取价报价制度 | $R_B^j/R=\exp\{\mu_B[(B^j/Y^j)/\bar b^j-1]\}$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L281 | PASS |
| A64 / 2 | `a34` L1609 | 政府对 IG 求导 G-IG | $\Lambda_G^j[1+\chi_I(g^j-1)g^j+\chi_I(g^j-1)^2/2]=q_G^j+\beta_GE_t[\Lambda^j_{G,+}\chi_I(g^j_+-1)(g^j_+)^2]$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L282 | PASS |
| A65 / 2 | `a35` L1615 | 政府对 KG+ 求导 G-KG | $q_G^j=\beta_GE_t[(1-\delta_G)q^j_{G,+}+\gamma_G(\omega_Y+\Lambda^j_{G,+}\tau_LY^j_+)/K^j_{G,+}]$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L285 | PASS |
| A66 / 2 | `a37` L1623 | 政府对 B 求导 G-B | $\Lambda_G^j[1-\varphi_B(B^j/\bar Y^j-\bar b^j)]=\beta_GE_t[\Lambda^j_{G,+}R_B^j/\Pi^j_+]$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L288 | PASS |
| A67 / 2 | `a33` L1596 | 公共资本技术 | $K^j_{G,+}=(1-\delta_G)K_G^j+I_G^j$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L290 | PASS |
| A68 / 2 | `a32` L1594 | 地方逐期预算 | $B^j=R^j_{B,-}B^j_-/\Pi^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j-\tau_LY^j-Z^j$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L291 | PASS |
| A69 / 2 | `a38` L1625 | 外生政府消费规则 | $\log(G^j/\bar G^j)=\rho_G\log(G^j_-/\bar G^j)$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L293 | PASS |
| A70 / 2 | `a40z` L1633 | 给定拨付规则 | $\log(Z^j/\bar Z^j)=\rho_Z\log(Z^j_-/\bar Z^j)+\phi_{Z,DS}(DS^j/\overline{DS}^j-1)+\phi_{Z,B}[(B^j_-/Y^j_-)/\bar b^j-1]$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L294 | PASS |
| A71 / — | `a39ya` L1652 | 共同价格加总 | $D=\sum_j s_jp_jD^j$；j=— | `code/baseline/RANK_two_region_baseline.mod` L301 | PASS |
| A72 / — | `a39y` L1650 | 共同价格加总 | $Y=\sum_j s_jp_jY^j$；j=— | `code/baseline/RANK_two_region_baseline.mod` L305 | PASS |
| A73 / — | `a39pi` L1653 | 固定权重价格指数增长 | $\Pi=(\Pi^1)^{\upsilon_1}(\Pi^2)^{\upsilon_2}$；j=— | `code/baseline/RANK_two_region_baseline.mod` L307 | PASS |
| A74 / — | `a39mp` L1654 | 货币冲击过程 | $MP=\rho_{MP}MP_-+\varepsilon_{MP}$；j=— | `code/baseline/RANK_two_region_baseline.mod` L308 | PASS |
| A75 / — | `a41D` L1655 | 负需求创新符号 | $\zeta=\rho_\zeta\zeta_--\varepsilon_\zeta$；j=— | `code/baseline/RANK_two_region_baseline.mod` L309 | PASS |
| A76 / — | `a41` L1662 | 货币规则制度 | $R/\bar R=(R_-/\bar R)^{\rho_R}[(\Pi/\bar\Pi)^{\phi_\pi}(Y/\bar Y)^{\phi_y}]^{1-\rho_R}e^{MP}$；j=— | `code/baseline/RANK_two_region_baseline.mod` L310 | PASS |
| A77 / 1 | `a42` L1666 | 最终品用途清算 | $D^j=C^j+I^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j$；j=1 | `code/baseline/RANK_two_region_baseline.mod` L314 | PASS |
| A78 / 2 | `a42` L1666 | 最终品用途清算 | $D^j=C^j+I^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j$；j=2 | `code/baseline/RANK_two_region_baseline.mod` L315 | PASS |

### F1.B

| Eq/region | Current TeX label/line | Economic origin | Independently checked form | Current code/line | Result |
|---|---|---|---|---|---|
| B01 / 1 | `a1` L1494 | 消费边际效用 | $\Lambda^1=(C^1)^{-\sigma}$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L215 | PASS |
| B02 / 1 | `a2` L1495 | 模型施加的资产特定缩约均衡楔子 | $\Lambda^1=\beta e^{-\zeta}E_t[\Lambda^1_+R/\Pi^1_+]$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L216 | PASS |
| B03 / 1 | `a5` L1498 | 效用/工资边际条件 | $\chi_N(N^j)^\varphi=\Lambda^j W^j$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L217 | PASS |
| B04 / 1 | `a10` L1499 | 安装技术 | $K^j_+=(1-\delta_K)K^j+[1-S(x^j)]I^j$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L221 | PASS |
| B05 / 1 | `a11` L1504 | 选择下一期资本 | $q_K^j=\beta E_t[m^j_+(R^j_{K,+}+(1-\delta_K)q^j_{K,+})]$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L223 | PASS |
| B06 / 1 | `a12` L1516 | 相邻两期安装边际效应 | $1=q_K^j A_I(x^j)+\beta E_t[m^j_+q^j_{K,+}B_I(x^j_+)]$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L225 | PASS |
| B07 / 2 | `a3` L1496 | 消费边际效用 | $\Lambda^2=(C^2)^{-\sigma}$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L230 | PASS |
| B08 / 2 | `a4` L1497 | 相同状态价格 | $\Lambda^2=\xi_{12}\Lambda^1Q_1^1/Q_1^2$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L231 | PASS |
| B09 / 2 | `a5` L1498 | 效用/工资边际条件 | $\chi_N(N^j)^\varphi=\Lambda^j W^j$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L232 | PASS |
| B10 / 2 | `a10` L1499 | 安装技术 | $K^j_+=(1-\delta_K)K^j+[1-S(x^j)]I^j$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L236 | PASS |
| B11 / 2 | `a11` L1504 | 选择下一期资本 | $q_K^j=\beta E_t[m^j_+(R^j_{K,+}+(1-\delta_K)q^j_{K,+})]$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L238 | PASS |
| B12 / 2 | `a12` L1516 | 相邻两期安装边际效应 | $1=q_K^j A_I(x^j)+\beta E_t[m^j_+q^j_{K,+}B_I(x^j_+)]$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L240 | PASS |
| B13 / 1 | `a13` L1529 | 成本最小化/零利润 | $1=[\omega_j(Q_j^j)^{1-\eta}+(1-\omega_j)(Q_{-j}^j)^{1-\eta}]^{1/(1-\eta)}$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L245 | PASS |
| B14 / 1 | `a14` L1530 | 本地品需求 FOC | $M_j^j=\omega_j(Q_j^j)^{-\eta}D^j$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L246 | PASS |
| B15 / 1 | `a15` L1531 | 外地品需求 FOC | $M_{-j}^j=(1-\omega_j)(Q_{-j}^j)^{-\eta}D^j$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L247 | PASS |
| B16 / 2 | `a13` L1529 | 成本最小化/零利润 | $1=[\omega_j(Q_j^j)^{1-\eta}+(1-\omega_j)(Q_{-j}^j)^{1-\eta}]^{1/(1-\eta)}$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L249 | PASS |
| B17 / 2 | `a14` L1530 | 本地品需求 FOC | $M_j^j=\omega_j(Q_j^j)^{-\eta}D^j$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L250 | PASS |
| B18 / 2 | `a15` L1531 | 外地品需求 FOC | $M_{-j}^j=(1-\omega_j)(Q_{-j}^j)^{-\eta}D^j$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L251 | PASS |
| B19 / — | `a16` L1537 | 价格定义第一条 | $Q_{1,t}^1/Q_{1,t-1}^1=\Pi_{M,t}^1/\Pi_t^1$；j=— | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L253 | PASS |
| B20 / — | `a16` L1537 | 价格定义第二条 | $Q_{2,t}^1/Q_{2,t-1}^1=\Pi_{M,t}^2/\Pi_t^1$；j=— | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L254 | PASS |
| B21 / — | `a16` L1537 | 价格定义第三条 | $Q_{1,t}^2/Q_{1,t-1}^2=\Pi_{M,t}^1/\Pi_t^2$；j=— | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L255 | PASS |
| B22 / — | `a16q` L1538 | 同一组名义价格 | $Q_1^1Q_2^2=Q_1^2Q_2^1$；j=— | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L256 | PASS |
| B23 / 1 | `a17` L1544 | 外生过程（无创新） | $\log(A^j/\bar A^j)=\rho_A\log(A^j_-/\bar A^j)$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L259 | PASS |
| B24 / 1 | `a18` L1545 | 品种技术积分 | $Y_M^j=A^j(K_G^j)^{\gamma_G}(K^j)^\alpha(N^j)^{1-\alpha}/V^j$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L260 | PASS |
| B25 / 1 | `a19` L1547 | 企业劳动成本最小化 | $W^j=(1-\alpha)Q_j^jMC^jY_M^jV^j/N^j$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L261 | PASS |
| B26 / 1 | `a20` L1548 | 企业资本成本最小化 | $R_K^j=\alpha Q_j^jMC^jY_M^jV^j/K^j$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L262 | PASS |
| B27 / 1 | `a21` L1549 | 来源地市场清算 | $s_jY_M^j=s_1M_j^1+s_2M_j^2$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L263 | PASS |
| B28 / 1 | `a22` L1550 | Calvo 价格分布 | $1=(1-\theta_p)(p_*^j)^{1-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p-1}$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L264 | PASS |
| B29 / 1 | `a23` L1551 | 重置价格 FOC 的成本项 | $\mathcal P_1^j=\Lambda^jQ_j^jMC^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p}\mathcal P_{1,+}^j]$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L265 | PASS |
| B30 / 1 | `a24` L1552 | 重置价格 FOC 的收入项 | $\mathcal P_2^j=\Lambda^jQ_j^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p-1}\mathcal P_{2,+}^j]$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L267 | PASS |
| B31 / 1 | `a25` L1553 | 垄断加成 FOC | $p_*^j=\epsilon_p\mathcal P_1^j/[(\epsilon_p-1)\mathcal P_2^j]$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L269 | PASS |
| B32 / 1 | `a26` L1554 | 相对价格负 ε 次幂积分 | $V^j=(1-\theta_p)(p_*^j)^{-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p}V^j_-$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L270 | PASS |
| B33 / 2 | `a17` L1544 | 外生过程（无创新） | $\log(A^j/\bar A^j)=\rho_A\log(A^j_-/\bar A^j)$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L272 | PASS |
| B34 / 2 | `a18` L1545 | 品种技术积分 | $Y_M^j=A^j(K_G^j)^{\gamma_G}(K^j)^\alpha(N^j)^{1-\alpha}/V^j$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L273 | PASS |
| B35 / 2 | `a19` L1547 | 企业劳动成本最小化 | $W^j=(1-\alpha)Q_j^jMC^jY_M^jV^j/N^j$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L274 | PASS |
| B36 / 2 | `a20` L1548 | 企业资本成本最小化 | $R_K^j=\alpha Q_j^jMC^jY_M^jV^j/K^j$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L275 | PASS |
| B37 / 2 | `a21` L1549 | 来源地市场清算 | $s_jY_M^j=s_1M_j^1+s_2M_j^2$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L276 | PASS |
| B38 / 2 | `a22` L1550 | Calvo 价格分布 | $1=(1-\theta_p)(p_*^j)^{1-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p-1}$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L277 | PASS |
| B39 / 2 | `a23` L1551 | 重置价格 FOC 的成本项 | $\mathcal P_1^j=\Lambda^jQ_j^jMC^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p}\mathcal P_{1,+}^j]$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L278 | PASS |
| B40 / 2 | `a24` L1552 | 重置价格 FOC 的收入项 | $\mathcal P_2^j=\Lambda^jQ_j^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p-1}\mathcal P_{2,+}^j]$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L280 | PASS |
| B41 / 2 | `a25` L1553 | 垄断加成 FOC | $p_*^j=\epsilon_p\mathcal P_1^j/[(\epsilon_p-1)\mathcal P_2^j]$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L282 | PASS |
| B42 / 2 | `a26` L1554 | 相对价格负 ε 次幂积分 | $V^j=(1-\theta_p)(p_*^j)^{-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p}V^j_-$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L283 | PASS |
| B43 / 1 | `a18x` L1546 | 生产地价值 | $Y^j=Q_j^jY_M^j$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L287 | PASS |
| B44 / 2 | `a18x` L1546 | 生产地价值 | $Y^j=Q_j^jY_M^j$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L288 | PASS |
| B45 / 1 | `a26d` L1571 | 四倍季度 GDP | $d^{j,ann}=B^j/(4Y^j)$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L298 | PASS |
| B46 / 1 | `a27` L1573 | 净实际债务服务定义 | $DS^j=(R^j_{B,-}/\Pi^j-1)B^j_-/Y^j$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L299 | PASS |
| B47 / 1 | `a28` L1577 | 预算移项 | $FS^j=\tau_LY^j+Z^j-G^j-(R^j_{B,-}/\Pi^j-1)B^j_-$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L300 | PASS |
| B48 / 1 | `a29` L1580 | 公共调整资源成本 | $\Phi_I^j=\chi_I(g^j-1)^2I_G^j/2$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L302 | PASS |
| B49 / 1 | `a30` L1583 | 债务管理资源成本 | $\Phi_B^j=\varphi_B(B^j/\bar Y^j-\bar b^j)^2\bar Y^j/2$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L303 | PASS |
| B50 / 1 | `a31` L1590 | 原子化取价报价制度 | $R_B^j/R=\exp\{\mu_B[(B^j/Y^j)/\bar b^j-1]\}$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L304 | PASS |
| B51 / 1 | `a34` L1609 | 政府对 IG 求导 G-IG | $\Lambda_G^j[1+\chi_I(g^j-1)g^j+\chi_I(g^j-1)^2/2]=q_G^j+\beta_GE_t[\Lambda^j_{G,+}\chi_I(g^j_+-1)(g^j_+)^2]$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L305 | PASS |
| B52 / 1 | `eq:stackelberg_QG` L1277 | 扩展 KG+ 变分 | $\text{S-KG：}\ q_G^j=\beta_GE_t[(1-\delta_G)q^j_{G,+}+\gamma_GJ^j_+/K^j_{G,+}]-\beta\nu_Q^jE_t[m^j_+\gamma_GR^j_{K,+}/K^j_{G,+}]$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L312 | PASS |
| B53 / 1 | `eq:stackelberg_K_corrected` L1294 | 扩展 K+ 变分 | $\text{S-K：}\ \nu_K^j=\beta_GE_t[\alpha J^j_+/K^j_++(1-\delta_K)\nu^j_{K,+}]+\beta\nu_Q^jE_t[m^j_+(1-\alpha)R^j_{K,+}/K^j_+]$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L320 | PASS |
| B54 / 1 | `eq:stackelberg_NR` L1310 | 扩展当期 N 变分 | $\text{S-N：}\ 0=[(1-\alpha)H^j+\alpha\Theta^jW^j-(\beta/\beta_G)\nu^j_{Q,-}m^j(1-\alpha)R_K^j]/N^j+\nu_N^j\chi_N\varphi(N^j)^{\varphi-1}$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L328 | PASS |
| B55 / 1 | `eq:stackelberg_QK` L1319 | 扩展当期 qK 变分 | $\text{S-q：}\ 0=\nu_Q^j-A_I(x^j)\nu_I^j-(\beta/\beta_G)m^j[(1-\delta_K)\nu^j_{Q,-}+B_I(x^j)\nu^j_{I,-}]$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L331 | PASS |
| B56 / 1 | `eq:stackelberg_I` L1337 | 扩展当期 I：四来源变分 | $\text{S-I 全式，见独立推导说明；} A_I^\prime=\phi_I(2-3x),\ B_I^\prime=\phi_I(3x^2-2x)$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L335 | PASS |
| B57 / 1 | `a37` L1623 | 政府对 B 求导 G-B | $\Lambda_G^j[1-\varphi_B(B^j/\bar Y^j-\bar b^j)]=\beta_GE_t[\Lambda^j_{G,+}R_B^j/\Pi^j_+]$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L344 | PASS |
| B58 / 1 | `a33` L1596 | 公共资本技术 | $K^j_{G,+}=(1-\delta_G)K_G^j+I_G^j$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L347 | PASS |
| B59 / 1 | `a32` L1594 | 地方逐期预算 | $B^j=R^j_{B,-}B^j_-/\Pi^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j-\tau_LY^j-Z^j$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L349 | PASS |
| B60 / 1 | `a38` L1625 | 外生政府消费规则 | $\log(G^j/\bar G^j)=\rho_G\log(G^j_-/\bar G^j)$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L352 | PASS |
| B61 / 1 | `a40z` L1633 | 给定拨付规则 | $\log(Z^j/\bar Z^j)=\rho_Z\log(Z^j_-/\bar Z^j)+\phi_{Z,DS}(DS^j/\overline{DS}^j-1)+\phi_{Z,B}[(B^j_-/Y^j_-)/\bar b^j-1]$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L354 | PASS |
| B62 / 2 | `a26d` L1571 | 四倍季度 GDP | $d^{j,ann}=B^j/(4Y^j)$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L358 | PASS |
| B63 / 2 | `a27` L1573 | 净实际债务服务定义 | $DS^j=(R^j_{B,-}/\Pi^j-1)B^j_-/Y^j$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L359 | PASS |
| B64 / 2 | `a28` L1577 | 预算移项 | $FS^j=\tau_LY^j+Z^j-G^j-(R^j_{B,-}/\Pi^j-1)B^j_-$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L360 | PASS |
| B65 / 2 | `a29` L1580 | 公共调整资源成本 | $\Phi_I^j=\chi_I(g^j-1)^2I_G^j/2$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L362 | PASS |
| B66 / 2 | `a30` L1583 | 债务管理资源成本 | $\Phi_B^j=\varphi_B(B^j/\bar Y^j-\bar b^j)^2\bar Y^j/2$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L363 | PASS |
| B67 / 2 | `a31` L1590 | 原子化取价报价制度 | $R_B^j/R=\exp\{\mu_B[(B^j/Y^j)/\bar b^j-1]\}$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L364 | PASS |
| B68 / 2 | `a34` L1609 | 政府对 IG 求导 G-IG | $\Lambda_G^j[1+\chi_I(g^j-1)g^j+\chi_I(g^j-1)^2/2]=q_G^j+\beta_GE_t[\Lambda^j_{G,+}\chi_I(g^j_+-1)(g^j_+)^2]$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L365 | PASS |
| B69 / 2 | `eq:stackelberg_QG` L1277 | 扩展 KG+ 变分 | $\text{S-KG：}\ q_G^j=\beta_GE_t[(1-\delta_G)q^j_{G,+}+\gamma_GJ^j_+/K^j_{G,+}]-\beta\nu_Q^jE_t[m^j_+\gamma_GR^j_{K,+}/K^j_{G,+}]$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L369 | PASS |
| B70 / 2 | `eq:stackelberg_K_corrected` L1294 | 扩展 K+ 变分 | $\text{S-K：}\ \nu_K^j=\beta_GE_t[\alpha J^j_+/K^j_++(1-\delta_K)\nu^j_{K,+}]+\beta\nu_Q^jE_t[m^j_+(1-\alpha)R^j_{K,+}/K^j_+]$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L376 | PASS |
| B71 / 2 | `eq:stackelberg_NR` L1310 | 扩展当期 N 变分 | $\text{S-N：}\ 0=[(1-\alpha)H^j+\alpha\Theta^jW^j-(\beta/\beta_G)\nu^j_{Q,-}m^j(1-\alpha)R_K^j]/N^j+\nu_N^j\chi_N\varphi(N^j)^{\varphi-1}$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L383 | PASS |
| B72 / 2 | `eq:stackelberg_QK` L1319 | 扩展当期 qK 变分 | $\text{S-q：}\ 0=\nu_Q^j-A_I(x^j)\nu_I^j-(\beta/\beta_G)m^j[(1-\delta_K)\nu^j_{Q,-}+B_I(x^j)\nu^j_{I,-}]$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L386 | PASS |
| B73 / 2 | `eq:stackelberg_I` L1337 | 扩展当期 I：四来源变分 | $\text{S-I 全式，见独立推导说明；} A_I^\prime=\phi_I(2-3x),\ B_I^\prime=\phi_I(3x^2-2x)$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L390 | PASS |
| B74 / 2 | `a37` L1623 | 政府对 B 求导 G-B | $\Lambda_G^j[1-\varphi_B(B^j/\bar Y^j-\bar b^j)]=\beta_GE_t[\Lambda^j_{G,+}R_B^j/\Pi^j_+]$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L399 | PASS |
| B75 / 2 | `a33` L1596 | 公共资本技术 | $K^j_{G,+}=(1-\delta_G)K_G^j+I_G^j$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L402 | PASS |
| B76 / 2 | `a32` L1594 | 地方逐期预算 | $B^j=R^j_{B,-}B^j_-/\Pi^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j-\tau_LY^j-Z^j$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L404 | PASS |
| B77 / 2 | `a38` L1625 | 外生政府消费规则 | $\log(G^j/\bar G^j)=\rho_G\log(G^j_-/\bar G^j)$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L407 | PASS |
| B78 / 2 | `a40z` L1633 | 给定拨付规则 | $\log(Z^j/\bar Z^j)=\rho_Z\log(Z^j_-/\bar Z^j)+\phi_{Z,DS}(DS^j/\overline{DS}^j-1)+\phi_{Z,B}[(B^j_-/Y^j_-)/\bar b^j-1]$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L409 | PASS |
| B79 / — | `a39ya` L1652 | 共同价格加总 | $D=\sum_j s_jp_jD^j$；j=— | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L416 | PASS |
| B80 / — | `a39y` L1650 | 共同价格加总 | $Y=\sum_j s_jp_jY^j$；j=— | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L420 | PASS |
| B81 / — | `a39pi` L1653 | 固定权重价格指数增长 | $\Pi=(\Pi^1)^{\upsilon_1}(\Pi^2)^{\upsilon_2}$；j=— | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L422 | PASS |
| B82 / — | `a39mp` L1654 | 货币冲击过程 | $MP=\rho_{MP}MP_-+\varepsilon_{MP}$；j=— | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L423 | PASS |
| B83 / — | `a41D` L1655 | 负需求创新符号 | $\zeta=\rho_\zeta\zeta_--\varepsilon_\zeta$；j=— | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L424 | PASS |
| B84 / — | `a41` L1662 | 货币规则制度 | $R/\bar R=(R_-/\bar R)^{\rho_R}[(\Pi/\bar\Pi)^{\phi_\pi}(Y/\bar Y)^{\phi_y}]^{1-\rho_R}e^{MP}$；j=— | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L425 | PASS |
| B85 / 1 | `a42` L1666 | 最终品用途清算 | $D^j=C^j+I^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j$；j=1 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L429 | PASS |
| B86 / 2 | `a42` L1666 | 最终品用途清算 | $D^j=C^j+I^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j$；j=2 | `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` L430 | PASS |

## All formal model structural comparisons

下表OccBin源文本计数80包含互斥的两行：common78 + slack1或binding1，即79 equations per regime。其余源文本计数就是实际逐期计数。54份predetermined声明均是k1 k2 kg1 kg2，无变量重名。

| Model | Endogenous | Source equations | Reference | Changed equation indices | Aliases match |
|---|---:|---:|---|---|---|
| `code/baseline/RANK_two_region_baseline.mod` | 78 | 78 | A | none | True |
| `code/debt_intensity/debt_intensity_b040.mod` | 78 | 78 | A | none | True |
| `code/debt_intensity/debt_intensity_b080.mod` | 78 | 78 | A | none | True |
| `code/debt_intensity/debt_intensity_b120.mod` | 78 | 78 | A | none | True |
| `code/debt_intensity/debt_intensity_b160.mod` | 78 | 78 | A | none | True |
| `code/demand_monetary/hawkish_phi_110.mod` | 78 | 78 | A | none | True |
| `code/demand_monetary/hawkish_phi_150.mod` | 78 | 78 | A | none | True |
| `code/demand_monetary/hawkish_phi_200.mod` | 78 | 78 | A | none | True |
| `code/demand_monetary/hawkish_phi_300.mod` | 78 | 78 | A | none | True |
| `code/demand_monetary/negative_demand_baseline_policy.mod` | 78 | 78 | A | none | True |
| `code/demand_monetary/negative_demand_phi_110.mod` | 78 | 78 | A | none | True |
| `code/demand_monetary/negative_demand_phi_200.mod` | 78 | 78 | A | none | True |
| `code/demand_monetary/negative_demand_phi_250.mod` | 78 | 78 | A | none | True |
| `code/demand_monetary/negative_demand_strong_inflation_policy.mod` | 78 | 78 | A | none | True |
| `code/extension_scenarios/demand_regional_balance_000.mod` | 78 | 78 | A | 76 | True |
| `code/extension_scenarios/demand_regional_balance_050.mod` | 78 | 78 | A | 76 | True |
| `code/extension_scenarios/demand_regional_balance_100.mod` | 78 | 78 | A | 76 | True |
| `code/extension_scenarios/demand_regional_balance_150.mod` | 78 | 78 | A | 76 | True |
| `code/extension_scenarios/demand_regional_balance_200.mod` | 78 | 78 | A | 76 | True |
| `code/extension_scenarios/scenario_01_baseline.mod` | 78 | 78 | A | none | True |
| `code/extension_scenarios/scenario_02_risk_premium.mod` | 78 | 78 | A | none | True |
| `code/extension_scenarios/scenario_03_transfer_buffer.mod` | 78 | 78 | A | none | True |
| `code/extension_scenarios/scenario_04_risk_and_transfer.mod` | 78 | 78 | A | none | True |
| `code/extension_scenarios/scenario_05_strong_io.mod` | 78 | 78 | A | none | True |
| `code/extension_scenarios/scenario_06_weak_io.mod` | 78 | 78 | A | none | True |
| `code/policy_counterfactual/policy_cf_baseline.mod` | 78 | 78 | A | none | True |
| `code/policy_counterfactual/policy_cf_central_transfer_stabilizer.mod` | 78 | 78 | A | none | True |
| `code/policy_counterfactual/policy_cf_no_transfer_stabilizer.mod` | 78 | 78 | A | none | True |
| `code/policy_counterfactual/policy_cf_regional_balance_taylor.mod` | 78 | 78 | A | 76 | True |
| `code/policy_counterfactual/policy_cf_standard_taylor.mod` | 78 | 78 | A | 76 | True |
| `code/policy_counterfactual/policy_cf_strict_debt_cap.mod` | 79 | 80 | A | 66, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80 | True |
| `code/scale_development/scale_development_y100.mod` | 78 | 78 | A | none | True |
| `code/scale_development/scale_development_y150.mod` | 78 | 78 | A | none | True |
| `code/scale_development/scale_development_y200.mod` | 78 | 78 | A | none | True |
| `code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod` | 86 | 86 | B | none | True |
| `code/stackelberg_B/robustness/scheme_A/RANK_two_region_scheme_A.mod` | 78 | 78 | A | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/alpha_high/A/RANK_scheme_A_alpha_high.mod` | 78 | 78 | A | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/alpha_high/B/RANK_scheme_B_alpha_high.mod` | 86 | 86 | B | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/alpha_low/A/RANK_scheme_A_alpha_low.mod` | 78 | 78 | A | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/alpha_low/B/RANK_scheme_B_alpha_low.mod` | 86 | 86 | B | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/baseline/A/RANK_scheme_A_baseline.mod` | 78 | 78 | A | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/baseline/B/RANK_scheme_B_baseline.mod` | 86 | 86 | B | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/chiIG_high/A/RANK_scheme_A_chiIG_high.mod` | 78 | 78 | A | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/chiIG_high/B/RANK_scheme_B_chiIG_high.mod` | 86 | 86 | B | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/chiIG_low/A/RANK_scheme_A_chiIG_low.mod` | 78 | 78 | A | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/chiIG_low/B/RANK_scheme_B_chiIG_low.mod` | 86 | 86 | B | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/gamma_high/A/RANK_scheme_A_gamma_high.mod` | 78 | 78 | A | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/gamma_high/B/RANK_scheme_B_gamma_high.mod` | 86 | 86 | B | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/gamma_low/A/RANK_scheme_A_gamma_low.mod` | 78 | 78 | A | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/gamma_low/B/RANK_scheme_B_gamma_low.mod` | 86 | 86 | B | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/phiI_high/A/RANK_scheme_A_phiI_high.mod` | 78 | 78 | A | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/phiI_high/B/RANK_scheme_B_phiI_high.mod` | 86 | 86 | B | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/phiI_low/A/RANK_scheme_A_phiI_low.mod` | 78 | 78 | A | none | True |
| `code/stackelberg_B/robustness/sensitivity_sanity/generated/phiI_low/B/RANK_scheme_B_phiI_low.mod` | 86 | 86 | B | none | True |


## 附录 F2. 代数与历史节点导数复核记录

### F2. 重新核对的代数、单位和时点

本文用 Y_j 表示生产GDP（代码xlocj），D_j表示最终吸收（代码yj），Y_M表示物量产出（代码ymj）。q11=P_M1/P1、q21=P_M2/P1、q12=P_M1/P2、q22=P_M2/P2。下标来源与使用地区方向重核，未把代码yj当成论文Y_j。全部Dynare (+1)产品按时点t条件期望解释；当期已知系数移入/移出期望等价。

#### CES 与中间品

CES一阶条件为 M_k^j=weight_k^j(Q_k^j)^(-eta)D_j，零利润给 sum_k weight_k^j(Q_k^j)^(1-eta)=1。将需求代回CES：括号为 D_j^((eta-1)/eta) 乘该和，故技术生产函数成立，不需新增非冗余等式。当前TeX183/191–194/1529–1531与A199–205、B245–251一致。三动态来自每个Q的价格定义；Q11Q22=Q12Q21使第四动态冗余，当前TeX198–207/1535–1538与A207–210一致。

企业常报酬私有要素技术使 WN=(1-alpha)Q MC Y_M V、RK K=alpha Q MC Y_M V。其和加利润 Omega=QY_M-Q MC Y_M V 恰为GDP=QY_M。这里MC用中间品计价，工资租金用本地最终品，故必须乘Q；V因品种价格离散导致总要素需求增加，不能从要素式中删除。当前TeX216/225–237/1544–1554与A213–237、241–242及B259–288一致。

Calvo从状态利润 sum_s(beta theta)^s Lambda_(t+s) Q_(t+s) [p*/cumPi−MC_(t+s)] [p*/cumPi]^(-epsilon)Y_M,(t+s) 求导，得到重置价 epsilon/(epsilon−1) 乘成本与收入现值比。递推的未来累积通胀幂分别epsilon、epsilon−1；Lambda Q在当前项中，未来项已包在P1/P2。其成本项不额外乘V，因为是品种边际产量成本，不是总要素账单。Calvo价格指数旧价项Pi_M^(epsilon−1)，离散度旧价项Pi_M^epsilon V_-，与TeX246–256、A218–237、B264–283完全一致。

#### 政府 FOC 与终端

从当前TeX1014–1020 Lagrangian取偏导，令g=IG/IG_-：
- dPhiI_t/dIG_t=chiI(g−1)g+chiI(g−1)^2/2。
- dPhiI_(t+1)/dIG_t=−chiI(g_+−1)g_+^2。
- dPhiB_t/dB_t=varphiB(B_t/Ybar−bbar)，外乘Ybar与导数分母抵消。
IG_t在当期资本约束中给+qG，所以 LambdaG[1+dPhiI_t]=qG+betaG E[LambdaG_+ chiI(g_+−1)g_+^2]。KG_(t+1)当期−qG、未来+(1−deltaG)qG和目标/税基 gammaG[omegaY+LambdaG tauL Y]/KG；得到当前TeX361/375，即A259–264与282–287对应两地区。B_t当期+LambdaG[1−PhiB']、未来−betaG E[LambdaG_+ RB_t/Pi_+]；得到当前TeX395、A265–266和288–289。RB报价取价，Z给定拨付，无dRB/dB或dZ/dB。

政府TVC的qG_T KG_(T+1)和私有资本TVC的Lambda_T qK_T K_(T+1)均与当期选择下一期存量一致；终端限制是无限期局部有界解的边界，并非40期末强制回稳态，也非逐期等式计数。正稳态及其局部有界可积邻域为本论文认证范围。

#### 债务、报价、转移、DS/FS

当前TeX266清楚定义B_t为当期价格平减的期末新债本金，旧合同RB_(t−1)与B_(t−1)给定，Pi_t实现后本期偿付RB_(t−1)B_(t−1)/Pi_t。RB_t随B_t选择期报价而决定下一期偿付。`b`虽不在predetermined_variables列表中，其滞后值仍是持有历史状态；不应因此把B_t错当期初存量。

报价 exp(muB[(B/Y)/(Bbar/Ybar)−1]) 与代码 exp(mu_b[dann/d_ann−1])完全等价，年化因子4抵消。只在取价FOC求导之后施加同类对称均衡，当前TeX278–279/1067解释正确。Z反馈使用当前DS/DSbar和上期(B/Y)/bbar，绝非当前债务率，A271–273/294–296与TeX305/a40z1633一致。

DS*Y=(RB_-/Pi−1)B_-=[(RB_-−1)/Pi]B_-+(1/Pi−1)B_-。不是普通利息率，当前TeX411–427明确净实际债务服务/本金重估。地方预算移项给 B−B_-=IG+PhiI+PhiB−FS。所以FS是保持上一期实际本金余额B=B_-的当期资源口径，不是固定名义本金，也不是完整跨期财政空间（TeX427–432）。A252–258/275–281与TeX415/418及附录a27/a28一致。

#### 全国与 Taylor

p1=(q12/q11)^gw2、p2=(q11/q12)^gw1；xagg=sum s p xloc；yagg=sum s p y；pinfagg=Pi1^gw1 Pi2^gw2；它们使用固定稳态GDP权重gw而数量聚合用测度s。标准利率式以及mp=rho_mp mp_-+emp、d=rho_d d_-−ed逐式相同。地区平衡7份唯一变化为乘[(xloc2/xbar2)/(xloc1/xbar1)]^phi_reg，位于1−rho_r外幂内部，当前TeX710–718一致。一阶为 rhat=rho_r rhat_-+(1−rho_r)[phi_pi pihat+phi_x yhat+phi_reg(yhat2−yhat1)]+MP；高债务相对更弱时附加项降低利率。phi_reg=0精确退回标准非线性式。

### F2. Stackelberg：重新历史节点求导

当前四个约束（TeX1217–1229）是F_N=chi N^varphi−Lambda W；F_K=(1−delta)K+(1−S)I−K_+；F_Q=q−beta E[m_+(RK_++(1−delta)q_+)]；F_I=1−q A_I(x)−beta E[m_+q_+B_I(x_+)]。四乘子nuN,nuK,nuQ,nuI映射muR,muK,muQ,muI。Lambda路径由资产市场给定，未加入消费Euler乘子（TeX1207）。局部函数A_I=1−phiI(x−1)^2/2−phiI x(x−1)，B_I=phiI x^2(x−1)，A_I'=phiI(2−3x)，B_I'=phiI(3x^2−2x)，与B175–212的32个别名逐项一致。

定义H=omegaY+LambdaG tauL Y、Theta=nuN Lambda、J=H−Theta W。政府选择的是历史节点计划，K_+/KG_+是本期选定的下一期预定存量，不能对每个后继状态分别零化其边际价值；所有未来项保留E_t。

- S-KG：当前−qG，未来betaG E[(1−deltaG)qG_++gammaG J_+/KG_+]，以及本期F_Q未来租金项−beta nuQ E[m_+gammaG RK_+/KG_+]；故TeX1277与B312–318/369–375相同。
- S-K：当前−nuK，未来betaG E[alpha J_+/K_++(1−deltaK)nuK_+]，本期F_Q中dRK_+/dK_+=(alpha−1)RK_+/K_+给正beta nuQ E[m_+(1−alpha)RK_+/K_+]；故TeX1294与B320–326/376–382相同。
- S-N：dY/dN=(1−alpha)Y/N，dW/dN=−alpha W/N，dRK/dN=(1−alpha)RK/N。上期F_Q在当前历史节点产生−(beta/betaG)nuQ_- m(1−alpha)RK/N；加当前FN直接劳动项nuN chi varphi N^(varphi−1)，得到TeX1304/1310与B328–330/383–385。
- S-q：当前FQ给nuQ，当前FI给−A_I nuI，历史FQ/FI给−(beta/betaG)m[(1−deltaK)nuQ_-+B_I nuI_-]，即TeX1319与B331–334/386–389。
- S-I：本期和下一期FK产生nuK A_I+betaG E[nuK_+B_I(x_+)]；本期FI产生nuI{−q A'_I/I_-+beta E[m_+q_+ B'_I(x_+)x_+/I]}；历史FI产生−(beta/betaG)nuI_-m q B'_I/I_-；下一期FI的当期A项产生+betaG E[nuI_+q_+ A'_I(x_+)x_+/I]。四来源分别与TeX1323–1337、B335–343/390–398逐项相同，未丢失lead/lag或条件期望。

新增H0（TeX1245–1254）等于上期FQ/FI继续约束当期自由选择的项：H0=−(beta/betaG)m0{nuQ_-1[RK0+(1−deltaK)q0]+nuI_-1 q0 B_I(x0)}。对N0求导恢复S-N历史RK项；对q0求导恢复两项S-q历史项；对I0求导恢复S-I历史B'_I/I_-1项。K0和KG0及I_-1是给定初值，其他省略的上期项独立于当期自由选择，无需补充。B的稳态模型给非零muQ=-94.368932038834771、muI=deltaK muQ；在stoch_simul围绕该稳态下，历史偏差初值为0指乘子水平等于该稳态，而非乘子水平为0。故新增边界与代码实现相容，不新增逐期动态条件。首次t=0宣布承诺的transition不同于此timeless IRF，TeX1254已明确区分。



## 附录 F3. 原始数值交叉核对明细

### F3. Baseline and debt intensity

TeX L616/L629: original `code/baseline/baseline_full_irf.csv` (also baseline MAT IRFs) gives:

| series | low extremum | high extremum | high/low magnitude | extremum quarter |
|---|---:|---:|---:|---|
| ds | 0.00446976012677124 | 0.0114552369863372 | 2.562830367054 | 2 / 2 |
| fs | -0.00458542078083335 | -0.0115398331274795 | 2.516635588977 | 2 / 2 |
| ig | -0.000694397917307715 | -0.00172233169510656 | 2.480323820360 | 8 / 8 |

Current TeX 2.56 / 2.52 / 2.48 is correct. KG low trough is q23, high q22; L629 says “约第22个季度”, which is a harmless approximate joint description, not a false exact timing statement. q40 KG low/high = -0.0062149387831187 / -0.0145982497632815; both still below steady. GDP low/high trough q1, high-low negative in all 40 quarters (range -0.0005474276963383 to -0.0001233137920909), supporting L631. Late IG high-low becomes positive, consistent with L629.

TeX L635/L644: `code/debt_intensity/debt_intensity_irf_series.csv` independently confirms d1=.4 and d2=.4/.8/1.2/1.6. Symmetric-case maximum gap is 2.04e-14 (public capital roundoff). For asymmetric cases DS gap peaks q2, IG gap troughs q8, KG gap troughs q22. DS gap peaks = .0046429205861976/.0093425647189555/.0141015609065443; IG minima = -.0006904333906444/-.0013604208416218/-.0020107102009889; KG minima = -.008236740463551/-.0160143660715724/-.0233575519420945. GDP/ KG gaps remain negative through q40, while IG gaps at q40 are positive. Narrative matches.

### F3. Scale/development

TeX L648/L1167–1200: `code/scale_development/scale_development_status.csv`, full IRF series, and three original MAT files verify r=1/1.5/2; s1=.5/.550510257216822/.585786437626905; unit GDP ratios = 1, sqrt(1.5), sqrt(2); GDP weights=.5/.6/.666666666666667; imports each=.075; d_ann=.4/1.0. Actual trade weights (.85,.85),(.875,.8125),(.8875,.775). Table 3-decimal display of half-way values is harmless rounding (L1191 .812, L1192 .887).

Original MAT first IRFs divided by original MAT own steady states:

|r|DS2 normalized t1|IG2 normalized t1|GDP2 normalized t1|
|---|---:|---:|---:|
|1|.175234679092437|-.00402098194074498|-.00235809765349249|
|1.5|.176836792819223|-.00404580566990539|-.00237248608249338|
|2|.177615582735215|-.00405807414929271|-.00237875811016475|

Matches L1190–1192 and L1200 percentages. These are own-steady relative responses, not percentage points or raw level gaps, as current captions correctly state.

### F3. Figure 4 and demand rule moments

TeX L667–704: `code/demand_monetary/figure4_stability_sync_grid.csv` has exactly 30 actual nodes, d1=.4, d2=.8/1/1.2/1.4/1.6 and phi_pi=1.1/1.3/1.5/2/2.5/3. Each six-node curve has increasing output-gap SD and decreasing inflation SD; at each fixed phi_pi both SDs increase with d2. All monotonicity assertions in L704 hold.

`negative_demand_policy_tradeoff_metrics.csv` matches original MAT `oo_.var` and `oo_.var_list` for all five displayed baseline-debt policy nodes. Direct formulas used sd_i=100*sqrt(Vii), gapSD=100*sqrt(Vii+Vjj-2Vij), corr=Vij/sqrt(Vii*Vjj).

Table L681–685 is precisely the correctly rounded matrix:

|phi_pi|sd Pi*100|sd Y*100|sd gap*100|corr Y1Y2|sd DS gap*100|
|---|---:|---:|---:|---:|---:|
|1.1|.365|.490|.071|.991|.863|
|1.5|.300|.370|.121|.952|.776|
|2|.239|.285|.164|.847|.727|
|2.5|.199|.247|.193|.741|.717|
|3|.171|.232|.214|.682|.722|

Inflation SD decline =53.0532508123%, correctly 53.1% in L669.

### F3. Demand regional-balance moments

TeX L722/L735/L739: all six moments directly recovered from each of the five original MAT covariance matrices match `code/extension_scenarios/demand_regional_balance_moments.csv` (max error 2e-15). The zero-rule MAT steady state, full `oo_.var`, and every `oo_.irfs` vector are bitwise equal to `negative_demand_baseline_policy` MAT (independent array comparisons, not only the archived check CSV).

phi_reg 0->2:
- output-gap SD .120532041148255 -> .0795662361040578: -33.9874813817%.
- correlation .951657645014868 -> .988789901946459.
- inflation SD .300091544499426 -> .489678084292311: +63.1762351416%.
- national output SD .369572576451149 -> .453270557589896: +22.6472380452%.
- DS-gap SD .775608634287865 -> .939834274338553: +21.1737766691%.
- IG-gap SD .199596729741069 -> .134221409754767: -32.7537029645%.

phi_reg 0->.5: gap SD -12.1631038489%, inflation SD +18.1097794688%, output SD +6.8094792434%. All paper rounded values match, including interpretation that DS-gap increases while IG-gap falls. No full welfare or optimal-coefficient conclusion is claimed.

### F3. OccBin archived path

TeX L774/L813: raw MAT `code/policy_counterfactual/policy_cf_strict_debt_cap/Output/policy_cf_strict_debt_cap_results.mat` has `oo_.occbin.simul.regime_history.regime=[0,1,0]`, `regimestart=[1,2,3]`. Thus ONLY q2 binds. `piecewise` is 40x79; b2 at q1/q2/q3=4.00474051850073/4.008/4.00458542484918; xicap2=0/.490137272942762/2.51e-17. This agrees with `occbin_regime_history.csv`.

Using `policy_counterfactual_irf_series.csv`, strict-minus-baseline differences:
- IG2 minimum -.0093808736479189 at q2; first positive q9.
- GDP2 minimum -.0059156627194442 at q2; first positive q7.
- KG2 minimum -.0336959740542949 at q7; first positive q20.

All current text timing matches. It correctly distinguishes relative ordering reversal from recovery to steady state and uses raw Dynare end-period public capital convention.

### F3. Transfer feedback

TeX L784/L830: `policy_counterfactual_transfer_irf_series.csv` independently gives rho_z=.7, phi_z_ds=.015, phi_z_b=.005. Transfer increment peak=.001198528565181 at q3. IG2 min=-.0013471229700648 at q8 versus no-feedback -.0017223316951065: magnitude improves 21.7849283101%. KG2 min=-.0161732802430379 at q22 versus -.0207173236391807: 21.9335444833%. KG2 at q40=-.0114781578514789. Correct displayed 21.8%,21.9%,-.011478.

### F3. Stackelberg A/B and sensitivity

TeX L661/L1344–1363: independently sum archived `sensitivity_gap_irf_series.csv` periods1:12 for baseline, after confirming normalized high-minus-low definition:

|variable|sum A|sum B|sum(B-A)|
|---|---:|---:|---:|
|IG|-.0839373035505624|-.0843734437383539|-.00043614018779154|
|KG|-.0111311400480733|-.0112067116537034|-.0000755716056301723|
|GDP|-.00555170370753830|-.00556543442104010|-.0000137307135017473|

All three rounded table rows match. Nine archived sensitivity scenarios produce 81 (variable,scope) comparisons, all classification SMALL, sign preserved and high/low ordering preserved. Max effective ratio .0206337954982484 at chiIG_low (IG, low debt). Current paper does not reintroduce the removed old Reff/R_eff government-sensitivity indicator; only narrow local-response comparisons are stated.

### F3. Extension scenarios and monetary regional rule

TeX L1421–1464: raw original MAT IRFs for all six extension scenarios, full40 quarters, support current qualitative statements:
- Risk only: DS gap remains positive throughout (q40 .0000374608), IG trough -.0019049192 q9, KG -.0242227887 q24, GDP -.0010394134 q8; amplified versus baseline.
- Transfer only: IG gap trough -.0003569204, KG -.0040017540, GDP -.0001930144; negative gap amplitudes reduced.
- Joint risk+transfer: IG gap positive in early/middle quarters (max .00045453284948, slight negative tail), KG gap positive throughout (max .0051693080), GDP gap positive all40 (range .0000201016810 to .0002340520688). Text correctly limits IG claim to early/middle and distinguishes relative from absolute response.
- Strong IO: GDP gap is closer to zero in EVERY quarter than baseline, ending -.0000206901578 versus baseline -.0001233137921.
- Weak IO: GDP-gap initial trough -.000521759999 at q6 is shallower than baseline -.000547427696 at q7, but q40=-.0002112722083 is more persistent. Relative to baseline, crossings occur at q5 and q18. Current text correctly avoids a globally monotonic weak-link assertion.
- Extension design MAT/model parameter values agree with table: risk coefficient .05; extension transfers rho_z=.5, phi_z_ds=.2, phi_z_b=0; strong IO(.70,.75), weak IO(.95,2.50).

TeX L1483 `policy_counterfactual_regional_balance_summary.csv`: standard/regional values are GDP-gap L2 .00206753427219/.00126781327156; max GDP gap .000547427696338/.000334543470003; max IG gap .0010279337778/.000627176986612; national inflation L2 .00206071968749/.00347378132143. All six-decimal paper values match. Caption correctly separates finite40 IRF L2 from unconditional moments.



---

**FINAL FREEZE STATUS: PASS**

- Core structural equations: certified consistent with code.
- Steady state and timing: certified consistent.
- Household financial implementation: internally feasible conditional on the stated non-distortionary settlement and compatible initial wealth.
- zeta: intentionally retained as a reduced-form asset-specific wedge; not claimed to be deeply microfounded.
- No core .mod modification is required.
