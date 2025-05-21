# Predicción de la permeabilidad de la BHE a través del cálculo de logBB

Este repositorio contiene el análisis realizado para el Trabajo de fin de Máster: Modelado computacional del paso de fármacos a través de la barrera hematoencefálica mediante la predicción de logBB

# Estructura

- `TFM-MartaBarreto.R`: Script principal con el análisis completo (consta de tres modelos)
-`train_set_filtered.csv`: datos de entrenamiento tras el filtrado clasificados según permeabilidad.

# Paquetes necesarios
```r
library(readxl)
library(caret)
library(leaps)
library(ggplot2)

