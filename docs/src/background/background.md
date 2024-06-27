# Background

## Heat integration

Process integration is a useful tool for benchmarking the potential for
heat recovery in a system. It was first conceptualized through Pinch
Analysis, a method that revolves around finding the process pinch point
where the hot and cold composite curves converge. At the pinch point the
process can be decoupled into two parts; a heat deficit region above
pinch and a heat surplus region below. Consequently, any heat transfer
across the pinch constitutes taking heat from the heat surplus region
and supply it to the heat deficit region. One therefore can maximize
heat recovery by eliminating any existing cross pinch heat transfer.
More times than not, however, the maximum energy recovery (MER) design
serves as an upper limit to heat integration that would require
significant capital investments to realize. Meanwhile, the actual best
design is very much dependent on the application and weighs capital
expenditures to heat recovery. Although originally based on a manual
procedure, mathematical optimization has since found its way into the
heat integration community, and today many automated pinch location
algorithms exist in the literature [DURAN1986, KRAVANJA1998, QUIRANTE2017, QUIRANTE2018, NIELSEN2019](@cite).


The oldest and among the most well known pinch location algorithms is
the transshipment model by Papoulias and Grossmann [PAPOULIAS1983](@cite). The
transshipment model formulates the heat integration target as a linear
program (LP) that lumps the individual stream contributions into heat
residuals that cascades down the temperature intervals. The maximum
energy recovery (MER) design is the arrangement with the least hot
utility supply (see Equations PAPOULIAS and HEATINTERVAL). Though inherently more simplistic than
the pinch location algorithms listed above, the transshipment model
benefits from its auspicious linear formulation and favourable scaling.

$$\tag{PAPOULIAS}
\begin{aligned}
& \underset{r_i}{\text{minimize}}
& & r_0\\
& \text{subject to} 
& &  r_i = r_{i-1} + q_i, \quad \forall i\in M,\\
& & & r_i \geq 0, \quad \forall i\in M, \\
\end{aligned}$$ where $r_i$ are the heat residuals in temperature
interval $i$, M is total number of streams, and $q_i$ is the surplus
heat as given by 

$$\tag{HEATINTERVAL}
    q_i = \sum_{m\in H} F_m(T_{i-1} - T_i) - \sum_{n\in C}f_n(t_{i-1}-t_i).$$
In Equation (HEATINTERVAL), $F$, $T$, $f$ and $t$ denote the heat
capacity flowrates and temperatures of the respective hot and cold
streams. The heat residual at a given temperature interval corresponds
to the surplus heat available at this temperature.

![Grand composite curve depicting the heat deficit region above pinch
and heat surplus region below.](composite_curve.png)


The transition model relies on temperatures and heat capacity flowrates
being known and fixed throughout. In an optimization model, it would
therefore make sense to nest the transshipment model in a separate
subroutine that calculates the heat residuals prior to optimizaiton of
the overall model. Although the model is normally applied to find the
optimal use of heat utilities (minimize external utility consumption),
the model has the advantage of mapping the residual heat present at
different temperature intervals. In other words, the transshipment model
can also be used to calculate the heat available or heat necessary at a
given temperature. This can be useful in cases where we look at
trans-process heat integration or heat recovery in different clusters.
Even though the fixed temperatures and heat capacity flowrates present
inherent limitations to the implementation of the model, there is a way
to bypass it, when looking at trans-process heat integration. In the
Intercur model, which was developed with heat integration of industrial
clusters in mind, a slight alteration was made to the model, where the
heat capacity flowrates were formulated as
$$F =\frac{mCp}{n_\textrm{product}}$$ where $n_\textrm{product}$ is used
to represent one unit of output product. In this case, the transshipment
model maps the available heat/heat needed per unit output product. As
for the fixed temperature intervals, this too can be circumvented in
cases where the possible discrete temperature intervals are known a
priori by adding a binary decision variable for whether the given
temperature intervals are active or not.

## Example of a possible implementation

To demonstrate a possible implementation of heat recovery in an overall
investment model, a simple example with an electrolyzer is used. Assume
that the Electrolyzer operates at a constant temperature
$T_\textrm{H} + \Delta T$, where $\Delta T$ is an arbitrary temperature
difference in the heat exchangers. To maintain this temperature, cooling
water is used, and is assumed to operate in the temperature interval
$T_\textrm{H}$ and $T_\textrm{C}$. It is moreover assumed that the
cooling water will always operate in this temperature interval, and that
the cooling capacity is regulated by regulating the mass flow (heat
capacity flowrate) in the heat exchangers.

![Heat recovery from an electrolyzer for using in a district heating
system](example_study.png)

Heat recovery is achieved by using the surplus heat in the cooling water
to heat up (partially or fully) the district heating water. The heat
that can be supplied to the district heating depends on the pinch point
temperature. As district heating involves heating a single cold stream
from a temperature $T_\textrm{c}$ to $T_\textrm{h}$, the pinch point
will be at the temperature $T_\textrm{c}$ as everything above that
constitutes the heat deficit region (heat must be supplied to the
system). In other words, $$T_\textrm{H} > T_\textrm{c},$$ if any heat
should be supplied to the system.

The amount of heat that can be supplied to the system depends on the
temperatures of $T_\textrm{C}$ and $T_\textrm{c}$ and of the heat
capacity flowrate of the cooling water in the electrolyzer
($F_\textrm{CW}$).

For instance, if $$T_\textrm{C} > T_\textrm{c},$$ the total heat that
can be delivered will be
$$Q = F_\textrm{cw}(T_\textrm{H}-T_\textrm{C}).$$ If however,
$$T_\textrm{c} > T_\textrm{C},$$ the total heat that can be delivered
will be limited to $$Q = F_\textrm{cw}(T_\textrm{H}-T_\textrm{c}).$$

As mentioned in the previous section, a limitation with the
transshipment model and how it calculates the residual heat at different
temperatures, is that it takes into account fixed temperature ranges and
heat capacity flowrates. As seen in this example, especially the
assumption about heat capacity flowrates remains invalid, in cases where
the electrolizer load varies. A workaround for this can be achieved by
expressing the heat residuals as a product of the heat capacity flowrate
per unit output product $F_\textrm{cw, u}$. That way the output product
at a time $t$ can be a decision variable in the overall investment
model, and the surplus heat available can be expressed as a factor of
this output product.

Let us say that $x_\textrm{el}$ denotes the amount of output product in
the electrolyzer (usually the output of hydrogen). A factor for the heat
capacity flowrate per unit output product could be to use the cooling
water need per hydrogen output at design conditions, i.e.
$$F_\textrm{cw, u}=\frac{m_\textrm{cw,d}Cp}{x_\textrm{el,d}},$$ where d
is used to denote operation at design conditions.

In most cases however, this factor need not be constant, as process
efficiency may vary at varying loads, in which case, the formulation
will be a little different. Now let us assume that
$\eta_\textrm{el}:X\to \mathbb{R}$ denotes the efficiency function under
varying loads $x \in X$. Unless $\eta_\textrm{el}$ is linear, the heat
available will not be linearly dependent on $x_\textrm{el}$, and the
previous formulation will be rendered insufficient. Another complicating
factor here is to preserve model linearity to fully benefit from the
vast toolbox that exists around mixed interger linear programs. In the
case of a nonlinear, yet convex efficiency function, this can be done by
representing $\eta_\textrm{el}$ as a series of piecewise affine
functions in the investment model. If such an approach is employed, one
has the ability to calculate the amount of waste heat in the
electrolyzer at different loads, by means of an energy balance.
$$q_\textrm{el} = p_\textrm{el} - \textrm{LHV}x_\textrm{el},$$ where
$p_\textrm{el}$ is the electrolyzer duty, $x_\textrm{el}$ is the
hydrogen output (in kg/s) and LHV is the lower heating value of
hydrogen. If we at the same time assumne a similar temperature interval
for the waste heat as before, we can assume that
$$q_\textrm{el} = F_\textrm{cw}(T_\textrm{H}-T_\textrm{C}),$$ or
$$F_\textrm{cw} = \frac{q_\textrm{el}}{T_\textrm{H}-T_\textrm{C}}.$$ In
other words, rather than defining the heat capacity flowrate as a
function of the amount of output product, one can get it from the energy
balance directly, given the constant temperature range of the cooling
water.

Now, what about the district heating system? District heating systems
are normally defined by their supply and return temperatures, and the
assumption of a constant temperature interval should thereby be valid
there. Instead, heat loads are regulated by altering the flowrate in the
system. In the example above, one could have routing to one or more
nodes (hubs) with an assigned heat load (which will be dependent on
time). There may also be heat losses in the system, which is equivalent
to increased loads. As temperatures are known a priori in such district
heating systems, the amount of heat that can be harnessed from the
electrolyzer operating over a defined heat interval will also be
quantifiable.

