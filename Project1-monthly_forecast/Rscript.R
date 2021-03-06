library(fpp)
library(fpp2)
library(forecast)

temp = read.csv("MonthTemp.csv")
temp$Mean = (temp$Min + temp$Max)/2
tempts_mean = ts(temp[,5], frequency = 12, start = c(1970,7), names = "temp_mean") # transform to time series data
summary(temp)


# Graphical exploration of the data.
## Time series plot
autoplot(tempts_mean, main = "Monthly Temperature in Melbourn (July 1997 - Feb 2020)", ylab = "Average Temperature(\u00B0C)", xlab = "Year") + theme_bw()

## Moving average (ma)
ma2x12 <- ma(tempts_mean, order=12, centre=TRUE)
autoplot(ma2x12, main = "Moving Average of Mean Temperature") + theme_bw()

## End-point ma to show trend
#define a function for backwards MA
ma_bk=function(y, order, ...){
  ma<-matrix(0,nrow(y),1)
  for(i in order:nrow(y))
  {
    ma[i]<-mean(y[i-order+1:order])
  }
  ma[1:(order-1)]=NA
  return(ma)
}

tp_mean =as.matrix(temp$Mean)

tp_ma12=ma_bk(tp_mean,12) # number of week days
plot(tp_ma12,type="l", col="red", main = "Backward Moving Averages of Mean Temperature", ylab = "")
tp_ma24=ma_bk(tp_mean,24)
lines(tp_ma24,col="blue")
tp_ma48=ma_bk(tp_mean,48)
lines(tp_ma48,col="green")
legend("topleft", legend = c("MA12", "MA24", "MA48"), col = c("red", "blue", "green"), lty = 1, cex = 0.75)


# Time series decomposition of the data - stl
fitstl = tempts_mean %>% stl(t.window = 12, s.window = 6, robust = TRUE) # STL decomposition
fitstl%>% autoplot()+ xlab("Year") +
  ggtitle("STL Decomposition of Mean Temperature") +theme_bw()

monthplot(fitstl$time.series[, "seasonal"], main = "", ylab = "Seasonal", xlab = "Month")

## test remainders
stl_res = remainder(fitstl)
Acf(stl_res,lag.max=30, main = "Remainder of STL Decomposition") ## autocorrelation in lag 12
Box.test(stl_res,type="Lj")


## extract seasonal adjusted data
stl_adj = seasadj(fitstl)
autoplot(stl_adj, main = "Seasonally Adjusted Data") +theme_bw()

## Split into training and test set
# Split data using 80-20 rule
stl_train = window(stl_adj, end = c(2010,2))
autoplot(stl_train, main = "Training Set of Seasonally Adjusted Data", xlab = "Year") +theme_bw()
stl_test = window(stl_adj, start = c(2010,3))
autoplot(stl_test, main = "Test Set of Seasonally Adjusted Data", xlab = "Year") +theme_bw()


# Regression analysis
## Quadratic regression
fit_q = tslm(stl_train ~ trend + I(trend^2))
summary(fit_q)

autoplot(stl_train, series = "Seasonal Adj", ylab = "At", xlab = "Year") + autolayer(fitted(fit_q), series = "Quadratic Regression") + scale_color_manual(values = c("black","red"),                                                        breaks = c("Seasonal Adj","Quadratic Regression")) + theme_bw()

CV(fit_q)
Acf(fit_q$residual,lag.max=30)
Box.test(fit_q$residual, fitdf=length(fit_q$coefficients)+1,lag=10,type="Lj")
dwtest(fit_q,alt="two.sided")
bgtest(fit_q,10)

## Piecewise linear 4 turning points
fit_pl4 = tslm(stl_train~trend+I(pmax(trend-127,0)) + I(pmax(trend-190,0)) + I(pmax(trend-263,0)) +  I(pmax(trend-308,0)))

summary(fit_pl4)
CV(fit_pl4)

autoplot(stl_train, main = 'Piecewise Linear Regression with Four Turning Points', ylab = 'At', series = "Seasonal Adj", xlab = "Year") + autolayer(fitted(fit_pl4), series = 'Piecewise Linear') +
  scale_color_manual(values = c("black","red"),
                     breaks = c("Seasonal Adj","Piecewise Linear")) + theme_bw()

