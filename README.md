# tlusty205_fork

Tlusty 205 fork with updated treatment of pseudocontinua (after Hummer & Mihalas 1988).

For a general manual on Tlusty 205, see Hubeny & Lanz (2017a,b,c):

https://arxiv.org/abs/1706.01859
https://arxiv.org/abs/1706.01935
https://arxiv.org/abs/1706.01937

## Building

    make                # t205_fork, using INCLUDE/
    make small          # same, without -mcmodel=medium
    make sdOstar2020    # t205_sdOstar2020 (ND=50)
    make sdO_full       # t205_sdO_full

Variant targets take BASICS.FOR and ODFPAR.FOR from `INCLUDE/<variant>/` and the
remaining includes from `INCLUDE/`, compiling under `build/<variant>/`.
