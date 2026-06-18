# Particle Discovery Timeline (auxiliary flare)

> Shared data for the Particles scale. Both `collider` and `accelerator` surface entries from
> this list **chronologically** as the player lands collisions/PERFECTs. It is **non-scoring,
> auxiliary** — pros ignore it, new players learn from it ("woah, I didn't know that").
>
> Rule: advance one entry per qualifying event (PERFECT collision / triggered collision), in
> historical order. Show `name · year · discoverer` + the one-liner. Loop or hold at Higgs.

| # | Particle | Year | Discoverer(s) | One-liner |
|---|---|---|---|---|
| 1 | Electron | 1897 | J.J. Thomson | First subatomic particle found — in cathode rays. |
| 2 | Photon | 1905 | Albert Einstein | The quantum of light (name "photon" coined 1926 by Gilbert Lewis). |
| 3 | Proton | 1917–1920 | Ernest Rutherford | The positive heart of the nucleus. |
| 4 | Neutron | 1932 | James Chadwick | The neutral partner that completes the nucleus. |
| 5 | Positron | 1932 | Carl Anderson | First antimatter ever seen — the electron's mirror. |
| 6 | Muon | 1936 | Anderson & Neddermeyer | A heavy cousin of the electron — "who ordered that?" |
| 7 | Pion | 1947 | Cecil Powell | The glue of the nucleus (predicted by Yukawa, 1935). |
| 8 | Kaon | 1947 | Rochester & Butler | A "strange" particle that lived too long. |
| 9 | Antiproton | 1955 | Chamberlain & Segrè | The proton's antimatter twin. |
| 10 | Neutrino | 1956 (detected) | Cowan & Reines | The ghost particle (proposed by Pauli, 1930). |
| 11 | Quarks | 1964 (proposed) | Gell-Mann & Zweig | The imprisoned trio inside protons & neutrons (seen 1968, SLAC). |
| 12 | Charm quark (J/ψ) | 1974 | Richter & Ting | The "November Revolution" that confirmed quarks. |
| 13 | Tau lepton | 1975 | Martin Perl | The heaviest cousin of the electron. |
| 14 | Bottom quark | 1977 | Leon Lederman | Found in the Upsilon at Fermilab. |
| 15 | W & Z bosons | 1983 | CERN (Rubbia, UA1/UA2) | Carriers of the weak force. |
| 16 | Top quark | 1995 | Fermilab (CDF & DØ) | The last and heaviest quark. |
| 17 | Higgs boson | 2012 | CERN (ATLAS & CMS) | The particle that gives mass — the timeline's finale. |

## Implementation notes
- Store as a const list `{name, year, who, blurb}` in a small Dart file at this scale
  (e.g. `particle_timeline.dart`); both games import it. Canvas-rendered text card, no assets.
- Surface as a brief, dismissible flare (fade in/out) near the collision point or in a HUD ribbon.
  Never blocks input; never affects score.
- The 4 EDUCATION blocks (quarks, electrons, photons, neutrinos) are a subset — the timeline is
  the richer "learn every particle" layer.