If, however, efficiencies is used, it would be advantageous to have heat
loads in the electrolyzer be defined for a $F_\textrm{cw} = 1$, and
$F_\textrm{dh} = 1$. That way, $\psi$ is the fraction of heat from the
electrolyzer that can be used for district heating given a similar heat
capacity flowrate for both streams. $\psi$ can then be defined as
$$\psi = \frac{T_\textrm{H}-T_\textrm{C}+\Delta T_\textrm{min}}{T_\textrm{h}-T_\textrm{c}}$$
if $$T_\textrm{C} - \Delta T_\textrm{min} \geq T_\textrm{c},$$ or
$$\psi = \frac{T_\textrm{H}-T_\textrm{c}+\Delta T_\textrm{min}}{T_\textrm{h}-T_\textrm{c}}$$
if $$T_\textrm{C} - \Delta T_\textrm{min} < T_\textrm{c},$$ where
$\Delta T_\textrm{min}$ is a constant minimum allowable temperature
difference for heat exchange.

Depending on the temperature intervals, there might be situations or
operating conditions where the electrolyzer cannot fully supply the heat
needed to operate the district heating systems. In such cases,
alternative (utility) heat sources may present an alternative. The same
is true when the temperatures $T_\textrm{H}$ and $T_\textrm{C}$ lay
below the supply and return temperatures of the district heating system.
Typical utility heat sources could be electric or gas boilers. Here, as
hydrogen is produced in the electrolyzer, sourcing some of the hydrogen
for using as a utility heat source could be an alternative, depending on
the efficiency of the electrolyzer.

![Heat recovery from an electrolyzer and an additional utility heat
source for use in a district heating
system](example_study2.png)

Utility heat could be either sensible (over a temperature interval) or
latent heat (e.g. through production of steam). In the case of sensible
heat, the approach would be analogous to the approach used for the
electrolyzer, whereas for latent heat, the latent heat of
evaporation/condensation would be used instead. Let us say for the sake
of the example that even with heat from the electrolyzer, the district
heating system still needs to cover a deficit heat load of
$q_\textrm{deficit}$. This heat load would have to come from a latent
heat utility source where the latent heat of evaporation is denoted by
$h_\textrm{evap}$. Then the mass flow of product from the utility heat
source would be
$$q_\textrm{deficit} = m_\textrm{util} h_\textrm{evap}.$$ From this, the
need for fuel can be calculated in the overall investment model by using
the following constraints in the district heating node
$$q_\textrm{dh} = \psi q_\textrm{el} + m_\textrm{util}  h_\textrm{evap},$$
$$q_\textrm{dh} \geq \sum_{n\in N_\textrm{h}} Q_n,$$ where
$N_\textrm{h}$ is used to denote the district heating hubs/customers and
$Q_n$ is the heat demand at these hubs.

## Different/unknown return temperatures for the district heating system

If there is unused capabilities in the district heating system, or one
wants to regulate the return temperature with decreasing loads, the
above-mentioned procedure will have to be expanded. One possibility is
to select a return temperature among possible discrete temperature
intervals. Each temperature interval would then have a distinct $\psi$
variable attached to it, calculated the same way as previously. One
would thereby assign binary variables to whether or not the return
temperature falls within the assigned temperature interval by the use of
big-M constraints.
$$T\leq \textrm{T}_{\textrm{max,}dT} + \textrm{T}_\textrm{max}(1-y_{dT}), \forall dT \in \{\delta T_1, \cdots, \delta T_n\}$$

$$T\geq \textrm{T}_{\textrm{min,}dT}y_{dT}, \forall dT \in \{\delta T_1, \cdots, \delta T_n\},$$
Where $T$ is the return temperature from the district heating system,
$y_{dT}$ is a binary variable denoting whether interval
$dT \in \{\delta T_1, \cdots, \delta T_n\}$ is active,
$\textrm{T}_\textrm{max}$ is the maximum allowable return temperature,
and $\textrm{T}_{\textrm{max/min,}dT}$ is the maximum/minimum
temperature of the temperature intervals.

By assuming an average $\psi_\textrm{avg}$ over the temperature
interval, a value for the recoverable heat from the electrolyzer can be
obtained.

$$q_{\textrm{el,}dh} \leq \psi_\textrm{avg} q_\textrm{el} + M(1-y_{dt}),$$

$$q_{\textrm{el,}dh} \geq \psi_\textrm{avg} q_\textrm{el} - M(1-y_{dt})$$

## References
```@bibliography
```