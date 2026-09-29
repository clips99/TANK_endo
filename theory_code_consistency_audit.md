# RANK_endo：理论推导—论文方程—Dynare 代码独立一致性审计

审计日期：2026-09-28。审计对象为当前工作目录中的正式源码；本轮只生成本报告，没有修改论文、模型、稳态程序、参数或数值结果。下述行号均指本次审计时的源文件。

## 1. 总判定与认证边界

**基准 78 条及 Stackelberg 86 条逐期方程的代数、符号和时点可以逐项对应；但目前不能对“经济优化问题 → 全部均衡和金融账户 → 论文 → 所有正式模型”作无保留的完全一致认证。** 主要障碍是家庭预算及需求楔子的微观实施说明不足、OccBin 的论文方程展示不完整，以及两处沿用旧结果的“三倍”表述。

本报告区分三件事：①代码有没有忠实实现论文已列出的方程；②这些方程能否从所声称的优化问题推得；③报告的经济解释与数值结果是否一致。①成立不能代替②或③。

| 用户要求明确回答的问题 | 审计结论 |
|---|---|
| 是否发现真正理论/求导错误？ | 未发现所审家庭劳动/资本/投资、CES、Calvo、基准政府、Stackelberg FOC 的确定性代数或随机时点错误。**但 ζ 的无摩擦家庭优化推导不成立；论文只称其为缩约金融楔子，没有给出足以验证的摩擦结构。按本次要求标 B“需要补充解释”，不把缺失的微观基础自动认证为正确。** |
| 是否发现论文—代码不一致？ | 核心 78/86 条已列逐期等式未发现 C 级公式差异。数值文字发现 C 级不一致：TeX L595、L608 的“接近三倍”不支持于当前 0.40/1.00 结果。OccBin 的 KKT 在代码中存在、论文未完整列出，属于 B 级展示缺口。 |
| 是否存在只需解释/展示修正的问题？ | 有：家庭完整预算、资产定价与基金实施，ζ 的明确来源，OccBin 的完整互补系统，L319 将 Stackelberg 描述成包含“消费条件”，以及 FS 中“本金滚动”的确切计量含义。 |
| 哪些方程需要修改？ | 当前证据不要求改写 78/86 条既有等式。应**补充**家庭预算/证券与中介账户、资产特定楔子的原始结构，以及 OccBin 的 KKT 和 regime 方程。若选择的微观结构不能精确实现现有 Euler，则须另行决定修改 Euler 及相关定价核；不能由本次审计擅自选择。 |
| 哪些 `.mod` 必须修改？ | 没有发现必须立即改动某个正式 `.mod` 的已证实公式错误。需求楔子涉及所有基准派生 A/B 模型；只有在后续选择改变其结构时才需要同步改动。OccBin 目前应补论文，非删除代码中的债务 KKT。 |
| 修改是否会改变稳态/IRF？ | 更正文案、补写当前约束不改变已有稳态/IRF；账户实施只有在严格支持现有配置且不新增非冗余约束时才保持结果不变。若引入真实资源金融成本、改变定价核或新增非冗余资产约束，可能改变 IRF，甚至稳态；需要重新求解。 |
| 能否认证“paper equations = code equations”？ | **对已列明的基准 78 条、Stackelberg 86 条：可以作限定的逐式代数一致认证。对完整论文所声称的微观经济及所有扩展：暂不能无保留认证。** |

### 1.1 模块等级

A = Correct and exactly matched；B = Correct but exposition/interpretation needs clarification；C = Paper–code / paper–current-results mismatch；D = Theoretical/derivation error。B 不表示已补齐微观基础；表中明确区分“可成立但缺实施说明”和“公式已经证明”。

| 模块 | 等级 | 核心理由 |
|---|---|---|
| 家庭劳动、私人资本、投资 FOC 与资本 TVC | A（在一次性结算对家庭边际决策外生的条件下） | 成本链式导数、期初资本、未来收益和边际效用比一致。 |
| 家庭完整预算、完备证券/本地资本实施 | B，高优先级 | 资源闭合可证明，金融实施可构造；论文未列逐期家庭预算和资产对手账，给定初始财富下的实施不能由一句“残差”替代。 |
| ζ 仅进入无风险 Euler | B，高优先级 | 代数一致；现有原始效用与无摩擦资产约束不能产生该楔子。需明确资产特定便利服务/金融摩擦。 |
| 最终品 CES、四个相对价格 | A | 零利润、需求、三个动态关系与交叉恒等式一致。 |
| 中间品技术、报酬、GDP、利润、Calvo | A | 特别核对了价格离散度 V 的位置及两个递归的通胀幂次。 |
| 基准地方政府及终端条件 | A，限论文声明的局部有界内点问题 | 从原始 Lagrangian 独立求导；不声称全局最优性或任意随机路径的终端可行性。 |
| DS、FS 定义及预算恒等式 | A；FS 滚动口径说明 B | DS 已明确为净实际债务服务率，非普通票息率。 |
| 全国价格换算、GDP/吸收、实物资源账户 | A | 换算方向正确；全国 GDP 等于全国最终吸收可由零利润和贸易清算推出。 |
| 中央/家庭/中介金融分配实施 | B，高优先级 | 全国合并恒等式无遗漏；独立地区税费、融资头寸和初始财富未唯一识别。 |
| Taylor、需求/货币冲击、地区平衡规则 | A（需求冲击结构沿用上述 B） | 非线性式与一阶含义一致，地区项位于平滑目标内。 |
| Stackelberg 全部 FOC、四乘子、timeless 稳态 | A；范围文字 B | 五组驻点条件及历史乘子正确；L319 的“消费条件”误述内生化范围。 |
| OccBin 数学实现/真实绑定路径 | A；论文完整展示 B | 限制实际余额 B2，代码有乘子；论文需补 KKT、互补及 slack/bind 方程。 |
| 风险报价与转移反馈 | A（缩约取价制度） | 原子化政府取报价/拨付路径为给定，不应添加报价斜率。 |
| 独立稳态与附录 B/MATLAB/`.mod` | A | 下文报告独立计算及逐变量比较。 |
| 全文数值解释 | C，限已定位文字 | 当前三项峰谷比约 2.5，而非约 3；不涉及重新校准。 |

## 2. 审计方法、文件范围与独立性

正式主文件：`RANK_DSGE_endo.tex`。基准 A：`code/baseline/RANK_two_region_baseline.mod`；扩展 B：`code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod`；比较 A：`code/stackelberg_B/robustness/scheme_A/RANK_two_region_scheme_A.mod`。政策、需求、债务、规模和敏感性实验的正式 `.mod` 也检查模型结构与声明差异。

没有执行现有 `validate_all_models.m`、`audit_rank_solution.m`、`audit_occbin_rank.m` 或既有 `symbolic_check.py`。本次先以原始目标函数/成本函数/清算恒等式手工重新推导，再读取既有稳态程序作比较；另用临时独立脚本解析逐期方程、代入自行计算的稳态、核对当前数据。既有 PASS、BK 和“已验证”文字不作为理论正确性证据。

独立的政府审查还从三层历史树 Lagrangian 对七类选择作数值偏导，在非稳态且 β≠βG 的节点上检验贴现和历史时点，未调用项目的既有求导检查。本报告给出公式本身，避免将该数值检查代替推导。

