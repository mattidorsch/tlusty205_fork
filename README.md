# tlusty205_fork

Tlusty 205 fork with updated treatment of pseudocontinua (after Hummer & Mihalas 1988).

For a general manual on Tlusty 205, see Hubeny & Lanz (2017a,b,c):

https://arxiv.org/abs/1706.01859
https://arxiv.org/abs/1706.01935
https://arxiv.org/abs/1706.01937

## Building

    make                 # t205_fork, using INCLUDE/
    make small           # same, without -mcmodel=medium
    make sdOstar2020     # t205_sdOstar2020
    make sdO_full        # t205_sdO_full
    make O70_d4_vhigh    # t205_O70_d4_vhigh
    make O70_d4_low      # t205_O70_d4_low
    make O70_d0.75_low   # t205_O70_d0.75_low

Variant targets take BASICS.FOR and ODFPAR.FOR from `INCLUDE/<variant>/` and the
remaining includes from `INCLUDE/`, compiling under `build/<variant>/`.

Variants are named `<type><ND>_d<DDNU>_<levels>`: the spectral type they are
dimensioned for, the depth points, the DDNU their frequency bounds assume, and
how many ion levels fit (low, mid, high, vhigh).

| variant | ND | DDNU | levels | MLEVEL | MFREQ | iron ODF | static |
| --- | --- | --- | --- | --- | --- | --- | --- |
| sdOstar2020 | 50 | 0.75 | high | 1596 | 350000 | yes | 3.0 GB |
| sdO_full | 70 | 4 | high | 1596 | 332432 | yes | 4.5 GB |
| O70_d4_vhigh | 70 | 4 | vhigh | 2400 | 332432 | yes, large line lists | 4.3 GB |
| O70_d4_low | 70 | 4 | low | 600 | 140000 | no | 0.9 GB |
| O70_d0.75_low | 70 | 0.75 | low | 150 | 190000 | no | 0.9 GB |

The two `low` variants set MKULEV, MLINE and MCFE to 2, so neither can compute
iron-group opacity distribution functions at all. `O70_d4_low` takes H, He and a
few CNO/Si ions; `O70_d0.75_low` is for H + He alone, at the finer DDNU those
models are usually run with.

A model over any bound stops in QUIT with the parameter named in fort.10. The
first line of fort.10 reports nfreq, nfreqc, nfreql and nflx against MFREQ,
MFREQC, MFREQP and MFREQL.

## Level dissolution

Level dissolution is switched on per level and per bound-free transition in the
atomic data file, not by a keyword:

| switch | where | effect |
| --- | --- | --- |
| `IFWOP` | 5th field of a level record | `0` no dissolution, `w=1`; `1` occupation probability computed; `2` generalized occupation probability for an iron-group superlevel (needs `ISPODF>0`, otherwise reset to 0); `<0` merged level, allowed only as an ion's last level |
| `MODE = ±5`, `±15` | 3rd field of a b-f record, followed by a record giving the cutoff frequency `FR0PC` | pseudo-continuum: the cross section is extrapolated below the edge, multiplied by the dissolved fraction `D(nu)`, and cut off hard at `FR0PC` |

`w` enters the Saha-Boltzmann factors, the radiative rates, and the line opacity
as `kappa ~ n_i w_j`; `D(nu) = 1 - w(m*)` multiplies the b-f cross section and
the matching photoionization rate in every opacity routine. The formulation is
that of Hummer & Mihalas (1988) and Hubeny, Hummer & Lanz (1994) -- see Paper II,
§ 12.4 -- with the critical field

    beta_c = 8.59e14 * Z^3 * K_n * n^-4 * ne^-2/3

evaluated in the hydrogenic approximation for any ion.

### What this fork changes

`DWNFR2` replaces the stock `DWNFR1` (which is now unused) and differs from it,
and from tlusty 208 and 3.0, in three ways:

1. `beta_c` is written in terms of the binding energy of the state the photon
   reaches, `beta_c ~ K_n * dE^2 / (Z Ry^2)`. This is algebraically the same as
   the hydrogenic expression, but it holds whatever the quantum defect, so it
   is what makes the treatment usable away from hydrogen and He II.
2. `K_n` is the full Hummer & Mihalas (1988) expression; stock tlusty drops its
   `(n+7/6)/(n^2+n+1/2)` factor, which matters at low `n`.
3. The Holtsmark normal field is normalised to the density of the charged
   perturbers rather than to `ne`, lowering `beta_c` by `(Ne/Nion)^(1/3)`. That
   factor is 1 in hydrogen and reaches `2^(1/3)` in ionized helium, so a He-rich
   subdwarf dissolves noticeably more than stock tlusty says. `DENS/WMM` counts
   every nucleus, so in partly neutral layers the perturber density -- and hence
   the suppression of dissolution -- is overstated.

