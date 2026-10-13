function spotify --wraps='flatpak run com.spotify.Client' --description 'alias spotify=flatpak run com.spotify.Client'
    flatpak run com.spotify.Client $argv
end
