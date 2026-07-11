# Black-Scholes Greeks from First Principles

This example derives, deploys, and validates exact analytical Greeks for European options using the Black-Scholes model for options pricing.

The Black-Scholes PDE has an exact closed-form solution, which means every Greek (Delta, Gamma, Vega, Theta, Rho, Vanna, Volga, Charm, Speed) comes out as a symbolic partial derivative. That parametric form gives you the full sensitivity surface in one expression, versus a bump-and-revalue approach.

The same workflow applies to any pricing PDE with a known functional form: put-call parity Greeks, digital/barrier options via limits, near-ATM polynomial approximations via Taylor expansion, or multi-asset cross-Greeks via the Jacobian.

## Example Outline

### 1. Geometric Brownian Motion and Ito's Lemma
Symbolic declaration of the Black-Scholes PDE from first principles: GBM dynamics, Ito's lemma on a twice-differentiable option value $V(S,t)$, and the no-arbitrage condition on a delta-hedged portfolio.

### 2. Analytic Solution Verification
States the known European call formula $C = S\,N(d_1) - Ke^{-r\tau}N(d_2)$ and proves it satisfies the PDE — the residual simplifies to exactly zero.

- `diff` — partial derivatives forming the PDE operator
- `simplify` — verify residual is identically zero

### 3. Extract All Greeks as Exact Partial Derivatives
Each Greek is a symbolic partial derivative of the option price. First-order (Delta, Vega, Theta, Rho) and second-order (Gamma, Vanna, Volga, Charm, Speed) Greeks are computed in closed form.

- `diff` — first and higher partial derivatives
- `simplify` — canonical form for each Greek expression

### 4. Put-Call Parity: Put Greeks by Differentiation
Put-call parity $P = C - S + Ke^{-r\tau}$ is differentiated symbolically to yield all put Greeks without re-derivation. The parity identities (put Delta = call Delta − 1, put Gamma = call Gamma) are verified exactly.

- `diff`, `simplify` — derive and verify parity relations

### 5. Near-ATM Taylor Expansions
Taylor expansion of Delta and Gamma around $S = K$ gives polynomial approximations for the moneyness regime where most hedging activity occurs. The Brenner-Subrahmanyam ATM call price approximation $C_{ATM} \approx K\sigma\sqrt{\tau}/\sqrt{2\pi}$ is derived by expanding in $\sigma$ under zero rates.

- `taylor` — systematic expansion in moneyness and volatility
- `subs` — substitute ATM condition before expanding

### 6. Barrier and Digital Option Limits
Digital (binary) call pricing as the limit of a call spread whose width goes to zero. The result $e^{-r\tau}N(d_2)$ is verified symbolically. Digital Greeks are computed exactly, which is critical near the barrier where finite differences are unreliable.

- `limit` — exact evaluation of the call-spread limit
- `subs` — construct shifted strikes symbolically

### 7. Multi-Asset Cross-Greeks via Jacobian
A two-asset portfolio's full cross-Greek matrix (4×4: sensitivities of Delta and Vega for each asset with respect to both spots and both vols) computed in one `jacobian` call.

- `jacobian` — matrix of all partial derivatives simultaneously
- `assume` — correlation bounds $-1 < \rho < 1$

### 8. Code Generation: Deploy to Pricing Engine
Convert symbolic Greek expressions into optimized MATLAB&reg; functions via `matlabFunction`. Three function files are generated: first-order Greeks, second-order Greeks, and near-ATM Taylor approximations.

- `matlabFunction` — generates `bsGreeks.m`, `bsGreeksSecondOrder.m`, `bsGreeksATM.m`

### 9. Numerical Evaluation: Greek Surface
Evaluate the exact Greeks across the full $(S, \tau)$ surface using realistic equity index parameters: $K = 4500$, $r = 4.5\%$, $\sigma = 18\%$. Surface plots of Delta, Gamma, Theta, and Vega.

### 10. Taylor Approximation Accuracy
Compare exact Delta against the near-ATM Taylor approximation across moneyness. The polynomial is extremely accurate within $\pm5\%$ of ATM, where most hedging activity occurs.

### 11. Validate Against Financial Toolbox
All symbolic Greeks validated against `blsprice`, `blsdelta`, `blsgamma`, `blsvega`, `blstheta`, `blsrho` to confirm the derivation is correct end-to-end.

### 12. Monte Carlo with Exact Greeks
50,000-path GBM simulation with exact Greeks evaluated at every weekly rebalancing point. Delta-hedge P&L distribution shows that discrete rebalancing error (not Greek noise) is the dominant residual. Performance benchmark: exact evaluation vs. bump-and-revalue timing and accuracy.

- `randn` — GBM path generation
- Vectorized Greek evaluation along all paths — no inner bump loop

## What Gets Generated

Running the example produces deployable MATLAB functions:

| Generated file | Signature | Use case |
|----------------|-----------|----------|
| `bsGreeks.m` | `[Price, Delta, Gamma, Vega, Theta, Rho] = bsGreeks(S, K, r, sigma, tau)` | First-order Greeks for pricing engines and risk aggregation |
| `bsGreeksSecondOrder.m` | `[Vanna, Volga, Charm, Speed] = bsGreeksSecondOrder(S, K, r, sigma, tau)` | Second-order Greeks for volatility risk and gamma scalping |
| `bsGreeksATM.m` | `[DeltaATM, GammaATM] = bsGreeksATM(S, K, r, sigma, tau)` | Near-ATM Taylor approximations for real-time dashboards |

All functions accept vectorized inputs. C code equivalents are available via `ccode()` for integration with low-latency pricing engines.

## Quick Start

### Requirements

- [MATLAB](https://www.mathworks.com/products/matlab.html) R2024b or later
- [Symbolic Math Toolbox&trade;](https://www.mathworks.com/products/symbolic.html)
- [Financial Toolbox&trade;](https://www.mathworks.com/products/finance.html) (for validation in Section 11 only)

### Running the Example

1. Open MATLAB and navigate to this directory
2. Open **`BlackScholesGreeks.m`** as a Live Script
3. Run section by section, or run all — the example is self-contained

The generated functions (`bsGreeks.m`, `bsGreeksSecondOrder.m`, `bsGreeksATM.m`) are written to the working directory at runtime.

## Files

| File | Description |
|------|-------------|
| `BlackScholesGreeks.m` | Main example (Live Script). Full workflow from PDE derivation through Monte Carlo deployment. |
| `bsGreeks.m` | Generated at runtime. First-order Greeks (Price, Delta, Gamma, Vega, Theta, Rho). |
| `bsGreeksSecondOrder.m` | Generated at runtime. Second-order Greeks (Vanna, Volga, Charm, Speed). |
| `bsGreeksATM.m` | Generated at runtime. Near-ATM Taylor approximations. |
