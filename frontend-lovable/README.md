# WinSchool Migration Tool - Frontend

A modern React frontend for the WinSchool database migration and normalization tool, built with TypeScript, Vite, and Tailwind CSS.

## Features

- **Phase 1: Raw Migration** - Select and migrate tables from MSSQL to PostgreSQL
- **Phase 2: Normalization** - Run normalization scripts on migrated data
- **Real-time Progress** - WebSocket-based live updates during migration
- **Modern UI** - Built with shadcn/ui components and Tailwind CSS
- **Type Safety** - Full TypeScript support with proper API typing

## Technology Stack

- **React 18** with TypeScript
- **Vite** for fast development and building
- **Tailwind CSS** for styling
- **shadcn/ui** for UI components
- **Socket.IO Client** for real-time communication
- **React Query** for API state management
- **React Router** for navigation

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Backend server running on `http://localhost:5000`

### Installation

1. Install dependencies:
```bash
npm install
```

2. Start the development server:
```bash
npm run dev
```

Or use the startup script:
```bash
chmod +x start.sh
./start.sh
```

The frontend will be available at `http://localhost:8080`

### Building for Production

```bash
npm run build
```

The built files will be in the `dist` directory.

## API Integration

The frontend integrates with the Flask backend through:

- **REST API** endpoints for table listing, migration control, and status
- **WebSocket** connection for real-time progress updates
- **Automatic reconnection** handling for robust connectivity

### API Endpoints Used

- `GET /api/tables` - Fetch available tables
- `GET /api/status` - Get current migration status
- `POST /api/migrate` - Start raw migration
- `POST /api/normalize` - Start normalization
- `POST /api/stop` - Stop current operation

### WebSocket Events

- `progress` - Migration progress updates
- `error` - Error notifications
- `complete` - Migration completion
- `connect/disconnect` - Connection status

## Project Structure

```
src/
├── components/          # React components
│   ├── ui/             # shadcn/ui components
│   ├── MigrationPhaseOne.tsx
│   ├── MigrationPhaseTwo.tsx
│   └── ProgressSection.tsx
├── hooks/              # Custom React hooks
│   ├── use-websocket.ts
│   └── use-toast.ts
├── lib/                # Utilities and services
│   ├── api.ts          # API service layer
│   └── utils.ts        # General utilities
├── pages/              # Page components
│   ├── Index.tsx
│   └── NotFound.tsx
└── App.tsx             # Main app component
```

## Development

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run build:dev` - Build in development mode
- `npm run lint` - Run ESLint
- `npm run preview` - Preview production build

### Environment Variables

The frontend automatically detects the environment:
- **Development**: API calls proxied to `http://localhost:5000`
- **Production**: API calls made to the same origin

## Features in Detail

### Phase 1: Raw Migration
- Fetches available tables from MSSQL database
- Allows selection of multiple tables
- Starts migration with real-time progress tracking
- Handles errors gracefully with user notifications

### Phase 2: Normalization
- Provides selection of normalization modules
- Shows detailed information about each module
- Executes SQL normalization scripts
- Tracks progress and completion

### Progress Tracking
- Real-time WebSocket updates
- Connection status indicator
- Detailed console logs
- Progress bar and status cards
- Error handling and notifications

## Troubleshooting

### Common Issues

1. **Connection Failed**: Ensure backend is running on port 5000
2. **WebSocket Errors**: Check firewall settings and CORS configuration
3. **Build Errors**: Clear `node_modules` and reinstall dependencies

### Debug Mode

Enable debug logging by opening browser dev tools and checking the console for detailed API and WebSocket logs.

## Contributing

1. Follow the existing code style and patterns
2. Add TypeScript types for new features
3. Test WebSocket functionality thoroughly
4. Update this README for new features