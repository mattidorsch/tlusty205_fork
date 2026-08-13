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
