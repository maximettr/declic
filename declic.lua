
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width, height = 600, 600
local clock = os.clock

-- Fonction utilitaire pour trouver yt-dlp dans divers emplacements
local function findYtDlp()
  -- Chemins possibles pour yt-dlp sur macOS
  local possiblePaths = {
    "/opt/homebrew/bin/yt-dlp",      -- Homebrew sur Apple Silicon (M1/M2)
    "/usr/local/bin/yt-dlp",         -- Homebrew sur Intel Mac
    "/usr/bin/yt-dlp",               -- Installation système
    "/usr/local/opt/yt-dlp/bin/yt-dlp", -- Homebrew lien symbolique
    os.getenv("HOME") .. "/.local/bin/yt-dlp", -- Installation utilisateur
  }
  
  -- Vérifier chaque chemin possible
  for _, path in ipairs(possiblePaths) do
    local file = io.open(path, "r")
    if file then
      file:close()
      print("[Info] yt-dlp trouvé à : " .. path)
      return path
    end
  end
  
  -- Si aucun chemin direct ne fonctionne, essayer avec which
  local proc = io.popen("which yt-dlp 2>/dev/null")
  local path = proc:read("*l")
  proc:close()
  
  if path and path ~= '' then
    print("[Info] yt-dlp trouvé via which : " .. path)
    return path
  end
  
  return nil
end

-- Fonction utilitaire pour trouver ffmpeg
local function findFfmpeg()
  local possiblePaths = {
    "/opt/homebrew/bin/ffmpeg",
    "/usr/local/bin/ffmpeg",
    "/usr/bin/ffmpeg",
  }
  
  for _, path in ipairs(possiblePaths) do
    local file = io.open(path, "r")
    if file then
      file:close()
      print("[Info] ffmpeg trouvé à : " .. path)
      return path
    end
  end
  
  local proc = io.popen("which ffmpeg 2>/dev/null")
  local path = proc:read("*l")
  proc:close()
  
  if path and path ~= '' then
    print("[Info] ffmpeg trouvé via which : " .. path)
    return path
  end
  
  return nil
end

-- Initialiser les chemins des programmes
local ytdlProgramPath = findYtDlp()
local ffmpegPath = findFfmpeg()

if not ytdlProgramPath then
  print("[Erreur] yt-dlp n'est pas trouvé. Chemins vérifiés :")
  print("  - /opt/homebrew/bin/yt-dlp (Homebrew Apple Silicon)")
  print("  - /usr/local/bin/yt-dlp (Homebrew Intel)")
  print("  - /usr/bin/yt-dlp (Installation système)")
  print("  - ~/.local/bin/yt-dlp (Installation utilisateur)")
  print("Veuillez vérifier votre installation yt-dlp.")
  return
end

if not ffmpegPath then
  print("[Attention] ffmpeg n'est pas trouvé. La conversion des formats pourrait ne pas fonctionner correctement.")
end

function sleep(n)
  local t0 = clock()
  while clock() - t0 <= n do end
end

