# Mouse Weight Analysis with Health Monitoring
Purpose of the program
   -
A web application for analyzing the weight dynamics of laboratory mice in order to monitor their health. The program allows you to:

•    Visualize changes in mouse weight over time

•    Calculate the first and second derivatives of the weight curve (rate and acceleration of weight change)

•    Identify critical points where the first derivative falls below a threshold value (indicator of possible health problems)

•    Determine zero crossing points for derivatives

•    Customize the visual representation of graphs

The program is intended for researchers in biology, medicine, and pharmacology who work with laboratory animals.

Programming language
   -
The program is written in R using the Shiny framework to create a web interface.

Input parameters
   -  
1.1. Measurement data

•    Format: Table with two columns

•    Column 1 (Day): Numeric (integer or fractional) - measurement days

•    Column 2 (Mass): Numeric (fractional) - mouse weight in grams

•	Input method:
o    File upload (Excel, CSV)
o    Paste from clipboard (copy from Excel)

1.2. Analysis parameters

•    rh (Smoothing parameter): Numeric (fractional, 0.1-5) - spline smoothing parameter

•    critical_value: Numeric (decimal) - critical value of the first derivative for determining a painful condition (default -0.6)

1.3. Visualization parameters (after calculation)

•    Graph and axis names: Text fields for setting titles

•    Theme: Choose from classic, minimalist, gray, or dark

•    Line and point colors: Choose from a color palette for each graph

•    Line and point sizes: Numeric values for setting thickness and size


Output parameters
-

 Tabular data
 -
•    Day: Numeric (fractional) - interpolated day values

•    Weight: Numeric (fractional) - smoothed weight values (spline)

•    FirstDerivative: Numeric (fractional) - first derivative values

•    SecondDerivative: Numeric (fractional) - second derivative values

 Graphical outputs
 -
•    Weight graph: Smoothed spline line + original measurement points

•	First derivative graph: Derivative line with zero crossing and critical threshold marks

•    Second derivative graph: Second derivative line with zero crossing marks

 Health warnings
-
•    Text warning: Displayed when first derivative values below the critical threshold are detected

•	First derivative table: With critical values highlighted

 Description of the implemented algorithm
 
 Smoothing spline algorithm
 
The program uses an algorithm for constructing a smoothing spline with a given smoothing parameter (rh). Main steps:

1.    Initialization of parameters:
  
•	Specifying the spline node grid

•    Initializing weight coefficients (rho)

2.    Solving the system of equations:
  
•    Constructing a tridiagonal matrix of coefficients

•    Solving using the Thomas algorithm

•	Calculate spline coefficients

 Interpolation:
 
•    Calculate spline values at specified points

• Calculate first and second derivatives analytically
 
• Algorithm for determining zero crossings

To determine the points where the derivative crosses the zero line:
```
find_zero_crossings <- function(x, y) {
  crossings <- c()
  for(i in 2:length(y)) {
    if(y[i-1] * y[i] < 0) {
      # Линейная интерполяция для точного определения точки пересечения
      x_cross <- x[i-1] - y[i-1] * (x[i] - x[i-1]) / (y[i] - y[i-1])
      crossings <- c(crossings, x_cross)
    }
  }
  crossings
}
```
 Algorithm for identifying health problems
 -
•    Comparison of the values of the first derivative with a critical threshold

•    Identification of days when the rate of weight loss exceeds the permissible limit

•    Visual and textual indication of problem periods

Test example
-
Input data:
```
Day: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
Mass: 25.1, 25.3, 25.0, 24.8, 24.5, 24.2, 23.8, 23.5, 23.2, 22.9
```
Analysis parameters:
```
rh = 1.0
critical_value = -0.6
```
Expected results:

1. Weight graph: A smooth curve passing close to the measurement points
   
2. First derivative:
   
• Negative values (weight loss)

• On days 6-7, the value may fall below -0.6 (if weight loss is accelerated)

3.	Second derivative:
   
•    May show changes in the acceleration of weight loss

•    Zero crossing points indicate a change in the nature of weight loss

Output data (example of the first lines):
-
```
Day      Weight    FirstDerivative  SecondDerivative
1.00     25.10     -0.05            0.01
1.25     25.08     -0.07            0.00
1.50     25.05     -0.10           -0.01
...      ...       ...              ...
```
Health notification:
-
If the value of the first derivative is less than -0.6 on certain days, a warning will appear:
```
⚠ WARNING: Animal is sick!
Critical days: 6.5, 7.2
Critical values: -0.65, -0.72
```

Access to the application: https://annakalyanova.shinyapps.io/mouse_weight_app/

Dependencies: shiny, ggplot2, colourpicker, DT, readxl

