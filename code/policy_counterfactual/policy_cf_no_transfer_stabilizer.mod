// Baseline two-region TANK DSGE model.
// Simplified first pass:
// - no local government bond risk premium: mu_b = 0
// - no earmarked transfer effect in the public investment rule: psi_z = 0
// - no technology, government spending, transfer, or public investment shocks
// - only a common contractionary monetary policy shock is active
// - asset market is closed by common risk-free Euler for region 1 and risk-sharing condition for region 2

var
    cr1 ch1 c1 nr1 nh1 n1 inv1 k1 qk1 lam1
    y1 ym1 w1 rk1 mc1 pinf1 pim1 pstar1 xone1 xtwo1 v1
    b1 rb1 ds1 fs1 fp1 ig1 kg1 a1 g1 tr1 z1
    cr2 ch2 c2 nr2 nh2 n2 inv2 k2 qk2 lam2
    y2 ym2 w2 rk2 mc2 pinf2 pim2 pstar2 xone2 xtwo2 v2
    b2 rb2 ds2 fs2 fp2 ig2 kg2 a2 g2 tr2 z2
    m11 m21 m12 m22
    q11 q21 q12 q22
    yagg pinfagg r mp;

varexo emp;

predetermined_variables k1 k2 kg1 kg2;

parameters
    beta sigma varphi chi_n lambda1 lambda2
    delta_k delta_g phi_i alpha gamma_g
    theta_p epsilon_p omega1 omega2 eta
    rho_a rho_g rho_tr rho_z rho_fp rho_ig rho_mp rho_r
    phi_pi phi_y tau_y theta_T
    mu_b psi_ds psi_fs psi_b psi_z phi_z_ds phi_z_b
    s1 s2
    rbar pinfbar ybar ybar1 ybar2 ymbar1 ymbar2 mcbar rkbar
    b_y1 b_y2 bbar1 bbar2
    kbar1 kbar2 invbar1 invbar2
    kgbar1 kgbar2 igbar1 igbar2
    nbar1 nbar2 wbar1 wbar2
    cbar1 cbar2 gbar1 gbar2 trbar1 trbar2
    dsbar1 dsbar2 fpbar1 fpbar2 fsbar1 fsbar2
    zbar1 zbar2;

// -------------------------------------------------------------------------
// Calibration block
// -------------------------------------------------------------------------
// Baseline principle: regions are symmetric in preferences, technology,
// price stickiness, fiscal-rule coefficients, public-capital externality,
// and interregional input weights. The only exogenous regional asymmetry in
// the baseline calibration is the steady-state local-debt ratio:
//     b_y2 > b_y1.
// This makes regional IRF differences attributable to local debt burdens.

// Common household and production parameters
beta       = 0.99;
sigma      = 2.00;
varphi     = 0.50;
lambda1    = 0.30;
lambda2    = 0.30;
delta_k    = 0.025;
delta_g    = 0.025;
phi_i      = 2.50;
alpha      = 0.45;
gamma_g    = 0.10;

// Common price-setting and interregional input aggregation parameters
theta_p    = 0.75;
epsilon_p  = 6.00;
omega1     = 0.85;
omega2     = 0.85;
eta        = 0.90;

// Common policy and fiscal-rule parameters
rho_a      = 0.70;
rho_g      = 0.70;
rho_tr     = 0.70;
rho_z      = 0;
rho_fp     = 0.70;
rho_ig     = 0.70;
rho_mp     = 0.70;
rho_r      = 0.70;
phi_pi     = 1.50;
phi_y      = 0.50;
tau_y      = 0.40;
theta_T    = 0.60;

mu_b       = 0.00;
psi_ds     = 0.10;
psi_fs     = 0.10;
psi_b      = 0.05;
psi_z      = 0;
phi_z_ds   = 0;
phi_z_b    = 0;
s1         = 0.50;
s2         = 0.50;

// Steady-state targets and internally consistent calibration.
// The two regions are symmetric except for steady-state local debt ratios.
pinfbar    = 1.00;
rbar       = 1 / beta;
ybar1      = 1.00;
ybar2      = 1.00;
ybar       = s1 * ybar1 + s2 * ybar2;

mcbar      = (epsilon_p - 1) / epsilon_p;
rkbar      = rbar - 1 + delta_k;
ymbar1     = omega1 * ybar1 + (1 - omega2) * ybar2;
ymbar2     = (1 - omega1) * ybar1 + omega2 * ybar2;

// Only exogenous regional asymmetry in the baseline:
// region 1 is low-debt, region 2 is high-debt.
b_y1       = 0.40;
b_y2       = 1.00;
bbar1      = b_y1 * ybar1;
bbar2      = b_y2 * ybar2;

