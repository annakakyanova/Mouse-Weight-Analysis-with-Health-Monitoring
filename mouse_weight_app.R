
library(shiny)
library(ggplot2)
library(colourpicker)
library(DT)
library(readxl)

ui <- fluidPage(
  titlePanel("Mouse Weight Analysis with Health Monitoring"),
  sidebarLayout(
    sidebarPanel(
      h4("Data Input"),
      radioButtons("input_type", "Input Method:",
                   choices = c("Upload Excel/CSV" = "upload",
                               "Paste from Excel" = "paste"),
                   selected = "upload"),
      
      conditionalPanel(
        condition = "input.input_type == 'upload'",
        fileInput("file", "Upload File",
                  accept = c(".xlsx", ".xls", ".csv"),
                  buttonLabel = "Browse..."),
        checkboxInput("header", "Header row", TRUE),
        helpText("File should contain two columns: Day and Mass")
      ),
      
      conditionalPanel(
        condition = "input.input_type == 'paste'",
        h5("Paste Excel data here:"),
        textAreaInput("pasted_data", "", rows = 5,
                      placeholder = "Paste (Ctrl+V) your data here\nTwo columns: Days (first) and Mass (second)\nSeparated by tabs or spaces"),
        actionButton("parse_data", "Parse Data", class = "btn-primary"),
        helpText("Copy two columns from Excel and paste here")
      ),
      
      numericInput("rh", "Smoothing parameter (rh):", 1, min = 0.1, max = 5, step = 0.1),
      numericInput("critical_value", "Critical value for 1st derivative:", -0.6, step = 0.01),
      tags$small(style = "color: grey;", "Values below this indicate potential health issues"),
      actionButton("calc", "Calculate", class = "btn-primary"),
      
      conditionalPanel(
        condition = "input.calc > 0",
        h4("Graph Settings"),
        
        h4("Text Customization"),
        textInput("mass_title", "Mass Plot Title:", "Weight Change"),
        textInput("mass_y_label", "Y-axis Label (Mass):", "Weight (g)"),
        
        textInput("deriv1_title", "1st Derivative Title:", "First Derivative"),
        textInput("deriv1_y_label", "Y-axis Label (1st Derivative):", "Weight Change Rate"),
        
        textInput("deriv2_title", "2nd Derivative Title:", "Second Derivative"),
        textInput("deriv2_y_label", "Y-axis Label (2nd Derivative):", "Weight Change Acceleration"),
        
        selectInput("theme", "Theme:",
                    choices = c("Classic" = "classic",
                                "Minimal" = "minimal",
                                "Gray" = "gray",
                                "Dark" = "dark")),
        
        h5("Mass Plot:"),
        colourInput("mass_line_color", "Line Color:", value = "red"),
        colourInput("mass_point_color", "Points Color:", value = "black"),
        numericInput("mass_line_size", "Line Size:", 1, min = 0.1, max = 5, step = 0.1),
        numericInput("mass_point_size", "Points Size:", 3, min = 1, max = 10, step = 0.5),
        
        h5("First Derivative:"),
        colourInput("deriv1_line_color", "Line Color:", value = "blue"),
        numericInput("deriv1_line_size", "Line Size:", 1, min = 0.1, max = 5, step = 0.1),
        colourInput("zero_line_color1", "Zero Line Color:", value = "gray50"),
        numericInput("zero_line_size1", "Zero Line Size:", 0.5, min = 0.1, max = 3, step = 0.1),
        colourInput("cross_line_color1", "Crossing Line Color:", value = "purple"),
        numericInput("cross_line_size1", "Crossing Line Size:", 0.7, min = 0.1, max = 3, step = 0.1),
        colourInput("label_color", "Label Color:", value = "purple"),
        numericInput("label_size", "Label Size:", 4, min = 2, max = 8, step = 0.5),
        
        h5("Second Derivative:"),
        colourInput("deriv2_line_color", "Line Color:", value = "green4"),
        numericInput("deriv2_line_size", "Line Size:", 1, min = 0.1, max = 5, step = 0.1),
        colourInput("zero_line_color2", "Zero Line Color:", value = "gray50"),
        numericInput("zero_line_size2", "Zero Line Size:", 0.5, min = 0.1, max = 3, step = 0.1),
        colourInput("cross_line_color2", "Crossing Line Color:", value = "orange"),
        numericInput("cross_line_size2", "Crossing Line Size:", 0.7, min = 0.1, max = 3, step = 0.1)
      )
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Mass", 
                 plotOutput("plot_mass"), 
                 downloadButton("download_mass", "Save Plot")),
        tabPanel("1st Derivative", 
                 plotOutput("plot_deriv1"),
                 uiOutput("health_warning"),
                 h4("First Derivative Values"),
                 DTOutput("deriv1_table"),
                 downloadButton("download_deriv1", "Save Plot")),
        tabPanel("2nd Derivative", 
                 plotOutput("plot_deriv2"), 
                 downloadButton("download_deriv2", "Save Plot")),
        tabPanel("All Data", 
                 tableOutput("table"), 
                 downloadButton("download_table", "Save Table"))
      )
    )
  )
)