`BERGFC` therefore no longer reaches the pseudo-continuum; it still scales the
occupation probabilities in `WNSTOR`/`WN`. It should be left at its default 1.

### Effective quantum numbers, and using dissolution for metals

Both `WNSTOR` (which fills `WOP`) and `DWNFR2` (which returns `D(nu)`) need a
quantum number, and for a non-hydrogenic ion neither the principal quantum
number nor the nominal `NQUANT` of a merged level is the right one. Both now use
the effective quantum number implied by the binding energy,

    n* = Z * sqrt(nu_H / nu_bind)

which is the principal quantum number itself for a hydrogenic ion, so H I and
He II are unaffected. Specifically:

- `WNSTOR` took `NQUANT` from the atomic data file. In the current model atoms
  `NQUANT` is a placeholder -- commonly 20 -- for exactly the high-lying and
  merged levels where dissolution acts, so `IFWOP=1` could not safely be set on
  a metal atom before. Levels at or above the ionization limit (`ENION <= 0`,
  autoionizing, converging to an excited parent) are now left undissolved
  rather than being given the occupation probability of a Rydberg state.
- `DWNFR2` scaled `n*` by the ground-state ionization energy instead of the
  Rydberg energy. That is exact for H I and He II but misses `n*` by
  `sqrt(Z^2 nu_H / nu_gs)` for anything else: a factor 2-3 too little
  dissolution for C IV or Si IV, and up to 44% too much for He I.

`SIGK` returned exactly zero below the first tabulated point of an Opacity
Project cross section (`IFANCY > 100`), which is typically only 0.2% below the
threshold. Since every modern metal atom uses those tables, a `MODE=5` continuum
on a metal was very nearly dead -- C III, the one light metal that carries
pseudo-continua, realised some 12-23% of the opacity its `FR0PC` cutoffs ask
for. The tabulated fit is now continued below the threshold when, and only when,
`SIGK` is called in extrapolating mode, i.e. for a pseudo-continuum.

Two further fixes: `nncdw` was counted before `TRAINI` assigned `MCDW`, so it
was always zero -- the `Too many pseudo-continua` guard never fired and `DWF1`
could be written past its end. It is now counted after `TRAINI`, and `MMCDW` is
raised from 19 to 100 (H, He I, He II and C III already use 16). The legacy
`DWNFR`, still called by `PRINC` for its diagnostics, multiplied by an
undeclared `berfc` rather than `bergfc` and so always reported `D = 1`.

### What to expect

Dissolution is governed by the binding energy, not by the element. At
`T = 40000 K` a level bound by 1 eV keeps `w > 0.95` up to `ne = 1e16`, whereas
one bound by 0.25 eV is already 80% dissolved at `ne = 3e15`:

| `w` at T = 40000 K, Z = 3 | ne = 1e15 | 3e15 | 1e16 | 3e16 | 1e17 |
| --- | --- | --- | --- | --- | --- |
| E_bind = 2.0 eV | 1.000 | 1.000 | 0.999 | 0.996 | 0.986 |
| E_bind = 1.0 eV | 0.998 | 0.995 | 0.981 | 0.941 | 0.785 |
| E_bind = 0.5 eV | 0.975 | 0.917 | 0.689 | 0.287 | 0.049 |
| E_bind = 0.33 eV | 0.860 | 0.555 | 0.144 | 0.023 | 0.003 |

What this does to a **metal** is best read per level, not per ion. The totals
barely move: switching `IFWOP` on for every metal changes any metal ion's total
population by under 1e-3, and leaves the ionization balance and the model
structure alone. Individual high-lying levels are another matter. They sit
close to the continuum, so they are populated by recombination and their
populations follow `w` directly. At Teff 39000 and log g 5.8, going from
`IFWOP=0` to `IFWOP=1` at fixed structure gives, at the depths where the
optical lines form:

| level | E_bind | n* | n(w=1) -> n(w) |
| --- | --- | --- | --- |
| Si III `1Do 2` | 0.33 eV | 19.3 | 0.60 / 0.26 / 0.14 (depths 41/46/49) |
| N III `+4_e 6` | 0.61 eV | 14.2 | 0.97 / 0.91 / 0.86 |
| N III `2Pe 4` | 0.63 eV | 13.9 | 0.98 / 0.93 / 0.88 |
| N II `+___10` | 0.63 eV | 9.3 | 0.99 / 0.98 / 0.96 |