igbar1     = 0.08 * ybar1;
igbar2     = 0.08 * ybar2;
kgbar1     = igbar1 / delta_g;
kgbar2     = igbar2 / delta_g;

kbar1      = alpha * mcbar * ymbar1 / rkbar;
kbar2      = alpha * mcbar * ymbar2 / rkbar;
invbar1    = delta_k * kbar1;
invbar2    = delta_k * kbar2;

nbar1      = (ymbar1 / (kgbar1^gamma_g * kbar1^alpha))^(1 / (1 - alpha));
nbar2      = (ymbar2 / (kgbar2^gamma_g * kbar2^alpha))^(1 / (1 - alpha));
wbar1      = (1 - alpha) * mcbar * ymbar1 / nbar1;
wbar2      = (1 - alpha) * mcbar * ymbar2 / nbar2;

gbar1      = 0.12 * ybar1;
gbar2      = 0.12 * ybar2;
cbar1      = ybar1 - invbar1 - gbar1 - igbar1;
cbar2      = ybar2 - invbar2 - gbar2 - igbar2;

trbar1     = cbar1 - wbar1 * nbar1;
trbar2     = cbar2 - wbar2 * nbar2;
chi_n      = cbar1^(-sigma) * wbar1 / (nbar1^varphi);

dsbar1     = (rbar - 1) * bbar1 / ybar1;
dsbar2     = (rbar - 1) * bbar2 / ybar2;
fpbar1     = dsbar1;
fpbar2     = dsbar2;
fsbar1     = igbar1;
fsbar2     = igbar2;

// zbar1 and zbar2 are residual steady-state fiscal closures. They differ
// because debt service differs, not because transfer-policy parameters differ.
zbar1      = fsbar1 + (rbar - 1) * bbar1 + gbar1 + lambda1 * trbar1
             - (1 - theta_T) * tau_y * ybar1;
zbar2      = fsbar2 + (rbar - 1) * bbar2 + gbar2 + lambda2 * trbar2
             - (1 - theta_T) * tau_y * ybar2;

