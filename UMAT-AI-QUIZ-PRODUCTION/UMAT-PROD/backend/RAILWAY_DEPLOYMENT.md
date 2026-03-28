# Railway Deployment Guide

This guide explains how to deploy the UMAT AI Quiz backend and PostgreSQL database on Railway.

## Prerequisites

- Railway account (https://railway.app)
- GitHub repository pushed with the latest changes

## Steps

### 1. Create Railway Project

1. Go to https://railway.app and sign in
2. Click "New Project"
3. Choose "Deploy from GitHub repo"
4. Select your repository: `frederickleroy63-ops/UMAT-AI-QUIZ-PRODUCTION`
5. Choose the branch (main)

### 2. Add PostgreSQL Database

1. In your Railway project dashboard, click "Add Service"
2. Choose "Database" > "PostgreSQL"
3. The database will be created automatically
4. Note the database service name (e.g., `postgresql`)

### 3. Deploy Backend Service

1. The backend should deploy automatically from the `UMAT-PROD/backend/` directory
2. Railway will detect the `Dockerfile` and build the application
3. The service will connect to the PostgreSQL database via environment variables

### 4. Configure Environment Variables

In the Railway dashboard, go to your backend service > Variables, and set:

- `JWT_SECRET`: Your JWT secret key (use the same as in application.properties or generate a new secure one)
- `CORS_ALLOWED_ORIGINS`: Comma-separated list of allowed origins (e.g., `https://your-frontend-domain.com`)

Railway automatically provides database connection variables:
- `DATABASE_URL`: Full PostgreSQL connection string
- `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`

### 5. Database Setup

The application uses JPA with `ddl-auto=update`, so tables will be created automatically on first run.

If you need to run custom SQL, you can connect to the database using Railway's database tools.

### 6. Access the Application

Once deployed, Railway will provide a public URL for your backend (e.g., `https://umat-quiz-backend.up.railway.app`)

The API will be available at `https://your-url/api/`

## Troubleshooting

- Check Railway logs in the service dashboard
- Ensure the Dockerfile builds correctly
- Verify database connection variables are set
- For CORS issues, update the `CORS_ALLOWED_ORIGINS` variable

## Frontend Deployment

The frontend files are in `UMAT-PROD/frontend/`. You can deploy them separately on:
- Vercel
- Netlify
- GitHub Pages
- Railway static site

Update the frontend's API base URL to point to your Railway backend URL.