server <- function(input, output, session) {
  # Reactive values
  app_data <- reactiveValues(
    raw_data = NULL,
    results = NULL,
    crossings1 = NULL,
    crossings2 = NULL,
    health_status = NULL
  )
  
  # Handle file upload
  observeEvent(input$file, {
    req(input$file)
    
    tryCatch({
      if(grepl("\\.csv$", input$file$name, ignore.case = TRUE)) {
        data <- read.csv(input$file$datapath, header = input$header)
      } else {
        data <- read_excel(input$file$datapath, col_names = input$header)
      }
      
      if(ncol(data) >= 2) {
        app_data$raw_data <- data.frame(
          day = data[[1]],
          mass = data[[2]]
        )
        names(app_data$raw_data) <- c("day", "mass")
        showNotification("Data uploaded successfully", type = "message")
      } else {
        showNotification("File must have at least 2 columns", type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Handle paste from Excel
  observeEvent(input$parse_data, {
    req(input$pasted_data)
    
    tryCatch({
      # Try tab separator first (common when copying from Excel)
      data <- tryCatch({
        read.table(text = input$pasted_data, sep = "\t", header = FALSE)
      }, error = function(e) {
        # If tab fails, try any whitespace
        read.table(text = input$pasted_data, header = FALSE)
      })
      
      if(ncol(data) >= 2) {
        app_data$raw_data <- data.frame(
          day = data[[1]],
          mass = data[[2]]
        )
        names(app_data$raw_data) <- c("day", "mass")
        showNotification("Data parsed successfully", type = "message")
      } else {
        showNotification("Need exactly 2 columns (Day and Mass)", type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error parsing data:", e$message), type = "error")
    })
  })
  
  # Apply theme
  apply_theme <- function(plot) {
    switch(input$theme,
           "classic" = plot + theme_classic(),
           "minimal" = plot + theme_minimal(),
           "gray" = plot + theme_gray(),
           "dark" = plot + theme_dark())
  }
  
  # Find zero crossings
  find_zero_crossings <- function(x, y) {
    crossings <- c()
    for(i in 2:length(y)) {
      if(y[i-1] * y[i] < 0) {
        x_cross <- x[i-1] - y[i-1] * (x[i] - x[i-1]) / (y[i] - y[i-1])
        crossings <- c(crossings, x_cross)
      }
    }
    crossings
  }
  
  # Main calculations
  observeEvent(input$calc, {
    req(input$calc)
    req(app_data$raw_data)
    
    y <- app_data$raw_data$mass
    x <- app_data$raw_data$day
    rh <- input$rh
    
    if (length(y) != length(x)) {
      showNotification("Error: number of masses and days must match!", type = "error")
      return()
    }
    
    if (length(y) < 2) {
      showNotification("Need at least 2 data points", type = "error")
      return()
    }
    
    # Original calculations
    kx <- 0
    n <- length(y)
    rho <- rep(rh, n)
    rho[10] <- 1
    rho[11] <- 1
    
    kxx <- rep(kx, n)
    nxx <- 1
    for(i in 1:(n-1)) {
      nxx <- nxx + kxx[i] + 1
    }
    
    xx <- numeric(nxx)
    xx[1] <- x[1]
    ixx <- 1
    for(i in 1:(n-1)) {
      h <- (x[i+1] - x[i])/(kxx[i]+1)
      for(j in 1:(kxx[i]+1)) {
        xx[ixx+j] <- x[i] + h*j
      }
      ixx <- ixx + kxx[i] + 1
    }
    
    a <- b <- c <- d <- e <- g <- zm <- numeric(n)
    aa <- dd <- u <- v <- w <- p <- q <- r <- s <- t <- numeric(n+2)
    sp <- d1sp <- d2sp <- delt <- numeric(n)
    spxx <- d1spxx <- d2spxx <- numeric(nxx)
    
    a[1] <- a[n] <- 1
    b[1] <- b[n-1] <- b[n] <- 0
    c[1] <- c[n-2] <- c[n-1] <- c[n] <- 0
    d[1] <- g[1] <- g[n] <- e[1] <- e[2] <- e[3] <- 0
    
    for(i in 2:(n-1)) {
      h1 <- x[i] - x[i-1]
      h2 <- x[i+1] - x[i]
      a[i] <- (h1+h2)/3 + rho[i-1]/h1^2 + (1/h1 + 1/h2)^2*rho[i] + rho[i+1]/h2^2
      g[i] <- (y[i+1]-y[i])/h2 - (y[i]-y[i-1])/h1
      
      if(i <= (n-2)) {
        h3 <- x[i+2] - x[i+1]
        b[i] <- h2/6 - ((1/h1 + 1/h2)*rho[i] + (1/h2 + 1/h3)*rho[i+1])/h2
        d[i+1] <- b[i]
      }
      if(i <= (n-3)) {
        h3 <- x[i+2] - x[i+1]
        c[i] <- rho[i+1]/(h2*h3)
        e[i+2] <- c[i]
      }
    }
    
    v[1] <- v[2] <- w[1] <- w[2] <- u[1] <- u[2] <- 0
    for(i in 1:n) {
      dd[i] <- d[i] + e[i]*v[i]
      aa[i] <- a[i] + dd[i]*v[i+1] + e[i]*w[i]
      u[i+2] <- (g[i] - dd[i]*u[i+1] - e[i]*u[i])/aa[i]
      v[i+2] <- -(b[i] + dd[i]*w[i+1])/aa[i]
      w[i+2] <- -c[i]/aa[i]
    }
    
    p[1] <- 0; q[2] <- 0; p[2] <- 1; q[1] <- 1
    for(i in 1:n) {
      p[i+2] <- -(dd[i]*p[i+1] + e[i]*p[i])/aa[i]
      q[i+2] <- -(dd[i]*q[i+1] + e[i]*q[i])/aa[i]
    }
    
    t[n-1] <- t[n] <- 0; s[n-1] <- 0; s[n] <- 1; r[n-1] <- 1; r[n] <- 0
    for(i in (n-2):1) {
      t[i] <- v[i+2]*t[i+1] + w[i+2]*t[i+2] + u[i+2]
      s[i] <- v[i+2]*s[i+1] + w[i+2]*s[i+2] + p[i+2]
      r[i] <- v[i+2]*r[i+1] + w[i+2]*r[i+2] + q[i+2]
    }
    
    a11 <- 1 - q[n+1] - w[n+1]*r[1]
    a12 <- -(p[n+1] + v[n+1] + w[n+1]*s[1])
    a21 <- -(v[n+2]*r[1] + w[n+2]*r[2] + q[n+2])
    a22 <- 1 - p[n+2] - v[n+2]*s[1] - w[n+2]*s[2]
    b1 <- w[n+1]*t[1] + u[n+1]
    b2 <- v[n+2]*t[1] + w[n+2]*t[2] + u[n+2]
    
    zm[n-1] <- (b1*a22 - b2*a12)/(a11*a22 - a12*a21)
    zm[n] <- (-b1*a21 + b2*a11)/(a11*a22 - a12*a21)
    
    for(i in 1:(n-2)) {
      zm[i] <- t[i] + s[i]*zm[n] + r[i]*zm[n-1]
    }
    
    aa <- numeric(n)
    aa[1] <- y[1] - rho[1]*(zm[2] - zm[1])/(x[2]-x[1])
    aa[n] <- y[n] + rho[n]*(zm[n] - zm[n-1])/(x[n]-x[n-1])
    
    for(i in 2:(n-1)) {
      d[i] <- (zm[i+1] - zm[i])/(x[i+1]-x[i]) - (zm[i] - zm[i-1])/(x[i]-x[i-1])
      aa[i] <- y[i] - rho[i]*d[i]
    }
    
    for(j in 1:length(xx)) {
      for(i in 2:n) {
        if(x[i] > xx[j]) break
      }
      i <- i - 1
      h <- x[i+1] - x[i]
      tt <- (xx[j] - x[i])/h
      spxx[j] <- aa[i]*(1-tt) + aa[i+1]*tt - h^2/6*tt*(1-tt)*((2-tt)*zm[i] + (1+tt)*zm[i+1])
      d1spxx[j] <- (aa[i+1] - aa[i])/h - h/6*((2 - 6*tt + 3*tt^2)*zm[i] + (1 - 3*tt^2)*zm[i+1])
      d2spxx[j] <- (1 - tt)*zm[i] + tt*zm[i+1]
    }
    
    app_data$results <- data.frame(
      Day = xx,
      Weight = spxx,
      FirstDerivative = d1spxx,
      SecondDerivative = d2spxx
    )
    
    app_data$crossings1 <- find_zero_crossings(xx, d1spxx)
    app_data$crossings2 <- find_zero_crossings(xx, d2spxx)
    
    # Health status check
    critical_points <- app_data$results$FirstDerivative < input$critical_value
    app_data$health_status <- if(any(critical_points, na.rm = TRUE)) {
      list(
        is_sick = TRUE,
        critical_days = app_data$results$Day[critical_points],
        critical_values = app_data$results$FirstDerivative[critical_points]
      )
    } else {
      list(is_sick = FALSE)
    }
  })
  
  # Health warning message
  output$health_warning <- renderUI({
    if(!is.null(app_data$health_status) && app_data$health_status$is_sick) {
      critical_days <- paste(round(app_data$health_status$critical_days, 2), collapse = ", ")
      critical_values <- paste(round(app_data$health_status$critical_values, 4), collapse = ", ")
      
      div(
        style = "color: red; font-size: 18px; font-weight: bold; margin: 15px 0; padding: 10px; background-color: #ffeeee; border: 1px solid red; border-radius: 5px;",
        icon("exclamation-triangle"), 
        strong("WARNING: Animal is sick!"),
        br(),
        paste("Critical days:", critical_days),
        br(),
        paste("Critical values:", critical_values)
      )
    }
  })
  
  # Formatted derivative table
  output$deriv1_table <- renderDT({
    req(app_data$results)
    
    datatable(
      app_data$results[, c("Day", "FirstDerivative")],
      rownames = FALSE,
      options = list(
        pageLength = 10,
        dom = 'tip',
        scrollX = TRUE
      )
    ) %>%
      formatRound('FirstDerivative', 4) %>%
      formatStyle(
        'FirstDerivative',
        backgroundColor = styleInterval(
          c(input$critical_value),
          c('red', 'white')
        ),
        color = styleInterval(
          c(input$critical_value),
          c('white', 'black')
        ),
        fontWeight = styleInterval(
          c(input$critical_value),
          c('bold', 'normal')
        )
      )
  })
  
  # Plot functions
  mass_plot <- reactive({
    req(app_data$results, app_data$raw_data)
    p <- ggplot(app_data$results, aes(Day, Weight)) +
      geom_line(color = input$mass_line_color, linewidth = input$mass_line_size) +
      geom_point(data = app_data$raw_data, aes(day, mass), 
                 color = input$mass_point_color, size = input$mass_point_size) +
      labs(title = input$mass_title, 
           x = "Day", 
           y = input$mass_y_label)
    
    apply_theme(p)
  })
  
  deriv1_plot <- reactive({
    req(app_data$results, app_data$crossings1)
    
    # Calculate y position for labels (5% above the bottom)
    y_range <- range(app_data$results$FirstDerivative)
    label_y <- y_range[1] + diff(y_range) * 0.05
    
    p <- ggplot(app_data$results, aes(Day, FirstDerivative)) +
      geom_line(color = input$deriv1_line_color, linewidth = input$deriv1_line_size) +
      geom_hline(yintercept = input$critical_value, color = "red", 
                 linewidth = 1, linetype = "dashed") +
      geom_hline(yintercept = 0, color = input$zero_line_color1, 
                 linewidth = input$zero_line_size1, linetype = "dashed") +
      labs(title = input$deriv1_title, 
           x = "Day", 
           y = input$deriv1_y_label)
    
    if(length(app_data$crossings1) > 0) {
      # Create data for labels
      crossing_labels <- data.frame(
        x = app_data$crossings1,
        y = rep(label_y, length(app_data$crossings1)),
        label = paste0("Day ", round(app_data$crossings1, 1))
      )
      
      p <- p + 
        geom_vline(xintercept = app_data$crossings1, 
                   color = input$cross_line_color1, 
                   linewidth = input$cross_line_size1,
                   linetype = "dotted") +
        geom_label(data = crossing_labels,
                   aes(x = x, y = y, label = label),
                   color = "white",
                   fill = input$label_color,
                   size = input$label_size,
                   alpha = 0.8,
                   label.size = 0,
                   label.padding = unit(0.2, "lines"))
    }
    
    apply_theme(p)
  })
  
  deriv2_plot <- reactive({
    req(app_data$results, app_data$crossings2)
    p <- ggplot(app_data$results, aes(Day, SecondDerivative)) +
      geom_line(color = input$deriv2_line_color, linewidth = input$deriv2_line_size) +
      geom_hline(yintercept = 0, color = input$zero_line_color2, 
                 linewidth = input$zero_line_size2, linetype = "dashed") +
      labs(title = input$deriv2_title, 
           x = "Day", 
           y = input$deriv2_y_label)
    
    if(length(app_data$crossings2) > 0) {
      p <- p + 
        geom_vline(xintercept = app_data$crossings2, 
                   color = input$cross_line_color2, 
                   linewidth = input$cross_line_size2,
                   linetype = "dotted")
    }
    
    apply_theme(p)
  })
  
  # Outputs
  output$plot_mass <- renderPlot({ mass_plot() })
  output$plot_deriv1 <- renderPlot({ deriv1_plot() })
  output$plot_deriv2 <- renderPlot({ deriv2_plot() })
  output$table <- renderTable({ app_data$results }, digits = 4)
  
  # Download handlers
  output$download_mass <- downloadHandler(
    filename = function() { paste("weight_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".png", sep = "") },
    content = function(file) {
      ggsave(file, plot = mass_plot(), device = "png", width = 8, height = 6, dpi = 300)
    }
  )
  
  output$download_deriv1 <- downloadHandler(
    filename = function() { paste("first_derivative_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".png", sep = "") },
    content = function(file) {
      ggsave(file, plot = deriv1_plot(), device = "png", width = 8, height = 6, dpi = 300)
    }
  )
  
  output$download_deriv2 <- downloadHandler(
    filename = function() { paste("second_derivative_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".png", sep = "") },
    content = function(file) {
      ggsave(file, plot = deriv2_plot(), device = "png", width = 8, height = 6, dpi = 300)
    }
  )
  
  output$download_table <- downloadHandler(
    filename = function() { paste("results_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".csv", sep = "") },
    content = function(file) {
      write.csv(app_data$results, file, row.names = FALSE, fileEncoding = "UTF-8")
    }
  )
}

shinyApp(ui, server)