参考软件语义仅用于解释 Dynare 的时点：`predetermined_variables` 将用户期初存量记号转成内部期末存量，IRF 展示的是本期决定的下一期资本；随机模型通常以当期信息对含 lead 的方程取条件期望。参见 [Dynare 7.0 官方手册](https://www.dynare.org/wp-repo/dynarewp087.pdf)。这不是对经济理论正确性的外部背书。

### 2.1 全部正式模型的结构覆盖

递归检查当前 `code/` 下 **54 个 `.mod`**，对 `model` 的逐式内容和同名局部定义比较，去除注释、空白和 equation name 标签。36 个 A（26 个普通模型、10 个带标签的比较/敏感性 A）结构相同；10 个 B 结构相同；7 个地区平衡版本仅 Taylor 项变化；1 个 OccBin 仅地区2债务KKT和互斥附加条件变化。共有局部 `#` 定义未发现漂移。地区平衡的两种多余括号写法代数等价，φreg=0退化回标准规则；OccBin 源文本两条互斥标记不应同时作为一个 regime 计数。

未发现未声明的方程增删或实验间意外结构漂移。参数、冲击、稳态目标不同仍按各实验设计分别核对，不因方程相同就声称校准相同。

## 3. 家庭：独立推导与不能省略的实施条件

以下先压去地区下标。记 ℓ_t=Λ_t=C_t^{-σ}，x_t=I_t/I_{t-1}，S(x)=φ_I(x−1)²/2，m_{t+1}=Λ_{t+1}/Λ_t。私人资本积累是

\[
K_{t+1}=(1-\delta_K)K_t+[1-S(x_t)]I_t.
\]

### 3.1 完整预算应如何写；当前论文缺少什么

用本币名义变量避免混用地方/全国实际单位。令 H_t^j 为本期买入的无风险资产本金，X_{t+1}^j(s^{t+1}) 为本期购买、下一状态兑现的名义保险索取权，Q_t^N 为包含概率的名义状态价格算子，T_t^{j,N} 为一次性净支付。含潜在资产摩擦成本 F_t^{j,N} 的家庭预算必须形如

\[
P_t^j(C_t^j+I_t^j)+H_t^j+
\sum_{s^{t+1}|s^t}Q_t^N(s^{t+1}|s^t)X_{t+1}^j(s^{t+1})+F_t^{j,N}
=P_t^j(W_t^jN_t^j+R_{K,t}^jK_t^j+\Omega_{M,t}^j)
+R_{t-1}H_{t-1}^j+X_t^j-T_t^{j,N}.
\]

若另列中央分红或银行利润，须从 T 中剔除相同项目；若直接采用净资产而非 H/X 分拆，也须明示其支付与购买价格。这里不是断言当前论文已采用此预算，而是展示验证其最优条件不可缺少的原始对象。现稿 L97–122、L1480、L1633 未列上述预算或等价形式；仅有基金净头寸清算和终端条件不能替代交易流量。

一次性税费必须是家庭优化时给定的状态依赖支付表。不能先令 T_t=WN+RK K+利润−C−I，再允许家庭把这一定义视为自身 C/I/N/K 的可操纵函数求导；那样会改变甚至消除所列最优条件。均衡后反推税费可以是实现配置的方法，但需要说明政策支付表的承诺和原子化取价含义。

### 3.2 无摩擦资产定价、风险分担与 ζ

在 F=0、现稿所列消费劳动效用且资产内点持有时，消费与名义证券的一阶条件给出

\[
Q_t^N(s'|s)=\beta p(s'|s)\frac{\Lambda_{t+1}^j/P_{t+1}^j}{\Lambda_t^j/P_t^j},
\qquad
\Lambda_t^j=\beta E_t[\Lambda_{t+1}^j R_t/\Pi_{t+1}^j].
\]

相同状态价格使 `(Λ²/P²)/(Λ¹/P¹)` 为常数，所以

\[
\Lambda_t^2=\xi_{12}\Lambda_t^1 P_t^2/P_t^1
=\xi_{12}\Lambda_t^1 Q_{1,t}^1/Q_{1,t}^2.
\]

这个方向正确；并不要求 C¹=C²。地区 2 的同类债券 Euler 可用风险分担、相对价格动态和地区 1 Euler 推出，因此不需另加第 79 条方程。

**现稿的 ζ 不能直接从上述无摩擦问题得到。** 按论文 `Λ=β E[Λ' R/Π']e^{−ζ}`，基本消费定价核隐含 `E[M^N R]=e^ζ`。一份普通无风险债若也可由完备证券复制，且没有资产服务或交易摩擦，则必须等于 1。ζ≠0 时二者不相容。称其为“需求冲击”并不能解除这个约束。

可以构造支持现有式子的资产特定结构。例如，对政策相关流动债券设置购买价附加项，边际总购买成本为 e^ζ，而现金支付仍为 R；相应 FOC 为 `e^ζ Λ=β E[Λ'R/Π']`。资本、普通保险索取权和企业股权没有该项时，其贴现核可保持不变。但必须进一步明确：家庭可进入哪些市场、政策融资与保险资产如何隔离或结算、费用/补贴由谁承担、同支付复制为何不消除摩擦。或者令 h=H/P^j 为本地实际流动资产持有量，引入其边际便利效用；FOC 需要 `v_h/Λ=1−e^ζ`，也须给出具体效用与持有量结构。两者不是现稿已经完成的推导。零均值 AR 过程允许 ζ 正负变化，而 ζ>0 时 `1−e^ζ<0`，所以单纯非负“便利收益”的口头解释也不够，须容许持有成本或等效金融摩擦。

因此，对用户重点问题 1 的结论为：**原则上可以支持；当前论文证据不足，B“需要补充解释”。** 不应将 ζ 当作一般时间偏好冲击后仍任意从资本 Euler 和 Calvo 核中删除；一般偏好贴现冲击通常会影响所有跨期收益的估值。若采用便利效用，福利的效用定义也需相应解释；若采用纯金融费用/补贴，须补对手账。

### 3.3 劳动、资本与投资的一阶条件

将第 3.1 节的名义预算除以 P_t^j 后，本地实际预算乘子为 Λ；未平减的名义预算乘子则为 Λ/P_t^j。资本约束乘子写成 Λq_K。对 N_t 求导得到 `χ_N N_t^φ=Λ_t W_t`。对本期选择的 K_{t+1} 求导，只有本期的负资本约束项和下一期的租金、未折旧价值：

\[
q_{K,t}=\beta E_t\{m_{t+1}[R_{K,t+1}+(1-\delta_K)q_{K,t+1}]\}.
\]

令 A_I(x)=1−S(x)−xS′(x)，B_I(x)=x²S′(x)。投资有两个边际作用：

\[
\partial_{I_t}\{[1-S(I_t/I_{t-1})]I_t\}=A_I(x_t),\quad
\partial_{I_t}\{[1-S(I_{t+1}/I_t)]I_{t+1}\}=B_I(x_{t+1}).
\]

于是

\[
1=q_{K,t}A_I(x_t)+\beta E_t[m_{t+1}q_{K,t+1}B_I(x_{t+1})].
\]

下一期项为正、比率为平方，当前代码均正确。S 是安装效率损失，已经用同一 I 支出形成更少资本，不能再把 `S I` 加到资源约束右侧。私人资本 TVC `lim β^{T−t}E_t[Λ_T q_{K,T}K_{T+1}]=0` 与本期资本选择记号一致。保险资产另需状态价格下的 TVC，二者不能互相替代。

## 4. 企业：CES、相对价格、技术、利润与 Calvo

最终品技术为 `D=[ω^{1/η}M_local^{(η−1)/η}+(1−ω)^{1/η}M_foreign^{(η−1)/η}]^{η/(η−1)}`。支出最小化的乘子为最终品价格；对两种 M 的 FOC 及零利润得到

\[
(P^j)^{1-\eta}=\omega_j(P_M^j)^{1-\eta}+(1-\omega_j)(P_M^{-j})^{1-\eta},\quad
M_j^j=\omega_j(Q_j^j)^{-\eta}D^j,\quad M_{-j}^j=(1-\omega_j)(Q_{-j}^j)^{-\eta}D^j.
\]

四个 Q 都是 P_M/P^j，因此三个增长率 `Q11/Q11_−=ΠM1/Π1`、`Q21/Q21_−=ΠM2/Π1`、`Q12/Q12_−=ΠM1/Π2` 加 `Q11 Q22=Q12 Q21` 已够。最后一式推出第四条动态关系；再加入它会冗余。初始价格必须满足交叉恒等式，当前稳态 Q=1 满足。

企业单品种技术对私人 K,N 为常报酬，公共 KG 为外部生产条件。所有品种在同一要素价格下采用相同 K/N，积分后有

\[
Y_M V=A K_G^{\gamma_G}K^\alpha N^{1-\alpha},\quad
W=(1-\alpha)Q\,MC\,Y_MV/N,\quad
R_K=\alpha Q\,MC\,Y_MV/K.
\]

GDP 为售出中间品价值 `Y=QY_M`，不是 `QY_M V`，也不是 D。因 `WN+R_KK=QMCY_MV`，利润恰为

\[
\Omega_M=QY_M-QMCY_MV=Y(1-MC V),\qquad WN+R_KK+\Omega_M=Y.
\]

所以离散度应出现在要素成本和聚合生产关系中；收入不能多乘 V。GDP 联动财政收入按一次性结算实现时不改变企业边际成本，否则必须重推企业 FOC。正文已经声明其不是企业面对的边际产出税。

对 Calvo 重置名义价格 p*，将未来品种需求 `(P*/P_{M,t+h})^{−ε}Y_{M,t+h}` 代入预期贴现利润并求导，边际收入和成本的相对价格幂分别为 ε−1 和 ε。故独立所得递归为

\[
\mathcal P_{1,t}=\Lambda_tQ_tMC_tY_{M,t}+\beta\theta_p E_t[\Pi_{M,t+1}^{\epsilon_p}\mathcal P_{1,t+1}],
\]
\[
\mathcal P_{2,t}=\Lambda_tQ_tY_{M,t}+\beta\theta_p E_t[\Pi_{M,t+1}^{\epsilon_p-1}\mathcal P_{2,t+1}],\qquad
p_{*,t}=\frac{\epsilon_p}{\epsilon_p-1}\frac{\mathcal P_{1,t}}{\mathcal P_{2,t}}.
\]

这里 Λ 已包含在递归变量定义中，未来项不应再乘一次 Λ'/Λ；Q 负责本地最终品单位换算。Calvo 价格分布直接给出

\[
1=(1-\theta_p)p_*^{1-\epsilon_p}+\theta_p\Pi_M^{\epsilon_p-1},\qquad
V_t=(1-\theta_p)p_*^{-\epsilon_p}+\theta_p\Pi_{M,t}^{\epsilon_p}V_{t-1}.
\]

论文主文、附录和两份正式模型在这些细节上均一致。

## 5. 地方政府：从原始 Lagrangian 重新求导

令 τ_L=(1−θ_T)τ_Y，r^B_{t−1,t}=R_{B,t−1}/Π_t，g_t=I_{G,t}/I_{G,t−1}。政府当期 Lagrangian 为

\[
\omega_Y\log Y_t+\Lambda_{G,t}[B_t-r^B_{t-1,t}B_{t-1}-G_t-I_{G,t}-\Phi_{I,t}-\Phi_{B,t}+\tau_LY_t+Z_t]
+q_{G,t}[(1-\delta_G)K_{G,t}+I_{G,t}-K_{G,t+1}],
\]

在 `E_0 Σ β_G^t` 内求和。这里 Λ_G 和 q_G 都是当前值乘子，不是已贴现乘子；工资、租金、消费的 Λ 与 Λ_G 不可混用。

成本的三个关键导数独立为

\[
\Phi_{I,t,I_{G,t}}=\chi_I(g_t-1)g_t+\frac{\chi_I}{2}(g_t-1)^2,
\]
\[
\Phi_{I,t+1,I_{G,t}}=-\chi_I(g_{t+1}-1)g_{t+1}^2,
\qquad
\Phi_{B,t,B_t}=\varphi_B(B_t/\bar Y-\bar b).
\]

后一成本的外乘 \(\bar Y\) 与求导的除数抵消；没有额外 `1/Ybar`，也没有当期 Y 的内生导数。三条选择条件是

\[
\Lambda_{G,t}(1+\Phi_{I,t,I_{G,t}})=q_{G,t}-\beta_G E_t[\Lambda_{G,t+1}\Phi_{I,t+1,I_{G,t}}], \tag{G-IG}
\]
\[
q_{G,t}=\beta_G E_t[(1-\delta_G)q_{G,t+1}+\gamma_G(\omega_Y+\Lambda_{G,t+1}\tau_LY_{t+1})/K_{G,t+1}], \tag{G-KG}
\]
\[
\Lambda_{G,t}[1-\varphi_B(B_t/\bar Y-\bar b)]
=\beta_G E_t[\Lambda_{G,t+1}R_{B,t}/\Pi_{t+1}]. \tag{G-B}
\]

对乘子求导则恢复预算与 KG 积累。IG 的下一期成本项符号正确：它是分母的直接导数，绝不是对未来最优投资作全导数。KG_{t+1} 本期选定，而未来税基/乘子随下期状态变化，必须保留 E_t。债务也是本期 B_t 选择、下期按本期合同利率偿付。

论文声明政府把报价和中央拨付过程作为给定，因此没有 `∂RB/∂B`、`∂Z/∂B` 或 `∂Z/∂Y` 项。求导前把代表性同类地区总债务率误当成单个辖区可操纵的量，才会产生不同的 FOC。当前模型没有这种错误。Scheme A 对私人 K,N 固定是**决策范围假设**，并非声称一般均衡里的 K,N 固定。

终端方面，资本 TVC 使用 `β_G^{T−t}q_{G,T}KG_{T+1}`，与资本选择一致；债务限制使用累计实际合同回报的倒数对 B_T 折现。对当前零通胀、R=1/β>1 的正稳态，两者均趋零；在持续靠近该稳态、回报与乘子有界且适当可积的路径上可成立。不能从 40 期 IRF 或单个 BK 通过推断所有非线性随机路径的全球无庞氏性质，也不应在第 40 期强制资本/债务等于稳态。这些终端限制不属于 78 条逐期方程。

## 6. DS、FS 与实际本金重估

直接从地方预算移项，不借助现成 DS 定义，可以写成

\[
B_t-B_{t-1}=I_{G,t}+\Phi_{I,t}+\Phi_{B,t}
-\{\tau_LY_t+Z_t-G_t-(R_{B,t-1}/\Pi_t-1)B_{t-1}\}.
\]

因此代码 `fs` 是花括号内的最终品**水平量**，`ds` 是净实际债务服务**除以当期 GDP 后的比率**。必须区别 `DS_t` 和 `DS_t Y_t`。

\[
(R_B/\Pi-1)B_- = (R_B-1)B_-/\Pi+(1/\Pi-1)B_-.
\]

第一项为名义票息的本期实际值，第二项为相对上期实际本金的重估。**对用户重点问题 2：应称“净实际债务服务（率）”或“相对上一期实际本金的偿债负担”，不能笼统称普通利息支出。当前正文 L398–418 已基本采用正确名称。** 净负担可以为负，不意味着合同票息为负。

FS 对应保持**实际余额** `B_t=B_{t−1}` 的基准。若所谓“滚动本金”指保持名义本金不变，则本期发行的实际本金应为 `B_{t−1}/Π_t`，相应可投资余量是 `τ_LY+Z−G−(R_B−1)B_{t−1}/Π_t`。两口径差 `(1/Π_t−1)B_{t−1}`。建议 L413、L418 明写“维持上期实际本金余额”，无需改现有定义和代码。

在零通胀稳态作一阶水平分解：

\[
\Delta DS_t=\frac{\bar B}{\bar Y}\Delta R_{B,t-1}
-\frac{\bar R_B\bar B}{\bar Y}\Delta\Pi_t
+\frac{\bar R_B-1}{\bar Y}\Delta B_{t-1}
-\frac{\overline{DS}}{\bar Y}\Delta Y_t.
\]

这说明当期 r_t 不能直接替代 r_{t−1} 进入既有债务服务，也说明 DS 的变化不纯粹是利息率变化。当前公式和解释方向一致。

## 7. 全国价格、资源与金融账户闭合

记 p_j=P^j/P，`P=(P¹)^υ1(P²)^υ2`。由 Q12/Q11=P¹/P²，得

\[
p_1=(Q12/Q11)^{\upsilon_2},\qquad p_2=(Q11/Q12)^{\upsilon_1}.
\]

地方实际流量换成全国价格单位应**乘 p_j**。全国 GDP、吸收和通胀分别为 `Y=Σ s_j p_jY_j`、`D=Σ s_j p_jD_j`、`Π=Π1^{υ1}Π2^{υ2}`，与代码方向完全一致。s 是地区测度，υ 是稳态 GDP 权重，一般不可互换。

### 7.1 实物账户的严格冗余证明

CES 零利润给出 `P_jD_j=Σ_k P_M^k M_k^j`。乘 s_j 并对使用地求和，再用来源地清算 `Σ_j s_jM_k^j=s_kY_M^k`，得到

\[
\sum_j s_jP_jD_j=\sum_k s_kP_M^kY_M^k=\sum_j s_jP_jY_j.
\]

故全国 `D=Y` 是这些条件的推论，地方则允许 `D_j≠Y_j`。令 `NX_j=Y_j−D_j`，有 `Σ s_jp_j NX_j=0`。再代入两地区资源约束及利润恒等式，得

\[
\sum_j s_jp_j(W_jN_j+R_{K,j}K_j+\Omega_{M,j}-C_j-I_j)
=\sum_j s_jp_j(G_j+I_{G,j}+\Phi_{I,j}+\Phi_{B,j}). \tag{AC-R}
\]

该式证明生产端收入与全部真实支出一致。Z、债券发行和偿付均未再次进入实物资源需求；私人安装效率损失不额外加一遍；公共投资/债务管理成本各计一次。**在实物资源系统中，未发现遗漏、重复计入或未闭合流量。**

### 7.2 财政和中介的合并账户

定义地方新融资净流量 `L_j=B_j−R_{B,−1}B_{j,−1}/Π_j`。地方预算意味着

\[
H_j\equiv G_j+I_{G,j}+\Phi_{I,j}+\Phi_{B,j}=\tau_LY_j+Z_j+L_j.
\]

中央余额 `S^C=Σ s_jp_j(θ_Tτ_YY_j−Z_j)`。于是

\[
\sum_j s_jp_jH_j=\tau_Y Y-S^C+\sum_j s_jp_jL_j. \tag{AC-F}
\]

式 AC-F 与 AC-R 严格相容：向私人部门收取 GDP 联动税费、返还中央正余额（或收取缺口），加上购买地方债的净资金，恰好覆盖真实公共支出。**全国合并所需的是中介“净融资流量”，不只是“净利差”。** 若中介借入无风险资金，须另列其融资负债及向家庭支付的回报；利差只是取消两边本金后出现的一部分。

### 7.3 家庭预算何时可从其他条件冗余；目前证据的限度

可给出一种明确的存在性构造。把中介/地方债的全部净流量在两地区分配为 \(L_j\) 对应的家庭资金用途，把中央余额按任意 \(c_j\) 分配且 `Σ s_jp_j c_j=S^C`，定义一次性公共净支付 `T_j=τ_YY_j−c_j+L_j`。则

\[
Y_j-T_j-(C_j+I_j)=NX_j+H_j-T_j\equiv f_j,
\qquad \sum_j s_jp_j f_j=0.
\]

由零和的保险/结算支付 `−f_j` 可逐地区补足家庭预算；全国该项完全抵消。如果将这些状态支付写入预先承诺的一次性税费表，即取 `T_new,j=T_j+f_j`，也可以选择零净证券头寸，基金清算和金融 TVC 自动满足。这个构造说明当前实物配置**可以嵌入**某个具有非扭曲、状态依赖结算的金融实施；不是发现了实物资源缺口。

但是：这项构造选择了支付分配和初始转移，不能证明“任意给定初始财富与任意既定地区税制都能实施”。若坚持仅用有偿交易的完备证券、固定初始财富、固定税费安排，就必须检查各家庭的状态价格现值预算/无庞氏条件，并由此确定 ξ12。零和当期支付本身不证明各家庭终身现值预算。正文未给相应地区分配表、中介资金来源及最初保险合约，因而**家庭预算的条件性冗余已可证明，当前论文所述特定家庭实施的充分性尚未证明**。

这里已将第 3.1 节分列的政策债券 H 的购买/兑付、费用 F 及其对手账纳入 T 的净金融结算；a 只表示剩余的保险资产，不能再重复计入 H 的流量。把该完备证券的当期到期支付记为共同价格单位的 a_t^j，购买成本为 E_t[M^C_{t,t+1}a_{t+1}^j]。预算与基金 TVC 迭代后，必须有

\[
a_0^j=E_0\sum_{t\ge0}M^C_{0,t}p_{j,t}(C_t^j+I_t^j-Y_t^j+T_t^j).
\]

全国零和仅保证右端所需初始财富的加总为零，不能保证它等于每户**预先给定**的 a_0^j。正文 `𝒜_t` 只称期末净头寸，仍应补充它与 a_t 到期支付、当期购买价的关系。另须区分“共同基金不直接持有地方债”与“家庭不承受任何地方财政收入风险”：财政/金融净流量仍可间接进入家庭税费和收入。

对用户重点问题 3：本地资本与完备风险分担在理论上完全可以共存。资本留在本地，跨地区证券保险其收入风险，无需把资本搬到另一地区。真正缺口在资产支付、财富和残差税费的实施说明，而非“本地资本”和“完全风险分担”本身冲突。

对“是否存在遗漏、重复计入或未闭合的资源/金融流量”的直接回答是：**资源流量无遗漏或重复；全国合并金融净流量可严格配平；地区家庭—中介—共同基金的逐项金融实施没有完整写出，不能认证为已展示并唯一闭合。** B 级问题是金融结构和分配规则的缺失，不是当前 `.mod` 多出或少消耗了一笔最终品。

## 8. Stackelberg：独立历史节点推导

政府接受 Λ 路径、价格、MC、V、A、政策及报价。以私人劳动、资本积累、资本 Euler、投资 FOC 的剩余依次记 F_N,F_K,F_Q,F_I，对应乘子 ν_N,ν_K,ν_Q,ν_I；将 `ΣνF` 加入第 5 节的政府 Lagrangian。符号采用论文的剩余方向：F_N=χN^φ−ΛW，F_K=(1−δK)K+(1−S)I−K'，F_Q=q−βE[m(RK'+(1−δK)q')]，F_I,t=1−q_t A_I(x_t)−βE_t[m_{t+1}q_{t+1}B_I(x_{t+1})]。

先移去嵌套条件期望，使用 `E[ν_t E_t X_{t+1}]=E[ν_t X_{t+1}]`。因此上一期私人 Euler 的贡献进入当期边际项时，其贴现比为 β/βG，而非 β 或 1；当前 K_{t+1} 在其所有后继状态上共享，必须对边际收益作 E_t。令 `Θ_t=ν_N,t Λ_t`，`H_t=ω_Y+Λ_G,t τ_LY_t`，`J_t=H_t−Θ_tW_t`。

技术偏导为：`Y_KG=γY/KG`、`Y_K=αY/K`、`Y_N=(1−α)Y/N`；`W_KG=γW/KG`、`W_K=αW/K`、`W_N=−αW/N`；`RK_KG=γRK/KG`、`RK_K=(α−1)RK/K`、`RK_N=(1−α)RK/N`。

独立驻点条件如下。

\[
q_{G,t}=\beta_G E_t[(1-\delta_G)q_{G,t+1}+\gamma_G J_{t+1}/K_{G,t+1}]
-\beta\nu_{Q,t}E_t[m_{t+1}\gamma_GR_{K,t+1}/K_{G,t+1}]. \tag{S-KG}
\]

\[
\nu_{K,t}=\beta_GE_t[\alpha J_{t+1}/K_{t+1}+(1-\delta_K)\nu_{K,t+1}]
+\beta\nu_{Q,t}E_t[m_{t+1}(1-\alpha)R_{K,t+1}/K_{t+1}]. \tag{S-K}
\]

\[
0=\frac{(1-\alpha)H_t+\alpha\Theta_tW_t-(\beta/\beta_G)\nu_{Q,t-1}m_t(1-\alpha)R_{K,t}}{N_t}
+\nu_{N,t}\chi_N\varphi N_t^{\varphi-1}. \tag{S-N}
\]

\[
0=\nu_{Q,t}-A_I(x_t)\nu_{I,t}
-(\beta/\beta_G)m_t[(1-\delta_K)\nu_{Q,t-1}+B_I(x_t)\nu_{I,t-1}]. \tag{S-q}
\]

\[
\begin{aligned}
0={}&\nu_{K,t}A_I(x_t)+\beta_G E_t[\nu_{K,t+1}B_I(x_{t+1})]\\
&+\nu_{I,t}\{-q_tA_I'(x_t)/I_{t-1}+\beta E_t[m_{t+1}q_{t+1}B_I'(x_{t+1})x_{t+1}/I_t]\}\\
&-(\beta/\beta_G)\nu_{I,t-1}m_tq_tB_I'(x_t)/I_{t-1}\\
&+\beta_G E_t[\nu_{I,t+1}q_{t+1}A_I'(x_{t+1})x_{t+1}/I_t].
\end{aligned} \tag{S-I}
\]

其中 `A_I′(x)=φ_I(2−3x)`，`B_I′(x)=φ_I(3x²−2x)`。四项 I 条件的来源分别是本期/下期资本积累、本期 F_I、上期 F_I、下期 F_I。特别是最后一项虽然写“+”，稳态 A_I′(1)=−φ_I，所以不能凭外部正号误判导数。IG、B 的 FOC 不变，KG 被 S-KG 替换，新增 S-K/S-N/S-q/S-I 四条；每地区恰增四乘子，但本结论来自上述逐项导数而非数目相等。

两地区正式代码中的 `muR_j` 对应 ν_N，`muK_j` 对应 ν_K，`muQ_j` 对应 ν_Q，`muI_j` 对应 ν_I；它们不是家庭类型权重。临时历史树独立数值偏导的最大绝对差为 2.18204×10⁻⁹，检验包含 β≠βG 和非稳态投资比率。已列 S-KG 至 S-I 与论文及代码逐项相符。

Timeless commitment 要保留 ν_Q,−1、ν_I,−1 的历史承诺，围绕非零乘子稳态作响应。若改成 t=0 首次承诺，应施加新的初始乘子条件并求转轨，不能沿用现在的 IRF。正文 L1210 已作该区分，但其 Lagrangian 形式仍从 t=0 求和；若要严格推出初始期带历史乘子的方程，应显式附加继承承诺边界（略去与选择无关的项）：

\[
-\frac{\beta}{\beta_G}m_0\{\nu_{Q,-1}[R_{K,0}+(1-\delta_K)q_{K,0}]+\nu_{I,-1}q_{K,0}B_I(x_0)\}.
\]

这是 B 级形式说明补充，当前稳态历史乘子的实现无误；不能把从零新承诺的裸 t=0 问题与 timeless 稳态混同。L319 的“资本、投资、劳动和消费条件”则应改成明确的四项约束；Λ 仍为领导者给定，未加入单独消费/无风险 Euler 乘子。

## 9. 独立稳态推导与三方比较

先使用基本参数和目标 `β=βG=.99, α=.45, γG=.1, δK=δG=.025, εp=6, Y=D=1, IG=.12, G=.10, τL=.08` 计算，之后才与附录 B、MATLAB 稳态程序、`.mod` 校准及 `steady_state_model` 比较。

零通胀下，私人投资 FOC 给 qK=1；Calvo 指数给 p*=1,V=1。无风险 Euler、Calvo 两递归比值与资本 Euler 分别给

\[
\bar R=1/\beta,\quad \overline{MC}=(\epsilon_p-1)/\epsilon_p,\quad
\bar R_K=1/\beta-1+\delta_K,\quad \bar K/\bar Y=\alpha\overline{MC}/\bar R_K.
\]

随后 `I=δK K`，`KG=IG/δG`，`C=D−I−G−IG`，`N=[Y_M/(A KG^γ K^α)]^{1/(1−α)}`，`W=(1−α)MCY_M/N`，`χN=C^{−σ}W/N^φ`。不是从稳态文件倒读这些数值。

基准 IG FOC 给 qG=ΛG。KG FOC 化为

\[
\bar\Lambda_G=\frac{\beta_G\gamma_G\omega_Y/\bar K_G}
{1-\beta_G(1-\delta_G)-\beta_G\gamma_G\tau_L\bar Y/\bar K_G}.
\]

分母 0.0331>0。B FOC 在目标处要求 βG R=1，与 βG=β 相容。`B=(1.6,4)`，`DS=(R−1)B/Y`，`Z=G+IG+(R−1)B−τLY`，`FS=IG`，中央余额由定义计算。

| 对象 | 独立计算值 | 附录 B / MATLAB / `.mod` 比较 |
|---|---:|---|
| R / RB | 1.01010101010101 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| MC | 0.833333333333333 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| RK | 0.0351010101010102 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| K/Y | 10.6834532374101 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| I | 0.267086330935251 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| IG | 0.12 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| KG | 4.8 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| C | 0.512913669064749 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| N | 0.108259193121186 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| W | 4.23366663023501 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| Λ | 3.80111889252538 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| χN | 48.9097810250406 | 附录48.909781025与参数chi_n一致（显示舍入） |
| B1 | 1.6 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| B2 | 4 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| DS1 | 0.0161616161616163 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| DS2 | 0.0404040404040407 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| Z1 | 0.156161616161616 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| Z2 | 0.180404040404041 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| FS1=FS2 | 0.12 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| ΛG=qG（A） | 0.62311178247734 | 一致；附录公式与独立值相符，代码值差≤5×10⁻¹⁴ |
| 企业利润 | 0.166666666666667 | 按定义核算一致；不是额外内生变量 |
| 中央余额 | -0.0482828282828284 | 按定义核算一致；不是额外内生变量 |

比较位置：TeX L1043–1123；基准 `.mod` L98–166、L318–399；`code/baseline/check_steady_state.m` L31–124、L153–157；Stackelberg 的 `solve_stackelberg_ss.m` L4、L13–17，以及其调用的 `solve_stackelberg_ss_for_parameters.m`。基准的 `check_steady_state.m` 是既有结果的检查器，独立计算答案不取自该文件。

独立构造全部内生变量后，代入原始 `.mod` 非线性稳态等式：A 的最大绝对残差为 **4.4408921×10⁻¹⁶**，B 为 **3.5527137×10⁻¹⁵**；独立值与 `.mod steady_state_model` 的最大差分别为 **2.7755576×10⁻¹⁷**、**5.6843419×10⁻¹⁴**。A 与 CSV 78 个值最大差 **4.7961635×10⁻¹⁴**，为输出舍入尺度。本次没有运行 Dynare 或既有 validation 来产生这些结论。

### 9.1 Stackelberg 乘子的独立闭式解

在 βG=β、m=1、x=1 下，A_I=1,B_I=0,A_I′=−φI,B_I′=φI。投资驻点项抵消后给 νK=0；qK 驻点给 νI=δKνQ。令 `H=ω_Y+Λ_G τ_LY`、`T=ν_NΛW`，联立 K 与 N 条件得 `T=−H/φ`，`νQ=−α(H−T)/[(1−α)RK]`。再用 KG 条件：

\[
c=\frac{\gamma_G(1+1/\varphi)}{(1-\alpha)\bar K_G(1/\beta-1+\delta_G)},\quad
\bar\Lambda_G=\bar q_G=\frac{c\omega_Y}{1-c\tau_L\bar Y}.
\]

独立结果为 ΛG=qG=4.36893203883494，νN=−0.167717916947058，νK=0，νQ=−94.3689320388347，νI=−2.35922330097087。与正式 MATLAB 解及 B `.mod` 相符。两套模型的非乘子稳态相同不是两套 FOC 相同，而是同样的配置目标配上不同影子价格；μK=0 是驻点推论，不是为获得 BK 人为删除方程。

## 10. 货币规则、报价及转移反馈

标准规则取对数的一阶式为

\[
\widehat R_t=\rho_R\widehat R_{t-1}+(1-\rho_R)(\phi_\pi\widehat\Pi_t+\phi_y\widehat Y_t)+MP_t.
\]

MP_t 的创新位于平滑目标之外，不乘 1−ρR；`mp=rho_mp*mp(-1)+emp`。需求变量 `d` 对应 ζ，`d=rho_d*d(-1)−ed`，正 ed 产生负 ζ；给定未来边际效用与利率，Euler 使当期 Λ 上升、C 下降，负需求方向成立。需求 Euler 一阶为 `ĉ_t=E ĉ_{t+1}−(r̂_t−Eπ̂_{t+1}−ζ_t)/σ`。

地区平衡型规则在平滑目标内加入 `[(Y2/Ybar2)/(Y1/Ybar1)]^{φreg}`，一阶新增 `(1−ρR)φreg(ŷ2−ŷ1)`。高债务地区相对更弱时该项降低政策利率。它响应稳态标准化生产 GDP 比，而不是最终吸收、债务率或自然产出缺口。非线性比值形式是论文一阶式的正确实现，不应把 φreg 移至整个平滑目标之外。

风险报价 `RB/R=exp[μB((B/Y)/(Bbar/Ybar)−1)]` 与 `exp[mu_b*(dann/d_ann−1)]` 完全等价；分子分母的 4 抵消。稳态目标本身不产生利差，一阶为 `r̂B−r̂=μB(b̂−ŷ)`。其含义是地区总体融资条件的缩约报价，不是已建立违约风险、损失或中介零利润的微观模型。

转移规则使用本期 `DS/DSbar−1` 和**上期** `(B/Y)/(Bbar/Ybar)−1`。因此 φ_Z,DS、φ_Z,B 是对这两个稳态标准化指标的反馈系数，不是转移占 GDP 比率、普通票息弹性或当期债务量系数。DSbar>0 在当前校准满足，故该归一化有定义。

## 11. OccBin：限制、KKT 与真实 regime

正式文件 `code/policy_counterfactual/policy_cf_strict_debt_cap.mod` 的限制是 **B2 的固定实际余额上限**，`debt_cap2=(1+.002)*bbar2=4.008`，不是 `B2/(4Y2)` 的债务率上限。GDP 变化时，binding 下债务率仍可变化。

对政府 Lagrangian 增加 `ξ_t(Bcap−B_t)`，独立 KKT 为

\[
\Lambda_{G,t}[1-\varphi_B(B_t/\bar Y-\bar b)]
=\beta_GE_t[\Lambda_{G,t+1}R_{B,t}/\Pi_{t+1}]+\xi_t,
\quad \xi_t\ge0,\quad Bcap-B_t\ge0,\quad \xi_t(Bcap-B_t)=0.
\]

代码 L294–295 在所有 regimes 保留**含 ξ 的债务 KKT**；L299–302 用 `ξ=0`（slack）或 `B2=cap`（binding）互相替换一条附加方程。这是正确的 79 条系统：binding 时没有再强制无约束债务 Euler 等式。错误做法反而是删除这个含 ξ 的 KKT、或既保留 ξ=0 又强制 B=cap。

切换条件 L328–330 是 `b2−cap>1e−6` 触发 binding，`xicap2<−1e−8` 触发 relax，存在明示数值容差。对当前路径这些容差没有制造额外绑定期。

本次用独立只读 MAT v5 解析器检查原始 OccBin `piecewise` 路径和 `regime_history`，而非把无约束路径超限日期当绑定日期。原始记录 `regime=[0,1,0]`、`regimestart=[1,2,3]`：

| 季度 | B2 水平 | ξ | cap−B2 | regime |
|---|---:|---:|---:|---|
| 1 | 4.00474051850073 | 0 | 0.00325948149927 | slack |
| 2 | 4.00800000000000 | 0.490137272942762 | 0 | binding |
| 3 | 4.00458542484918 | 约 0 | 0.00341457515082 | slack |

40 期最大越限为 0，最大互补乘积绝对值约 5.29×10⁻¹⁸；最小乘子约 −3.07×10⁻¹⁷，为机器精度误差。**仅第 2 季度绑定属实。** 这些是当前分段一阶近似解的检查，不是对原始全非线性最优解的认证。

论文有余额限额和 OccBin 说明，但没有显式列出上述 ξ、KKT、互补条件及 slack/bind 替换。需补入论文才能宣称扩展的“完整 paper equations = code equations”；目前是 B 级展示缺口，没有发现相反的代码方向错误。

## 12. 全文数值及定性表述扫描

已通读 TeX 的模型参数、结果段落、表格、图注、附录和重复于摘要/引言/结论的模型内判断；搜索旧债务校准及家庭类型文字。未发现 `0.35`、`35%` 或 TANK 被误用作当前设定；“两类家庭”出现在文献背景，并明确与本文 RANK 区分。参考文献中的年份、卷页与外部经验主张不属于本次模型计算认证。

两处需修正的原文及当前数值：

| 位置 | 当前原文含义 | 重新计算的当前比值 | 结论 |
|---|---|---:|---|
| TeX L595 | DS 高/低峰值接近三倍 | 2.562830367 | 应约2.56倍 |
| TeX L595 | FS 高/低谷值幅度接近三倍 | 2.516635589 | 应约2.52倍 |
| TeX L608 | IG 高/低谷值幅度接近三倍 | 2.480323820 | 应约2.48倍 |

这些是水平偏离峰谷的比，不是稳态债务比的机械代入；当前稳态债务比为1.00/0.40=2.5。下面列出全文分项覆盖与证据限度。

|TeX范围/主题|独立检查与当前证据|判定|
|---|---|---|
|L523–583模型参数、频率与校准表|逐参数对baseline.mod：beta=.99,sigma=2,varphi=.5,alpha=.45,gamma=.1,delta=.025,phiI=2.5,theta_p=.75,epsilon=6,eta=.9,omega=.85,tau=.2,thetaT=.6,betaG=.99,chiIG=20,varphiB=.05,omegaY=1,rhoR=.75,phiPi=1.5,phiY=.125,rhoMP=0,rhoD=.8；年度债务.40/1对应季度1.6/4；IG/Y=.12,G/Y=.10；shock=.0025。表phi_y=.13是L583明确说明的舍入；Z/Y的15.6%/18.0%与精确值一致|A|
|L595基准冲击与DS/FS|原MAT和baseline_full_irf.csv全部52条路径最大差4.86e-17。r初期为+.0018131324；通胀两区当期约-.00165/-.00173、q7附近转正，q8接近0；DS峰值和FS谷值均q2。DS峰比2.56283037、FS谷比2.51663559，而正文说三倍|C：两处数值修文|
|L608–610基准投资、资本、GDP|IG两区谷值q8=-.0006943979/-.0017223317，倍数2.48032382（第三个三倍错误）；KG低/高谷值q23/q22=-.0085443633/-.0207173236，近22期表述可接受但可写22–23；IG高减低q33转正；KG q40=-.006214939/-.014598250仍负；GDP谷值均q1且高债务全40期更低|C仅三倍，其余A|
|L614债务率实验|四个原始MAT直接重算地区差：对称.40/.40所有所述差为数值零（KG最大2.05e-14）；非对称.80/1.20/1.60的DS差峰q2、IG差谷q8、KG差谷q22，IG差谷依次-.0006904334/-.0013604208/-.0020107102，KG差谷依次-.0082367405/-.0160143661/-.0233575519；GDP/KG全期负，晚期投资回补|A|
|L627、L1132–1165规模实验及表|从三个原MAT重算ds2、ig2、xloc2首期标准化列：r1=.175234679,-.004020982,-.002358098；r1.5=.176836793,-.004045806,-.002372486；r2=.177615583,-.004058074,-.002378758；全部对应表和17.52→17.76%、-.402→-.406%、-.236→-.238%。s1=.5,.550510257,.585786438；gw1=.5,.6,2/3；trade权重对应|A（舍入内）|
|L646–683需求标准Taylor、表和30节点图|没有用既有汇总值作正确答案：从每个已存MAT的ghx,ghu,state_var,Sigma_e独立解离散Lyapunov，用V=GPG'+HSigmaH'计算理论矩。五点Pi标准差×100=.365022714,.300091544,.238742793,.198919164,.171366298；Y=.490351617,.369572576,.284730771,.246854461,.232391761；Ygap=.070777893,.120532041,.164290884,.193066714,.213541393；corr=.990840048,.951657645,.846544545,.741192104,.682193284；DSgap=.862878438,.775608634,.726911162,.716907188,.721691670。表舍入及Pi下降53.1%正确。30节点CSV逐差验证全部五曲线phi增大时右下、相同phi债务增大时右上。其余网格单点没有各自独立MAT，故额外节点只认证CSV内部及与基准点相符，不声称重新算30次均衡|A，对额外grid节点有限归档证据|
|L688–722需求地区平衡|5点同样从原ghx/ghu独立计算矩，与MAT保存var最大误差~1.23e-16。0→2：Ygap-.3398748138即-33.98748%，corr .951657645→.988789902；Pi+63.176235%，Y+22.647238%；DSgap+21.173777%，IGgap-32.753703%。0→.5：Ygap-12.163104%、Pi+18.109779%、Y+6.809479%；全部舍入吻合。phi_reg=0的稳态、ghx、ghu及共有IRF与标准需求基准逐位差0|A|
|L728–780余额限额、L1334–1358附录|原始OccBin MAT确认q2唯一绑定；严格减基准IG/Y政策差谷均q2，KG差谷q7；Y/IG/KG政策差首次转正为q7/q9/q20，与L778完全一致。只有实际余额限额，不是年度债务率限额；正文区分正确|数学A、KKT展示B|
|L782–799温和转移|原MAT Z2峰q3=.001198528565；IG谷q8=-.001347122970、KG谷q22=-.016173280243；相对无反馈谷值改善21.78492831%和21.93354448%，q40 KG=-.011478157851；GDP首期-.002358097653→-.002348069347，只改约1e-5，文字几乎相同正确|A|
|L640,L1299–1330 A/B表与路径|各方案原MAT中IRF除各自SS后，独立累计前12期地区差：A IG=-.083937303551,KG=-.011131140048,Y=-.005551703708；B IG=-.084373443738,KG=-.011206711654,Y=-.005565434421；差=-.000436140188,-.000075571606,-.000013730714。对应表全部值及方向|A|
|L1375–1420风险/转移/投入联系六情景|独立原MAT差路径：风险单独IG/KG/Y负差较大且DS正差持续40期（基准1–7）；强转移单独IG/KG/Y谷差收窄；联合情景IG差q1–32正、KG/Y全40期正（证明文字“前中期”而非所有时期）；strong IO GDP负差全期小于基准，末期-.000020690vs基准-.000123314；weak IO GDP谷-.000521760较基准-.000547428浅、末期-.000211272更差，q5–17高于基准其余更低，路径确交叉|A|
|L1424–1433货币冲击区域平衡|phi_reg=2的公式与正式mod一致，shock emp；正文仅探索性路径比较无额外数值结论|A|
|L1635–1686方法/计数/期限|baseline78,B86,OccBin79（每regime），order1/irf40与模型一致；资本图用Dynare期末输出解释与代码predetermined资本一致；数值表的说明和不做完整福利排序并无额外无证数值。本次未运行新的BK/Jacobian诊断，不能把旧status当新理论证明|A口径；旧validation状态非本次认证证据|

摘要、引言和结论重复的模型内定性结论已通过上述逐段结果核对；这不构成外部实证/文献引文的真实性鉴定。明确未做：新求均衡、重跑validation、重新绘图或编译论文；未作福利优劣认证。自存矩阵与原始路径检验不代替独立FOC推导，后者由主审计覆盖。

## 13. 逐方程唯一 mapping

以下表格按实际 `.mod model` 中的等式顺序编号。A01–A78、B01–B86 各编号出现一次；地区通式展开为 j=1、j=2，三条相对价格动态单独列示。`#` 是局部表达式替换，不是额外均衡方程；参数校准、价格权重定义、TVC 和事后利润/中央账户也不冒充逐期方程。

“一致”列只判断所列论文等式与代码的代数/时点；“等级”同时记录经济来源的说明缺口。独立式使用本报告的简写：`x=I/I_−`、`g=IG/IG_−`、`m_+=Λ_+/Λ`、`τL=(1−θT)τY`、`A_I=1−S−xS′`、`B_I=x²S′`；含未来随机量的括号均按 E_t 解释。家庭式、G-、S-等式的来源已在以上推导完整给出。表中 `Y`=生产 GDP、`D`=最终吸收，不能按代码 `y` 字面混淆。

### 13.1 A：78 条

文件：[code/baseline/RANK_two_region_baseline.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod)。行号包括可选 equation name 标签。

| 编号/地区 | Paper equation（TeX 行） | Economic origin | Independently derived equation | `.mod` / line | Exact match? | Discrepancy | Severity |
|---|---|---|---|---|---|---|---|
| A01 / 1 | `a1`（L1450） | 消费边际效用 | $\Lambda^1=(C^1)^{-\sigma}$；j=1 | [A:L181](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:181) | 是，代数/时点 | 无 | A |
| A02 / 1 | `a2`（L1451） | 资产 FOC＋资产特定楔子 | $\Lambda^1=\beta e^{-\zeta}E_t[\Lambda^1_+R/\Pi^1_+]$；j=1 | [A:L182](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:182) | 是，代数/时点 | 代数相同；楔子原始结构未给 | B/高 |
| A03 / 1 | `a5`（L1454） | 效用/工资边际条件 | $\chi_N(N^j)^\varphi=\Lambda^j W^j$；j=1 | [A:L183](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:183) | 是，代数/时点 | 无 | A |
| A04 / 1 | `a10`（L1455） | 安装技术 | $K^j_+=(1-\delta_K)K^j+[1-S(x^j)]I^j$；j=1 | [A:L184](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:184) | 是，代数/时点 | 无 | A |
| A05 / 1 | `a11`（L1460） | 选择下一期资本 | $q_K^j=\beta E_t[m^j_+(R^j_{K,+}+(1-\delta_K)q^j_{K,+})]$；j=1 | [A:L185](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:185) | 是，代数/时点 | 无 | A |
| A06 / 1 | `a12`（L1472） | 相邻两期安装边际效应 | $1=q_K^j A_I(x^j)+\beta E_t[m^j_+q^j_{K,+}B_I(x^j_+)]$；j=1 | [A:L186–187](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:186) | 是，代数/时点 | 无 | A |
| A07 / 2 | `a3`（L1452） | 消费边际效用 | $\Lambda^2=(C^2)^{-\sigma}$；j=2 | [A:L190](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:190) | 是，代数/时点 | 无 | A |
| A08 / 2 | `a4`（L1453） | 相同状态价格 | $\Lambda^2=\xi_{12}\Lambda^1Q_1^1/Q_1^2$；j=2 | [A:L191](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:191) | 是，代数/时点 | 代数相同；预算/初始财富实施待补 | B/高 |
| A09 / 2 | `a5`（L1454） | 效用/工资边际条件 | $\chi_N(N^j)^\varphi=\Lambda^j W^j$；j=2 | [A:L192](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:192) | 是，代数/时点 | 无 | A |
| A10 / 2 | `a10`（L1455） | 安装技术 | $K^j_+=(1-\delta_K)K^j+[1-S(x^j)]I^j$；j=2 | [A:L193](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:193) | 是，代数/时点 | 无 | A |
| A11 / 2 | `a11`（L1460） | 选择下一期资本 | $q_K^j=\beta E_t[m^j_+(R^j_{K,+}+(1-\delta_K)q^j_{K,+})]$；j=2 | [A:L194](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:194) | 是，代数/时点 | 无 | A |
| A12 / 2 | `a12`（L1472） | 相邻两期安装边际效应 | $1=q_K^j A_I(x^j)+\beta E_t[m^j_+q^j_{K,+}B_I(x^j_+)]$；j=2 | [A:L195–196](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:195) | 是，代数/时点 | 无 | A |
| A13 / 1 | `a13`（L1485） | 成本最小化/零利润 | $1=[\omega_j(Q_j^j)^{1-\eta}+(1-\omega_j)(Q_{-j}^j)^{1-\eta}]^{1/(1-\eta)}$；j=1 | [A:L199](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:199) | 是，代数/时点 | 无 | A |
| A14 / 1 | `a14`（L1486） | 本地品需求 FOC | $M_j^j=\omega_j(Q_j^j)^{-\eta}D^j$；j=1 | [A:L200](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:200) | 是，代数/时点 | 无 | A |
| A15 / 1 | `a15`（L1487） | 外地品需求 FOC | $M_{-j}^j=(1-\omega_j)(Q_{-j}^j)^{-\eta}D^j$；j=1 | [A:L201](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:201) | 是，代数/时点 | 无 | A |
| A16 / 2 | `a13`（L1485） | 成本最小化/零利润 | $1=[\omega_j(Q_j^j)^{1-\eta}+(1-\omega_j)(Q_{-j}^j)^{1-\eta}]^{1/(1-\eta)}$；j=2 | [A:L203](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:203) | 是，代数/时点 | 无 | A |
| A17 / 2 | `a14`（L1486） | 本地品需求 FOC | $M_j^j=\omega_j(Q_j^j)^{-\eta}D^j$；j=2 | [A:L204](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:204) | 是，代数/时点 | 无 | A |
| A18 / 2 | `a15`（L1487） | 外地品需求 FOC | $M_{-j}^j=(1-\omega_j)(Q_{-j}^j)^{-\eta}D^j$；j=2 | [A:L205](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:205) | 是，代数/时点 | 无 | A |
| A19 / — | `a16`（L1493） | 价格定义第一条 | $Q_{1,t}^1/Q_{1,t-1}^1=\Pi_{M,t}^1/\Pi_t^1$；j=— | [A:L207](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:207) | 是，代数/时点 | 无 | A |
| A20 / — | `a16`（L1493） | 价格定义第二条 | $Q_{2,t}^1/Q_{2,t-1}^1=\Pi_{M,t}^2/\Pi_t^1$；j=— | [A:L208](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:208) | 是，代数/时点 | 无 | A |
| A21 / — | `a16`（L1493） | 价格定义第三条 | $Q_{1,t}^2/Q_{1,t-1}^2=\Pi_{M,t}^1/\Pi_t^2$；j=— | [A:L209](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:209) | 是，代数/时点 | 无 | A |
| A22 / — | `a16q`（L1494） | 同一组名义价格 | $Q_1^1Q_2^2=Q_1^2Q_2^1$；j=— | [A:L210](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:210) | 是，代数/时点 | 无 | A |
| A23 / 1 | `a17`（L1500） | 外生过程（无创新） | $\log(A^j/\bar A^j)=\rho_A\log(A^j_-/\bar A^j)$；j=1 | [A:L213](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:213) | 是，代数/时点 | 无 | A |
| A24 / 1 | `a18`（L1501） | 品种技术积分 | $Y_M^j=A^j(K_G^j)^{\gamma_G}(K^j)^\alpha(N^j)^{1-\alpha}/V^j$；j=1 | [A:L214](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:214) | 是，代数/时点 | 无 | A |
| A25 / 1 | `a19`（L1503） | 企业劳动成本最小化 | $W^j=(1-\alpha)Q_j^jMC^jY_M^jV^j/N^j$；j=1 | [A:L215](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:215) | 是，代数/时点 | 无 | A |
| A26 / 1 | `a20`（L1504） | 企业资本成本最小化 | $R_K^j=\alpha Q_j^jMC^jY_M^jV^j/K^j$；j=1 | [A:L216](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:216) | 是，代数/时点 | 无 | A |
| A27 / 1 | `a21`（L1505） | 来源地市场清算 | $s_jY_M^j=s_1M_j^1+s_2M_j^2$；j=1 | [A:L217](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:217) | 是，代数/时点 | 无 | A |
| A28 / 1 | `a22`（L1506） | Calvo 价格分布 | $1=(1-\theta_p)(p_*^j)^{1-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p-1}$；j=1 | [A:L218](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:218) | 是，代数/时点 | 无 | A |
| A29 / 1 | `a23`（L1507） | 重置价格 FOC 的成本项 | $\mathcal P_1^j=\Lambda^jQ_j^jMC^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p}\mathcal P_{1,+}^j]$；j=1 | [A:L219–220](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:219) | 是，代数/时点 | 无 | A |
| A30 / 1 | `a24`（L1508） | 重置价格 FOC 的收入项 | $\mathcal P_2^j=\Lambda^jQ_j^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p-1}\mathcal P_{2,+}^j]$；j=1 | [A:L221–222](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:221) | 是，代数/时点 | 无 | A |
| A31 / 1 | `a25`（L1509） | 垄断加成 FOC | $p_*^j=\epsilon_p\mathcal P_1^j/[(\epsilon_p-1)\mathcal P_2^j]$；j=1 | [A:L223](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:223) | 是，代数/时点 | 无 | A |
| A32 / 1 | `a26`（L1510） | 相对价格负 ε 次幂积分 | $V^j=(1-\theta_p)(p_*^j)^{-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p}V^j_-$；j=1 | [A:L224](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:224) | 是，代数/时点 | 无 | A |
| A33 / 2 | `a17`（L1500） | 外生过程（无创新） | $\log(A^j/\bar A^j)=\rho_A\log(A^j_-/\bar A^j)$；j=2 | [A:L226](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:226) | 是，代数/时点 | 无 | A |
| A34 / 2 | `a18`（L1501） | 品种技术积分 | $Y_M^j=A^j(K_G^j)^{\gamma_G}(K^j)^\alpha(N^j)^{1-\alpha}/V^j$；j=2 | [A:L227](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:227) | 是，代数/时点 | 无 | A |
| A35 / 2 | `a19`（L1503） | 企业劳动成本最小化 | $W^j=(1-\alpha)Q_j^jMC^jY_M^jV^j/N^j$；j=2 | [A:L228](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:228) | 是，代数/时点 | 无 | A |
| A36 / 2 | `a20`（L1504） | 企业资本成本最小化 | $R_K^j=\alpha Q_j^jMC^jY_M^jV^j/K^j$；j=2 | [A:L229](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:229) | 是，代数/时点 | 无 | A |
| A37 / 2 | `a21`（L1505） | 来源地市场清算 | $s_jY_M^j=s_1M_j^1+s_2M_j^2$；j=2 | [A:L230](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:230) | 是，代数/时点 | 无 | A |
| A38 / 2 | `a22`（L1506） | Calvo 价格分布 | $1=(1-\theta_p)(p_*^j)^{1-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p-1}$；j=2 | [A:L231](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:231) | 是，代数/时点 | 无 | A |
| A39 / 2 | `a23`（L1507） | 重置价格 FOC 的成本项 | $\mathcal P_1^j=\Lambda^jQ_j^jMC^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p}\mathcal P_{1,+}^j]$；j=2 | [A:L232–233](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:232) | 是，代数/时点 | 无 | A |
| A40 / 2 | `a24`（L1508） | 重置价格 FOC 的收入项 | $\mathcal P_2^j=\Lambda^jQ_j^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p-1}\mathcal P_{2,+}^j]$；j=2 | [A:L234–235](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:234) | 是，代数/时点 | 无 | A |
| A41 / 2 | `a25`（L1509） | 垄断加成 FOC | $p_*^j=\epsilon_p\mathcal P_1^j/[(\epsilon_p-1)\mathcal P_2^j]$；j=2 | [A:L236](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:236) | 是，代数/时点 | 无 | A |
| A42 / 2 | `a26`（L1510） | 相对价格负 ε 次幂积分 | $V^j=(1-\theta_p)(p_*^j)^{-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p}V^j_-$；j=2 | [A:L237](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:237) | 是，代数/时点 | 无 | A |
| A43 / 1 | `a18x`（L1502） | 生产地价值 | $Y^j=Q_j^jY_M^j$；j=1 | [A:L241](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:241) | 是，代数/时点 | 无 | A |
| A44 / 2 | `a18x`（L1502） | 生产地价值 | $Y^j=Q_j^jY_M^j$；j=2 | [A:L242](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:242) | 是，代数/时点 | 无 | A |
| A45 / 1 | `a26d`（L1527） | 四倍季度 GDP | $d^{j,ann}=B^j/(4Y^j)$；j=1 | [A:L252](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:252) | 是，代数/时点 | 无 | A |
| A46 / 1 | `a27`（L1529） | 净实际债务服务定义 | $DS^j=(R^j_{B,-}/\Pi^j-1)B^j_-/Y^j$；j=1 | [A:L253](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:253) | 是，代数/时点 | 无 | A |
| A47 / 1 | `a28`（L1533） | 预算移项 | $FS^j=\tau_LY^j+Z^j-G^j-(R^j_{B,-}/\Pi^j-1)B^j_-$；j=1 | [A:L254–255](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:254) | 是，代数/时点 | 公式相同；明确固定实际本金口径 | B/低 |
| A48 / 1 | `a29`（L1536） | 公共调整资源成本 | $\Phi_I^j=\chi_I(g^j-1)^2I_G^j/2$；j=1 | [A:L256](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:256) | 是，代数/时点 | 无 | A |
| A49 / 1 | `a30`（L1539） | 债务管理资源成本 | $\Phi_B^j=\varphi_B(B^j/\bar Y^j-\bar b^j)^2\bar Y^j/2$；j=1 | [A:L257](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:257) | 是，代数/时点 | 无 | A |
| A50 / 1 | `a31`（L1546） | 原子化取价报价制度 | $R_B^j/R=\exp\{\mu_B[(B^j/Y^j)/\bar b^j-1]\}$；j=1 | [A:L258](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:258) | 是，代数/时点 | 无 | A |
| A51 / 1 | `a34`（L1565） | 政府对 IG 求导 G-IG | $\Lambda_G^j[1+\chi_I(g^j-1)g^j+\chi_I(g^j-1)^2/2]=q_G^j+\beta_GE_t[\Lambda^j_{G,+}\chi_I(g^j_+-1)(g^j_+)^2]$；j=1 | [A:L259–261](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:259) | 是，代数/时点 | 无 | A |
| A52 / 1 | `a35`（L1571） | 政府对 KG+ 求导 G-KG | $q_G^j=\beta_GE_t[(1-\delta_G)q^j_{G,+}+\gamma_G(\omega_Y+\Lambda^j_{G,+}\tau_LY^j_+)/K^j_{G,+}]$；j=1 | [A:L262–264](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:262) | 是，代数/时点 | 无 | A |
| A53 / 1 | `a37`（L1579） | 政府对 B 求导 G-B | $\Lambda_G^j[1-\varphi_B(B^j/\bar Y^j-\bar b^j)]=\beta_GE_t[\Lambda^j_{G,+}R_B^j/\Pi^j_+]$；j=1 | [A:L265–266](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:265) | 是，代数/时点 | 无 | A |
| A54 / 1 | `a33`（L1552） | 公共资本技术 | $K^j_{G,+}=(1-\delta_G)K_G^j+I_G^j$；j=1 | [A:L267](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:267) | 是，代数/时点 | 无 | A |
| A55 / 1 | `a32`（L1550） | 地方逐期预算 | $B^j=R^j_{B,-}B^j_-/\Pi^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j-\tau_LY^j-Z^j$；j=1 | [A:L268–269](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:268) | 是，代数/时点 | 无 | A |
| A56 / 1 | `a38`（L1581） | 外生政府消费规则 | $\log(G^j/\bar G^j)=\rho_G\log(G^j_-/\bar G^j)$；j=1 | [A:L270](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:270) | 是，代数/时点 | 无 | A |
| A57 / 1 | `a40z`（L1589） | 给定拨付规则 | $\log(Z^j/\bar Z^j)=\rho_Z\log(Z^j_-/\bar Z^j)+\phi_{Z,DS}(DS^j/\overline{DS}^j-1)+\phi_{Z,B}[(B^j_-/Y^j_-)/\bar b^j-1]$；j=1 | [A:L271–273](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:271) | 是，代数/时点 | 无 | A |
| A58 / 2 | `a26d`（L1527） | 四倍季度 GDP | $d^{j,ann}=B^j/(4Y^j)$；j=2 | [A:L275](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:275) | 是，代数/时点 | 无 | A |
| A59 / 2 | `a27`（L1529） | 净实际债务服务定义 | $DS^j=(R^j_{B,-}/\Pi^j-1)B^j_-/Y^j$；j=2 | [A:L276](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:276) | 是，代数/时点 | 无 | A |
| A60 / 2 | `a28`（L1533） | 预算移项 | $FS^j=\tau_LY^j+Z^j-G^j-(R^j_{B,-}/\Pi^j-1)B^j_-$；j=2 | [A:L277–278](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:277) | 是，代数/时点 | 公式相同；明确固定实际本金口径 | B/低 |
| A61 / 2 | `a29`（L1536） | 公共调整资源成本 | $\Phi_I^j=\chi_I(g^j-1)^2I_G^j/2$；j=2 | [A:L279](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:279) | 是，代数/时点 | 无 | A |
| A62 / 2 | `a30`（L1539） | 债务管理资源成本 | $\Phi_B^j=\varphi_B(B^j/\bar Y^j-\bar b^j)^2\bar Y^j/2$；j=2 | [A:L280](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:280) | 是，代数/时点 | 无 | A |
| A63 / 2 | `a31`（L1546） | 原子化取价报价制度 | $R_B^j/R=\exp\{\mu_B[(B^j/Y^j)/\bar b^j-1]\}$；j=2 | [A:L281](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:281) | 是，代数/时点 | 无 | A |
| A64 / 2 | `a34`（L1565） | 政府对 IG 求导 G-IG | $\Lambda_G^j[1+\chi_I(g^j-1)g^j+\chi_I(g^j-1)^2/2]=q_G^j+\beta_GE_t[\Lambda^j_{G,+}\chi_I(g^j_+-1)(g^j_+)^2]$；j=2 | [A:L282–284](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:282) | 是，代数/时点 | 无 | A |
| A65 / 2 | `a35`（L1571） | 政府对 KG+ 求导 G-KG | $q_G^j=\beta_GE_t[(1-\delta_G)q^j_{G,+}+\gamma_G(\omega_Y+\Lambda^j_{G,+}\tau_LY^j_+)/K^j_{G,+}]$；j=2 | [A:L285–287](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:285) | 是，代数/时点 | 无 | A |
| A66 / 2 | `a37`（L1579） | 政府对 B 求导 G-B | $\Lambda_G^j[1-\varphi_B(B^j/\bar Y^j-\bar b^j)]=\beta_GE_t[\Lambda^j_{G,+}R_B^j/\Pi^j_+]$；j=2 | [A:L288–289](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:288) | 是，代数/时点 | 无 | A |
| A67 / 2 | `a33`（L1552） | 公共资本技术 | $K^j_{G,+}=(1-\delta_G)K_G^j+I_G^j$；j=2 | [A:L290](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:290) | 是，代数/时点 | 无 | A |
| A68 / 2 | `a32`（L1550） | 地方逐期预算 | $B^j=R^j_{B,-}B^j_-/\Pi^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j-\tau_LY^j-Z^j$；j=2 | [A:L291–292](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:291) | 是，代数/时点 | 无 | A |
| A69 / 2 | `a38`（L1581） | 外生政府消费规则 | $\log(G^j/\bar G^j)=\rho_G\log(G^j_-/\bar G^j)$；j=2 | [A:L293](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:293) | 是，代数/时点 | 无 | A |
| A70 / 2 | `a40z`（L1589） | 给定拨付规则 | $\log(Z^j/\bar Z^j)=\rho_Z\log(Z^j_-/\bar Z^j)+\phi_{Z,DS}(DS^j/\overline{DS}^j-1)+\phi_{Z,B}[(B^j_-/Y^j_-)/\bar b^j-1]$；j=2 | [A:L294–296](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:294) | 是，代数/时点 | 无 | A |
| A71 / — | `a39ya`（L1608） | 共同价格加总 | $D=\sum_j s_jp_jD^j$；j=— | [A:L301–302](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:301) | 是，代数/时点 | 无 | A |
| A72 / — | `a39y`（L1606） | 共同价格加总 | $Y=\sum_j s_jp_jY^j$；j=— | [A:L305–306](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:305) | 是，代数/时点 | 无 | A |
| A73 / — | `a39pi`（L1609） | 固定权重价格指数增长 | $\Pi=(\Pi^1)^{\upsilon_1}(\Pi^2)^{\upsilon_2}$；j=— | [A:L307](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:307) | 是，代数/时点 | 无 | A |
| A74 / — | `a39mp`（L1610） | 货币冲击过程 | $MP=\rho_{MP}MP_-+\varepsilon_{MP}$；j=— | [A:L308](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:308) | 是，代数/时点 | 无 | A |
| A75 / — | `a41D`（L1611） | 负需求创新符号 | $\zeta=\rho_\zeta\zeta_--\varepsilon_\zeta$；j=— | [A:L309](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:309) | 是，代数/时点 | 无 | A |
| A76 / — | `a41`（L1618） | 货币规则制度 | $R/\bar R=(R_-/\bar R)^{\rho_R}[(\Pi/\bar\Pi)^{\phi_\pi}(Y/\bar Y)^{\phi_y}]^{1-\rho_R}e^{MP}$；j=— | [A:L310–312](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:310) | 是，代数/时点 | 无 | A |
| A77 / 1 | `a42`（L1622） | 最终品用途清算 | $D^j=C^j+I^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j$；j=1 | [A:L314](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:314) | 是，代数/时点 | 无 | A |
| A78 / 2 | `a42`（L1622） | 最终品用途清算 | $D^j=C^j+I^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j$；j=2 | [A:L315](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod:315) | 是，代数/时点 | 无 | A |

