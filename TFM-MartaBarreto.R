library(readxl)
library(caret)
library(leaps)
library(ggplot2)
DESCRIPTORES <- read_excel("~/Desktop/DESCRIPTORES.xlsx")
View(DESCRIPTORES)

# MODELO 1
# Establecemos semilla para la reproducibilidad
set.seed(123)
indices <- sample(1:nrow(DESCRIPTORES), size = floor(0.8 * nrow(DESCRIPTORES)))
train_set <- DESCRIPTORES[indices, ]
test_set <- DESCRIPTORES[-indices, ]

# Convertir todas las columnas a numérico
train_set[] <- lapply(train_set, function(x) as.numeric(as.character(x)))
test_set[] <- lapply(test_set, function(x) as.numeric(as.character(x)))

# Eliminamos variables con alta correlación (>0.7)
corr_matrix <- cor(train_set)
high_corr_indices <- findCorrelation(corr_matrix, cutoff = 0.7)
train_set_filtered <- train_set[, -high_corr_indices]
test_set_filtered <- test_set[, -high_corr_indices]

# Ajustamos el modelo 1
modelo_1 <- regsubsets(logBB ~ ., data = train_set_filtered, nvmax = 10)
print(summary(modelo_1))

# Selección del mejor modelo según BIC
modelo_1_summary <- summary(modelo_1)
best_model_index <- which.min(modelo_1_summary$bic)
variables_modelo_1 <- names(train_set_filtered)[modelo_1_summary$which
                                                [best_model_index,]]
cat("Índice del mejor modelo:", best_model_index, "\n")
cat("Variables seleccionadas en el mejor modelo:", variables_modelo_1, "\n")

# Ajustamos el. modelo con las variables seleccionadas
modelo_final_1 <- lm(
   logBB ~ `Carbo-Aromatic Rings` + `VDW-Volume` + `H-Donors` + cLogP,
   data = train_set_filtered
   )

View(modelo_final_1)
summary(modelo_final_1)

# Realizamos mediciones en el conjunto de prueba
predicciones_1 <- predict(modelo_final_1, newdata = test_set)

# Error cuadrático medio en el conjunto de prueba
mse <- mean((predicciones_1 - test_set$logBB)^2)
cat("Error cuadrático medio(MSE en el conjunto de prueba:", mse, "\n")

# Validación cruzada 10-fold
train_control <- trainControl(method = "cv", number = 10)
modelo_cv_1 <- train(
  logBB ~ `Carbo-Aromatic Rings` + `VDW-Volume` + `H-Donors` + cLogP,
  data      = train_set_filtered,
  method    = "lm",
  trControl = train_control(method = "cv", number = 10)
   )
                       
print(modelo_cv_1)

# Predicciones para el modelo 1
pred_train_1 <- predict(modelo_final_1, newdata = train_set_filtered)
pred_test_1 <- predict(modelo_final_1, newdata = test_set_filtered)
# Métricas de entrenamiento Modelo 1

mse_train_1 <- mean((pred_train_1 - train_set_filtered$logBB)^2)
rmse_train_1 <- sqrt(mse_train_1)
mae_train_1 <- mean(abs(pred_train_1 - train_set_filtered$logBB))
r2_train_1 <- summary(modelo_final_1)$r.squared
adjr2_train_1 <- summary(modelo_final_1)$adjr.r.squared

# Métricas en test para el modelo 1
mse_test_1 <- mean((pred_test_1 - test_set$logBB)^2)
rmse_test_1 <- sqrt(mse_test_1)
mae_test_1 <- mean(abs(pred_test_1 - test_set$logBB))
r2_test_1 <- cor(pred_test_1, test_set$logBB)^2

# Clasificamos las moléculas en permeables y no permeables
train_set_filtered$BHE <- ifelse(train_set_filtered$logBB >0, "Permeable", 
                                 "No Permeable")
write.csv(train_set_filtered, 
          file = "train_set_filtered.csv", row.names = FALSE)

# Gráfico comparación predichos y reales
ggplot(test_set_filtered, aes(
  x = predict(modelo_final_1, newdata = test_set_filtered),
  y = logBB
 )) +
geom_point(color = "steelblue", size = 2) +
geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
labs(
 title = "Modelo 1: Predicciones vs Reales (conjunto de prueba)",
   x     = "Valores Predichos",
   y     = "Valores Reales"
    ) +
   theme_minimal()
      
