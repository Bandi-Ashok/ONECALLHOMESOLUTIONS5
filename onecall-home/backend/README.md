# OneCall Home Solutions Backend REST API & PostgreSQL System

Welcome to the backend architecture for **OneCall Home Solutions / Urban Services Enterprise Platform**.

## Architecture Overview

- **Database Engine**: PostgreSQL 14+ with PostGIS / pg_trgm / uuid-ossp
- **API Runtime**: Node.js / Express or Kotlin Ktor
- **Module Breakdown**: 30 Enterprise Modules (Auth, Customer, Property, Technician, Services, Bookings, Dispatch, Payments, Notifications, Inventory, CRM, Vendors, Workforce, Analytics, AI Platform, Admin, Security, etc.)

## Directory Structure

```
/backend
  ├── database/
  │   ├── schema.sql      # Complete 30-Module PostgreSQL Schema DDL
  │   └── seed.sql        # Initial Seed Data (Categories, Services, Default Roles)
  ├── src/
  │   ├── config/         # Database Pool Configuration
  │   ├── routes/         # Express REST API Route Controllers
  │   │   ├── auth.routes.js
  │   │   ├── customer.routes.js
  │   │   ├── service.routes.js
  │   │   ├── booking.routes.js
  │   │   ├── technician.routes.js
  │   │   ├── property.routes.js
  │   │   └── payment.routes.js
  │   └── server.js       # Main Express Server Entrypoint
  ├── package.json
  └── README.md
```

## Running the Backend

1. **Install Dependencies**:
   ```bash
   cd backend
   npm install
   ```

2. **Setup PostgreSQL Database**:
   ```bash
   createdb urban_services_enterprise
   psql -d urban_services_enterprise -f database/schema.sql
   psql -d urban_services_enterprise -f database/seed.sql
   ```

3. **Start Server**:
   ```bash
   npm start
   ```