### 13.2 B：86 条

文件：[code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod)。行号包括可选 equation name 标签。

| 编号/地区 | Paper equation（TeX 行） | Economic origin | Independently derived equation | `.mod` / line | Exact match? | Discrepancy | Severity |
|---|---|---|---|---|---|---|---|
| B01 / 1 | `a1`（L1450） | 消费边际效用 | $\Lambda^1=(C^1)^{-\sigma}$；j=1 | [B:L215](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:215) | 是，代数/时点 | 无 | A |
| B02 / 1 | `a2`（L1451） | 资产 FOC＋资产特定楔子 | $\Lambda^1=\beta e^{-\zeta}E_t[\Lambda^1_+R/\Pi^1_+]$；j=1 | [B:L216](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:216) | 是，代数/时点 | 代数相同；楔子原始结构未给 | B/高 |
| B03 / 1 | `a5`（L1454） | 效用/工资边际条件 | $\chi_N(N^j)^\varphi=\Lambda^j W^j$；j=1 | [B:L217–218](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:217) | 是，代数/时点 | 无 | A |
| B04 / 1 | `a10`（L1455） | 安装技术 | $K^j_+=(1-\delta_K)K^j+[1-S(x^j)]I^j$；j=1 | [B:L221–222](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:221) | 是，代数/时点 | 无 | A |
| B05 / 1 | `a11`（L1460） | 选择下一期资本 | $q_K^j=\beta E_t[m^j_+(R^j_{K,+}+(1-\delta_K)q^j_{K,+})]$；j=1 | [B:L223–224](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:223) | 是，代数/时点 | 无 | A |
| B06 / 1 | `a12`（L1472） | 相邻两期安装边际效应 | $1=q_K^j A_I(x^j)+\beta E_t[m^j_+q^j_{K,+}B_I(x^j_+)]$；j=1 | [B:L225–227](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:225) | 是，代数/时点 | 无 | A |
| B07 / 2 | `a3`（L1452） | 消费边际效用 | $\Lambda^2=(C^2)^{-\sigma}$；j=2 | [B:L230](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:230) | 是，代数/时点 | 无 | A |
| B08 / 2 | `a4`（L1453） | 相同状态价格 | $\Lambda^2=\xi_{12}\Lambda^1Q_1^1/Q_1^2$；j=2 | [B:L231](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:231) | 是，代数/时点 | 代数相同；预算/初始财富实施待补 | B/高 |
| B09 / 2 | `a5`（L1454） | 效用/工资边际条件 | $\chi_N(N^j)^\varphi=\Lambda^j W^j$；j=2 | [B:L232–233](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:232) | 是，代数/时点 | 无 | A |
| B10 / 2 | `a10`（L1455） | 安装技术 | $K^j_+=(1-\delta_K)K^j+[1-S(x^j)]I^j$；j=2 | [B:L236–237](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:236) | 是，代数/时点 | 无 | A |
| B11 / 2 | `a11`（L1460） | 选择下一期资本 | $q_K^j=\beta E_t[m^j_+(R^j_{K,+}+(1-\delta_K)q^j_{K,+})]$；j=2 | [B:L238–239](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:238) | 是，代数/时点 | 无 | A |
| B12 / 2 | `a12`（L1472） | 相邻两期安装边际效应 | $1=q_K^j A_I(x^j)+\beta E_t[m^j_+q^j_{K,+}B_I(x^j_+)]$；j=2 | [B:L240–242](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:240) | 是，代数/时点 | 无 | A |
| B13 / 1 | `a13`（L1485） | 成本最小化/零利润 | $1=[\omega_j(Q_j^j)^{1-\eta}+(1-\omega_j)(Q_{-j}^j)^{1-\eta}]^{1/(1-\eta)}$；j=1 | [B:L245](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:245) | 是，代数/时点 | 无 | A |
| B14 / 1 | `a14`（L1486） | 本地品需求 FOC | $M_j^j=\omega_j(Q_j^j)^{-\eta}D^j$；j=1 | [B:L246](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:246) | 是，代数/时点 | 无 | A |
| B15 / 1 | `a15`（L1487） | 外地品需求 FOC | $M_{-j}^j=(1-\omega_j)(Q_{-j}^j)^{-\eta}D^j$；j=1 | [B:L247](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:247) | 是，代数/时点 | 无 | A |
| B16 / 2 | `a13`（L1485） | 成本最小化/零利润 | $1=[\omega_j(Q_j^j)^{1-\eta}+(1-\omega_j)(Q_{-j}^j)^{1-\eta}]^{1/(1-\eta)}$；j=2 | [B:L249](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:249) | 是，代数/时点 | 无 | A |
| B17 / 2 | `a14`（L1486） | 本地品需求 FOC | $M_j^j=\omega_j(Q_j^j)^{-\eta}D^j$；j=2 | [B:L250](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:250) | 是，代数/时点 | 无 | A |
| B18 / 2 | `a15`（L1487） | 外地品需求 FOC | $M_{-j}^j=(1-\omega_j)(Q_{-j}^j)^{-\eta}D^j$；j=2 | [B:L251](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:251) | 是，代数/时点 | 无 | A |
| B19 / — | `a16`（L1493） | 价格定义第一条 | $Q_{1,t}^1/Q_{1,t-1}^1=\Pi_{M,t}^1/\Pi_t^1$；j=— | [B:L253](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:253) | 是，代数/时点 | 无 | A |
| B20 / — | `a16`（L1493） | 价格定义第二条 | $Q_{2,t}^1/Q_{2,t-1}^1=\Pi_{M,t}^2/\Pi_t^1$；j=— | [B:L254](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:254) | 是，代数/时点 | 无 | A |
| B21 / — | `a16`（L1493） | 价格定义第三条 | $Q_{1,t}^2/Q_{1,t-1}^2=\Pi_{M,t}^1/\Pi_t^2$；j=— | [B:L255](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:255) | 是，代数/时点 | 无 | A |
| B22 / — | `a16q`（L1494） | 同一组名义价格 | $Q_1^1Q_2^2=Q_1^2Q_2^1$；j=— | [B:L256](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:256) | 是，代数/时点 | 无 | A |
| B23 / 1 | `a17`（L1500） | 外生过程（无创新） | $\log(A^j/\bar A^j)=\rho_A\log(A^j_-/\bar A^j)$；j=1 | [B:L259](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:259) | 是，代数/时点 | 无 | A |
| B24 / 1 | `a18`（L1501） | 品种技术积分 | $Y_M^j=A^j(K_G^j)^{\gamma_G}(K^j)^\alpha(N^j)^{1-\alpha}/V^j$；j=1 | [B:L260](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:260) | 是，代数/时点 | 无 | A |
| B25 / 1 | `a19`（L1503） | 企业劳动成本最小化 | $W^j=(1-\alpha)Q_j^jMC^jY_M^jV^j/N^j$；j=1 | [B:L261](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:261) | 是，代数/时点 | 无 | A |
| B26 / 1 | `a20`（L1504） | 企业资本成本最小化 | $R_K^j=\alpha Q_j^jMC^jY_M^jV^j/K^j$；j=1 | [B:L262](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:262) | 是，代数/时点 | 无 | A |
| B27 / 1 | `a21`（L1505） | 来源地市场清算 | $s_jY_M^j=s_1M_j^1+s_2M_j^2$；j=1 | [B:L263](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:263) | 是，代数/时点 | 无 | A |
| B28 / 1 | `a22`（L1506） | Calvo 价格分布 | $1=(1-\theta_p)(p_*^j)^{1-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p-1}$；j=1 | [B:L264](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:264) | 是，代数/时点 | 无 | A |
| B29 / 1 | `a23`（L1507） | 重置价格 FOC 的成本项 | $\mathcal P_1^j=\Lambda^jQ_j^jMC^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p}\mathcal P_{1,+}^j]$；j=1 | [B:L265–266](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:265) | 是，代数/时点 | 无 | A |
| B30 / 1 | `a24`（L1508） | 重置价格 FOC 的收入项 | $\mathcal P_2^j=\Lambda^jQ_j^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p-1}\mathcal P_{2,+}^j]$；j=1 | [B:L267–268](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:267) | 是，代数/时点 | 无 | A |
| B31 / 1 | `a25`（L1509） | 垄断加成 FOC | $p_*^j=\epsilon_p\mathcal P_1^j/[(\epsilon_p-1)\mathcal P_2^j]$；j=1 | [B:L269](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:269) | 是，代数/时点 | 无 | A |
| B32 / 1 | `a26`（L1510） | 相对价格负 ε 次幂积分 | $V^j=(1-\theta_p)(p_*^j)^{-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p}V^j_-$；j=1 | [B:L270](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:270) | 是，代数/时点 | 无 | A |
| B33 / 2 | `a17`（L1500） | 外生过程（无创新） | $\log(A^j/\bar A^j)=\rho_A\log(A^j_-/\bar A^j)$；j=2 | [B:L272](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:272) | 是，代数/时点 | 无 | A |
| B34 / 2 | `a18`（L1501） | 品种技术积分 | $Y_M^j=A^j(K_G^j)^{\gamma_G}(K^j)^\alpha(N^j)^{1-\alpha}/V^j$；j=2 | [B:L273](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:273) | 是，代数/时点 | 无 | A |
| B35 / 2 | `a19`（L1503） | 企业劳动成本最小化 | $W^j=(1-\alpha)Q_j^jMC^jY_M^jV^j/N^j$；j=2 | [B:L274](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:274) | 是，代数/时点 | 无 | A |
| B36 / 2 | `a20`（L1504） | 企业资本成本最小化 | $R_K^j=\alpha Q_j^jMC^jY_M^jV^j/K^j$；j=2 | [B:L275](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:275) | 是，代数/时点 | 无 | A |
| B37 / 2 | `a21`（L1505） | 来源地市场清算 | $s_jY_M^j=s_1M_j^1+s_2M_j^2$；j=2 | [B:L276](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:276) | 是，代数/时点 | 无 | A |
| B38 / 2 | `a22`（L1506） | Calvo 价格分布 | $1=(1-\theta_p)(p_*^j)^{1-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p-1}$；j=2 | [B:L277](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:277) | 是，代数/时点 | 无 | A |
| B39 / 2 | `a23`（L1507） | 重置价格 FOC 的成本项 | $\mathcal P_1^j=\Lambda^jQ_j^jMC^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p}\mathcal P_{1,+}^j]$；j=2 | [B:L278–279](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:278) | 是，代数/时点 | 无 | A |
| B40 / 2 | `a24`（L1508） | 重置价格 FOC 的收入项 | $\mathcal P_2^j=\Lambda^jQ_j^jY_M^j+\beta\theta_pE_t[(\Pi_{M,+}^j)^{\epsilon_p-1}\mathcal P_{2,+}^j]$；j=2 | [B:L280–281](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:280) | 是，代数/时点 | 无 | A |
| B41 / 2 | `a25`（L1509） | 垄断加成 FOC | $p_*^j=\epsilon_p\mathcal P_1^j/[(\epsilon_p-1)\mathcal P_2^j]$；j=2 | [B:L282](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:282) | 是，代数/时点 | 无 | A |
| B42 / 2 | `a26`（L1510） | 相对价格负 ε 次幂积分 | $V^j=(1-\theta_p)(p_*^j)^{-\epsilon_p}+\theta_p(\Pi_M^j)^{\epsilon_p}V^j_-$；j=2 | [B:L283](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:283) | 是，代数/时点 | 无 | A |
| B43 / 1 | `a18x`（L1502） | 生产地价值 | $Y^j=Q_j^jY_M^j$；j=1 | [B:L287](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:287) | 是，代数/时点 | 无 | A |
| B44 / 2 | `a18x`（L1502） | 生产地价值 | $Y^j=Q_j^jY_M^j$；j=2 | [B:L288](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:288) | 是，代数/时点 | 无 | A |
| B45 / 1 | `a26d`（L1527） | 四倍季度 GDP | $d^{j,ann}=B^j/(4Y^j)$；j=1 | [B:L298](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:298) | 是，代数/时点 | 无 | A |
| B46 / 1 | `a27`（L1529） | 净实际债务服务定义 | $DS^j=(R^j_{B,-}/\Pi^j-1)B^j_-/Y^j$；j=1 | [B:L299](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:299) | 是，代数/时点 | 无 | A |
| B47 / 1 | `a28`（L1533） | 预算移项 | $FS^j=\tau_LY^j+Z^j-G^j-(R^j_{B,-}/\Pi^j-1)B^j_-$；j=1 | [B:L300–301](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:300) | 是，代数/时点 | 公式相同；明确固定实际本金口径 | B/低 |
| B48 / 1 | `a29`（L1536） | 公共调整资源成本 | $\Phi_I^j=\chi_I(g^j-1)^2I_G^j/2$；j=1 | [B:L302](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:302) | 是，代数/时点 | 无 | A |
| B49 / 1 | `a30`（L1539） | 债务管理资源成本 | $\Phi_B^j=\varphi_B(B^j/\bar Y^j-\bar b^j)^2\bar Y^j/2$；j=1 | [B:L303](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:303) | 是，代数/时点 | 无 | A |
| B50 / 1 | `a31`（L1546） | 原子化取价报价制度 | $R_B^j/R=\exp\{\mu_B[(B^j/Y^j)/\bar b^j-1]\}$；j=1 | [B:L304](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:304) | 是，代数/时点 | 无 | A |
| B51 / 1 | `a34`（L1565） | 政府对 IG 求导 G-IG | $\Lambda_G^j[1+\chi_I(g^j-1)g^j+\chi_I(g^j-1)^2/2]=q_G^j+\beta_GE_t[\Lambda^j_{G,+}\chi_I(g^j_+-1)(g^j_+)^2]$；j=1 | [B:L305–308](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:305) | 是，代数/时点 | 无 | A |
| B52 / 1 | `eq:stackelberg_QG`（L1233） | 扩展 KG+ 变分 | $\text{S-KG：}\ q_G^j=\beta_GE_t[(1-\delta_G)q^j_{G,+}+\gamma_GJ^j_+/K^j_{G,+}]-\beta\nu_Q^jE_t[m^j_+\gamma_GR^j_{K,+}/K^j_{G,+}]$；j=1 | [B:L312–318](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:312) | 是，代数/时点 | 无 | A |
| B53 / 1 | `eq:stackelberg_K_corrected`（L1250） | 扩展 K+ 变分 | $\text{S-K：}\ \nu_K^j=\beta_GE_t[\alpha J^j_+/K^j_++(1-\delta_K)\nu^j_{K,+}]+\beta\nu_Q^jE_t[m^j_+(1-\alpha)R^j_{K,+}/K^j_+]$；j=1 | [B:L320–326](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:320) | 是，代数/时点 | 无 | A |
| B54 / 1 | `eq:stackelberg_NR`（L1266） | 扩展当期 N 变分 | $\text{S-N：}\ 0=[(1-\alpha)H^j+\alpha\Theta^jW^j-(\beta/\beta_G)\nu^j_{Q,-}m^j(1-\alpha)R_K^j]/N^j+\nu_N^j\chi_N\varphi(N^j)^{\varphi-1}$；j=1 | [B:L328–330](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:328) | 是，代数/时点 | 无 | A |
| B55 / 1 | `eq:stackelberg_QK`（L1275） | 扩展当期 qK 变分 | $\text{S-q：}\ 0=\nu_Q^j-A_I(x^j)\nu_I^j-(\beta/\beta_G)m^j[(1-\delta_K)\nu^j_{Q,-}+B_I(x^j)\nu^j_{I,-}]$；j=1 | [B:L331–334](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:331) | 是，代数/时点 | 无 | A |
| B56 / 1 | `eq:stackelberg_I`（L1293） | 扩展当期 I：四来源变分 | $\text{S-I 全式，见第 8 节；} A_I^\prime=\phi_I(2-3x),\ B_I^\prime=\phi_I(3x^2-2x)$；j=1 | [B:L335–343](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:335) | 是，代数/时点 | 无 | A |
| B57 / 1 | `a37`（L1579） | 政府对 B 求导 G-B | $\Lambda_G^j[1-\varphi_B(B^j/\bar Y^j-\bar b^j)]=\beta_GE_t[\Lambda^j_{G,+}R_B^j/\Pi^j_+]$；j=1 | [B:L344–346](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:344) | 是，代数/时点 | 无 | A |
| B58 / 1 | `a33`（L1552） | 公共资本技术 | $K^j_{G,+}=(1-\delta_G)K_G^j+I_G^j$；j=1 | [B:L347–348](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:347) | 是，代数/时点 | 无 | A |
| B59 / 1 | `a32`（L1550） | 地方逐期预算 | $B^j=R^j_{B,-}B^j_-/\Pi^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j-\tau_LY^j-Z^j$；j=1 | [B:L349–351](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:349) | 是，代数/时点 | 无 | A |
| B60 / 1 | `a38`（L1581） | 外生政府消费规则 | $\log(G^j/\bar G^j)=\rho_G\log(G^j_-/\bar G^j)$；j=1 | [B:L352](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:352) | 是，代数/时点 | 无 | A |
| B61 / 1 | `a40z`（L1589） | 给定拨付规则 | $\log(Z^j/\bar Z^j)=\rho_Z\log(Z^j_-/\bar Z^j)+\phi_{Z,DS}(DS^j/\overline{DS}^j-1)+\phi_{Z,B}[(B^j_-/Y^j_-)/\bar b^j-1]$；j=1 | [B:L354–356](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:354) | 是，代数/时点 | 无 | A |
| B62 / 2 | `a26d`（L1527） | 四倍季度 GDP | $d^{j,ann}=B^j/(4Y^j)$；j=2 | [B:L358](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:358) | 是，代数/时点 | 无 | A |
| B63 / 2 | `a27`（L1529） | 净实际债务服务定义 | $DS^j=(R^j_{B,-}/\Pi^j-1)B^j_-/Y^j$；j=2 | [B:L359](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:359) | 是，代数/时点 | 无 | A |
| B64 / 2 | `a28`（L1533） | 预算移项 | $FS^j=\tau_LY^j+Z^j-G^j-(R^j_{B,-}/\Pi^j-1)B^j_-$；j=2 | [B:L360–361](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:360) | 是，代数/时点 | 公式相同；明确固定实际本金口径 | B/低 |
| B65 / 2 | `a29`（L1536） | 公共调整资源成本 | $\Phi_I^j=\chi_I(g^j-1)^2I_G^j/2$；j=2 | [B:L362](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:362) | 是，代数/时点 | 无 | A |
| B66 / 2 | `a30`（L1539） | 债务管理资源成本 | $\Phi_B^j=\varphi_B(B^j/\bar Y^j-\bar b^j)^2\bar Y^j/2$；j=2 | [B:L363](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:363) | 是，代数/时点 | 无 | A |
| B67 / 2 | `a31`（L1546） | 原子化取价报价制度 | $R_B^j/R=\exp\{\mu_B[(B^j/Y^j)/\bar b^j-1]\}$；j=2 | [B:L364](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:364) | 是，代数/时点 | 无 | A |
| B68 / 2 | `a34`（L1565） | 政府对 IG 求导 G-IG | $\Lambda_G^j[1+\chi_I(g^j-1)g^j+\chi_I(g^j-1)^2/2]=q_G^j+\beta_GE_t[\Lambda^j_{G,+}\chi_I(g^j_+-1)(g^j_+)^2]$；j=2 | [B:L365–368](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:365) | 是，代数/时点 | 无 | A |
| B69 / 2 | `eq:stackelberg_QG`（L1233） | 扩展 KG+ 变分 | $\text{S-KG：}\ q_G^j=\beta_GE_t[(1-\delta_G)q^j_{G,+}+\gamma_GJ^j_+/K^j_{G,+}]-\beta\nu_Q^jE_t[m^j_+\gamma_GR^j_{K,+}/K^j_{G,+}]$；j=2 | [B:L369–375](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:369) | 是，代数/时点 | 无 | A |
| B70 / 2 | `eq:stackelberg_K_corrected`（L1250） | 扩展 K+ 变分 | $\text{S-K：}\ \nu_K^j=\beta_GE_t[\alpha J^j_+/K^j_++(1-\delta_K)\nu^j_{K,+}]+\beta\nu_Q^jE_t[m^j_+(1-\alpha)R^j_{K,+}/K^j_+]$；j=2 | [B:L376–382](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:376) | 是，代数/时点 | 无 | A |
| B71 / 2 | `eq:stackelberg_NR`（L1266） | 扩展当期 N 变分 | $\text{S-N：}\ 0=[(1-\alpha)H^j+\alpha\Theta^jW^j-(\beta/\beta_G)\nu^j_{Q,-}m^j(1-\alpha)R_K^j]/N^j+\nu_N^j\chi_N\varphi(N^j)^{\varphi-1}$；j=2 | [B:L383–385](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:383) | 是，代数/时点 | 无 | A |
| B72 / 2 | `eq:stackelberg_QK`（L1275） | 扩展当期 qK 变分 | $\text{S-q：}\ 0=\nu_Q^j-A_I(x^j)\nu_I^j-(\beta/\beta_G)m^j[(1-\delta_K)\nu^j_{Q,-}+B_I(x^j)\nu^j_{I,-}]$；j=2 | [B:L386–389](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:386) | 是，代数/时点 | 无 | A |
| B73 / 2 | `eq:stackelberg_I`（L1293） | 扩展当期 I：四来源变分 | $\text{S-I 全式，见第 8 节；} A_I^\prime=\phi_I(2-3x),\ B_I^\prime=\phi_I(3x^2-2x)$；j=2 | [B:L390–398](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:390) | 是，代数/时点 | 无 | A |
| B74 / 2 | `a37`（L1579） | 政府对 B 求导 G-B | $\Lambda_G^j[1-\varphi_B(B^j/\bar Y^j-\bar b^j)]=\beta_GE_t[\Lambda^j_{G,+}R_B^j/\Pi^j_+]$；j=2 | [B:L399–401](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:399) | 是，代数/时点 | 无 | A |
| B75 / 2 | `a33`（L1552） | 公共资本技术 | $K^j_{G,+}=(1-\delta_G)K_G^j+I_G^j$；j=2 | [B:L402–403](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:402) | 是，代数/时点 | 无 | A |
| B76 / 2 | `a32`（L1550） | 地方逐期预算 | $B^j=R^j_{B,-}B^j_-/\Pi^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j-\tau_LY^j-Z^j$；j=2 | [B:L404–406](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:404) | 是，代数/时点 | 无 | A |
| B77 / 2 | `a38`（L1581） | 外生政府消费规则 | $\log(G^j/\bar G^j)=\rho_G\log(G^j_-/\bar G^j)$；j=2 | [B:L407](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:407) | 是，代数/时点 | 无 | A |
| B78 / 2 | `a40z`（L1589） | 给定拨付规则 | $\log(Z^j/\bar Z^j)=\rho_Z\log(Z^j_-/\bar Z^j)+\phi_{Z,DS}(DS^j/\overline{DS}^j-1)+\phi_{Z,B}[(B^j_-/Y^j_-)/\bar b^j-1]$；j=2 | [B:L409–411](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:409) | 是，代数/时点 | 无 | A |
| B79 / — | `a39ya`（L1608） | 共同价格加总 | $D=\sum_j s_jp_jD^j$；j=— | [B:L416–417](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:416) | 是，代数/时点 | 无 | A |
| B80 / — | `a39y`（L1606） | 共同价格加总 | $Y=\sum_j s_jp_jY^j$；j=— | [B:L420–421](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:420) | 是，代数/时点 | 无 | A |
| B81 / — | `a39pi`（L1609） | 固定权重价格指数增长 | $\Pi=(\Pi^1)^{\upsilon_1}(\Pi^2)^{\upsilon_2}$；j=— | [B:L422](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:422) | 是，代数/时点 | 无 | A |
| B82 / — | `a39mp`（L1610） | 货币冲击过程 | $MP=\rho_{MP}MP_-+\varepsilon_{MP}$；j=— | [B:L423](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:423) | 是，代数/时点 | 无 | A |
| B83 / — | `a41D`（L1611） | 负需求创新符号 | $\zeta=\rho_\zeta\zeta_--\varepsilon_\zeta$；j=— | [B:L424](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:424) | 是，代数/时点 | 无 | A |
| B84 / — | `a41`（L1618） | 货币规则制度 | $R/\bar R=(R_-/\bar R)^{\rho_R}[(\Pi/\bar\Pi)^{\phi_\pi}(Y/\bar Y)^{\phi_y}]^{1-\rho_R}e^{MP}$；j=— | [B:L425–427](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:425) | 是，代数/时点 | 无 | A |
| B85 / 1 | `a42`（L1622） | 最终品用途清算 | $D^j=C^j+I^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j$；j=1 | [B:L429](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:429) | 是，代数/时点 | 无 | A |
| B86 / 2 | `a42`（L1622） | 最终品用途清算 | $D^j=C^j+I^j+G^j+I_G^j+\Phi_I^j+\Phi_B^j$；j=2 | [B:L430](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod:430) | 是，代数/时点 | 无 | A |

