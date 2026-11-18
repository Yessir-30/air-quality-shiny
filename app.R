# =====================================================================
#  Projet Shiny — Le vent fait-il baisser la pollution ?
#  Analyse de données avec R — JUNIA
# =====================================================================

library(shiny)    # shiny : construit une page web interactive pilotée par R
library(dplyr)    # dplyr : filter(), mutate(), group_by(), summarise()...
library(ggplot2)  # ggplot2 : les graphiques
library(readr)    # readr : read_csv() lit le fichier CSV

# ---------------------------------------------------------------------
# 1. LES DONNÉES — chargées UNE seule fois, au démarrage de l'application
# ---------------------------------------------------------------------
data <- read_csv("08_air_quality.csv")

# La liste des polluants : à gauche le nom affiché, à droite la colonne du CSV
polluants <- c("Particules fines (PM2.5)" = "pm25",
               "Dioxyde d'azote (NO2)"    = "no2",
               "Ozone (O3)"               = "o3")

# Le trafic est coupé en deux groupes à sa valeur médiane
seuil_trafic <- median(data$traffic_index)
data <- data %>%
  mutate(trafic = case_when(traffic_index <= seuil_trafic ~ "Trafic faible",
                            TRUE                          ~ "Trafic élevé"))

# Nos 2 couleurs : orange = vent faible, violet = vent fort
couleurs <- c("Vent faible" = "#F28C28", "Vent fort" = "#5B2A86")