model;
    # sinv1  = phi_i / 2 * (inv1 / inv1(-1) - 1)^2;
    # spinv1 = phi_i * (inv1 / inv1(-1) - 1);
    # spinv1p = phi_i * (inv1(+1) / inv1 - 1);
    # sinv2  = phi_i / 2 * (inv2 / inv2(-1) - 1)^2;
    # spinv2 = phi_i * (inv2 / inv2(-1) - 1);
    # spinv2p = phi_i * (inv2(+1) / inv2 - 1);

    // Region 1 households and private capital
    lam1 = cr1^(-sigma);
    lam1 = beta * lam1(+1) * r / pinf1(+1);
    chi_n * nr1^varphi = lam1 * w1;
    ch1 = w1 * nh1 + tr1;
    chi_n * nh1^varphi = ch1^(-sigma) * w1;
    c1 = (1 - lambda1) * cr1 + lambda1 * ch1;
    n1 = (1 - lambda1) * nr1 + lambda1 * nh1;
    k1(+1) = (1 - delta_k) * k1 + (1 - sinv1) * inv1;
    qk1 = beta * (lam1(+1) / lam1) * (rk1(+1) + (1 - delta_k) * qk1(+1));
    1 = qk1 * (1 - sinv1 - spinv1 * inv1 / inv1(-1))
        + beta * (lam1(+1) / lam1) * qk1(+1) * spinv1p * (inv1(+1) / inv1)^2;

    // Region 2 households and private capital
    lam2 = cr2^(-sigma);
    lam2 = lam1 * q11 / q12;
    chi_n * nr2^varphi = lam2 * w2;
    ch2 = w2 * nh2 + tr2;
    chi_n * nh2^varphi = ch2^(-sigma) * w2;
    c2 = (1 - lambda2) * cr2 + lambda2 * ch2;
    n2 = (1 - lambda2) * nr2 + lambda2 * nh2;
    k2(+1) = (1 - delta_k) * k2 + (1 - sinv2) * inv2;
    qk2 = beta * (lam2(+1) / lam2) * (rk2(+1) + (1 - delta_k) * qk2(+1));
    1 = qk2 * (1 - sinv2 - spinv2 * inv2 / inv2(-1))
        + beta * (lam2(+1) / lam2) * qk2(+1) * spinv2p * (inv2(+1) / inv2)^2;

    // Final goods firms and relative prices
    1 = (omega1 * q11^(1 - eta) + (1 - omega1) * q21^(1 - eta))^(1 / (1 - eta));
    m11 = omega1 * q11^(-eta) * y1;
    m21 = (1 - omega1) * q21^(-eta) * y1;

    1 = (omega2 * q22^(1 - eta) + (1 - omega2) * q12^(1 - eta))^(1 / (1 - eta));
    m22 = omega2 * q22^(-eta) * y2;
    m12 = (1 - omega2) * q12^(-eta) * y2;

    q11 / q11(-1) = pim1 / pinf1;
    q21 / q21(-1) = pim2 / pinf1;
    q12 / q12(-1) = pim1 / pinf2;
    q22 / q22(-1) = pim2 / pinf2;

    // Intermediate goods production and price setting
    log(a1) = rho_a * log(a1(-1));
    ym1 = a1 * kg1^gamma_g * k1^alpha * n1^(1 - alpha) / v1;
    w1 = (1 - alpha) * q11 * mc1 * ym1 * v1 / n1;
    rk1 = alpha * q11 * mc1 * ym1 * v1 / k1;
    ym1 = m11 + m12;
    1 = (1 - theta_p) * pstar1^(1 - epsilon_p) + theta_p * pim1^(epsilon_p - 1);
    xone1 = lam1 * q11 * mc1 * ym1
            + beta * theta_p * pim1(+1)^epsilon_p * xone1(+1);
    xtwo1 = lam1 * q11 * ym1
            + beta * theta_p * pim1(+1)^(epsilon_p - 1) * xtwo1(+1);
    pstar1 = epsilon_p / (epsilon_p - 1) * xone1 / xtwo1;
    v1 = (1 - theta_p) * pstar1^(-epsilon_p) + theta_p * pim1^epsilon_p * v1(-1);

    log(a2) = rho_a * log(a2(-1));
    ym2 = a2 * kg2^gamma_g * k2^alpha * n2^(1 - alpha) / v2;
    w2 = (1 - alpha) * q22 * mc2 * ym2 * v2 / n2;
    rk2 = alpha * q22 * mc2 * ym2 * v2 / k2;
    ym2 = m21 + m22;
    1 = (1 - theta_p) * pstar2^(1 - epsilon_p) + theta_p * pim2^(epsilon_p - 1);
    xone2 = lam2 * q22 * mc2 * ym2
            + beta * theta_p * pim2(+1)^epsilon_p * xone2(+1);
    xtwo2 = lam2 * q22 * ym2
            + beta * theta_p * pim2(+1)^(epsilon_p - 1) * xtwo2(+1);
    pstar2 = epsilon_p / (epsilon_p - 1) * xone2 / xtwo2;
    v2 = (1 - theta_p) * pstar2^(-epsilon_p) + theta_p * pim2^epsilon_p * v2(-1);

    // Local governments and public capital
    ds1 = (rb1(-1) / pinf1 - 1) * b1(-1) / y1;
    fs1 = (1 - theta_T) * tau_y * y1 + z1
          - (rb1(-1) / pinf1 - 1) * b1(-1) - g1 - lambda1 * tr1;
    rb1 / r = exp(mu_b * ((b1 / y1) / b_y1 - 1));
    fp1 = rho_fp * fp1(-1) + (1 - rho_fp) * ds1;
    ig1 / igbar1 = (ig1(-1) / igbar1)^rho_ig
        * exp(-psi_ds * (fp1 / fpbar1 - 1)
              + psi_fs * (fs1 / fsbar1 - 1)
              - psi_b * ((b1(-1) / y1(-1)) / b_y1 - 1)
              + psi_z * (z1 / zbar1 - 1));
    kg1(+1) = (1 - delta_g) * kg1 + ig1;
    b1 = rb1(-1) / pinf1 * b1(-1) + g1 + ig1 + lambda1 * tr1
         - (1 - theta_T) * tau_y * y1 - z1;
    log(g1 / gbar1) = rho_g * log(g1(-1) / gbar1);
    log(tr1 / trbar1) = rho_tr * log(tr1(-1) / trbar1);
    log(z1 / zbar1) = rho_z * log(z1(-1) / zbar1)
                      + phi_z_ds * (ds1 / dsbar1 - 1)
                      + phi_z_b * ((b1(-1) / y1(-1)) / b_y1 - 1);

    ds2 = (rb2(-1) / pinf2 - 1) * b2(-1) / y2;
    fs2 = (1 - theta_T) * tau_y * y2 + z2
          - (rb2(-1) / pinf2 - 1) * b2(-1) - g2 - lambda2 * tr2;
    rb2 / r = exp(mu_b * ((b2 / y2) / b_y2 - 1));
    fp2 = rho_fp * fp2(-1) + (1 - rho_fp) * ds2;
    ig2 / igbar2 = (ig2(-1) / igbar2)^rho_ig
        * exp(-psi_ds * (fp2 / fpbar2 - 1)
              + psi_fs * (fs2 / fsbar2 - 1)
              - psi_b * ((b2(-1) / y2(-1)) / b_y2 - 1)
              + psi_z * (z2 / zbar2 - 1));
    kg2(+1) = (1 - delta_g) * kg2 + ig2;
    b2 = rb2(-1) / pinf2 * b2(-1) + g2 + ig2 + lambda2 * tr2
         - (1 - theta_T) * tau_y * y2 - z2;
    log(g2 / gbar2) = rho_g * log(g2(-1) / gbar2);
    log(tr2 / trbar2) = rho_tr * log(tr2(-1) / trbar2);
    log(z2 / zbar2) = rho_z * log(z2(-1) / zbar2)
                      + phi_z_ds * (ds2 / dsbar2 - 1)
                      + phi_z_b * ((b2(-1) / y2(-1)) / b_y2 - 1);

    // Monetary policy, aggregation, and resource constraints
    yagg = s1 * y1 + s2 * y2;
    pinfagg = pinf1^s1 * pinf2^s2;
    mp = rho_mp * mp(-1) + emp;
    r / rbar = (r(-1) / rbar)^rho_r
        * ((pinfagg / pinfbar)^phi_pi * (yagg / ybar)^phi_y)^(1 - rho_r)
        * exp(mp);

    y1 = c1 + inv1 + g1 + ig1;
    y2 = c2 + inv2 + g2 + ig2;