局部表达式单独核对：A 的 `sinv/spinv/spinvp/rig/rigp`（L169–178）与 S、S′及投资比率一致；B 的 `ainv/binv/aprime/bprime`、前瞻版本、`thetaf/mn`（L175–212）分别对应 A_I、B_I、A_I′、B_I′、Θ 和 S-N 的劳动边际项，未漏掉局部替换中的 lead/lag。A/B 共有 **76 条不变等式**，去除名称标签与空白后逐字相等；另有两条 KG 替换和八条新增驻点条件，已在 B 表逐条核对。

## 14. 逐变量符号及时点审计

本节的“跳跃”指本期在新信息下选择/调整，不等同于 Dynare 简化后的纯前瞻变量分类。一个本期跳跃变量可同时以滞后值构成状态，例如 I、IG、政策利率和承诺乘子。不能仅根据它有没有 `(-1)` 判为“当期不可变”。

`predetermined_variables k1 k2 kg1 kg2`（A L24）是关键：源方程 `k(+1)=(1−δ)k+inv` 与论文期初存量完全一致；内部/输出 `k_t` 表示本期决定、明期投产的存量。债务 b 没有这个声明，`b_t` 本来就是本期期末选择；将 b 也声明 predetermined 会改错其时点。

| Code variable | 论文符号 | 经济时点/角色 | 重点检查 |
|---|---|---|---|
| `c1` | C（地区1） | 本期消费选择/跳跃 | 边际效用通过未来资产定价决定 |
| `n1` | N（地区1） | 本期劳动选择 | 非期初既定劳动；供需当期出清 |
| `inv1` | I（地区1） | 本期投资选择/跳跃；滞后为状态 | I_−既定；I影响K_+和下期安装成本 |
| `k1` | K（地区1） | 期初 predetermined | 源k是K_t；源k(+1)为本期选择；输出k是K_{t+1} |
| `qk1` | q_K（地区1） | 前瞻影子价/跳跃 | 今日价值定价下一期租金和资本余值 |
| `lam1` | Λ（地区1） | 边际效用/跳跃 | 当前C决定；+1进入定价；B中−1形成边际效用比 |
| `y1` | D（地区1） | 本期最终吸收 | 不是生产GDP，也非预定状态 |
| `ym1` | Y_M（地区1） | 本期产出 | 使用期初K、KG和当期N、V |
| `w1` | W（地区1） | 本期实际工资 | 当地最终品单位 |
| `rk1` | R_K（地区1） | 本期资本租金 | 支付给本期既有K；下一期租金进入今日Euler |
| `mc1` | MC（地区1） | 本期边际成本 | 中间品单位；Calvo的成本项 |
| `pinf1` | Π（地区1） | 当期实现的最终品通胀 | 重估旧债；+1在Euler中为条件预期 |
| `pim1` | Π_M（地区1） | 当期中间品通胀/跳跃 | 进入价格指数、离散度和未来递归 |
| `pstar1` | p_*（地区1） | 本期重置价格 | 未来利润通过两个递归决定 |
| `xone1` | 𝒫₁（地区1） | 前瞻递归/跳跃 | 已含Λ；未来Π_M的ε次幂 |
| `xtwo1` | 𝒫₂（地区1） | 前瞻递归/跳跃 | 已含Λ；未来Π_M的ε−1次幂 |
| `v1` | V（地区1） | 当期内生递归量；滞后为状态 | V_−既定；V_t能随本期重置价格调整 |
| `b1` | B（地区1） | 本期选择的期末债务 | B_−为期初既有债务；未声明predetermined是正确的 |
| `rb1` | R_B（地区1） | 本期新债合同报价 | RB_−是旧合同；当前RB影响明期偿付 |
| `dann1` | d_ann（地区1） | 本期派生比率 | B_t/(4Y_t)；不是债务存量状态 |
| `ds1` | DS（地区1） | 本期派生负担率 | RB_−、B_−、Π_t、Y_t |
| `fs1` | FS（地区1） | 本期派生财政余量 | 本期收入减G及净实际债务服务 |
| `ig1` | I_G（地区1） | 本期公共投资/跳跃；滞后为状态 | IG_−既定；今日IG形成KG_+ |
| `kg1` | K_G（地区1） | 期初 predetermined | 源kg是KG_t；输出kg是KG_{t+1} |
| `phiig1` | Φ_I（地区1） | 本期资源成本 | 当前/滞后IG比率 |
| `phib1` | Φ_B（地区1） | 本期资源成本 | 当前B和固定稳态尺度 |
| `lamg1` | Λ_G（地区1） | 预算当前值乘子/跳跃 | 未来值进入债务与IG/KG条件 |
| `qg1` | q_G（地区1） | 公共资本当前值影子价/跳跃 | 对下一期存量求导对应今日乘子 |
| `muR_1` | ν_N（地区1） | 本期私人劳动约束乘子 | +1进入KG/K边际；不是家庭类型权重 |
| `muK_1` | ν_K（地区1） | 前瞻私人积累乘子 | 不是私人资本存量；稳态为0不意味着可删 |
| `muQ_1` | ν_Q（地区1） | 当期承诺乘子；滞后为历史状态 | νQ_−进入N和qK；timeless下初始历史不设0 |
| `muI_1` | ν_I（地区1） | 当期承诺乘子；滞后为历史状态 | νI_−和νI_+进入投资驻点 |
| `a1` | A（地区1） | 给定递归过程 | 当前模型无创新，稳态出发不动 |
| `g1` | G（地区1） | 给定财政递归过程 | 当前模型无创新，稳态出发不动 |
| `z1` | Z（地区1） | 对个体给定、总量可内生的当期反馈 | 自身滞后+本期DS+滞后B/Y |
| `c2` | C（地区2） | 本期消费选择/跳跃 | 边际效用通过未来资产定价决定 |
| `n2` | N（地区2） | 本期劳动选择 | 非期初既定劳动；供需当期出清 |
| `inv2` | I（地区2） | 本期投资选择/跳跃；滞后为状态 | I_−既定；I影响K_+和下期安装成本 |
| `k2` | K（地区2） | 期初 predetermined | 源k是K_t；源k(+1)为本期选择；输出k是K_{t+1} |
| `qk2` | q_K（地区2） | 前瞻影子价/跳跃 | 今日价值定价下一期租金和资本余值 |
| `lam2` | Λ（地区2） | 边际效用/跳跃 | 当前C决定；+1进入定价；B中−1形成边际效用比 |
| `y2` | D（地区2） | 本期最终吸收 | 不是生产GDP，也非预定状态 |
| `ym2` | Y_M（地区2） | 本期产出 | 使用期初K、KG和当期N、V |
| `w2` | W（地区2） | 本期实际工资 | 当地最终品单位 |
| `rk2` | R_K（地区2） | 本期资本租金 | 支付给本期既有K；下一期租金进入今日Euler |
| `mc2` | MC（地区2） | 本期边际成本 | 中间品单位；Calvo的成本项 |
| `pinf2` | Π（地区2） | 当期实现的最终品通胀 | 重估旧债；+1在Euler中为条件预期 |
| `pim2` | Π_M（地区2） | 当期中间品通胀/跳跃 | 进入价格指数、离散度和未来递归 |
| `pstar2` | p_*（地区2） | 本期重置价格 | 未来利润通过两个递归决定 |
| `xone2` | 𝒫₁（地区2） | 前瞻递归/跳跃 | 已含Λ；未来Π_M的ε次幂 |
| `xtwo2` | 𝒫₂（地区2） | 前瞻递归/跳跃 | 已含Λ；未来Π_M的ε−1次幂 |
| `v2` | V（地区2） | 当期内生递归量；滞后为状态 | V_−既定；V_t能随本期重置价格调整 |
| `b2` | B（地区2） | 本期选择的期末债务 | B_−为期初既有债务；未声明predetermined是正确的 |
| `rb2` | R_B（地区2） | 本期新债合同报价 | RB_−是旧合同；当前RB影响明期偿付 |
| `dann2` | d_ann（地区2） | 本期派生比率 | B_t/(4Y_t)；不是债务存量状态 |
| `ds2` | DS（地区2） | 本期派生负担率 | RB_−、B_−、Π_t、Y_t |
| `fs2` | FS（地区2） | 本期派生财政余量 | 本期收入减G及净实际债务服务 |
| `ig2` | I_G（地区2） | 本期公共投资/跳跃；滞后为状态 | IG_−既定；今日IG形成KG_+ |
| `kg2` | K_G（地区2） | 期初 predetermined | 源kg是KG_t；输出kg是KG_{t+1} |
| `phiig2` | Φ_I（地区2） | 本期资源成本 | 当前/滞后IG比率 |
| `phib2` | Φ_B（地区2） | 本期资源成本 | 当前B和固定稳态尺度 |
| `lamg2` | Λ_G（地区2） | 预算当前值乘子/跳跃 | 未来值进入债务与IG/KG条件 |
| `qg2` | q_G（地区2） | 公共资本当前值影子价/跳跃 | 对下一期存量求导对应今日乘子 |
| `muR_2` | ν_N（地区2） | 本期私人劳动约束乘子 | +1进入KG/K边际；不是家庭类型权重 |
| `muK_2` | ν_K（地区2） | 前瞻私人积累乘子 | 不是私人资本存量；稳态为0不意味着可删 |
| `muQ_2` | ν_Q（地区2） | 当期承诺乘子；滞后为历史状态 | νQ_−进入N和qK；timeless下初始历史不设0 |
| `muI_2` | ν_I（地区2） | 当期承诺乘子；滞后为历史状态 | νI_−和νI_+进入投资驻点 |
| `a2` | A（地区2） | 给定递归过程 | 当前模型无创新，稳态出发不动 |
| `g2` | G（地区2） | 给定财政递归过程 | 当前模型无创新，稳态出发不动 |
| `z2` | Z（地区2） | 对个体给定、总量可内生的当期反馈 | 自身滞后+本期DS+滞后B/Y |
| `m11` | M_1^1 | 本期需求 | 来源1、使用1 |
| `m21` | M_2^1 | 本期需求 | 来源2、使用1 |
| `m12` | M_1^2 | 本期需求 | 来源1、使用2 |
| `m22` | M_2^2 | 本期需求 | 来源2、使用2 |
| `q11` | Q_1^1 | 本期相对价格；其滞后为状态 | P_M1/P1；不能把当前Q固定 |
| `q21` | Q_2^1 | 本期相对价格；其滞后为状态 | P_M2/P1 |
| `q12` | Q_1^2 | 本期相对价格；其滞后为状态 | P_M1/P2 |
| `q22` | Q_2^2 | 本期相对价格 | 由交叉恒等式恢复；第四动态式冗余 |
| `yagg` | D 全国 | 当期加总 | 共同价格单位最终吸收 |
| `xloc1` | Y¹ | 当期GDP | q11*ym1 |
| `xloc2` | Y² | 当期GDP | q22*ym2 |
| `xagg` | Y 全国 | 当期加总 | 共同价格单位生产GDP |
| `pinfagg` | Π 全国 | 当期价格指数增长 | 固定稳态GDP权重 |
| `r` | R | 本期政策利率；滞后为平滑状态 | 今日R进入明期资产支付 |
| `mp` | MP | 冲击实现后的外生状态 | emp为本期创新；ρmp=0基准 |
| `d` | ζ | 冲击实现后的外生状态 | 正ed进入ζ时带负号 |
| `xicap2`（OccBin另增） | ξ² | 当期债务约束乘子 | slack为0；binding内生非负，不是外生冲击 |

