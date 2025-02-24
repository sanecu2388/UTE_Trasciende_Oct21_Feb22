# Librerias ----
library(dplyr)
library(data.table)
library(tidyr)
library(readr)
library(pivottabler)
library(tidyverse)

# Cargar webexam ----
webexam <- read.table("C:/CEIE_R/UTE_Trasciende_Oct21_Feb22/Archivo Resultado Data.txt",
                      header = TRUE,
                      sep = ";",
                      stringsAsFactors = FALSE,
                      dec = ".")

# Corregir espacios en los nombres de los �tems
webexam$PREGUNTA <- gsub("MATVP019\n", "MATVP019", webexam$PREGUNTA)
webexam$PREGUNTA <- gsub(" ", "", webexam$PREGUNTA)
length(unique(webexam$PREGUNTA))

# Seleccionar subset
webexam <- webexam %>% select(CEDULA, ESTUDIANTE, EXAMEN,FECHA_HORA_RINDIO_EXAMEN, 
                      PREGUNTA, RESPUESTA, VALOR_RESPUESTA_SELECCIONADA) %>% 
                      mutate(FECHA_HORA_RINDIO_EXAMEN=as.POSIXct(FECHA_HORA_RINDIO_EXAMEN)) %>% 
                      mutate(FORMA = substr(EXAMEN, start = 1, stop = 2)) %>% 
                      unite(CODITEM, c("PREGUNTA", "FORMA"), sep = "_", remove = FALSE)

# Cargar dise�o ----
diseno <- read.table("Diseno.txt", 
                     header = TRUE,
                     sep = ";", 
                     stringsAsFactors = FALSE,
                     dec = ".",
                     colClasses = c(FORMA="character"))

diseno <- diseno %>% unite(CODITEM, c("ITEM", "FORMA"), sep = "_", remove = FALSE) %>% 
                     mutate(N1 = substr(ESTRUCTURA, start = 1, stop = 1)) %>% 
                     mutate(N3 = substr(ESTRUCTURA, start = 1, stop = 3)) %>%
                     select(CODITEM, COMPETENCIA, ESTRUCTURA, FUNCION, N1, N3)

# Left join de webexam y diseno ----
attach(webexam)
webexam <- webexam %>% left_join(diseno, by = "CODITEM")

# pivot de c�dula por competencias, aciertos totales ----
resultado <-
  webexam %>% filter(FUNCION == "OPERATIVO") %>% 
  group_by(CEDULA, EXAMEN, FECHA_HORA_RINDIO_EXAMEN, COMPETENCIA) %>% 
  summarise(ACIERTOS= sum(VALOR_RESPUESTA_SELECCIONADA)) %>% 
  spread(COMPETENCIA, ACIERTOS) %>% 
  arrange(desc(FECHA_HORA_RINDIO_EXAMEN)) 

resultado <-
  mutate_if(resultado, is.numeric, ~replace(., is.na(.), 0)) 

resultado <-
  mutate(resultado, TOTAL = sum(c(CIENTIFICA+COMUNICATIVA+MATEMATICA+`RAZONAMIENTO ABSTRACTO`)))
                         

# Generar lista de estudiantes evaluados CEIE
#est_eval<-dcast(Archivo.Resultado.Data, 
 #                            CEDULA + FECHA_HORA_RINDIO_EXAMEN + EXAMEN ~
  #                             VALOR_RESPUESTA_SELECCIONADA)

# Matriculados_convocar<- filter(Matriculados_pagados, EVALUADO == "no") 
# Matriculados_convocar<- arrange(Matriculados_convocar, FACULTAD, CARRERA, NOMBRE)
# dcast(Matriculados_convocar, FACULTAD ~ EVALUADO)

# Exportar reporte de evaluados
reporte<-write.table(est_eval,file = "Evaluados.csv",
                     sep = ";", dec = ",",
                     row.names = FALSE,
                     col.names = TRUE)
