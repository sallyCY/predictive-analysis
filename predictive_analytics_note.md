### Outline

* Prediction with regression models
  * Prediction with multiple linear regression *
  * Prediction error *
  * Back-testing and measures of forecast accuracy

- Time-series decomposition 
  - Deterministic vs stochastic trend
  - Classical decomposition: trends and seasonality; addictive vs multiplicative
  - Alternative decompositions: SLT *, SEATS & X11(X12, X13)
  - Forecasting with decompositions
- **Project1: monthly_forecast**
- Exponential smoothing
  - Simple exponential smoothing
  - Holt's linear trend method, exponential trend method, Holt-Winters method
  - State space representation of exponential smoothing
- Autoregressive models
  - Stochastic trends, differencing and related properties
  - ARMA with seasonality
  - Model selection
- Dynamics regression & complex seasonality *
  - Regression with ARIMA errors
  - Dynamic harmonic regression
  - Dealing with multi-layer seasonality
- Predictive distribution
  - Modelling changing distributions
  - Prediction using mixture models
  - Assessment of predictive distributions
- **Project 2: daily_forecast**
- Further topics
  - Forecast combination *
  - Multivariate time series: vector auto-regression
  - Hierarchical time series



### Highlights

>  **Model fit assessment**
>
> * **R<sup>2</sup>** - larger is better - % of y explained by the model
>  $$
>   R^2 = 1-SSE/Va(y)
>  $$
>
> * **Adjusted R<sup>2</sup>** - penalizes the number of predictors
>
> * **AIC** - smaller is better
>  $$
>   AIC = Nln(SSE/N)+2(k+2)
>  $$
>
> * Corrected AIC (AICc) - adjust for bias that for small number of obs, AIC tends to favor models with large number of explanatory
>
> * **BIC** - smaller is better There are cases  where AIC and BIC conflict, if more conservative, i.e. prefer smaller model --> use BIC
>  $$
>   BIC = Nln(SSE/N)+(k+2)lnN
>  $$
>
> * **CV** - smaller is better - cross validation, measure 'out-of-sample' predictive ability. 'leave-one-out' algorithm
>  $$
>   CV = 1/N \sum_i^N (e_i^*)^2
>  $$
>
> * 
>
> 
>
> **Model forecast evaluation**
>
> * MSE, RMSE, MAE, MAPE, MASE
>



>  1. test for stationarity of y3
>
>  **Box_Ljung test**
>
>  * Box.test(remainder): a type of statistical test of whether any of a group of *autocorrelations* of a time series are different from zero
>
>  **Durbin Watson test**
>
>  * dwtest(fitted_model): a measure of autocorrelation in the residuals from regression analysis (restricted to 1st-order)
>
>  **Breusch-Godfrey test**
>
>  * bgtest(fitted_model, p): detect autocorrelation up to predetermined order p
>
>  **adf test**
>
>  **kpss test**
>
>  