win = disp:AddWindow({
  ID = 'MyWin',
  WindowTitle = 'DÉCLIC v0.2 Alpha',
  Geometry = {100, 100, 750, 700},
  Spacing = 10,
  Margin = 25,

  ui:VGroup{
    ID = 'root',
    
    -- Header DÉCLIC simplifié
    ui:VGroup{
      ui:Label{
        Text = '🎬 DÉCLIC - YouTube Video Downloader',
        Weight = 0,
        StyleSheet = 'font-size: 24px; font-weight: bold; color: white; background: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 #DC143C, stop:1 #B22222); padding: 12px 20px; border-radius: 8px; text-align: center; margin-bottom: 5px;'
      },
      ui:HGroup{
        ui:Label{
          Text = 'v0.2 Alpha - Outil Interne',
          Weight = 0,
          StyleSheet = 'color: #AAAAAA; font-size: 12px;'
        },
        ui:Button{
          ID = 'updatecheck',
          Text = '🔄 Vérifier les mises à jour',
          Weight = 0,
          MinimumSize = {160, 20},
          StyleSheet = 'color: #DC143C; font-size: 12px; background: transparent; border: 1px solid #DC143C; border-radius: 3px; padding: 2px 8px;'
        },
      },
      ui:Label{
        Text = 'Téléchargez et importez des extraits vidéo dans DaVinci Resolve',
        Weight = 0,
        StyleSheet = 'color: #AAAAAA; font-size: 12px; text-align: center; margin-bottom: 10px;'
      },
    },

    -- Section URL
    ui:VGroup{
      ui:Label{
        Text = '📎 URL de la vidéo YouTube :',
        Weight = 0,
        StyleSheet = 'font-weight: bold; color: #E5E5E5; margin-top: 15px; margin-bottom: 5px;'
      },
      
      ui:HGroup{
        ui:LineEdit{ 
          ID = "inputurl", 
          PlaceholderText = "Collez l'URL YouTube ici (ex: https://youtube.com/watch?v=...)", 
          Text = "", 
          Weight = 1,
          MinimumSize = {500, 32},
          StyleSheet = 'padding: 8px; border: 2px solid #555; border-radius: 4px; background: #2A2A2A;'
        },
        ui:Button{ 
          ID='analyzeurl', 
          Text='🔍 Analyser',
          Weight = 0,
          MinimumSize = {100, 32},
          StyleSheet = 'padding: 8px 15px; background: #DC143C; color: white; border: none; border-radius: 4px; font-weight: bold;'
        },
      },
    },

    -- Section informations vidéo
    ui:VGroup{
      ui:Label{
        Text = '📺 Informations vidéo :',
        Weight = 0,
        StyleSheet = 'font-weight: bold; color: #E5E5E5; margin-top: 15px; margin-bottom: 5px;'
      },
      
      ui:TextEdit{ 
        ID='videoinfo', 
        Text = 'Aucune vidéo analysée. Collez une URL et cliquez sur "Analyser" pour voir les détails.',
        ReadOnly = true,
        MinimumSize = {600, 120},
        StyleSheet = 'padding: 15px; border: 1px solid #555; border-radius: 4px; background: #1E1E1E; color: #CCCCCC;'
      },
    },

    -- Section choix du dossier de téléchargement
    ui:VGroup{
      ui:Label{
        Text = '📁 Dossier de téléchargement :',
        Weight = 0,
        StyleSheet = 'font-weight: bold; color: #E5E5E5; margin-top: 15px; margin-bottom: 5px;'
      },
      ui:HGroup{
        ui:LineEdit{
          ID = 'downloadpath',
          Text = os.getenv("HOME") .. "/Downloads/DECLIC_Videos",
          ReadOnly = true,
          Weight = 1,
          StyleSheet = 'padding: 5px; border: 1px solid #555; border-radius: 4px; background: #2A2A2A;'
        },
        ui:Button{
          ID = 'browsepath',
          Text = '📂 Parcourir',
          Weight = 0,
          MinimumSize = {100, 28},
          StyleSheet = 'padding: 5px 10px; background: #666; color: white; border: none; border-radius: 4px;'
        },
      },
    },

    -- Section timecode pour extraits
    ui:VGroup{
      ui:Label{
        Text = '⏱️ Sélection d\'extrait (optionnel) :',
        Weight = 0,
        StyleSheet = 'font-weight: bold; color: #E5E5E5; margin-top: 15px; margin-bottom: 5px;'
      },
      ui:HGroup{
        ui:VGroup{
          ui:Label{
            Text = 'Début (HH:MM:SS) :',
            StyleSheet = 'color: #CCCCCC;'
          },
          ui:LineEdit{
            ID = 'starttime',
            PlaceholderText = '00:00:00',
            Text = '',
            MinimumSize = {80, 28},
            StyleSheet = 'padding: 5px; border: 1px solid #555; border-radius: 4px; background: #2A2A2A;'
          },
        },
        ui:VGroup{
          ui:Label{
            Text = 'Fin (HH:MM:SS) :',
            StyleSheet = 'color: #CCCCCC;'
          },
          ui:LineEdit{
            ID = 'endtime',
            PlaceholderText = '00:00:00',
            Text = '',
            MinimumSize = {80, 28},
            StyleSheet = 'padding: 5px; border: 1px solid #555; border-radius: 4px; background: #2A2A2A;'
          },
        },
        ui:VGroup{
          ui:Label{
            Text = ' ',
          },
          ui:CheckBox{
            ID = 'fullvideo',
            Text = 'Vidéo complète',
            Checked = true,
            StyleSheet = 'color: #CCCCCC;'
          },
        },
      },
    },

    -- Section choix de qualité et format
    ui:HGroup{
      ui:VGroup{
        ui:Label{
          Text = '� Type de média :',
          Weight = 0,
          StyleSheet = 'font-weight: bold; color: #E5E5E5; margin-bottom: 5px;'
        },
        ui:ComboBox{
          ID = 'mediatype',
          Weight = 1,
          MinimumSize = {120, 32},
          StyleSheet = 'padding: 5px; border: 1px solid #555; border-radius: 4px; background: #2A2A2A;'
        },
      },
      
      ui:VGroup{
        ui:Label{
          Text = '�🎥 Qualité :',
          Weight = 0,
          StyleSheet = 'font-weight: bold; color: #E5E5E5; margin-bottom: 5px;'
        },
        ui:ComboBox{
          ID = 'qualitycombo',
          Weight = 1,
          MinimumSize = {150, 32},
          StyleSheet = 'padding: 5px; border: 1px solid #555; border-radius: 4px; background: #2A2A2A;'
        },
      },
      
      ui:VGroup{
        ui:Label{
          Text = '📦 Format final :',
          Weight = 0,
          StyleSheet = 'font-weight: bold; color: #E5E5E5; margin-bottom: 5px;'
        },
        ui:ComboBox{
          ID = 'formatcombo',
          Weight = 1,
          MinimumSize = {140, 32},
          StyleSheet = 'padding: 5px; border: 1px solid #555; border-radius: 4px; background: #2A2A2A;'
        },
      },
    },
    
    ui:HGroup{
      ui:Label{
        Text = ' ', -- Espacement
        Weight = 1,
      },
      ui:Button{ 
        ID='download', 
        Text='⬇️ Télécharger & Importer',
        Weight = 0,
        MinimumSize = {200, 40},
        StyleSheet = 'padding: 10px 20px; background: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 #DC143C, stop:1 #B22222); color: white; border: none; border-radius: 6px; font-weight: bold; font-size: 14px;'
      },
      ui:Label{
        Text = ' ', -- Espacement
        Weight = 1,
      },
    },

    -- Barre de statut
    ui:Label{
      ID = 'status',
      Text = 'Prêt - © DÉCLIC ',
      Weight = 0,
      StyleSheet = 'color: #888888; margin-top: 15px; padding: 8px; border-top: 2px solid #DC143C; background: #1A1A1A; border-radius: 4px;'
    },
  },
})

