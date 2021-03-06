library(tidyverse)
library(tm)
library(stringi)
library(tidytext)
#Read the data
profile<-read.csv2("Data/Occupation Structure/CBO2002 - PerfilOcupacional.csv")
profile<-profile[,c(5,7,9)]
profile$Description<-paste(profile$NOME_GRANDE_AREA,profile$NOME_ATIVIDADE)
profile<-profile[,c(-2,-3)]

#To lower
profile<-profile %>% mutate(Description = tolower(Description))

#Remove stopwords
profile$Description<-removeWords(profile$Description, c("\\f", stopwords("portuguese")))

#Remove acents
profile$Description<-stri_trans_general(profile$Description, "Latin-ASCII")

#Count the number of words by CBO (unigram)
count1 <- profile %>%
  unnest_tokens(word, Description, token = "ngrams", n = 1)
count1 <- count1 %>%
  group_by(COD_OCUPACAO) %>% 
  count(word, sort = TRUE)

#Count the number of words by CBO (bigram)
count2 <- profile %>%
  unnest_tokens(word, Description, token = "ngrams", n = 2)
count2 <- count2 %>%
  group_by(COD_OCUPACAO) %>% 
  count(word, sort = TRUE)

#Rbind
listWords<-bind_rows(count1,count2)

#Select the words with the highest variance
stat <- listWords %>% 
            group_by(word) %>% 
            summarise(variance = var(n),
                      Mean = mean(n)) 
stat[ is.na(stat) ] <- 0 
stat$CV <- sqrt(stat$variance)/stat$Mean
stat[ is.na(stat) ] <- 0 
hist(stat$CV)
quantile(stat$CV,probs=seq(0,1,length.out = 100))

#Keep the top 5%
statCV <- stat %>% 
        filter(CV>0.5) %>% 
        select(word)

#Merge with listWords
listWordsFilter<- listWords %>% 
                  inner_join(statCV,"word")

#Check if all CBO�s are here
length(unique(listWords$COD_OCUPACAO))
length(unique(listWordsFilter$COD_OCUPACAO))

#Create the data matrix
dataWords<- reshape2::dcast(listWordsFilter, COD_OCUPACAO ~ word, sum, fill=0) 

#Create the correlation plot
M<-cor(dataWords[,-1])
hist(M)
saveRDS(dataWords,"Data/CBOwords.rds")
