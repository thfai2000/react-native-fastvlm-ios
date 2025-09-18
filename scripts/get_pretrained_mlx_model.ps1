# PowerShell script for downloading FastVLM models
# For licensing see accompanying LICENSE_MODEL file.
# Copyright (C) 2025 Apple Inc. All Rights Reserved.

param(
    [Parameter(Mandatory=$true)]
    [string]$Model,
    
    [Parameter(Mandatory=$true)]
    [string]$Dest,
    
    [switch]$Help
)

# Help function
function Show-Help {
    Write-Host "Usage: .\get_pretrained_mlx_model.ps1 -Model <model_size> -Dest <destination_directory>"
    Write-Host ""
    Write-Host "Required parameters:"
    Write-Host "  -Model <model_size>    Size of the model to download"
    Write-Host "  -Dest <directory>      Directory where the model will be downloaded"
    Write-Host ""
    Write-Host "Available model sizes:"
    Write-Host "  0.5b  - 0.5B parameter model (FP16)"
    Write-Host "  1.5b  - 1.5B parameter model (INT8)"
    Write-Host "  7b    - 7B parameter model (INT4)"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Help    Show help message"
}

# Show help if requested
if ($Help) {
    Show-Help
    exit 0
}

# Validate required parameters
if (-not $Model) {
    Write-Host "Error: -Model parameter is required" -ForegroundColor Red
    Write-Host ""
    Show-Help
    exit 1
}

if (-not $Dest) {
    Write-Host "Error: -Dest parameter is required" -ForegroundColor Red
    Write-Host ""
    Show-Help
    exit 1
}

# Map model size to full model name
$modelMap = @{
    "0.5b" = "llava-fastvithd_0.5b_stage3_llm.fp16"
    "1.5b" = "llava-fastvithd_1.5b_stage3_llm.int8"
    "7b"   = "llava-fastvithd_7b_stage3_llm.int4"
}

if (-not $modelMap.ContainsKey($Model)) {
    Write-Host "Error: Invalid model size '$Model'" -ForegroundColor Red
    Write-Host ""
    Show-Help
    exit 1
}

$modelName = $modelMap[$Model]
$baseUrl = "https://ml-site.cdn-apple.com/datasets/fastvlm"

# Create temp directory
$tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }

function Cleanup {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}

# Register cleanup on exit
trap { Cleanup }

function Download-Model {
    # Create destination directory if it doesn't exist
    if (-not (Test-Path $Dest)) {
        Write-Host "Creating destination directory: $Dest"
        New-Item -ItemType Directory -Path $Dest -Force | Out-Null
    } elseif ((Get-ChildItem $Dest | Measure-Object).Count -gt 0) {
        Write-Host "Destination directory '$Dest' exists and is not empty."
        $confirm = Read-Host "Do you want to clear it and continue? [y/N]"
        if ($confirm -notmatch "^[Yy]$") {
            Write-Host "Stopping."
            exit 1
        }
        Write-Host "Clearing existing contents in '$Dest'"
        Remove-Item -Path "$Dest\*" -Recurse -Force
    }

    # File paths
    $zipFile = Join-Path $tempDir "$modelName.zip"
    $extractDir = Join-Path $tempDir $modelName
    $downloadUrl = "$baseUrl/$modelName.zip"

    # Create extract directory
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

    try {
        # Download model
        Write-Host ""
        Write-Host "Downloading '$modelName' model..."
        Write-Host ""
        
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $zipFile)
        
        # Unzip model
        Write-Host ""
        Write-Host "Extracting model..."
        Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force

        # Copy model files to destination directory
        Write-Host ""
        Write-Host "Copying model files to destination directory..."
        $sourceDir = Join-Path $extractDir $modelName
        
        if (Test-Path $sourceDir) {
            Copy-Item -Path "$sourceDir\*" -Destination $Dest -Recurse -Force
        } else {
            Write-Host "Error: Source directory '$sourceDir' not found after extraction" -ForegroundColor Red
            exit 1
        }

        # Verify destination directory exists and is not empty
        if (-not (Test-Path $Dest) -or (Get-ChildItem $Dest | Measure-Object).Count -eq 0) {
            Write-Host ""
            Write-Host "Model extraction failed. Destination directory '$Dest' is missing or empty." -ForegroundColor Red
            exit 1
        }

        Write-Host ""
        Write-Host "Model downloaded and extracted to '$Dest'"
        
    } catch {
        Write-Host ""
        Write-Host "Error downloading model: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    } finally {
        if ($webClient) {
            $webClient.Dispose()
        }
    }
}

# Download the model
Download-Model

# Cleanup will be called automatically via trap