itm = win:GetItems()
resolve = Resolve()
projectManager = resolve:GetProjectManager()
project = projectManager:GetCurrentProject()
mediapool = project:GetMediaPool()
folder = mediapool:GetCurrentFolder()
mediastorage = resolve:GetMediaStorage()
mtdvol = mediastorage:GetMountedVolumes()

-- Variables globales pour stocker les formats disponibles
local availableVideoFormats = {}
local availableAudioFormats = {}
local videoTitle = ""
local videoThumbnail = ""
local channelName = ""
local videoDuration = ""

-- Système de mise à jour
local currentVersion = "0.2"
local updateUrl = "https://api.github.com/repos/your-username/declic-downloader/releases/latest"

-- Fonction pour vérifier les mises à jour
local function checkForUpdates()
  print("[Info] Vérification des mises à jour...")
  
  -- Essai simple avec curl vers un service de test
  local testCmd = "curl -s --connect-timeout 10 \"https://httpbin.org/json\""
  local testProc = io.popen(testCmd)
  local testOutput = testProc:read('*all')
  testProc:close()
  
  print("[Info] Test de connexion: " .. tostring(testOutput))
  
  if testOutput and testOutput ~= "" then
    -- Pour le moment, simulons une mise à jour
    local fakeVersion = "0.3"
    if fakeVersion ~= currentVersion then
      itm.status.Text = "🔄 Simulation: Nouvelle version " .. fakeVersion .. " disponible ! (Version actuelle: " .. currentVersion .. ")"
      print("[Info] Simulation de mise à jour détectée")
      return true
    else
      itm.status.Text = "✅ Vous avez la dernière version (" .. currentVersion .. ")"
      print("[Info] Version à jour")
      return false
    end
  else
    itm.status.Text = "❌ Impossible de vérifier les mises à jour (pas de connexion internet?)"
    print("[Erreur] Pas de connexion pour les mises à jour")
    return false
  end
end

-- Fonction pour convertir HH:MM:SS en secondes
local function timeToSeconds(timeStr)
  if not timeStr or timeStr == "" then return 0 end
  local h, m, s = timeStr:match("(%d+):(%d+):(%d+)")
  if h and m and s then
    return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
  end
  return 0
end