# ---------------------------------------------------------------------
# 2. L'INTERFACE (ui) — CE QUE L'UTILISATEUR VOIT
# ---------------------------------------------------------------------
ui <- fluidPage(
  
  # bs_theme() choisit les couleurs et la police de toute la page
  theme = bslib::bs_theme(version = 5, bg = "#F7F3FB", fg = "#2B1A3D",
                          primary = "#5B2A86", secondary = "#F28C28",
                          base_font = "'Segoe UI', Helvetica, Arial, sans-serif"),
  
  # Le CSS règle l'apparence : couleurs, arrondis, ombres et animations
  tags$style(HTML("
    /* Le bandeau du titre, en dégradé violet vers orange */
    h2 { background: linear-gradient(90deg, #5B2A86, #F28C28); color: white;
         font-weight: 700; font-size: 38px; padding: 26px 32px;
         border-radius: 0 0 24px 24px; margin: 0 0 24px; }

    /* Les cartes blanches */
    .well, .tab-content { background: white; border: none; border-radius: 20px;
                          box-shadow: 0 6px 24px rgba(91, 42, 134, 0.12); padding: 24px; }
    .tab-content { margin-top: 16px; }

    /* Le contenu apparaît en douceur quand on change d'onglet */
    @keyframes apparition { from { opacity: 0; transform: translateY(10px); }
                            to   { opacity: 1; transform: translateY(0); } }
    .tab-pane.active { animation: apparition 0.4s ease; }

    /* Les onglets en forme de pastilles */
    .nav-tabs { border: none; gap: 8px; }
    .nav-tabs .nav-link { border: none; border-radius: 980px; color: #5B2A86;
                          font-weight: 600; transition: all 0.2s; }
    .nav-tabs .nav-link:hover { background: #F28C28; color: white; transform: translateY(-2px); }
    .nav-tabs .nav-link.active { background: #5B2A86; color: white; }

    /* Les réponses de la devinette : de vrais boutons */
    .radio input { position: absolute; opacity: 0; }
    .radio label { border: 2px solid #5B2A86; border-radius: 980px; padding: 8px 20px;
                   margin: 4px 0; cursor: pointer; font-weight: 600; transition: all 0.2s; }
    .radio label:hover { background: #F28C28; border-color: #F28C28; color: white;
                         transform: translateY(-2px); }
    .radio label:has(input:checked) { background: #5B2A86; color: white; }

    /* Le curseur en dégradé */
    .irs--shiny .irs-bar { background: linear-gradient(90deg, #F28C28, #5B2A86); border: none; }
    .irs--shiny .irs-single { background: #5B2A86; }
    .irs--shiny .irs-handle { border-color: #F28C28; }

    /* Les textes mis en avant */
    h1 { color: #5B2A86; font-weight: 700; font-size: 48px; }
    #verdict, #guess_result { color: #5B2A86; font-size: 20px; font-weight: 600; margin-top: 16px; }
    #jour_clique { color: #C96A10; font-weight: 600; margin-top: 8px; }
  ")),
  
  # Carte twist n° 8 : le titre est une question
  titlePanel("💨 Le vent fait-il baisser la pollution ?"),
  
  sidebarLayout(
    
    sidebarPanel(
      selectInput("city", "🏙️ Ville :",
                  choices = sort(unique(data$city)),
                  selected = "Lille"),
      
      selectInput("polluant", "🧪 Polluant :", choices = polluants),
      
      # Un curseur à une poignée : au-dessus, le vent est « fort »
      sliderInput("seuil", "🍃 Seuil de vent fort (km/h) :",
                  min = 5, max = 30, value = 15),
      
      # input_switch() : un interrupteur ; sa valeur est TRUE ou FALSE
      bslib::input_switch("tendance", "📉 Droite de tendance", value = TRUE),
      
      bslib::input_switch("show_secret", "✨ Révéler notre découverte", value = FALSE)
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("📊 Explorer",
                 # h1() affiche le chiffre clé en très grand
                 h1(textOutput("big_number")),
                 # click = "clic" : l'endroit cliqué se lit dans input$clic
                 plotOutput("plot_main", click = "clic"),
                 textOutput("jour_clique"),
                 textOutput("verdict"),
                 textOutput("sentence")),
        tabPanel("🏙️ Comparer les villes",
                 plotOutput("plot_villes")),
        tabPanel("🚗 Examiner le trafic",
                 plotOutput("plot_trafic"),
                 textOutput("trafic_sentence")),
        tabPanel("🤨 Notre découverte",
                 # La devinette ; selected = character(0) ne coche rien au départ
                 radioButtons("devine", "🤔 À votre avis, quel polluant baisse le moins quand le vent est fort ?",
                              choices = polluants, selected = character(0)),
                 textOutput("guess_result"),
                 plotOutput("plot_secret"),
                 textOutput("secret_sentence"))
      )
    )
  )
)

# ---------------------------------------------------------------------
# 3. LE SERVEUR — LES CALCULS QUI RÉAGISSENT AUX CHOIX
# ---------------------------------------------------------------------
server <- function(input, output, session) {
  
  # Le nom affiché du polluant choisi, par exemple « Ozone (O3) »
  nom_polluant <- reactive({
    names(polluants)[polluants == input$polluant]
  })
  
  # Toutes les villes : on copie le polluant choisi dans la colonne « valeur »
  # et on classe chaque journée selon le seuil de vent.
  # .data[[ ]] lit une colonne dont le nom est contenu dans input$polluant.
  mesures <- reactive({
    data %>%
      mutate(valeur = .data[[input$polluant]],
             vent = case_when(wind_kmh <= input$seuil ~ "Vent faible",
                              TRUE                    ~ "Vent fort"))
  })
  
  # La ville choisie seulement
  filtered_data <- reactive({
    mesures() %>% filter(city == input$city)
  })
  
  # Le chiffre clé : il change avec la ville et le polluant
  output$big_number <- renderText({
    paste0("💨 Moyenne : ", round(mean(filtered_data()$valeur), 1))
  })
  
  # Une journée = un point ; la couleur indique le groupe de vent
  output$plot_main <- renderPlot({
    p <- ggplot(filtered_data(), aes(x = wind_kmh, y = valeur)) +
      geom_point(aes(colour = vent), size = 3) +
      # Une ligne verticale placée au seuil choisi avec le curseur
      geom_vline(xintercept = input$seuil, linetype = "dashed") +
      scale_colour_manual(values = couleurs) +
      labs(x = "Vent (km/h)", y = nom_polluant(), colour = "Force du vent",
           title = paste(nom_polluant(), "à", input$city)) +
      theme_minimal(base_size = 15)
    # geom_smooth(method = "lm") ajoute une droite qui résume la tendance
    if (input$tendance) {
      p <- p + geom_smooth(method = "lm", se = FALSE, colour = "grey30")
    }
    p
  })
  
  # nearPoints() trouve la journée la plus proche de l'endroit cliqué
  output$jour_clique <- renderText({
    jour <- nearPoints(filtered_data(), input$clic,
                       xvar = "wind_kmh", yvar = "valeur", maxpoints = 1)
    if (nrow(jour) == 0) {
      "👆 Cliquez sur un point pour voir cette journée."
    } else {
      paste0("📅 ", jour$date, " : vent à ", jour$wind_kmh, " km/h, ",
             nom_polluant(), " à ", jour$valeur, ", trafic à ", jour$traffic_index, ".")
    }
  })
  
  # On calcule les 2 moyennes de la ville, puis on les compare
  output$verdict <- renderText({
    m <- filtered_data() %>% group_by(vent) %>% summarise(moyenne = mean(valeur))
    faible <- m$moyenne[m$vent == "Vent faible"]
    fort <- m$moyenne[m$vent == "Vent fort"]
    paste0(input$city, " : ", round(faible, 1), " par vent faible, ",
           round(fort, 1), " par vent fort (écart de ", round(fort - faible, 1), ").")
  })
  
  output$sentence <- renderText({
    d <- filtered_data()
    paste0(nrow(d), " journées à ", input$city, " ; moyenne de ", nom_polluant(),
           " : ", round(mean(d$valeur), 1), ".")
  })
  
  # geom_col() dessine des barres ; position = "dodge" les place côte à côte
  output$plot_villes <- renderPlot({
    bilan <- mesures() %>%
      group_by(city, vent) %>%
      summarise(moyenne = mean(valeur))
    ggplot(bilan, aes(x = city, y = moyenne, fill = vent)) +
      geom_col(position = "dodge") +
      scale_fill_manual(values = couleurs) +
      labs(x = "Ville", y = nom_polluant(), fill = "Force du vent",
           title = "Le même seuil de vent dans les six villes") +
      theme_minimal(base_size = 15)
  })
  
  # Le vent compte-t-il encore quand on compare des journées de trafic proche ?
  output$plot_trafic <- renderPlot({
    bilan <- filtered_data() %>%
      group_by(trafic, vent) %>%
      summarise(moyenne = mean(valeur))
    ggplot(bilan, aes(x = trafic, y = moyenne, fill = vent)) +
      geom_col(position = "dodge") +
      scale_fill_manual(values = couleurs) +
      labs(x = "Groupe de trafic", y = nom_polluant(), fill = "Force du vent",
           title = paste("Vent et trafic à", input$city)) +
      theme_minimal(base_size = 15)
  })
  
  output$trafic_sentence <- renderText({
    paste0("Le trafic est coupé en deux à sa valeur médiane (", seuil_trafic,
           "). Comparez les deux barres à l'intérieur de chaque groupe.")
  })
  
  # La réponse est calculée sur les six villes, puis comparée au choix
  output$guess_result <- renderText({
    if (!input$show_secret) {
      "Faites votre choix, puis activez « Révéler notre découverte »."
    } else {
      # Une ligne par groupe de vent, une colonne par polluant
      m <- mesures() %>%
        group_by(vent) %>%
        summarise(pm25 = mean(pm25), no2 = mean(no2), o3 = mean(o3))
      faible <- m[m$vent == "Vent faible", ]
      fort <- m[m$vent == "Vent fort", ]
      # La baisse de chaque polluant, en % pour pouvoir les comparer
      baisses <- c(pm25 = (faible$pm25 - fort$pm25) / faible$pm25 * 100,
                   no2  = (faible$no2 - fort$no2) / faible$no2 * 100,
                   o3   = (faible$o3 - fort$o3) / faible$o3 * 100)
      bonne_reponse <- names(baisses)[baisses == min(baisses)]
      resultat <- if (is.null(input$devine)) {
        "Pas de réponse choisie."
      } else if (input$devine == bonne_reponse) {
        "🎉 Bonne réponse !"
      } else {
        "😮 Raté !"
      }
      paste0(resultat, " Baisse par vent fort : PM2.5 ", round(baisses["pm25"]),
             " %, NO2 ", round(baisses["no2"]), " %, O3 ", round(baisses["o3"]), " %.")
    }
  })
  
  # L'onglet « Notre découverte » : gris au départ, coloré une fois activé
  output$plot_secret <- renderPlot({
    p <- ggplot(mesures(), aes(x = wind_kmh, y = valeur))
    if (input$show_secret) {
      p <- p + geom_point(aes(colour = vent), size = 2) +
        scale_colour_manual(values = couleurs) +
        labs(colour = "Force du vent")
    } else {
      p <- p + geom_point(colour = "grey60", size = 2)
    }
    p + labs(x = "Vent (km/h)", y = nom_polluant(), title = "Les six villes réunies") +
      theme_minimal(base_size = 15)
  })
  
  # Les chiffres sont calculés : ils changent avec le polluant et le seuil
  output$secret_sentence <- renderText({
    if (!input$show_secret) {
      "Activez « Révéler notre découverte », puis changez de polluant."
    } else {
      m <- mesures() %>% group_by(vent) %>% summarise(moyenne = mean(valeur))
      paste0(nom_polluant(), " : ",
             round(m$moyenne[m$vent == "Vent faible"], 1), " en moyenne par vent faible, contre ",
             round(m$moyenne[m$vent == "Vent fort"], 1), " par vent fort.")
    }
  })
}

# shinyApp() assemble l'interface et le serveur et lance l'application
shinyApp(ui = ui, server = server)