外生创新 `emp`、`ed` 均在当期实现；两者的持续性通过 `mp`、`d` 表示，不能把 ε 的时点误移到下一期。A 变量是上表除去八个 `mu*` 乘子后的 78 个。

特别核验：当期生产使用 K_t/KG_t；K_{t+1}/KG_{t+1} 为当期选择。B_{t−1}、RB_{t−1} 为既有本金和合同，Π_t 为当期实现通胀；B_t、RB_t 决定下一期偿付。I_t/I_{t−1}、IG_t/IG_{t−1} 的分母是既有投资而非资本；下一期成本的分母为当期投资。Stackelberg νQ,−1、νI,−1 是历史承诺，不能任意初始化为零后仍称同一 timeless 稳态。未发现论文文字与当前资本输出注释的时点冲突。

## 15. 待修改清单与影响

| 优先级/等级 | 位置 | 建议动作（本轮未执行） | `.mod` 与结果影响 |
|---|---|---|---|
| 高 / B | TeX L97–122、L1480、L1633 | 给出完整家庭预算、保险证券的购买与支付、中央/中介对手账、一次性税费对家庭决策的外生性及初始财富安排。 | 若仅补当前配置的非扭曲实施，不改 78/86 系统；如另加实质约束需重求解。 |
| 高 / B | `eq:euler_rf`、`a2`，L122、L1448 | 给出能产生 e^{−ζ} 的具体资产特定结构，明确普通证券/资本/Calvo 核为何不受同一直接楔子影响。 | 所有派生模型共享此式；是否需改代码取决于经确认的结构选择。当前不自动改。 |
| 中 / C | TeX L595、L608 | 将 DS/FS/IG 的“接近三倍”按当前结果改为约 2.5 倍，最好列相应指标的准确比值。 | 不改代码、稳态或 IRF。 |
| 中 / B | OccBin 限额讨论及动态方程附录 | 补含 ξ 的债务 KKT、ξ≥0、cap−B≥0、互补条件及两 regime 方程。 | `policy_cf_strict_debt_cap.mod` 当前实现正确；不改路径。 |
| 中 / B | TeX L1197–1210 | 显式补充继承 νQ,−1、νI,−1 的 timeless 初始边界。 | 不改当前模型；若改为首次承诺，则需另做转轨并改变IRF。 |
| 低 / B | TeX L319 | 删除“消费条件”误述，列出劳动供给、私人积累、资本 Euler、投资 FOC 四项。 | 不改代码、稳态或 IRF。 |
| 低 / B | TeX L413、L418 | 把“本金滚动”明确为维持上期**实际余额**，区别固定名义本金滚续。 | 不改 DS/FS 定义、代码或 IRF。 |