-- Fonction pour récupérer les métadonnées de la vidéo
local function getVideoMetadata(url)
  -- Essayer d'abord avec --print pour obtenir les métadonnées de manière plus fiable
  local metadataCmd = ytdlProgramPath .. " --print \"%(title)s\" --print \"%(thumbnail)s\" --print \"%(uploader)s\" --print \"%(duration_string)s\" --no-warnings --skip-download \"" .. url .. "\""
  local proc = io.popen(metadataCmd)
  local output = proc:read('*all')
  local exitCode = proc:close()
  
  print("Commande métadonnées: " .. metadataCmd)
  print("Sortie métadonnées: " .. tostring(output))
  
  if output and output ~= "" then
    local lines = {}
    for line in output:gmatch("[^\r\n]+") do
      if line and line ~= "" and line ~= "NA" then
        table.insert(lines, line)
      end
    end
    
    if #lines >= 1 then
      local title = lines[1] or "Titre indisponible"
      local thumbnail = lines[2] or ""
      local uploader = lines[3] or "Chaîne inconnue"
      local duration = lines[4] or ""
      return title, thumbnail, uploader, duration
    end
  end
  
  -- Méthode de fallback avec les anciennes options
  print("Essai avec méthode de fallback...")
  local fallbackCmd = ytdlProgramPath .. " --get-title --no-warnings --skip-download \"" .. url .. "\""
  local fallbackProc = io.popen(fallbackCmd)
  local fallbackOutput = fallbackProc:read('*all')
  fallbackProc:close()
  
  if fallbackOutput and fallbackOutput ~= "" then
    local title = fallbackOutput:gsub("\n", ""):gsub("\r", "")
    if title and title ~= "" then
      print("Titre récupéré avec fallback: " .. title)
      return title, "", "Chaîne inconnue", ""
    end
  end
  
  -- Dernière tentative - juste vérifier si l'URL est valide
  print("Dernière tentative - vérification URL...")
  local testCmd = ytdlProgramPath .. " --simulate --quiet \"" .. url .. "\""
  local testResult = os.execute(testCmd)
  
  if testResult == 0 then
    return "Vidéo YouTube valide", "", "Chaîne inconnue", ""
  end
  
  return nil, nil, nil, nil
end

-- Fonction pour télécharger la miniature
local function downloadThumbnail(thumbnailUrl, downloadPath)
  if not thumbnailUrl or thumbnailUrl == "" then return nil end
  
  local thumbnailFile = downloadPath .. "/thumbnail.jpg"
  local curlCmd = "curl -s -o \"" .. thumbnailFile .. "\" \"" .. thumbnailUrl .. "\""
  
  print("Téléchargement miniature: " .. curlCmd)
  local result = os.execute(curlCmd)
  
  if result == 0 then
    local file = io.open(thumbnailFile, "r")
    if file then
      file:close()
      return thumbnailFile
    end
  end
  
  return nil
end

-- Fonction pour parser et organiser les formats yt-dlp
local function parseFormats(rawOutput)
  local videoFormats = {}
  local audioFormats = {}
  
  -- Parser chaque ligne de format
  for line in rawOutput:gmatch("[^\r\n]+") do
    local formatId, ext, resolution, note = line:match("^(%S+)%s+(%S+)%s+(%S*)%s*(.*)")
    if formatId and ext and formatId ~= "ID" then
      local quality = "Inconnue"
      local fps = ""
      local isAudio = false
      
      -- Détecter si c'est un format audio
      if resolution and (resolution:match("audio") or ext:match("^m4a$") or ext:match("^mp3$") or ext:match("^aac$") or ext:match("^opus$") or ext:match("^wav$")) then
        isAudio = true
        -- Extraire le bitrate audio si disponible
        local bitrate = note and note:match("(%d+)k") or "Inconnue"
        quality = bitrate .. "k"
      else
        -- Extraire la résolution vidéo
        if resolution and resolution ~= "" then
          if resolution:match("%d+x%d+") then
            local height = resolution:match("x(%d+)")
            if height then
              quality = height .. "p"
            end
          end
        end
        
        -- Extraire les FPS si disponible
        if note and note:match("(%d+)fps") then
          fps = " @" .. note:match("(%d+)fps") .. "fps"
        end
      end
      
      local formatInfo = {
        id = formatId,
        ext = ext:upper(),
        quality = quality,
        fps = fps,
        fullDesc = quality .. fps .. " (" .. ext:upper() .. " - Natif)",
        raw = line,
        isNative = true
      }
      
      if isAudio then
        table.insert(audioFormats, formatInfo)
      elseif ext == "mp4" or ext == "webm" or ext == "mkv" or ext == "mov" then
        table.insert(videoFormats, formatInfo)
      end
    end
  end
  
  return videoFormats, audioFormats
end

-- Fonction pour mettre à jour la ComboBox des qualités
local function updateQualityCombo()
  local mediaType = itm.mediatype.CurrentText
  local currentFormats = mediaType == "Audio seulement" and availableAudioFormats or availableVideoFormats
  
  local qualities = {}
  -- Extraire les qualités uniques
  for _, format in ipairs(currentFormats) do
    if not qualities[format.quality] then
      table.insert(qualities, format.quality)
      qualities[format.quality] = true
    end
  end
  
  -- Trier les qualités par ordre décroissant
  table.sort(qualities, function(a, b)
    local numA = tonumber(a:match("(%d+)"))
    local numB = tonumber(b:match("(%d+)"))
    if numA and numB then
      return numA > numB
    end
    return a > b
  end)
  
  -- Remplir la ComboBox des qualités
  itm.qualitycombo:Clear()
  itm.qualitycombo:AddItem("Meilleure qualité disponible")
  for _, quality in ipairs(qualities) do
    itm.qualitycombo:AddItem(quality)
  end
  itm.qualitycombo.CurrentIndex = 0
  
  -- Mettre à jour les formats
  updateFormatCombo()
