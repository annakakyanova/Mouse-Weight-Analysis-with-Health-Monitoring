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