# Gráfico de residuos
residuos_1 <- test_set_filtered$logBB - predicciones_1
df_residuos_1 <- data.frame(predichos = predicciones_1, residuos = residuos_1)
ggplot(df_residuos_1, aes(x = predichos, y = residuos)) +
geom_point(color = "steelblue", size = 2) +
geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
labs(
 title = "Modelo 1: Residuos vs Valores Predichos",
 x     = "Valores Predichos",
 y     = "Residuos"
   ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

# Graficamos el QQ-plot
qqnorm(residuos_1,
+        main = "QQ plot de residuos - Modelo 1")
qqline(residuos_1,
col  = "red",
  lty  = 2)
 
                      
# MODELO 1 CON VARIABLES SELECCIONADAS POR R2 AJUSTADO
best_model_index_r2 <- which.max(modelo_1_summary$adjr2)
variables_modelo_r2 <- names(train_set_filtered)[modelo_1_summary$which
                                                [best_model_index_r2, ]]
variables_modelo_r2 <- setdiff(variables_modelo_r2, "logBB")
print(variables_modelo_r2)

# Eliminamos las variables que no deben de ir en el modelo
variables_modelo_r2 <- setdiff(variables_modelo_r2, c("logBB", "BHE"))

# Ajustamos el modelo con las variables seleccionadas por R2 ajustado
modelo_final_r2 <- lm(
   logBB ~ `Electronegative Atoms` + `Carbo-Aromatic Rings` + Amides +
   `Basic Nitrogens` + `Globularity SVD` + `VDW-Volume` +
   `Total Molweight` + `H-Donors` + cLogP,
    data = train_set_filtered
    )
                       
# Métricas en el conjunto de entrenamiento
resumen <- summary(modelo_final_r2)
r2_entrenamiento <- resumen$r.squared
r2_ajustado <- resumen$adj.r.squared
mse_entrenamiento <- mean(residuals(modelo_final_r2)^2)
rmse_train_r2 <- sqrt(mse_entrenamiento)
 mae_train_r2 <- mean(abs(residuals(modelo_final_r2)))
 
# Métricas en el conjunto de prueba para el modelo basado en R2 ajustado
pred_test_r2 <- predict(modelo_final_r2, newdata = test_set_filtered)
errores_test_r2 <- test_set_filtered$logBB - pred_test_r2
mse_test_r2 <- mean(errores_test_r2^2)
rmse_test_r2 <- sqrt(mse_test_r2)
mae_test_r2 <- mean(abs(errores_test_r2))
ss_res_r2 <- sum((test_set_filtered$logBB - pred_test_r2)^2)
ss_tot_r2 <- sum((test_set_filtered$logBB - mean(test_set_filtered$logBB))^2)
r2_test_r2 <- 1 - ss_res_r2 / ss_tot_r2

# Validación cruzada para el modelo basado en R2 ajustado
control_r2 <- trainControl(method = "cv", number = 10)
 modelo_cv_r2 <- train(
        logBB ~ `Electronegative Atoms` + `Carbo-Aromatic Rings` + Amides +
       `Basic Nitrogens` + `Globularity SVD` + `VDW-Volume` +
       `Total Molweight` + `H-Donors` + cLogP,
        data = train_set_filtered,
        method = "lm",
        trControl = control_r2
        )
                      
cv_r2_r2   <- modelo_cv_r2$results$Rsquared
cv_rmse_r2 <- modelo_cv_r2$results$RMSE
cv_mae_r2  <- modelo_cv_r2$results$MAE

# MODELO 2
library(readxl)
DESCRIPTORES_modelo2 <- read_excel
            ("~/Desktop/TFM_final/DESCRIPTORES_modelo2.xlsx")
View(DESCRIPTORES_modelo2)                                                                
                       
# Establecemos semilla para reproducibilidad
set.seed(123)
indices <- sample(1:nrow(DESCRIPTORES_modelo2), 
                  size = floor(0.8 * nrow(DESCRIPTORES_modelo2)))
train_set_2 <- DESCRIPTORES_modelo2[indices, ]
test_set_2 <- DESCRIPTORES_modelo2[-indices, ]
train_set_2[] <- lapply(train_set_2, function(x) as.numeric(as.character(x)))
test_set_2[] <- lapply(test_set_2, function(x) as.numeric(as.character(x)))
corr_matrix_2 <- cor(train_set_2)
high_corr_indices_2 <- findCorrelation(corr_matrix_2, cutoff = 0.7)
train_set_filtered_2 <- train_set_2[, -high_corr_indices_2]
test_set_filtered_2 <- test_set_2[, -high_corr_indices_2]
modelo_2 <- regsubsets(logBB ~ ., data = train_set_filtered_2, nvmax = 10)
modelo_2_summary <- summary(modelo_2)
best_model_index_2 <- which.min(modelo_2_summary$bic)
variables_modelo_2 <- names(train_set_filtered_2)[modelo_2_summary$which
                                                  [best_model_index_2,]]
variables_modelo_2 <- setdiff(variables_modelo_2, "logBB")
modelo_final_2 <- lm( as.formula(paste("logBB ~", paste0("`", 
                            variables_modelo_2, "`", collapse = " + "))),
                           data = train_set_filtered_2
                         )
                      
resumen_2 <- summary(modelo_final_2)
r2_train_2 <- resumen_2$r.squared
adjr2_train_2 <- resumen_2$adj.r.squared
mse_train_2 <- mean(residuals(modelo_final_2)^2)
rmse_train_2 <- sqrt(mse_train_2)
mae_train_2 <- mean(abs(residuals(modelo_final_2)))
pred_test_2 <- predict(modelo_final_2, newdata = test_set_filtered_2)
errores_test_2 <- test_set_filtered_2$logBB - pred_test_2
mse_test_2 <- mean(errores_test_2^2)
rmse_test_2 <- sqrt(mse_test_2)
mae_test_2 <- mean(abs(errores_test_2))
ss_res_2 <- sum((test_set_filtered_2$logBB - pred_test_2)^2)
ss_tot_2 <- sum((test_set_filtered_2$logBB - mean(test_set_filtered_2$logBB))^2)
r2_test_2 <- 1 - ss_res_2 / ss_tot_2
train_control_2 <- trainControl(method = "cv", number = 10)
modelo_cv_2 <- train(as.formula(paste
          ("logBB ~", paste0("`", variables_modelo_2, "`", collapse = " + "))),
           data = train_set_filtered_2,
           method = "lm",
           trControl = train_control_2
            )
              
cv_r2_2   <- modelo_cv_2$results$Rsquared
cv_rmse_2 <- modelo_cv_2$results$RMSE
cv_mae_2  <- modelo_cv_2$results$MAE

# Gráfico de valores predichos para el modelo 2
plot(
  pred_test_2,
  test_set_filtered_2$logBB,
  xlab = "Valores Predichos (Modelo 2)",
  ylab = "Valores Reales",
  main = "Modelo 2: Predicciones vs Reales"
     )
  abline(0, 1, col = "red")
  
# Creamos el data frame
df2 <- data.frame(
predichos = pred_test_2,residuos  = errores_test_2)

# Graficamos
ggplot(df2, aes(x = predichos, y = residuos)) +
    geom_point(color = "steelblue", size = 2) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    labs(
       title = "Modelo 2: Residuos vs Valores Predichos",
       x     = "Valores Predichos",
       y     = "Residuos"
   ) +
   theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))
   