本次结论不是“模型能跑所以正确”。可认证的证据是独立求导后 78/86 个逐期等式的唯一对应、时点核查、独立稳态及合并账户恒等式；尚不能认证的部分是原始家庭金融结构与完整扩展方程展示。完成上述补充并确认 ζ 的实施方式后，才能对用户要求的整条链条给出无保留最终认证。

## 16. 证据、复核范围及源文件完整性

报告中的独立运算包括：原始函数的手工导数；七类政府/领导者选择的历史树偏导；78/86变量独立稳态计算与原方程代入；原始MAT路径与决策矩阵的只读解析；需求及地区平衡矩的独立Lyapunov计算；54份模型结构比较。未重新生成 IRF、未执行旧 validation、未以旧 BK 或 Jacobian 状态作为本次理论证据。

需求/地区平衡矩通过独立读取 ghx、ghu、state_var、Sigma_e 并解 Lyapunov 方程重算，和已存协方差矩阵最大绝对差约 4.81×10⁻¹⁶。额外30节点图中无单点MAT的节点只核对CSV一致性，未虚称独立重求全部30个均衡。MATLAB一次只读启动失败后改用独立Python解析器成功读取原始MAT，未因此跳过OccBin二进制记录。

以下哈希固定本次报告对应版本；完成后重新检查论文、全部 `.mod`、MATLAB `.m` 和CSV的哈希，未发生变更。Git工作树唯一新增文件是本报告。临时推导和解析文件保存在系统临时目录，不是新的正式代码/输出来源。