end

-- Fonction pour mettre à jour la ComboBox des formats
local function updateFormatCombo()
  local mediaType = itm.mediatype.CurrentText
  local selectedQuality = itm.qualitycombo.CurrentText
  local currentFormats = mediaType == "Audio seulement" and availableAudioFormats or availableVideoFormats
  
  itm.formatcombo:Clear()
  
  if selectedQuality == "Meilleure qualité disponible" then
    -- Afficher tous les formats disponibles groupés par extension
    local formatsByExt = {}
    for _, format in ipairs(currentFormats) do
      if not formatsByExt[format.ext] then
        formatsByExt[format.ext] = {}
      end
      table.insert(formatsByExt[format.ext], format)
    end
    
    -- Ajouter les formats natifs par extension
    for ext, formats in pairs(formatsByExt) do
      if #formats > 0 then
        itm.formatcombo:AddItem(ext .. " (Natif)")
      end
    end
    
    -- Ajouter les options de conversion si ffmpeg disponible
    if ffmpegPath then
      if mediaType ~= "Audio seulement" then
        itm.formatcombo:AddItem("MP4 H.264 (Converti)")
        itm.formatcombo:AddItem("MOV ProRes (Converti)")
        itm.formatcombo:AddItem("MP4 H.265 (Converti)")
      else
        itm.formatcombo:AddItem("MP3 (Converti)")
        itm.formatcombo:AddItem("AAC (Converti)")
        itm.formatcombo:AddItem("WAV (Converti)")
      end
    end
  else
    -- Afficher les formats spécifiques pour cette qualité
    for _, format in ipairs(currentFormats) do
      if format.quality == selectedQuality then
        itm.formatcombo:AddItem(format.fullDesc)
      end
    end
    
    -- Ajouter les options de conversion
    if ffmpegPath then
      if mediaType ~= "Audio seulement" then
        itm.formatcombo:AddItem("MP4 H.264 (Converti)")
        itm.formatcombo:AddItem("MOV ProRes (Converti)")
        itm.formatcombo:AddItem("MP4 H.265 (Converti)")
      else
        itm.formatcombo:AddItem("MP3 (Converti)")
        itm.formatcombo:AddItem("AAC (Converti)")
        itm.formatcombo:AddItem("WAV (Converti)")
      end
    end
  end
  
  if itm.formatcombo.ItemCount > 0 then
    itm.formatcombo.CurrentIndex = 0
  end
end

-- Fonction pour remplir les ComboBox avec les formats
local function populateComboBoxes(videoFormats, audioFormats)
  -- Remplir le type de média
  itm.mediatype:Clear()
  itm.mediatype:AddItem("Vidéo + Audio")
  itm.mediatype:AddItem("Audio seulement")
  if #videoFormats > 0 and #audioFormats > 0 then
    itm.mediatype:AddItem("Vidéo sans son")
  end
  itm.mediatype.CurrentIndex = 0
  
  -- Mettre à jour les qualités et formats
  updateQualityCombo()
end

-- Fonction pour valider le format de timecode
local function validateTimecode(timecode)
  if timecode == "" then return true end
  return timecode:match("^%d+:%d%d:%d%d$") ~= nil
end

function win.On.MyWin.Close(ev)
  disp:ExitLoop()
end

function win.On.mediatype.CurrentIndexChanged(ev)
  -- Mettre à jour les qualités selon le type de média sélectionné
  if #availableVideoFormats > 0 or #availableAudioFormats > 0 then
    updateQualityCombo()
  end
end

function win.On.qualitycombo.CurrentIndexChanged(ev)
  -- Mettre à jour les formats disponibles selon la qualité sélectionnée
  if #availableVideoFormats > 0 or #availableAudioFormats > 0 then
    updateFormatCombo()
  end
end

function win.On.updatecheck.Clicked(ev)
  itm.status.Text = "🔍 Vérification des mises à jour..."
  checkForUpdates()
end

function win.On.browsepath.Clicked(ev)
  local selectedPath = fu:RequestDir()
  if selectedPath then
    itm.downloadpath.Text = selectedPath
  end
end

function win.On.fullvideo.Clicked(ev)
  if itm.fullvideo.Checked then
    itm.starttime.Text = ""
    itm.endtime.Text = ""
  end
end

