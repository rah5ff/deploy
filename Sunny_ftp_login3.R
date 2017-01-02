### this is the file to pull daily tpi/DNB from an ftp using my desktop

## clear cache the script should run self contained
rm(list=ls())

##delete the older version of the file
file.remove("C://Users//rhealy//Desktop//Sunny ftp login//test_tpi.txt")

## extra check
if(file.exists("C://Users//rhealy//Desktop//Sunny ftp login//test_tpi.txt")) {stop()}


library(devtools)
library(httr)
library(XLConnect)
library(readr)
library(mailR)
library(lubridate)
library(dplyr)


setwd("C://Users//rhealy//Desktop//Sunny ftp login//")

## the purpose of this function is to grab from a given ftp site
 
  Sunny.url <- "https://ftpdbi01.wal-mart.com/TPI_DISB_INPUT/TPI_Supplier.txt"
  set_config(use_proxy(url="sysproxy.wal-mart.com",port = 8080))
  set_config(config(ssl_verifypeer = 0L))
  
  config <- authenticate("tpi","Walmart7")
  test_new <- httr::GET(Sunny.url, config = config, write_disk("test_tpi.txt", overwrite = T))
  
  test_tpi <- read_delim("C://Users//rhealy//Desktop//Sunny ftp login//test_tpi.txt"
                          ,"\t", escape_double = FALSE, trim_ws = TRUE,na = "",
                         locale = locale(encoding = "UTF-8"))
  
  temp <- content(test_new)
  temp







Today <- paste(format(Sys.Date(), "%B %d %Y"), sep = "_")

wb_name <- paste("Daily_DNB_MDM_Interface_File",Today,".xls",sep = "_")
wb <- loadWorkbook(file.path(wb_name), create = T)
createSheet(wb, "New Format")
createSheet(wb, "Old Format")
writeWorksheet(wb, test_tpi, "New Format")

## add in the old Format logic
ind_temp <- which((test_tpi$`PAYMENT STATUS` == "") & (test_tpi$DECISION == "Approved"))
test_tpi[ind_temp,"PAYMENT STATUS"] <- "Unblocked"

ind_temp <- which((test_tpi$`PAYMENT STATUS` == ""))
test_tpi[ind_temp, "PAYMENT STATUS"] <- "Blocked"

new_temp <- select_(test_tpi, "`ENTITY ID`", "`ENTITY NAME`", "`FOLDER`", DECISION = "`PAYMENT STATUS`" ,
                    "`SUB FOLDER`",
                    "`TAX ID`")

new_temp$DECISION <- ifelse(new_temp$DECISION == "Allowed","Unblocked","Blocked")

names <- c("ENTITY ID",	"ENTITY NAME",	"FOLDER",	"DECISION",	"SUB FOLDER",	"TAX ID")

writeWorksheet(wb, new_temp, "Old Format")
saveWorkbook(wb)



library(mailR)
sender <- "Ryan.Healy@walmart.com"

recipients <- c("Sunny.Mann@walmart.com","ryan.healy@walmart.com",
                "Michael.Tustison@walmart.com","DNB_Dai.id2r3yxgwq1xro3n@u.box.com")



email <- send.mail(from = sender,
                   to = recipients,
                   subject = "Daily DNB File",
                   body = "This is an automated file",
                   smtp = list(host.name = "SMTP-GW1.WAL-MART.COM", port = 25, 
                               user.name = "####",            
                               passwd = "#####", ssl = F),
                   authenticate = F, attach.files = wb_name,
                   send = F)

email$send()




#### make sure the Old format Decision column says unblocked instead of allowed