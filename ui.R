
# Loading relevant libraries ----------------------------------------------
library(shiny)
library(ggplot2)
library(wordcloud)

# Define UI for application 
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Philadelphia Primary Election Tweets by Candidate"),
  
  # Sidebar  
  #Enable user to select candidate to view
  sidebarLayout(
    sidebarPanel(
       selectInput("select_candidate", label=h3("Select Candidate"),
                  choices=c("Donald Trump", "John Kasich", 
                               "Ted Cruz", "Hillary Clinton", "Bernie Sanders"), selected="Hillary Clinton")
    ),
    
    # Main Panel
     mainPanel(
       #Output which candidate selected
        textOutput("text1"),
        #textOutput("toptenwords"),
        #Output word cloud of words most tweeted by candidate
        plotOutput("wordcloud"),
        #Output valence score (positive/negative) for all candidiates
        plotOutput("score"),
        #Output distribution of tweets for all candidates
        plotOutput("freqtweets")
    )
  )
))
