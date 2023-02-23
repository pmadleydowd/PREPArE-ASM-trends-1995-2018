setwd("//ads.bris.ac.uk/filestore/HealthSci SafeHaven/CPRD Projects UOB/Projects/20_000228/Analysis/datafiles/Derived_data/CPRD/")


data_1 <-  read.csv("indication_combinations.txt") 

install.packages('venneuler')
library(venneuler)

install.packages('UpSetR')
library(UpSetR)

upset(data_1, nsets=11, order.by = c("freq", "degree"))
upset(data_1,  nsets=11,  order.by = c("freq"))
upset(data_1, order.by = c("degree"))