| 核心源文件 | SHA-256 |
|---|---|
| [RANK_DSGE_endo.tex](C:/Users/Chow/Desktop/codex/RANK_endo/RANK_DSGE_endo.tex) | `cdf22463906c295e0b9447150b0484d85044bdeae54538ae82570d622c305bcc` |
| [code/baseline/RANK_two_region_baseline.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod) | `bad1348443f47b1a8367648d11970a3ab2e30433de9217b8ca0502e08b445ee5` |
| [code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod) | `09613b0c42538c3b2ee4953be3bfc310442c44194165f3f801d817ae599a1ae9` |
| [code/stackelberg_B/robustness/scheme_A/RANK_two_region_scheme_A.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/scheme_A/RANK_two_region_scheme_A.mod) | `a1b7cf0402edfe3bf7c5b0f22eda20c36b2b750682c30e5056823fc41dc6ff6f` |
| [code/policy_counterfactual/policy_cf_strict_debt_cap.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/policy_counterfactual/policy_cf_strict_debt_cap.mod) | `a9ccef763b5c89ad6364a8f95a15441aa65efbb4e3b2040a04b1047d44a2a488` |

正式 `.mod` 审计清单（54个）：

| # | 文件 |
|---|---|
| 1 | [code/baseline/RANK_two_region_baseline.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/baseline/RANK_two_region_baseline.mod) |
| 2 | [code/debt_intensity/debt_intensity_b040.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/debt_intensity/debt_intensity_b040.mod) |
| 3 | [code/debt_intensity/debt_intensity_b080.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/debt_intensity/debt_intensity_b080.mod) |
| 4 | [code/debt_intensity/debt_intensity_b120.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/debt_intensity/debt_intensity_b120.mod) |
| 5 | [code/debt_intensity/debt_intensity_b160.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/debt_intensity/debt_intensity_b160.mod) |
| 6 | [code/demand_monetary/hawkish_phi_110.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/demand_monetary/hawkish_phi_110.mod) |
| 7 | [code/demand_monetary/hawkish_phi_150.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/demand_monetary/hawkish_phi_150.mod) |
| 8 | [code/demand_monetary/hawkish_phi_200.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/demand_monetary/hawkish_phi_200.mod) |
| 9 | [code/demand_monetary/hawkish_phi_300.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/demand_monetary/hawkish_phi_300.mod) |
| 10 | [code/demand_monetary/negative_demand_baseline_policy.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/demand_monetary/negative_demand_baseline_policy.mod) |
| 11 | [code/demand_monetary/negative_demand_phi_110.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/demand_monetary/negative_demand_phi_110.mod) |
| 12 | [code/demand_monetary/negative_demand_phi_200.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/demand_monetary/negative_demand_phi_200.mod) |
| 13 | [code/demand_monetary/negative_demand_phi_250.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/demand_monetary/negative_demand_phi_250.mod) |
| 14 | [code/demand_monetary/negative_demand_strong_inflation_policy.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/demand_monetary/negative_demand_strong_inflation_policy.mod) |
| 15 | [code/extension_scenarios/demand_regional_balance_000.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/extension_scenarios/demand_regional_balance_000.mod) |
| 16 | [code/extension_scenarios/demand_regional_balance_050.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/extension_scenarios/demand_regional_balance_050.mod) |
| 17 | [code/extension_scenarios/demand_regional_balance_100.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/extension_scenarios/demand_regional_balance_100.mod) |
| 18 | [code/extension_scenarios/demand_regional_balance_150.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/extension_scenarios/demand_regional_balance_150.mod) |
| 19 | [code/extension_scenarios/demand_regional_balance_200.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/extension_scenarios/demand_regional_balance_200.mod) |
| 20 | [code/extension_scenarios/scenario_01_baseline.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/extension_scenarios/scenario_01_baseline.mod) |
| 21 | [code/extension_scenarios/scenario_02_risk_premium.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/extension_scenarios/scenario_02_risk_premium.mod) |
| 22 | [code/extension_scenarios/scenario_03_transfer_buffer.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/extension_scenarios/scenario_03_transfer_buffer.mod) |
| 23 | [code/extension_scenarios/scenario_04_risk_and_transfer.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/extension_scenarios/scenario_04_risk_and_transfer.mod) |
| 24 | [code/extension_scenarios/scenario_05_strong_io.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/extension_scenarios/scenario_05_strong_io.mod) |
| 25 | [code/extension_scenarios/scenario_06_weak_io.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/extension_scenarios/scenario_06_weak_io.mod) |
| 26 | [code/policy_counterfactual/policy_cf_baseline.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/policy_counterfactual/policy_cf_baseline.mod) |
| 27 | [code/policy_counterfactual/policy_cf_central_transfer_stabilizer.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/policy_counterfactual/policy_cf_central_transfer_stabilizer.mod) |
| 28 | [code/policy_counterfactual/policy_cf_no_transfer_stabilizer.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/policy_counterfactual/policy_cf_no_transfer_stabilizer.mod) |
| 29 | [code/policy_counterfactual/policy_cf_regional_balance_taylor.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/policy_counterfactual/policy_cf_regional_balance_taylor.mod) |
| 30 | [code/policy_counterfactual/policy_cf_standard_taylor.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/policy_counterfactual/policy_cf_standard_taylor.mod) |
| 31 | [code/policy_counterfactual/policy_cf_strict_debt_cap.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/policy_counterfactual/policy_cf_strict_debt_cap.mod) |
| 32 | [code/scale_development/scale_development_y100.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/scale_development/scale_development_y100.mod) |
| 33 | [code/scale_development/scale_development_y150.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/scale_development/scale_development_y150.mod) |
| 34 | [code/scale_development/scale_development_y200.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/scale_development/scale_development_y200.mod) |
| 35 | [code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/baseline/RANK_two_region_stackelberg.mod) |
| 36 | [code/stackelberg_B/robustness/scheme_A/RANK_two_region_scheme_A.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/scheme_A/RANK_two_region_scheme_A.mod) |
| 37 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/alpha_high/A/RANK_scheme_A_alpha_high.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/alpha_high/A/RANK_scheme_A_alpha_high.mod) |
| 38 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/alpha_high/B/RANK_scheme_B_alpha_high.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/alpha_high/B/RANK_scheme_B_alpha_high.mod) |
| 39 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/alpha_low/A/RANK_scheme_A_alpha_low.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/alpha_low/A/RANK_scheme_A_alpha_low.mod) |
| 40 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/alpha_low/B/RANK_scheme_B_alpha_low.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/alpha_low/B/RANK_scheme_B_alpha_low.mod) |
| 41 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/baseline/A/RANK_scheme_A_baseline.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/baseline/A/RANK_scheme_A_baseline.mod) |
| 42 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/baseline/B/RANK_scheme_B_baseline.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/baseline/B/RANK_scheme_B_baseline.mod) |
| 43 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/chiIG_high/A/RANK_scheme_A_chiIG_high.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/chiIG_high/A/RANK_scheme_A_chiIG_high.mod) |
| 44 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/chiIG_high/B/RANK_scheme_B_chiIG_high.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/chiIG_high/B/RANK_scheme_B_chiIG_high.mod) |
| 45 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/chiIG_low/A/RANK_scheme_A_chiIG_low.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/chiIG_low/A/RANK_scheme_A_chiIG_low.mod) |
| 46 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/chiIG_low/B/RANK_scheme_B_chiIG_low.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/chiIG_low/B/RANK_scheme_B_chiIG_low.mod) |
| 47 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/gamma_high/A/RANK_scheme_A_gamma_high.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/gamma_high/A/RANK_scheme_A_gamma_high.mod) |
| 48 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/gamma_high/B/RANK_scheme_B_gamma_high.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/gamma_high/B/RANK_scheme_B_gamma_high.mod) |
| 49 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/gamma_low/A/RANK_scheme_A_gamma_low.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/gamma_low/A/RANK_scheme_A_gamma_low.mod) |
| 50 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/gamma_low/B/RANK_scheme_B_gamma_low.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/gamma_low/B/RANK_scheme_B_gamma_low.mod) |
| 51 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/phiI_high/A/RANK_scheme_A_phiI_high.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/phiI_high/A/RANK_scheme_A_phiI_high.mod) |
| 52 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/phiI_high/B/RANK_scheme_B_phiI_high.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/phiI_high/B/RANK_scheme_B_phiI_high.mod) |
| 53 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/phiI_low/A/RANK_scheme_A_phiI_low.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/phiI_low/A/RANK_scheme_A_phiI_low.mod) |
| 54 | [code/stackelberg_B/robustness/sensitivity_sanity/generated/phiI_low/B/RANK_scheme_B_phiI_low.mod](C:/Users/Chow/Desktop/codex/RANK_endo/code/stackelberg_B/robustness/sensitivity_sanity/generated/phiI_low/B/RANK_scheme_B_phiI_low.mod) |