Acf(fit_pl4$residual,lag.max=30, main = "ACF of PLR4")
Box.test(fit_pl4$residual, fitdf=length(fit_pl4$coefficients)+1,lag=10,type="Lj")
dwtest(fit_pl4,alt="two.sided")
bgtest(fit_pl4,10)

## Piecewise linear 2 turning points
fit_pl2 = tslm(stl_train~trend+I(pmax(trend-127,0)) + I(pmax(trend-190,0)))
# + I(pmax(trend-263,0)) + I(pmax(trend-308,0))
summary(fit_pl2)
CV(fit_pl2)

autoplot(stl_train, main = 'Piecewise Linear Regression with Two Turning Points', ylab = 'At', series = "Seasonal Adj", xlab = "Year") + autolayer(fitted(fit_pl2), series = 'Piecewise Linear') +
  scale_color_manual(values = c("black","red"),
                     breaks = c("Seasonal Adj","Piecewise Linear")) + theme_bw()

Acf(fit_pl2$residual,lag.max=30, main = "ACF of PLR2")
Box.test(fit_pl2$residual, fitdf=length(fit_pl2$coefficients)+1,lag=10,type="Lj")
dwtest(fit_pl2,alt="two.sided")
bgtest(fit_pl2,10)


# Forecast evaluation
tp_in = window(tempts_mean, end = c(2010,2))
tp_out = window(tempts_mean, start = c(2010,3))
season_in = (tp_in - stl_train)[-c(1:416)] #extract 5yr seasonal pattern from latest train dataset
season_rep = rep(season_in,2) # replicate seasonal pattern to 10yr

## Quadratic regression
fcast_q = forecast(fit_q, h = 120)

fcast_q$x = fcast_q$x + (tp_in - stl_train) # original 
fcast_q$mean = fcast_q$mean + season_rep # forecast
fcast_q$upper = fcast_q$upper + season_rep
fcast_q$lower = fcast_q$lower + season_rep

plot(fcast_q, main = "Forecast from Quadratic Regression Model", ylab = "Average Temperature(\u00B0C)", xlab = "Year")

accuracy(fcast_q, stl_test+season_rep)

## Piecewise linear 4 turning points
fcast_pl4 = forecast(fit_pl4, h = 120)

fcast_pl4$x = fcast_pl4$x + (tp_in - stl_train) # original 
fcast_pl4$mean = fcast_pl4$mean + season_rep # forecast
fcast_pl4$upper = fcast_pl4$upper + season_rep
fcast_pl4$lower = fcast_pl4$lower + season_rep

plot(fcast_pl4, main = "Forecast from PLR4 Model", ylab = "Average Temperature(\u00B0C)", xlab = "Year")

accuracy(fcast_pl4, stl_test+season_rep)


## Piecewise linear 2 turning points
fcast_pl2 = forecast(fit_pl2, h = 120)

fcast_pl2$x = fcast_pl2$x + (tp_in - stl_train) # original 
fcast_pl2$mean = fcast_pl2$mean + season_rep # forecast
fcast_pl2$upper = fcast_pl2$upper + season_rep
fcast_pl2$lower = fcast_pl2$lower + season_rep

plot(fcast_pl2, main = "Forecast from PLR2 Model", ylab = "Average Temperature(\u00B0C)", xlab = "Year")

accuracy(fcast_pl2, stl_test+season_rep)


## Compare Forecast Error Difference
# Compare Forecast Error Difference between 2 piecewise linear models
dm.test((tp_out-fcast_pl2$mean),(tp_out-fcast_pl4$mean),power=2, alternative = "l")


# Forcast Temperature for next 10 years
# Use piecewise linear 2 turning points, since it has best forecast accuracy
n10_fit = tslm(stl_adj~trend+I(pmax(trend-127,0)) + I(pmax(trend-190,0))) # fit model with whole dataset
n10_fcast = forecast(n10_fit, h = 120)

seasonC = (tempts_mean - stl_adj)[-c(1:536)]
seasonC_rep = rep(seasonC,2)

n10_fcast$x = n10_fcast$x + (tempts_mean - stl_adj) # original 
n10_fcast$mean = n10_fcast$mean + seasonC_rep # forecast
n10_fcast$upper = n10_fcast$upper + seasonC_rep
n10_fcast$lower = n10_fcast$lower + seasonC_rep

plot(n10_fcast, main = "Melbourne Temperature Forecast for Next 10 Years", ylab = "Average Temperature(\u00B0C)", xlab = "Year")

