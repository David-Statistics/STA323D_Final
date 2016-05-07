setwd("~/STA323D_Final")
load("my_oauth.Rdata")

library(streamR)
library(lubridate)
time_s = paste0(hour(Sys.time()), ".", minute(Sys.time()))


filterStream(file.name = paste0("/home/vis/djc37/STA323D_Final/data/tweetsPhilly", time_s, ".json"), # Save tweets in a json file
             track = c("trump", "kasich", "cruz", "hillary", "bernie", "clinton", "primary",
                       "fightingforus", "feelthebern", "makeamericagreatagain",
                       "nevertrump", "drumpf", "Elections2016"), 
             language = "en",
             location = c(-75.338745, 39.857046, -74.84436, 40.049694), #-124, 25, -64, 49 
             timeout = 600, # Keep connection alive for 60 seconds 40.11799 | Longitude: -75.39505
             oauth = my_oauth) # Use my_oauth file as the OAuth credentials