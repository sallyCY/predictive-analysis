
# Part I: Data pre-processing
```{r}
dailyweather = read.csv("DailyWeather.csv")
colnames(dailyweather)
```

```{r}
summary(dailyweather)
```
More than 50% missing value in sunshine variable

## Combine date columns
```{r}
df_combinedate = dailyweather %>% 
  mutate(date = as.Date(with(dailyweather, paste(Year, Month, Day,sep="-")), "%Y-%m-%d")) %>% select(-c("Year","Month","Day"))
```


## Missing values clustering index
```{r}
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
```

## Remove missing value cluster
```{r}
df_remove_naclust = df_combinedate[-(1:x-1),] #df after 1999-08-18
summary(df_remove_naclust)
```

## Remaining missing value index
```{r}
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

```


## Missing Value Imputation
```{r}
ts_df = ts(df_remove_naclust, frequency = 365.25, start = c(1999,230))
ts_imputed = na_interpolation(ts_df, option = "linear") # linear interpolation
```


```{r}
# Check imputation
par(mfrow=c(1,2))
ts.plot(ts_df[140:160,"wind"], type = "l", ylab = "Wind (km/h)", main = "Raw Data (Index 140 to 160)")
ts.plot(ts_imputed[140:160, "wind"], type = "l", ylab = "Wind (km/h)", main = "After Linear Imputation")

par(mfrow=c(1,2))
ts.plot(ts_df[3610:3680,"wind"], type = "l",  ylab = "Wind (km/h)", main = "Raw Data (Index 3610 to 3680)")
ts.plot(ts_imputed[3610:3680, "wind"], type = "l",  ylab = "Wind (km/h)", main = "After Linear Imputation")
```


## Train and Test Set Splitting
```{r}
# split train and test set
split_index = length(ts_imputed[,6])*0.80
lower = ts_imputed[,6][round(split_index)]
upper = ts_imputed[,6][round(split_index)+1]

train = ts_imputed[ts_imputed[,6]<=lower,]
test = ts_imputed[ts_imputed[,6]>=upper,]

```

```{r, eval = FALSE}
# Check test and train set ratio
length(test)/length(ts_imputed) # 20%
length(train)/length(ts_imputed) # 80%
length(train) + length(test) == length(ts_imputed)

# Check start and end dates of test data
as.Date(train[,"date"])[6034]
```

```{r, eval=FALSE, include=FALSE}
df_full = ts_imputed %>% as.data.frame() %>% mutate(date = as.Date(date))
df_train = train %>% as.data.frame() %>% mutate(date = as.Date(date))
df_test = test %>% as.data.frame() %>% mutate(date = as.Date(date))

# Save train and test data
write.csv(df_full, "full.csv", row.names = FALSE)
write.csv(train_df, "train.csv", row.names = FALSE)
write.csv(test_df, "test.csv", row.names = FALSE)

```




# Forecast Modelling
## Train and Test Data Exploration
test_ts = ts(test, frequency = 365.25, start = c(1999,08,18))
train_ts = ts(train, frequency = 365.25, start = c(1999,08,18))


library(ggcorrplot)
corr = round(cor(train_df[,1:5]),1)
ggcorrplot(corr, type = "lower", lab = TRUE)

library(GGally)
GGally::ggpairs(train_df[,1:5])




acf
pacf
kpss.test
adf.test



fitts1_trun <- tslm(max_t~trend+sunshine_t+wind_t+rainfall_t+fourier(max_t,K=2))
##AIC=42120.75 Adjusted R^2=0.6444
##positive: sunshine, wind; negative: rainfall
summary(fitts1_trun)
AIC(fitts1_trun)
plot(max_t)
lines(fitts1_trun$fitted.values, col="red")
#model diagnostics
par(mfrow=c(2,1))
Acf(fitts1_trun$residual,lag.max=20,main="ACF of Max Temp residuals from tslm (truncated)") #MA(q)=2
pacf(fitts1_trun$residuals,lag.max=20,main="PACF of Max Temp residuals from tslm (truncated)") #AR(p)=2
Box.test(fitts1_trun$residual, fitdf=length(fitts1_trun$coefficients)+1,lag=20,type="Lj")
dwtest(fitts1_trun,alt="two.sided")
bgtest(fitts1_trun,20) #p-value<0.05, reject H0, autocorrelation
