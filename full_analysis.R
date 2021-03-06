library(parallel)
library(tictoc)
library(tm)
library(tools)

## Get data files
files = list.files("./Rdata")
files = files[grep("Philly", files)]

## Pull positive and negative words
neg_words = unlist(read.csv("negative_words.txt", stringsAsFactors = FALSE))
pos_words = unlist(read.csv("postive_words.txt", stringsAsFactors = FALSE))
pos_words = pos_words[-grep("trump", pos_words)]
named_pos = rep(1, length(pos_words))
names(named_pos) = pos_words
named_neg = rep(-1, length(neg_words))
names(named_neg) = neg_words

## Initialize full data frame and loop over the files
full.df = NULL
for (file in files) {
  load(paste0("./Rdata/",file))
  
  ## Grab and clean the tweets
  new.df = mclapply(tweets$text, function(s) {
    
    ## Remove punctuation, change problematic characters, split on whitespace, remove links, and score the tweet
    words = gsub("[[:punct:]]", "", s)
    words = iconv(words, to = "utf-8", sub = "")
    words = strsplit(words, "\\s")[[1]]
    words = sapply(words, function(w) try(tolower(w)))
    words = words[!grepl("http", words)]
    score = sum(sapply(words, function(w) {
      return(sum(named_neg[w], named_pos[w], na.rm = T))
    }))
    c(paste(words, collapse = " "), score)
  }, mc.cores = 24)
  
  ## Combine the new data with the old
  new.df = as.data.frame(do.call(rbind, new.df), stringsAsFactors = FALSE)
  new.df[,2] = as.numeric(new.df[,2])
  names(new.df) = c("text", "score")
  new.df = cbind(new.df, tweets[,2:3])
  full.df = rbind(full.df, new.df)
}

## Remove duplicates (retweets) and convert created_at to an actual time vector
full.df = full.df[!duplicated(full.df$text), ]
full.df$created_at = strptime(sapply(strsplit(full.df$created_at, "\\s"), function(x) {
  paste(x[1:4], collapse = " ")
  }), "%a %b %d %H:%M:%S")
full.df$secs = as.numeric(full.df$created_at)

## Classify tweets as talking about a candidate by using common words/hashtags
candidates = list(c("trump", "donald", "makeamericagreatagain"), 
                  c("kasich"), 
                  c("cruz", "tedcruz"),
                  c("hillary", "imwithher", "fightingforus"), 
                  c("bernie", "sanders", "feelthebern"))
mentions = mclapply(full.df$text, function(s) {
  sapply(candidates, function(c) {
    return(any(sapply(c, function(phrase) phrase %in% strsplit(s, "\\s")[[1]])))
  })
}, mc.cores = 24)
mentions = do.call(rbind, mentions)

## Append the mentions onto the original full data frame
candidate_names = toTitleCase(sapply(candidates, function(c) c[1]))
colnames(mentions) = candidate_names
full.df = cbind(full.df, mentions)

## Add a column for either the single candidate mentioned or multiple candidates
cands = unlist(mclapply(1:nrow(full.df), function(i) {
  if(sum(full.df[i, 6:10] == TRUE)>1) {return("Multiple")}
  if(sum(full.df[i, 6:10] == TRUE)==0) {return("None")}
  else {
    return(candidate_names[which(full.df[i, 6:10] == TRUE)])
  }
}, mc.cores = 24))
full.df$Candidate = factor(cands)

## Remove tweets that don't mention any candidates
full.df = full.df[full.df$Candidate != "None", ]
full.df$Candidate = droplevels(full.df$Candidate)
save(full.df, file = "full_data.Rdata")

## Construct a vector corpus based on the candidates
vc = sapply(candidate_names, function(s) {
  inds = which(full.df[[s]])
  text = iconv(enc2utf8(paste(full.df$text[inds], collapse = " ")), to = 'UTF-8')
  iconv(text, "UTF-8", "ASCII", sub="")
})

VC = VCorpus(VectorSource(vc))

## Create tfidf scores for the candidates and words
tdm = TermDocumentMatrix(VC)
tfidf = weightTfIdf(tdm)

## Convert the tfidf object to a matrix for ease of use
tfidf.m = as.matrix(tfidf)
save(tfidf, file = "tfidf.Rdata")
save(tfidf.m, file = "tfidf.m.Rdata")
