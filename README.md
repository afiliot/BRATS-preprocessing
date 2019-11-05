# BRATS preprocessing.

This script reproduces the main steps of BRATS challenge preprocessing (https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4833122/pdf/nihms775317.pdf, p.4). Namely:

- Bias Field Correction using N4BiasFieldCorrection from ANTS.
- Skull-stripping using BET2 algorithm from FSL.
- Co-registration on contrast-enhanced T1 MRI using antsRegistrationSyN.sh from ANTS (default to rigid).
- Isotropic resolution to 1x1x1 mm^3 and cropping/zero-padding to fit to volumes of size 240x240x155.
- Cast the resulting images to the same type as initial ones to save memory.

Requirements: ``-m``option
Help: ``-h``option