function win.On.analyzeurl.Clicked(ev)
  local url = tostring(itm.inputurl.Text)
  
  if url == "" then
    itm.status.Text = "❌ Veuillez entrer une URL YouTube"
    return
  end
  
  itm.status.Text = "🔍 Analyse des métadonnées en cours..."
  itm.videoinfo.PlainText = "Récupération des informations de la vidéo..."
  
  -- Créer le dossier temporaire pour la miniature
  local downloadPath = tostring(itm.downloadpath.Text)
  os.execute("mkdir -p \"" .. downloadPath .. "\"")
  
  -- Récupérer les métadonnées
  local title, thumbnail, uploader, duration = getVideoMetadata(url)
  
  if title then
    videoTitle = title
    videoThumbnail = thumbnail
    channelName = uploader
    videoDuration = duration
    
    local infoText = "✅ Vidéo trouvée !\n\n"
    infoText = infoText .. "🎬 Titre: " .. title .. "\n"
    infoText = infoText .. "📺 Chaîne: " .. uploader .. "\n"
    if duration and duration ~= "" then
      infoText = infoText .. "⏱️ Durée: " .. duration .. "\n"
    end
    infoText = infoText .. "\n🔄 Analyse des formats disponibles..."
    
    itm.videoinfo.PlainText = infoText
    itm.status.Text = "🔍 Analyse des formats en cours..."
  else
    itm.videoinfo.PlainText = '❌ Erreur: Impossible de récupérer les métadonnées.\n\nVérifiez que l\'URL est correcte et accessible.'
    itm.status.Text = "❌ Erreur lors de la récupération des métadonnées"
    return
  end

  -- Analyser les formats disponibles
  local ytformatcmd = ytdlProgramPath .. " -F \"" .. url .. "\""
  local formatproc = io.popen(ytformatcmd)
  local foutput = formatproc:read('*all')
  formatproc:close()

  if not foutput or foutput == '' then
    itm.videoinfo.PlainText = itm.videoinfo.PlainText .. '\n\n❌ Erreur lors de l\'analyse des formats.'
    itm.status.Text = "❌ Erreur lors de l'analyse des formats"
  else
    -- Parser les formats
    availableVideoFormats, availableAudioFormats = parseFormats(foutput)
    
    if #availableVideoFormats > 0 or #availableAudioFormats > 0 then
      populateComboBoxes(availableVideoFormats, availableAudioFormats)
      
      local finalText = "✅ Analyse terminée !\n\n"
      finalText = finalText .. "🎬 Titre: " .. title .. "\n"
      finalText = finalText .. "📺 Chaîne: " .. uploader .. "\n"
      if duration and duration ~= "" then
        finalText = finalText .. "⏱️ Durée: " .. duration .. "\n"
      end
      finalText = finalText .. "📊 " .. #availableVideoFormats .. " formats vidéo, " .. #availableAudioFormats .. " formats audio\n"
      finalText = finalText .. "\n💡 Configurez vos options et cliquez sur 'Télécharger'"
      
      itm.videoinfo.PlainText = finalText
      itm.status.Text = "✅ Prêt pour le téléchargement - " .. (#availableVideoFormats + #availableAudioFormats) .. " formats trouvés"
    else
      itm.videoinfo.PlainText = itm.videoinfo.PlainText .. '\n\n⚠️ Aucun format compatible trouvé.'
      itm.status.Text = "⚠️ Aucun format compatible trouvé"
    end
  end
end

function win.On.download.Clicked(ev)
  local url = tostring(itm.inputurl.Text)
  
  if url == "" then
    itm.status.Text = "❌ Veuillez entrer une URL et l'analyser d'abord"
    return
  end
  
  if #availableVideoFormats == 0 and #availableAudioFormats == 0 then
    itm.status.Text = "❌ Veuillez d'abord analyser la vidéo"
    return
  end
  
  -- Vérifier les timecodes si l'extrait est activé
  local startTime = tostring(itm.starttime.Text)
  local endTime = tostring(itm.endtime.Text)
  local isFullVideo = itm.fullvideo.Checked
  local mediaType = itm.mediatype.CurrentText
  
  if not isFullVideo then
    if not validateTimecode(startTime) or not validateTimecode(endTime) then
      itm.status.Text = "❌ Format de timecode invalide (utilisez HH:MM:SS)"
      return
    end
    if startTime == "" or endTime == "" then
      itm.status.Text = "❌ Veuillez spécifier le début ET la fin pour un extrait"
      return
    end
  end
  
  local selectedQuality = itm.qualitycombo.CurrentText
  local selectedFormat = itm.formatcombo.CurrentText
  local downloadPath = tostring(itm.downloadpath.Text)
  
  -- Créer le dossier de téléchargement
  os.execute("mkdir -p \"" .. downloadPath .. "\"")
  
  -- Déterminer le format selon le type de média
  local formatFlag = ""
  local currentFormats = mediaType == "Audio seulement" and availableAudioFormats or availableVideoFormats
  
  if selectedQuality == "Meilleure qualité disponible" then
    if mediaType == "Audio seulement" then
      formatFlag = " -f 'bestaudio'"
    elseif mediaType == "Vidéo sans son" then
      formatFlag = " -f 'bestvideo'"
    else
      formatFlag = " -f 'best[ext=mp4]/best'"
    end
  else
    local bestFormat = nil
    for _, format in ipairs(currentFormats) do
      if format.quality == selectedQuality then
        bestFormat = format
        break
      end
    end
    
    if bestFormat then
      formatFlag = " -f " .. bestFormat.id
    else
      if mediaType == "Audio seulement" then
        formatFlag = " -f 'bestaudio'"
      else
        formatFlag = " -f 'best[height<=" .. selectedQuality:gsub("p", "") .. "]/best'"
      end
    end
  end

  itm.status.Text = "⬇️ Téléchargement en cours..."
  
  -- Nom de fichier avec timestamp pour éviter les conflits
  local timestamp = os.date("%Y%m%d_%H%M%S")
  local safeTitle = videoTitle:gsub("[^%w%s%-_]", ""):gsub("%s+", "_")
  local tempFile = downloadPath .. "/" .. safeTitle .. "_" .. timestamp .. "_temp"
  local finalFile = downloadPath .. "/" .. safeTitle .. "_" .. timestamp
  
  -- Ajouter suffixe d'extrait si nécessaire
  if not isFullVideo then
    finalFile = finalFile .. "_extrait_" .. startTime:gsub(":", "-") .. "_" .. endTime:gsub(":", "-")
  end
  
  -- Commande yt-dlp avec options d'extrait si nécessaire
  local ytdlcomm = ytdlProgramPath .. formatFlag .. " \"" .. url .. "\" -o \"" .. tempFile .. ".%(ext)s\""
  
  if not isFullVideo then
    local startSeconds = timeToSeconds(startTime)
    local endSeconds = timeToSeconds(endTime)
    
    if startSeconds >= endSeconds then
      itm.status.Text = "❌ Le temps de début doit être inférieur au temps de fin"
      return
    end
    
    ytdlcomm = ytdlcomm .. " --download-sections \"*" .. startSeconds .. "-" .. endSeconds .. "\""
    print("Extrait: " .. startTime .. " (" .. startSeconds .. "s) à " .. endTime .. " (" .. endSeconds .. "s)")
  end
  
  print("Commande yt-dlp: " .. ytdlcomm)
  local result = os.execute(ytdlcomm)
  
  print("Code de retour yt-dlp: " .. tostring(result))
  
  -- Initialiser downloadedFile
  local downloadedFile = nil
  
  -- Sur macOS, os.execute retourne true/false au lieu de codes numériques
  if result == false or result == nil then
    -- Essayer une méthode alternative pour les extraits si la première échoue
    if not isFullVideo then
      itm.status.Text = "🔄 Essai méthode alternative pour l'extrait..."
      print("Tentative avec méthode alternative...")
      
      -- Télécharger d'abord la vidéo complète puis découper avec ffmpeg
      local fullVideoCmd = ytdlProgramPath .. formatFlag .. " \"" .. url .. "\" -o \"" .. tempFile .. "_full.%(ext)s\""
      print("Téléchargement complet: " .. fullVideoCmd)
      
      local fullResult = os.execute(fullVideoCmd)
      if fullResult == false or fullResult == nil then
        itm.status.Text = "❌ Erreur lors du téléchargement de la vidéo"
        return
      end
      
      -- Trouver le fichier téléchargé complet
      local fullVideoFile = nil
      local extensions = {"mp4", "webm", "mkv", "mov", "flv"}
      for _, ext in ipairs(extensions) do
        local testFile = tempFile .. "_full." .. ext
        local file = io.open(testFile, "r")
        if file then
          file:close()
          fullVideoFile = testFile
          break
        end
      end
      
      if not fullVideoFile then
        itm.status.Text = "❌ Fichier vidéo complet non trouvé"
        return
      end
      
      -- Découper avec ffmpeg si disponible
      if ffmpegPath then
        itm.status.Text = "✂️ Découpage de l'extrait avec ffmpeg..."
        local outputExt = fullVideoFile:match("%.([^%.]+)$")
        local extractFile = tempFile .. "." .. outputExt
        
        -- Utiliser des options ffmpeg plus robustes
        local ffmpegExtractCmd = ffmpegPath .. " -i \"" .. fullVideoFile .. "\" -ss " .. startTime .. " -to " .. endTime .. " -c copy -avoid_negative_ts make_zero \"" .. extractFile .. "\" -y"
        print("Découpage ffmpeg: " .. ffmpegExtractCmd)
        
        local extractResult = os.execute(ffmpegExtractCmd)
        
        print("Code de retour ffmpeg: " .. tostring(extractResult))
        
        -- Supprimer le fichier complet
        os.execute("rm \"" .. fullVideoFile .. "\"")
        
        if extractResult == false or extractResult == nil then
          itm.status.Text = "❌ Erreur lors du découpage"
          return
        end
        
        -- Vérifier que le fichier d'extrait existe
        local file = io.open(extractFile, "r")
        if file then
          file:close()
          downloadedFile = extractFile
          print("Extrait créé avec succès: " .. extractFile)
        else
          itm.status.Text = "❌ Fichier d'extrait non créé"
          return
        end
      else
        itm.status.Text = "❌ ffmpeg requis pour le découpage d'extrait"
        os.execute("rm \"" .. fullVideoFile .. "\"")
        return
      end
    else
      itm.status.Text = "❌ Erreur lors du téléchargement (code: " .. tostring(result) .. ")"
      return
    end
  else
    -- Trouver le fichier téléchargé normalement
    local extensions = {"mp4", "webm", "mkv", "mov", "flv"}
    for _, ext in ipairs(extensions) do
      local testFile = tempFile .. "." .. ext
      local file = io.open(testFile, "r")
      if file then
        file:close()
        downloadedFile = testFile
        break
      end
    end
  end
  
  if not downloadedFile then
    itm.status.Text = "❌ Fichier téléchargé non trouvé"
    return
  end
  
  -- Conversion avec ffmpeg si nécessaire
  local finalExtension = "mp4"
  local ffmpegOptions = ""
  
  if selectedFormat:match("MP4 %(H%.264") then
    finalExtension = "mp4"
    ffmpegOptions = "-c:v libx264 -c:a aac -preset medium -crf 23"
  elseif selectedFormat:match("MOV %(ProRes") then
    finalExtension = "mov"
    ffmpegOptions = "-c:v prores_ks -profile:v 2 -c:a pcm_s16le"
  elseif selectedFormat:match("MP4 %(H%.265") then
    finalExtension = "mp4"
    ffmpegOptions = "-c:v libx265 -c:a aac -preset medium -crf 28"
  else
    -- Format original - pas de conversion
    finalFile = finalFile .. "." .. downloadedFile:match("%.([^%.]+)$")
    os.execute("mv \"" .. downloadedFile .. "\" \"" .. finalFile .. "\"")
    mediastorage:AddItemListToMediaPool(finalFile)
    itm.status.Text = "✅ Téléchargement terminé et importé: " .. finalFile:match("([^/]+)$")
    return
  end
  
  -- Conversion avec ffmpeg
  if ffmpegPath then
    itm.status.Text = "🔄 Conversion en cours (" .. selectedFormat .. ")..."
    finalFile = finalFile .. "." .. finalExtension
    
    local ffmpegCmd = ffmpegPath .. " -i \"" .. downloadedFile .. "\" " .. ffmpegOptions .. " \"" .. finalFile .. "\" -y"
    print("Commande ffmpeg: " .. ffmpegCmd)
    
    local ffmpegResult = os.execute(ffmpegCmd)
    print("Code de retour ffmpeg conversion: " .. tostring(ffmpegResult))
    
    -- Supprimer le fichier temporaire
    os.execute("rm \"" .. downloadedFile .. "\"")
    
    if ffmpegResult == false or ffmpegResult == nil then
      itm.status.Text = "❌ Erreur lors de la conversion"
      return
    end
    
    -- Vérifier que le fichier final existe
    local file = io.open(finalFile, "r")
    if not file then
      itm.status.Text = "❌ Fichier final non créé après conversion"
      return
    end
    file:close()
  else
    -- Pas de ffmpeg disponible, utiliser le fichier original
    finalFile = finalFile .. "." .. downloadedFile:match("%.([^%.]+)$")
    os.execute("mv \"" .. downloadedFile .. "\" \"" .. finalFile .. "\"")
  end

  -- Importer dans DaVinci Resolve
  mediastorage:AddItemListToMediaPool(finalFile)
  
  local fileName = finalFile:match("([^/]+)$")
  if not isFullVideo then
    itm.status.Text = "✅ Extrait téléchargé et importé: " .. fileName
  else
    itm.status.Text = "✅ Vidéo téléchargée et importée: " .. fileName
  end
end

win:Show()
disp:RunLoop()
win:Hide()