# Graficamos QQ-plot
residuos2 <- test_set_filtered_2$logBB - pred_test_2
  qqnorm(residuos2,
         main = "QQ plot de residuos - Modelo 2")
         qqline(residuos2,
         col  = "red",
         lty  = 2)
                   
# MODELO 3
library(readxl)
DESCRIPTORES_modelo3 <- read_excel
                 ("~/Desktop/TFM_final/DESCRIPTORES_modelo3.xlsx")
View(DESCRIPTORES_modelo3)                                                                
                     
# Establecemos semilla para la reproducibilidad
set.seed(123)
indices <- sample(1:nrow(DESCRIPTORES_modelo3), size = floor
                  (0.8 * nrow(DESCRIPTORES_modelo3)))
train_set_3 <- DESCRIPTORES_modelo3[indices, ]
test_set_3 <- DESCRIPTORES_modelo3[-indices, ]

# Convertimos a numérico
train_set_3[] <- lapply(train_set_3, function(x) as.numeric(as.character(x)))
test_set_3[] <- lapply(test_set_3, function(x) as.numeric(as.character(x)))

# Eliminamos variables con alta correlación (>0.7)
corr_matrix_3 <- cor(train_set_3)
high_corr_indices_3 <- findCorrelation(corr_matrix_3, cutoff = 0.7)
train_set_filtered_3 <- train_set_3[, -high_corr_indices_3]
test_set_filtered_3 <- test_set_3[, -high_corr_indices_3]
modelo_3 <- regsubsets(logBB ~ ., data = train_set_filtered_3, nvmax = 10)
modelo_summary_3 <- summary(modelo_3)
best_model_index_3 <- which.min(modelo_summary_3$bic)
variables_modelo_3 <- names(train_set_filtered_3)[modelo_summary_3$which
                                                  [best_model_index_3, ]]
