
# anomanor

<!-- badges: start -->

[![R-CMD-check](https://github.com/dmenne/anomanor/workflows/R-CMD-check/badge.svg)](https://github.com/dmenne/anomanor/actions)
[![Codecov test
coverage](https://codecov.io/gh/dmenne/anomanor/branch/master/graph/badge.svg)](https://app.codecov.io/gh/dmenne/anomanor?branch=master)
<!-- badges: end -->

## Overview

EUGIM Hub Project: Educational training of physicians working with
high-resolution anorectal manometry
![readme_sample](https://user-images.githubusercontent.com/506275/146637934-4f688341-d62a-47f6-aa63-cb420e62239b.png)

Interactive application providing online training for physicians and
other practitioners using high-resolution anorectal manometry and the
[London
Classification](https://onlinelibrary.wiley.com/doi/full/10.1111/nmo.13679)
for disorders of anorectal function. It provides the opportunity to
compare classification performance using High-Resolution-Manometry (HRM)
and conventional manometry against a “reference standard” set by the
lead authors of this classification system. Data acquired during this
training will be used to assess inter-observer agreement between
practitioners.

The results will be published. All those completing all 50 cases will be
acknowledged. The information obtained will contribute to the
development of version 2.0 of the London classification.

## Credits

- Version: 1.6.2
- Dieter Menne (aut, cre)
- Mark Fox (fnd, ctb)
- Isabella Bielicki (ctb)
- Menne Biomed Consulting (cph)
- Laborie Medical Technologies (fnd)
- International Working Group for Disorders of Gastrointestinal Motility
  and Function, subgroup Anorectal Physiology (fnd, dtc)
- EUGIM European Gastrointestinal Motility (fnd, dtc)
- University Hospital of Zurich, Dep. Gastroenterology (dtc)
- Klinik Arlesheim (dtc)

*aut, cre, cph, …* see [Library of Congress Code List for
Relators](https://www.loc.gov/marc/relators/relaterm.html)

The program uses [R](https://www.r-project.org/),
[Shiny](https://shiny.rstudio.com/)/[R](https://www.r-project.org/) and
is under [MIT Licence](https://en.wikipedia.org/wiki/MIT_License).

[**London
Classification**](https://onlinelibrary.wiley.com/doi/full/10.1111/nmo.13679)
Emma Carrington, Henriette Heinrich, Mark Fox, Charles Knowles, Mark
Scott Funding: United European Gastroenterology: Guideline Dissemination
Activity Grant

## Simple installation

You can run the Shiny app locally on your Windows or Linux desktop as a
simulated user `sa_admin`. Two sample records are included. Instructions
for installation are given on the [Docker Hub site for
anomanor](https://hub.docker.com/repository/docker/dmenne/anomanor).

## Developer installation

As a developer with background in R and Shiny, you can install the
R-package and associated files with

    devtools::install_github("dmenne/anomanor")

## Full Installation

This app is part of a Docker-based web installation using
[Keykloak](https://www.keycloak.org/) and
[ShinyProxy](https://www.shinyproxy.io/) for user management. Scripts
and templates for setting are included - see the comments in the `inst`
folder and the configuration scripts, e.g. `run_all.sh`. Installation of
the full system requires extensive knowledge and is not explained here.
