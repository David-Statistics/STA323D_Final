library(parallel)
library(tictoc)
library(tm)
load("./Rdata/tweetsPhilly21.10.Rdata")

neg_words = unlist(read.csv("negative_words.txt", stringsAsFactors = FALSE))
pos_words = unlist(read.csv("postive_words.txt", stringsAsFactors = FALSE))
pos_words = pos_words[-grep("trump", pos_words)]
named_pos = rep(1, length(pos_words))
names(named_pos) = pos_words
named_neg = rep(-1, length(neg_words))
names(named_neg) = neg_words

tic("cleaning")
test_sub = mclapply(tweets$text, function(s) {
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
toc()

test_sub = as.data.frame(do.call(rbind, test_sub), stringsAsFactors = FALSE)
test_sub[,2] = as.numeric(test_sub[,2])
names(test_sub) = c("text", "score")

tic()
candidates = list(c("trump", "donald", "makeamericagreatagain"), 
                  c("kasich"), 
                  c("cruz", "tedcruz"),
                  c("hillary", "imwithher", "fightingforus"), 
                  c("bernie", "sanders", "feelthebern"))
mentions = mclapply(test_sub$text, function(s) {
  sapply(candidates, function(c) {
    return(any(sapply(c, function(phrase) phrase %in% strsplit(s, "\\s")[[1]])))
  })
}, mc.cores = 12)
mentions = do.call(rbind, mentions)
test_sub = cbind(test_sub, mentions)
toc()

vc = sapply(candidates, function(s) {
  inds = which(test_sub[[s]])
  text = iconv(enc2utf8(paste(test_sub$text[inds], collapse = " ")), to = 'UTF-8')
  iconv(text, "UTF-8", "ASCII", sub="")
})
VC = VCorpus(VectorSource(vc))
inspect(VC)
tdm = TermDocumentMatrix(VC)
tfidf = weightTfIdf(tdm)

tfidf.m = as.matrix(tfidf)