variables_modelo_3 <- setdiff(variables_modelo_3, "logBB")
modelo_final_3 <- lm(
   as.formula(paste("logBB ~", paste0("`", variables_modelo_3, "`", 
   collapse = " + "))),
   data = train_set_filtered_3
    )
                     
summary(modelo_final_3)

# Validación cruzada
train_control_3 <- trainControl(method = "cv", number = 10)
 modelo_cv_3 <- train(
   logBB ~ `Electronegative Atoms` + `H-Donors` + cLogP,
   data = train_set_filtered_3,
   method = "lm",
   trControl = train_control_3
           )
                      
cv_rmse_3 <- modelo_cv_3$results$RMSE
cv_r2_3   <- modelo_cv_3$results$Rsquared
cv_mae_3  <- modelo_cv_3$results$MAE
cat("RMSE (CV):", round(cv_rmse_3, 4), "\n")
cat("R² (CV):", round(cv_r2_3, 4), "\n")
cat("MAE (CV):", round(cv_mae_3, 4), "\n")

# Calculamos predicciones
test_set_filtered_3$predicciones <- predict(modelo_final_3,
                                        newdata = test_set_filtered_3)

# Grafico de valores predichos vs valores reales
ggplot(test_set_filtered_3, aes(x = predicciones, y = logBB)) +
   geom_point(color = "steelblue", size = 2) +
   geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
   labs(
   title = "Modelo 3: Valores Predichos vs Valores Reales",
    x = "logBB Predicho",
    y = "logBB Real"
    )+ 
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5))
    
# Gráfico de residuos
test_set_filtered_3$predicciones <- predict(modelo_final_3, 
                                            newdata = test_set_filtered_3)
test_set_filtered_3$residuos <- test_set_filtered_3$logBB - 
  test_set_filtered_3$predicciones

ggplot(data = test_set_filtered_3, aes(x = predicciones, y = residuos)) +
     geom_point(color = "steelblue", size = 2) +
     geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
     labs(
     title = "Modelo 3: Residuos vs Valores Predichos",
     x = "Valores Predichos",
     y = "Residuos"
           )+ 
     theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5))
     
# Graficamos QQ-plot modelo 3
residuos_3 <- test_set_filtered_3$residuos
qqnorm(residuos_3,
   main = "QQ plot de residuos - Modelo 3")
   qqline(residuos_3, col = "red", lty = 2)
   
# COMPROBACIÓN DEL MODELO 3
library(readxl)
Comprobacion <- read_excel("~/Desktop/TFM_final/Comprobacion.xlsx")
View(Comprobacion)  

# Predecimos el logBB con el modelo 3
Comprobacion$logBB_predicho <- predict(modelo_final_3, newdata = Comprobacion)

# Convertimos a numérico
Comprobacion$logBB <- as.numeric(gsub("[^0-9.-]", "", Comprobacion$logBB))
                       
# Clasificamos en permeables/no permeables
Comprobacion$Permeable_real <- ifelse(Comprobacion$logBB > 0, "Sí", "No")
Comprobacion$Permeable_predicha <- ifelse(Comprobacion$logBB_predicho > 0,
                                          "Sí", "No")

# Calculamos residuos
Comprobacion$residuos <- Comprobacion$logBB - Comprobacion$logBB_predicho
mae_comp <- mean(abs(Comprobacion$residuos))
rmse_comp <- sqrt(mean(Comprobacion$residuos^2))
r2_comp <- 1 - sum(Comprobacion$residuos^2) / sum((Comprobacion$logBB - 
                                                  mean(Comprobacion$logBB))^2)
cat("MAE:", mae_comp, "\n")
MAE: 0.6463157 
cat("RMSE:", rmse_comp, "\n")
RMSE: 0.7765506 
cat("R2:", r2_comp, "\n")
R2: 0.5179709 

# Comparación entre permeabilidad real y predicha
tabla_confusion <- table(
   Real     = Comprobacion$Permeable_real,
  Predicha = Comprobacion$Permeable_predicha
                           )
 print(tabla_confusion)
 