end;

steady_state_model;
    cr1 = cbar1;
    ch1 = cbar1;
    c1 = cbar1;
    nr1 = nbar1;
    nh1 = nbar1;
    n1 = nbar1;
    inv1 = invbar1;
    k1 = kbar1;
    qk1 = 1;
    lam1 = cbar1^(-sigma);
    y1 = ybar1;
    ym1 = ymbar1;
    w1 = wbar1;
    rk1 = rkbar;
    mc1 = mcbar;
    pinf1 = pinfbar;
    pim1 = pinfbar;
    pstar1 = 1;
    xone1 = lam1 * mcbar * ymbar1 / (1 - beta * theta_p);
    xtwo1 = lam1 * ymbar1 / (1 - beta * theta_p);
    v1 = 1;
    b1 = bbar1;
    rb1 = rbar;
    ds1 = dsbar1;
    fs1 = fsbar1;
    fp1 = fpbar1;
    ig1 = igbar1;
    kg1 = kgbar1;
    a1 = 1;
    g1 = gbar1;
    tr1 = trbar1;
    z1 = zbar1;

    cr2 = cbar2;
    ch2 = cbar2;
    c2 = cbar2;
    nr2 = nbar2;
    nh2 = nbar2;
    n2 = nbar2;
    inv2 = invbar2;
    k2 = kbar2;
    qk2 = 1;
    lam2 = cbar2^(-sigma);
    y2 = ybar2;
    ym2 = ymbar2;
    w2 = wbar2;
    rk2 = rkbar;
    mc2 = mcbar;
    pinf2 = pinfbar;
    pim2 = pinfbar;
    pstar2 = 1;
    xone2 = lam2 * mcbar * ymbar2 / (1 - beta * theta_p);
    xtwo2 = lam2 * ymbar2 / (1 - beta * theta_p);
    v2 = 1;
    b2 = bbar2;
    rb2 = rbar;
    ds2 = dsbar2;
    fs2 = fsbar2;
    fp2 = fpbar2;
    ig2 = igbar2;
    kg2 = kgbar2;
    a2 = 1;
    g2 = gbar2;
    tr2 = trbar2;
    z2 = zbar2;

    m11 = omega1 * ybar1;
    m21 = (1 - omega1) * ybar1;
    m22 = omega2 * ybar2;
    m12 = (1 - omega2) * ybar2;
    q11 = 1;
    q21 = 1;
    q12 = 1;
    q22 = 1;
    yagg = ybar;
    pinfagg = pinfbar;
    r = rbar;
    mp = 0;
end;

shocks;
    var emp; stderr 0.0025;
end;

resid;
steady;
model_diagnostics;
check;

stoch_simul(order = 1, irf = 40, nograph)
    mp r rb1 rb2 yagg pinfagg
    z1 z2 b1 b2 ds1 ds2 fs1 fs2
    ig1 ig2 kg1 kg2
    y1 y2 c1 c2 inv1 inv2 pinf1 pinf2;
