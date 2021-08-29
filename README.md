# I3DA-2021: Measurement of a car cabin binaural impulse response and auralization via convolution

<p align="left">
  <a href="https://github.com/eac-ufsm/i3da-2021/releases/" target="_blank">
    <img alt="GitHub release" src="https://img.shields.io/github/v/release/eac-ufsm/i3da-2021?include_prereleases&style=flat-square">
  </a>

  <a href="https://github.com/eac-ufsm/i3da-2021/commits/master" target="_blank">
    <img src="https://img.shields.io/github/last-commit/eac-ufsm/i3da-2021?style=flat-square" alt="GitHub last commit">
  </a>

  <a href="https://github.com/eac-ufsm/i3da-2021/issues" target="_blank">
    <img src="https://img.shields.io/github/issues/eac-ufsm/i3da-2021?style=flat-square&color=red" alt="GitHub issues">
  </a>

  <a href="https://github.com/eac-ufsm/i3da-2021/blob/master/LICENSE" target="_blank">
    <img alt="LICENSE" src="https://img.shields.io/github/license/eac-ufsm/i3da-2021?style=flat-square&color=yellow">
  <a/>

</p>
<hr>


Repository with support files for the I3DA paper "Measurement of a car cabin binaural impulse response and auralization via convolution"


## Description
This repository contains the resources necessary to reproduce the complete pipeline for recording and reproducing binaural signal, in the scope of the paper. The processing chain, sofa files and binaural examples are also available.


## Folder structure:
  - ```/Auralization:``` Contains the scripts to assemble, post process, and make auralization with .sofa files.


# Cite us

> William D’Andrea Fonseca; Felipe Ramos de Mello; Davi Rocha Carvalho; Paulo Henrique Mareze; Olavo M. Silva. “Measurement of car cabin binaural impulse responses and auralization via convolution,” in *International Conference on Immersiveand 3D Audio — I3DA*, Bologna, Italy, Sep. 2021, pp. 1—13.

**Bibtex:**
```
@InProceedings{I3DA:binauralMEMS,
  author    = {William {\relax D’A}ndrea Fonseca and Felipe Ramos de Mello and Davi Rocha Carvalho and Paulo Henrique Mareze and Olavo M. Silva},
  booktitle = {{International Conference on Immersive and 3D Audio --- I3DA}},
  title     = {Measurement of car cabin binaural impulse responses and auralization via convolution},
  year      = {2021},
  address   = {Bologna, Italy},
  month     = {Sep.},
  pages     = {1---13},
  abstract  = {Auralization is a well-known method used to create virtual acoustic scenarios. This work elaborates techniques for the Binaural Room Impulse Response (BRIR) extraction of the interior of a passenger car cabin. As a novelty, this study developed a binaural recorder based upon digital MEMS (micro-electro-mechanical system) microphones combined with an Arduino compatible microcontroller (Teensy). To improve the recordings, spectral corrections to the acquired data were carried out. The system is compact and cost-effective, creating an advantage for those measuring different source-receiver positions. For this paper, several combinations of BRIRs were tested, including combinations of binaural recordings for ambiance. Finally, equipped with the BRIRs database, it was possible to auralize different situations in real-time, for example, a conversation between two people (with the possibility to switch/tune background music and engine sound on and off). Furthermore, it was also possible to combine sources and receivers simultaneously with a contactless camera head tracker. Listening tests revealed that the spatial impression was preserved, rendering exceptional results as a virtual environment.},
  comment   = {PACS: 43.10.Pr, 43.38.Gy, 43.55.Ka, 43.66.Pn, 43.55.Hy, 91.10.Lh },
  keywords  = {Binaural Room Impulse Response (BRIR), digital MEMS microphone, auralization, convolution, measurement, Finite Element Method (FEM), filtering, signal processing},
}
```

