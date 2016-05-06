library(parallel)
library(tictoc)
library(tm)
files = list.files("./Rdata")
files = files[grep("Philly", files)]

neg_words = unlist(read.csv("negative_words.txt", stringsAsFactors = FALSE))
pos_words = unlist(read.csv("postive_words.txt", stringsAsFactors = FALSE))
pos_words = pos_words[-grep("trump", pos_words)]
named_pos = rep(1, length(pos_words))
names(named_pos) = pos_words
named_neg = rep(-1, length(neg_words))
names(named_neg) = neg_words

full.df = NULL
for (file in files) {
  load(paste0("./Rdata/",file))
  new.df = mclapply(tweets$text, function(s) {
    words = gsub("[[:punct:]]", "", s)
    words = iconv(words, to = "utf-8", sub = "")
    words = strsplit(words, "\\s")[[1]]
    words = sapply(words, function(w) try(tolower(w)))
    score = sum(sapply(words, function(w) {
      return(sum(named_neg[w], named_pos[w], na.rm = T))
    }))
    c(paste(words, collapse = " "), score)
  }, mc.cores = 24)
  
  
  new.df = as.data.frame(do.call(rbind, new.df), stringsAsFactors = FALSE)
  new.df[,2] = as.numeric(new.df[,2])
  names(new.df) = c("text", "score")
  new.df = cbind(new.df, tweets[,2:3])
  full.df = rbind(full.df, new.df)
}


candidates = c("trump", "kasich", "cruz", "hillary", "bernie")
mentions = mclapply(full.df$text, function(s) {
  sapply(candidates, function(c) {
    return(c %in% strsplit(s, "\\s")[[1]])
  })
}, mc.cores = 12)
mentions = do.call(rbind, mentions)
full.df = cbind(full.df, mentions)
save(full.df, file = "full_data.Rdata")


vc = sapply(candidates, function(s) {
  inds = which(full.df[[s]])
  text = iconv(enc2utf8(paste(full.df$text[inds], collapse = " ")), to = 'UTF-8')
  iconv(text, "UTF-8", "ASCII", sub="")
})
VC = VCorpus(VectorSource(vc))
inspect(VC)
tdm = TermDocumentMatrix(VC)
tfidf = weightTfIdf(tdm)

tfidf.m = as.matrix(tfidf)
save(tfidf, file = "tfidf.Rdata")
save(tfidf.m, file = "tfidf.m.Rdata")
