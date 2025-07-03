
library(eulerr)

twlabels = c("90-130 ms","150-210 ms","300-350 ms")

reallabels = c('Spontaneous\ndissimilarity','Face-like\nratings','Face-object\ncategorisation',
               'SD/face-like','SD/categorisation','face-like/categorisation','all')

# Custom color palette from tab20 colours
colors <- c("#1f77b4", "#aec7e8", "#ff7f0e")





### FIRST TIME WINDOW ###############

#specify values to use in venn diagram
values1<-c('A' = 0.003, 
               'B' = 0.005, 
               'C' = 0.003,
               'A&B' = 0.004,
               'A&C' = 0,
               'B&C' = 0,
               'A&B&C' = 0.001
               )


# Create the proportional Venn diagram with eulerr
fit1 <- euler(values1)


# Create the plot with customized appearance
plot(fit1, 
     quantities = TRUE,                         # Show quantities in the diagram
     fills = colors,                            # Set colors for circles
     alpha = 0.5,                               # Set transparency
     labels = reallabels,#list(labels = names(values)),     # Use single-letter labels for regions
     edges = list(lty = 1, lwd = 1.5),          # Edge line settings
     main = twlabels[1], # Main title
     legend = FALSE)                             # Show legend




### SECOND TIME WINDOW ###############

#specify values to use in venn diagram
values2<-c('A' = 0.0003, 
          'B' = 0.004, 
          'C' = 0.184,
          'A&B' = 0.001,
          'A&C' = 0.030,
          'B&C' = 0.035,
          'A&B&C' = 0.070
)

# Create the proportional Venn diagram with eulerr
fit2 <- euler(values2)


# Create the plot with customized appearance
plot(fit2, 
     quantities = TRUE,                         # Show quantities in the diagram
     fills = colors,                            # Set colors for circles
     alpha = 0.5,                               # Set transparency
      labels = reallabels,#list(labels = names(values)),     # Use single-letter labels for regions
     edges = list(lty = 1, lwd = 1.5),          # Edge line settings
     main = twlabels[2], # Main title
     legend = FALSE)                             # Show legend




### THIRD TIME WINDOW ###############

#specify values to use in venn diagram
values3<-c('A' = 0.002, 
          'B' = 0.001, 
          'C' = 0.070,
          'A&B' = 0.001,
          'A&C' = 0.021,
          'B&C' = 0.015,
          'A&B&C' = 0.039
)


# Create the proportional Venn diagram with eulerr
fit3 <- euler(values3)


# Create the plot with customized appearance
plot(fit3, 
     quantities = TRUE,                         # Show quantities in the diagram
     fills = colors,                            # Set colors for circles
     alpha = 0.5,                               # Set transparency
     labels = reallabels,#list(labels = names(values)),     # Use single-letter labels for regions
     edges = list(lty = 1, lwd = 1.5),          # Edge line settings
     main = twlabels[3], # Main title
     legend = FALSE)                             # Show legend




