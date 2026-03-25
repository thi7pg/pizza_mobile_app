# Pizza App Backend (Express.js)

Simple Node.js + Express backend for Pizza Delivery Flutter app.

## Setup Instructions

### 1. Install Node.js
Download and install from: https://nodejs.org/

### 2. Install Dependencies
```bash
cd backend
npm install
```

### 3. Start the Server
```bash
npm start
```

Or for development with auto-reload:
```bash
npm run dev
```

The backend will run on `http://localhost:3000`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user

### Products
- `GET /api/products` - Get all products
- `GET /api/products/:id` - Get product by ID

### Profile
- `GET /api/profile/:email` - Get user profile
- `PUT /api/profile/:email` - Update user profile

### Orders
- `POST /api/orders` - Create order
- `GET /api/orders/:email` - Get user orders

### Health
- `GET /api/health` - Check server status

## Example Requests

### Register
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"123456","fullName":"John Doe"}'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"123456"}'
```

### Get Products
```bash
curl http://localhost:3000/api/products
```

## Notes
- User data is stored in-memory (resets on server restart)
- For production, use a real database (MongoDB, PostgreSQL, etc.)
- Implement proper JWT authentication
- Add input validation and error handling
- Use bcryptjs for password hashing
