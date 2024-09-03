# Ścieżka do głównego folderu zawierającego pliki
$folderPath = "."

# Ścieżka do folderu 1
$subfolderPath = Join-Path $folderPath "1"

# Mapowanie fragmentów nazw domen na pełne nazwy domen
$domainMap = @{
    "manager" = "https://managerplus.pl/"
    "handlowe" = "https://www.wiadomoscihandlowe.pl/"
    "wnp" = "https://www.wnp.pl/"
    # Dodaj inne fragmenty domen
}

# Ścieżka do pliku wynikowego
$outputFilePath = "$folderPath\domains.txt"

# Jeśli istnieje plik wynikowy, usuń go
if (Test-Path $outputFilePath) {
    Remove-Item $outputFilePath
}

# Funkcja zmieniająca rozszerzenie plików PNG na JPG
function Convert-PngToJpg {
    param (
        [string]$folder
    )

    Get-ChildItem -Path $folder -Filter "*.png" | ForEach-Object {
        $newFileName = [System.IO.Path]::ChangeExtension($_.FullName, ".jpg")
        Rename-Item -Path $_.FullName -NewName $newFileName
        Write-Output "Zmieniono rozszerzenie: $($_.Name) -> $(Split-Path $newFileName -Leaf)"
    }
}

# Funkcja tworząca archiwum ZIP dla każdego pliku JPG
function zrobZip {
    param (
        [string]$jpgFile,
        [string]$sourceFolder,
        [string]$destinationFolder
    )

    $zipFileName = Join-Path $destinationFolder "$([System.IO.Path]::GetFileNameWithoutExtension($jpgFile)).zip"

    # Tymczasowy katalog do przechowywania plików przed spakowaniem
    $tempFolder = New-Item -ItemType Directory -Path (Join-Path $destinationFolder "temp_$([System.IO.Path]::GetFileNameWithoutExtension($jpgFile))")

    # Kopiowanie pliku JPG do tymczasowego katalogu
    Copy-Item -Path $jpgFile -Destination $tempFolder

    # Kopiowanie plików z folderu 1 do tymczasowego katalogu
    Get-ChildItem -Path $sourceFolder | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $tempFolder
    }

    # Tworzenie archiwum ZIP z zawartości tymczasowego katalogu
    Compress-Archive -Path $tempFolder\* -DestinationPath $zipFileName

    # Usunięcie tymczasowego katalogu
    Remove-Item -Recurse -Force $tempFolder

    Write-Output "Utworzono archiwum: $zipFileName"
}

# Wywołanie funkcji do zmiany rozszerzeń plików PNG na JPG
Convert-PngToJpg -folder $folderPath

# Przetwarzanie plików JPG
Get-ChildItem -Path $folderPath -Filter "*.jpg" | ForEach-Object {
    $fileName = $_.Name
    $fullPath = $_.FullName

    # Szukanie fragmentu domeny w nazwie pliku
    $matchedDomain = $null
    foreach ($fragment in $domainMap.Keys) {
        if ($fileName -like "*$fragment*") {
            $matchedDomain = $domainMap[$fragment]
            break
        }
    }

    # Jeśli znaleziono pasujący fragment, zapisz wynik do pliku
    if ($matchedDomain) {
        $outputLine = "$fileName, $matchedDomain"
        Add-Content -Path $outputFilePath -Value $outputLine
    }
    
    # Tworzenie archiwum ZIP dla pliku JPG
    zrobZip -jpgFile $fullPath -sourceFolder $subfolderPath -destinationFolder $folderPath
}

# Zapobieganie zamknięciu okna PowerShell
Read-Host "Naciśnij Enter, aby zamknąć okno"
