library(dplyr)
library(fpp)
library(fpp2)
library(seasonal)
library(ggplot2)
library(imputeTS) # imputation for ts

##### Part I: Data pre-processing #####

dailyweather = read.csv("DailyWeather.csv")
colnames(dailyweather)

# Data exploration
summary(dailyweather)

## Combine date columns
df_combinedate = dailyweather %>% 
  mutate(date = as.Date(with(dailyweather, paste(Year, Month, Day,sep="-")), "%Y-%m-%d")) %>% select(-c("Year","Month","Day"))

## Missing values clustering index
col_sunshine = df_combinedate$sunshine
x=0
for (i in 1:length(col_sunshine)) {
  if (is.na(col_sunshine)[i] == FALSE) {
    x = i
    break
  }
}

#sunshine value all equal to NA before 1999-08-18
df_combinedate[x,] 


df_remove_naclust = df_combinedate[-(1:x-1),] #df after 1999-08-18
summary(df_remove_naclust)


## Remaining missing value index
## sunshine
col_sunshine1 = df_remove_naclust$sunshine
c = 1
y1= NA
for (i in 1:length(col_sunshine1)) {
  if (is.na(col_sunshine1)[i] & c <=2 ){
    y1[c] = i
    c = c+1
  }
}
y1 # 4067 7535


## wind
col_wind = df_remove_naclust$wind
c = 1
y2= NA

for (i in 1:length(col_wind)) {
  if (is.na(col_wind)[i] & c <=25 ){
    y2[c] = i
    c = c+1
  }
}
y2 #24  145  146  147  148  149  150 1908 2441 2442 2635 3109 3517 3616 3677 3798 4155 4354 4419 4425 4504 4520 5370 6374 6375

## min
y3= NA
col_min = df_remove_naclust$min
for (i in 1:length(col_min)) {
  if (is.na(col_min)[i]){
    y3 =i
    break
  }
}
y3 # 15



## Missing Value Imputation
ts_df = ts(df_remove_naclust, frequency = 365.25, start = c(1999,8))
ts_imputed = na_interpolation(ts_df, option = "linear") # linear interpolation


# Check imputation
par(mfrow=c(1,2))
plot(ts_df[140:160,"wind"], type = "l", ylab = "Wind (km/h)", main = "Raw Data (Index 140 to 160)")
plot(ts_imputed[140:160, "wind"], type = "l", ylab = "Wind (km/h)", main = "After Linear Imputation")

par(mfrow=c(1,2))
plot(ts_df[3610:3680,"wind"], type = "l",  ylab = "Wind (km/h)", main = "Raw Data (Index 3610 to 3680)")
plot(ts_imputed[3610:3680, "wind"], type = "l",  ylab = "Wind (km/h)", main = "After Linear Imputation")



## Train and Test Set Splitting
# split train and test set
split_index = length(ts_imputed[,6])*0.80

lower = ts_imputed[,6][round(split_index)]
upper = ts_imputed[,6][round(split_index)+1]

train = ts_imputed[ts_imputed[,6]<=lower,]
test = ts_imputed[ts_imputed[,6]>=upper,]


# Check test and train set ratio
length(test)/length(ts_imputed) # 20%
length(train)/length(ts_imputed) # 80%
length(train) + length(test) == length(ts_imputed)

# Check start and end dates of test data
as.Date(train[,"date"])[6034]

df_full = ts_imputed %>% as.data.frame() %>% mutate(date = as.Date(date))
df_train = train %>% as.data.frame() %>% mutate(date = as.Date(date))
df_test = test %>% as.data.frame() %>% mutate(date = as.Date(date))


# Save train and test data
write.csv(df_full, "full.csv", row.names = FALSE)
write.csv(df_train, "train.csv", row.names = FALSE)
write.csv(df_test, "test.csv", row.names = FALSE)


