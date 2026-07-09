# =================================================================================
#        AUTOMATED GCP INFRASTRUCTURE SETUP SCRIPT (ENGLISH LOGS)
# =================================================================================
# Project: EV Co-ownership Cost Sharing System
# Support: Automates VPC, Private SQL, Secret Manager, Service Account Setup
# =================================================================================

$PROJECT_ID = "ev-cost-sharing-496416"
$REGION = "asia-southeast1"
$DB_INSTANCE = "ev-database"
$DB_PASSWORD = "AnhNguyen1511@"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " STARTING GCP INFRASTRUCTURE SETUP" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Project ID: $PROJECT_ID"
Write-Host "Region    : $REGION"
Write-Host "Database  : $DB_INSTANCE"

# 1. Ensure correct Project
Write-Host "`n[1/8] Setting Google Cloud Project..." -ForegroundColor Yellow
gcloud config set project $PROJECT_ID --quiet

# 2. Wait for Database to be RUNNABLE
Write-Host "`n[2/8] Checking status of database '$DB_INSTANCE'..." -ForegroundColor Yellow
while ($true) {
    $state = gcloud sql instances describe $DB_INSTANCE --format="value(state)"
    if ($state -eq "RUNNABLE") {
        Write-Host "Database instance is ready ($state)." -ForegroundColor Green
        break
    }
    Write-Host "Current state: $state. Waiting for database to start (15s)..."
    Start-Sleep -Seconds 15
}

# 3. Patch Database to Private IP
Write-Host "`n[3/8] Patching Database to Private IP..." -ForegroundColor Yellow
$vpcPath = "projects/$PROJECT_ID/global/networks/ev-sharing-vpc"
gcloud sql instances patch $DB_INSTANCE --network=$vpcPath --no-assign-ip --quiet

# Get Private IP
$DB_PRIVATE_IP = gcloud sql instances describe $DB_INSTANCE --format="value(ipAddresses.filter(type:PRIVATE).ipAddress)"
if (-not $DB_PRIVATE_IP) {
    $DB_PRIVATE_IP = gcloud sql instances describe $DB_INSTANCE --format="value(ipAddresses[0].ipAddress)"
}
Write-Host "Database Private IP Address: $DB_PRIVATE_IP" -ForegroundColor Green

# 4. Create Serverless VPC Access Connector
Write-Host "`n[4/8] Checking and creating Serverless VPC Connector..." -ForegroundColor Yellow
$connExists = gcloud compute networks vpc-access connectors list --region=$REGION --filter="name:ev-vpc-connector" --format="value(name)"
if (-not $connExists) {
    Write-Host "Creating connector 'ev-vpc-connector' (this takes 2-3 minutes)..." -ForegroundColor Yellow
    gcloud compute networks vpc-access connectors create ev-vpc-connector `
        --region=$REGION `
        --network=ev-sharing-vpc `
        --range=10.8.0.0/28 `
        --min-instances=2 `
        --max-instances=10 `
        --machine-type=f1-micro `
        --quiet
    Write-Host "Connector created successfully!" -ForegroundColor Green
} else {
    Write-Host "Connector 'ev-vpc-connector' already exists." -ForegroundColor Green
}

# 5. Setup Secret Manager
Write-Host "`n[5/8] Configuring database credentials in Secret Manager..." -ForegroundColor Yellow
$secretExists = gcloud secrets list --filter="name:ev-db-password" --format="value(name)"
if (-not $secretExists) {
    Write-Host "Creating secret 'ev-db-password'..."
    gcloud secrets create ev-db-password --replication-policy="automatic" --quiet
}
Write-Host "Adding password version..."
echo -n "$DB_PASSWORD" | gcloud secrets versions add ev-db-password --data-file=- --quiet

# Grant access to Cloud Run default service account
$projectNum = gcloud projects describe $PROJECT_ID --format="value(projectNumber)"
$runSa = "$projectNum-compute@developer.gserviceaccount.com"
Write-Host "Granting Secret Accessor role to Cloud Run Service Account ($runSa)..."
gcloud secrets add-iam-policy-binding ev-db-password --member="serviceAccount:$runSa" --role="roles/secretmanager.secretAccessor" --quiet | Out-Null
Write-Host "Secret Manager configured successfully!" -ForegroundColor Green

# 6. Create Google Artifact Registry
Write-Host "`n[6/8] Checking and creating Artifact Registry Docker Repository..." -ForegroundColor Yellow
$repoExists = gcloud artifacts repositories list --location=$REGION --filter="name:ev-sharing-repo" --format="value(name)"
if (-not $repoExists) {
    Write-Host "Creating repository 'ev-sharing-repo'..."
    gcloud artifacts repositories create ev-sharing-repo `
        --repository-format=docker `
        --location=$REGION `
        --description="Docker repository for EV Co-ownership" `
        --quiet
    Write-Host "Repository created successfully!" -ForegroundColor Green
} else {
    Write-Host "Repository 'ev-sharing-repo' already exists." -ForegroundColor Green
}

# 7. Setup Service Account for CI/CD
Write-Host "`n[7/8] Setting up Service Account 'github-cicd-sa'..." -ForegroundColor Yellow
$saEmail = "github-cicd-sa@$PROJECT_ID.iam.gserviceaccount.com"
$saExists = gcloud iam service-accounts list --filter="email:$saEmail" --format="value(email)"
if (-not $saExists) {
    gcloud iam service-accounts create github-cicd-sa --display-name="GitHub CI/CD Service Account" --quiet
}

# Bind roles
Write-Host "Binding roles to Service Account..."
$roles = @(
    "roles/artifactregistry.writer",
    "roles/run.developer",
    "roles/iam.serviceAccountUser",
    "roles/secretmanager.secretAccessor"
)
foreach ($role in $roles) {
    gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$saEmail" --role="$role" --quiet | Out-Null
}

# Generate JSON Key
Write-Host "Generating JSON Key for GitHub..." -ForegroundColor Yellow
if (Test-Path "github-sa-key.json") {
    Remove-Item "github-sa-key.json" -Force
}
gcloud iam service-accounts keys create github-sa-key.json --iam-account=$saEmail --quiet
Write-Host "JSON Key exported to: github-sa-key.json" -ForegroundColor Green

# 8. Results and Instructions
Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host " GCP INFRASTRUCTURE SETUP COMPLETED!" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "VPC Network, Private SQL, Secret Manager, and Registry are ready."
Write-Host "`nSTEPS TO CONFIGURE GITHUB SECRETS:" -ForegroundColor Yellow
Write-Host "Go to Settings -> Secrets and variables -> Actions on GitHub and add:"
Write-Host "1. GCP_PROJECT_ID   : $PROJECT_ID" -ForegroundColor Cyan
Write-Host "2. GCP_DB_PRIVATE_IP : $DB_PRIVATE_IP" -ForegroundColor Cyan
Write-Host "3. GCP_SA_KEY        : (Copy contents of 'github-sa-key.json' created in the project root)" -ForegroundColor Cyan
Write-Host "================================================================="
