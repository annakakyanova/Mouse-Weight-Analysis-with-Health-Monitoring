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
o	Specifying the spline node grid
o    Initializing weight coefficients (rho)
2.    Solving the system of equations:
o    Constructing a tridiagonal matrix of coefficients
o    Solving using the Thomas algorithm
o	Calculate spline coefficients
3.    Interpolation:
o    Calculate spline values at specified points
o    Calculate first and second derivatives analytically
5.2. Algorithm for determining zero crossings
To determine the points where the derivative crosses the zero line:

