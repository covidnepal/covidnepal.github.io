# follow the following website
# https://medium.com/@anjesh/step-by-step-choropleth-map-in-r-a-case-of-mapping-nepal-7f62a84078d9

install.packages("rgdal")
install.packages("gpclib")
install.packages("maptool")

library(rgdal)
library(ggplot2)
library(dplyr)
library(gpclib)
gpclibPermit()
library(maptools)

nepal.adm3.shp <- readOGR(dsn="/Users/bibhadhungel/Desktop/webpage/NepalMaps/baselayers/NPL_adm", layer="NPL_adm3", stringsAsFactors = FALSE)
nepal.adm3.shp.df <- fortify(nepal.adm3.shp, region = "NAME_3")

map <- ggplot(data = nepal.adm3.shp.df, aes(x = long, y = lat, group = group))

map + geom_path()

map + 
  geom_polygon(aes(fill = id)) +
  coord_fixed(1.3) +
  guides(fill = FALSE)

nepal.adm3.shp.df %>%
  distinct(id) %>%
  write.csv("/Users/bibhadhungel/Desktop/webpage/NepalMaps/baselayers/districts12.csv", row.names = FALSE)

nepal.adm3.shp.df %>%
  distinct(id) %>%
  write.csv("districts.csv", row.names = FALSE)

#hpi.data <- read.csv("districts.csv")
#colnames(hpi.data) <- c("id")

hpi.data <- read.csv("/Users/bibhadhungel/Desktop/webpage/NepalMaps/baselayers/corona.csv")
#hpi.data <- read.csv("/Users/bibhadhungel/Desktop/webpage/NepalMaps/data.csv.txt")
#hpi.data
#colnames(hpi.data) <- c("id","A","B","C","D","HPI")


nepal.adm3.shp.df <- merge(nepal.adm3.shp.df, hpi.data, by ="id")

# Drawing Choropleth map
#Since dataframe nepal.adm3.shp.df is now updated (with extra HPI column), lets re-create the map plot variable again.

map <- ggplot(data = nepal.adm3.shp.df, aes(x = long, y = lat, group = group))

# Run the following code to create polygon map, using corona CASES to fill the polygons.
map + 
  geom_polygon(aes(fill = Cases), color = 'gray', size = 0.1) +
  coord_fixed(1.3)

#However there are still issues, lets change the gradient so that the high value of HPI (40+) is represented by dark colors and low value (20-) by light colors.
#Changing the gradient scale
#Add scale_fill_gradient(..) and give high and low colors. Play with the colors to see how the colors are changed in the map.

  map + 
    geom_polygon(aes(fill = Cases), color = 'gray', size = 0.1) +
    scale_fill_gradient(high = "#e34a33", low = "#fee8c8", guide = "colorbar") +
    coord_fixed(1.3)

# Changing Legend Title
  #Now change the legend title from default to something you want.
  
  map + 
    geom_polygon(aes(fill = Cases), color = 'gray', size = 0.1) +
    scale_fill_gradient(high = "#e34a33", low = "#fee8c8", guide = "colorbar") +
    coord_fixed(1.3) +
    guides(fill=guide_colorbar(title="Total Covid-19 cases"))
  
  #Moving the Legend inside chart
  #There’s ample space inside the chart, why don’t we move the legend inside the chart.
  map + 
    geom_polygon(aes(fill = Cases), color = 'gray', size = 0.1) +
    scale_fill_gradient(high = "#e34a33", low = "#fee8c8", guide = "colorbar") +
    coord_fixed(1.3) +
    guides(fill=guide_colorbar(title="Total Covid-19 cases")) + 
    theme(legend.justification=c(0,0), legend.position=c(0,0))

  
  # Creating clean map
  #The background grid and lat-long axis are not necessary for the map. Lets remove them.
  theme_bare <- theme(
    axis.line = element_blank(), 
    axis.text.x = element_blank(), 
    axis.text.y = element_blank(),
    axis.ticks = element_blank(), 
    axis.title.x = element_blank(), 
    axis.title.y = element_blank(),
    legend.text=element_text(size=7),
    legend.title=element_text(size=8),
    panel.background = element_blank(),
    panel.border = element_rect(colour = "gray", fill=NA, size=0.5)
  )
  map + 
    geom_polygon(aes(fill = Cases), color = 'gray', size = 0.1) +
    guides(fill=guide_colorbar(title="HP Index")) + 
    scale_fill_gradient(high = "#e34a33", low = "#fee8c8", guide = "colorbar") +
    coord_fixed(1.3) +
    theme(legend.justification=c(0,0), legend.position=c(0,0)) +
    theme_bare
  
  
  # Adding labels for each district polygon
  #Now we need to show districts names in the map. Centroids calculation is bit tricky, but it works if you follow this code from stackoverflow.
  
  centroids <- setNames(do.call("rbind.data.frame", by(nepal.adm3.shp.df, nepal.adm3.shp.df$group, function(x) {Polygon(x[c('long', 'lat')])@labpt})), c('long', 'lat')) 
  centroids$label <- nepal.adm3.shp.df$id[match(rownames(centroids), nepal.adm3.shp.df$group)]
  
  #######################################################################
  #the above code didn7 work so i used this by my self. Be cautious if the latitude and longitude matches the district names
  corona <- read.csv("~/Desktop/webpage/NepalMaps/baselayers/corona.csv")
  centroids$label <- corona$id
  #######################################################################
  
  
  map + 
    geom_polygon(aes(fill = Cases), color = 'gray', size = 0.1) +
    guides(fill=guide_colorbar(title="Total Covid-19 cases")) + 
    scale_fill_gradient(high = "#e34a33", low = "#fee8c8", guide = "colorbar") +
    coord_fixed(1.3) +
    theme(legend.justification=c(0,0), legend.position=c(0,0)) +
    with(centroids, annotate(geom="text", x = long, y = lat, label=label, size=2)) +
    theme_bare
  
  #Showing labels for selected districts only
  #The map looks cluttered. I am interested in districts which passes certain criteria. Lets show the names for districts for which HPI is greater than 40.
  
  centroids.selected <- centroids[centroids$label %in% (nepal.adm3.shp.df[nepal.adm3.shp.df$Cases>1,]$id),]
  map + 
    geom_polygon(aes(fill = Cases), color = 'gray', size = 0.1) +
    guides(fill=guide_colorbar(title="Total Covid-19 cases")) + 
    scale_fill_gradient(high = "#e34a33", low = "#fee8c8", guide = "colorbar") +
    coord_fixed(1.3) +
    theme(legend.justification=c(0,0), legend.position=c(0,0)) +
    with(centroids.selected, annotate(geom="text", x = long, y = lat, label=label, size=2)) +
    theme_bare
  
  
  # Adding title to the map
  #This is the easiest of all. ggtitle(..) does the job.
  
  map + 
    geom_polygon(aes(fill = Cases), color = 'gray', size = 0.1) +
    ggtitle("Covid-19 cases Nepal") +
    guides(fill=guide_colorbar(title="Total Covid-19 cases")) + 
    scale_fill_gradient(high = "#e34a33", low = "#fee8c8", guide = "colorbar") +
    coord_fixed(1.3) +
    theme(legend.justification=c(0,0), legend.position=c(-0.01,0)) +
    with(centroids.selected, annotate(geom="text", x = long, y = lat, label=label, size=2)) +
    theme_bare
  
  
  
  
  
  
  
  
  
  
  