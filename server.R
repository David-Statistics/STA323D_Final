
# Load relevant libraries -------------------------------------------------
library(shiny)
library(ggplot2)
library(wordcloud)

# Define server logic 
#Define list of candidates for indexing
cands<-list("Donald Trump"=1, "John Kasich"=2, "Ted Cruz"=3, "Hillary Clinton"=4, "Bernie Sanders"=5)

shinyServer(function(input, output, session) {
  load("../tfidf.m.Rdata")
  load("../full_data.Rdata")

#Output user selection for candidate chosen
  output$text1 <- renderText({paste("You have selected", paste0(input$select_candidate, "."))})
  # output$toptenwords<-renderText({
  #   paste("Top Ten Relevant Words for", input$select_candidate, "are",
  #         paste(names(head(sort(tfidf.m[,cands[[input$select_candidate]]], decreasing=T),10)), 
  #         collapse = ", "))
  #   })
#Create word cloud
  wordcloud_rep <- repeatable(wordcloud)
  words<-reactive({
    head(sort(tfidf.m[,cands[[input$select_candidate]]], decreasing=T), 500)
  })
#Plot word cloud
  output$wordcloud <- renderPlot({
    v <- words()
    wordcloud_rep(names(v), v, scale=c(4,0.5),
                  max.words=50,
                  colors=brewer.pal(8, "Dark2"))
  })  
#Plot valence scores
  output$score<-renderPlot({
    print(ggplot(full.df, aes(x = created_at, y = score, group = cand, col = cand))
          +geom_smooth(se = F)+ ggtitle("Valence Scores for All Candidates Over Time")+xlab("Time Created")
          +ylab("Valence Score (Higher Score->Positive)"))
  })
#Plot distribution of tweets
  output$freqtweets<-renderPlot({
    print(ggplot(full.df, aes(x = created_at, col = cand)) + geom_density()
          +ggtitle("Distribution of Tweets for All Candidate Over Time")+xlab("Time Created")
          +ylab("Relative Number of Tweets"))
  })
  
})
