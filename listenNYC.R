setwd("~/STA323D_Final")
load("my_oauth.Rdata")

library(streamR)
library(lubridate)
time_s = paste0(hour(Sys.time()), ".", minute(Sys.time()))


filterStream(file.name = paste0("/home/vis/djc37/STA323D_Final/data/tweetsNYC", time_s, ".json"), # Save tweets in a json file
             track = c("trump", "kasich", "cruz", "hillary", "bernie", "clinton", "primary",
                       "fightingforus", "feelthebern", "makeamericagreatagain",
                       "nevertrump", "drumpf", "VoteNY", "NYCvotes", "Elections2016"), 
             language = "en",
             location = c(-74.28, 40.48, -71.9, 41.2), #-124, 25, -64, 49
             timeout = 600, # Keep connection alive for 60 seconds
             oauth = my_oauth) # Use my_oauth file as the OAuth credentials