Those are exactly the levels that carry the optical lines of a nearly-fully
ionized species -- Si III 4018, 4027, 5640, 5690; N III 4236, 5324, 6333;
N II 3521-7464 -- so an ion whose total population is untouched can still have
its optical lines suppressed by a large factor. Most of those transitions
involve a superlevel, so the wavelength is a population-weighted mean and says
only which region of the spectrum the bundle lives in; what is physical is the
level population. The detailed C II atom's top level, `C2 +4_o 5`, is bound by
0.018 eV (n* = 55) and is more than 99.9% dissolved throughout the photosphere.

The effect steepens quickly with gravity. Taking the depth where T = Teff at
40000 K:

| approx log g | 4.5 | 5.0 | 5.5 | 6.0 | 6.5 | 7.0 |
| --- | --- | --- | --- | --- | --- | --- |
| Si III `1Do 2` (0.33 eV) | 0.91 | 0.78 | 0.49 | 0.20 | 0.046 | 0.009 |
| N III `+4_e 6` (0.61 eV) | 0.99 | 0.98 | 0.96 | 0.89 | 0.71 | 0.38 |
| Mg II `+2__4` (0.55 eV) | 1.00 | 0.99 | 0.98 | 0.95 | 0.87 | 0.65 |
| N II `+___10` (0.63 eV) | 1.00 | 1.00 | 0.99 | 0.97 | 0.93 | 0.80 |

How much of this a model sees depends on how far up its atoms reach. The
compact atoms stop 0.9-4 eV below their limits and show only a 3-5% effect
(C II `+2__5` -> 0.971, N III `+4__7` -> 0.949); the detailed ones reach
0.018-0.6 eV and give the numbers above. H I, He I and He II carry levels
closer still and dissolve strongly -- at these gravities He I loses up to 12%
of its total population at `tau ~ 1` -- which is why they have always had
`IFWOP=1`.

Which model atoms this is worth setting on, ranked by how much their topmost
bound level dissolves (T = 40000 K, at the depth where T = Teff):

| atom file | top bound level | E_bind | n* | w at log g 5.0 / 5.8 / 6.5 |
| --- | --- | --- | --- | --- |
| `c2_34+5lev` | `C2 +4_o 5` | 0.018 eV | 55 | 0.000 / 0.000 / 0.000 |
| `si3_31+15lev` | `Si3 1Do 2` | 0.329 eV | 19 | 0.63 / 0.20 / 0.03 |
| `c1_28+12lev` | `C1 +3__12` | 0.153 eV | 9.4 | 0.72 / 0.28 / 0.05 |
| `ne1_23+12lev` | `Ne1 +1__12` | 0.153 eV | 9.4 | 0.72 / 0.28 / 0.05 |
| `o1_23+10lev` | `O1 +3__10` | 0.153 eV | 9.4 | 0.72 / 0.28 / 0.05 |
| `n3_40+9lev` | `N3 +4_e 6` | 0.608 eV | 14 | 0.97 / 0.89 / 0.65 |
| `mg2_21+4lev`, `si2_36+4lev`, `mn2_40lev` | | 0.55 eV | 10 | 0.99 / 0.95 / 0.84 |
| `n2_32+10lev`, `ar2`, `s2`, `fe3`, ... | | 0.6-0.9 eV | 9-12 | 0.99 / 0.97 / 0.9 |

The neutrals `c1`, `ne1` and `o1` each carry six levels with w < 0.95 at
log g 5.8. Everything not listed keeps w > 0.98 even at log g 6.5.

The other metal effect is the pseudo-continuum opacity below the metal edges.
That is an opacity effect, not a population effect, and it needs `MODE=5` and
`FR0PC` in the atomic data file, not just `IFWOP`.

### Note for spectrum synthesis

`synspec` computes its own occupation probabilities from the same atomic data
files, in its own `WNSTOR` and `DWNFR1`, and both carry the two problems fixed
here: `WNSTOR` takes the quantum number from `NQUANT`, and `DWNFR1` scales n* by
the ground-state ionization energy. Until the same corrections are made there,
`synspec` and tlusty will disagree about w for any non-hydrogenic level.
`synspec` also applies `BERGFC` to beta where `DWNFR2` no longer does.

`synspec` assigns each line-list level the population of the nearest-in-energy
explicit level, scaled by (2J+1)/g, so a dissolved level's reduced population is
inherited by every line-list level in its energy window -- for Si III, that is
everything bound by less than about 1 eV. Line-list levels above the highest
explicit level instead get pure LTE populations when `INLTE=1` in fort.55, i.e.
no dissolution at all for the states that are the most dissolved of any.
