import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Activity, Database, Percent, Wifi, WifiOff } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { useWebSocket } from "@/hooks/use-websocket";

interface ProgressSectionProps {
  currentPhase: string;
  currentTable: string;
  progress: number;
}

interface LogEntry {
  id: string;
  timestamp: string;
  message: string;
  type: 'info' | 'error' | 'success' | 'warning';
}

const ProgressSection = ({ currentPhase, currentTable, progress }: ProgressSectionProps) => {
  const { isConnected, lastProgress, lastError, lastComplete, connectionError } = useWebSocket();
  const [logs, setLogs] = useState<LogEntry[]>([
    {
      id: '1',
      timestamp: new Date().toLocaleTimeString(),
      message: 'Ready to start...',
      type: 'info'
    }
  ]);

  // Update progress from WebSocket
  const [wsProgress, setWsProgress] = useState(progress);
  const [wsCurrentPhase, setWsCurrentPhase] = useState(currentPhase);
  const [wsCurrentTable, setWsCurrentTable] = useState(currentTable);

  useEffect(() => {
    if (lastProgress) {
      setWsProgress(lastProgress.progress);
      setWsCurrentPhase(lastProgress.phase);
      setWsCurrentTable(lastProgress.current_table || '-');
      
      // Add progress message to logs
      if (lastProgress.message) {
        const newLog: LogEntry = {
          id: Date.now().toString(),
          timestamp: new Date().toLocaleTimeString(),
          message: lastProgress.message,
          type: 'info'
        };
        setLogs(prev => [...prev, newLog].slice(-100)); // Keep last 100 logs
      }
    }
  }, [lastProgress]);

  useEffect(() => {
    if (lastError) {
      const newLog: LogEntry = {
        id: Date.now().toString(),
        timestamp: new Date().toLocaleTimeString(),
        message: `Error: ${lastError.error}`,
        type: 'error'
      };
      setLogs(prev => [...prev, newLog].slice(-100));
    }
  }, [lastError]);

  useEffect(() => {
    if (lastComplete) {
      const newLog: LogEntry = {
        id: Date.now().toString(),
        timestamp: new Date().toLocaleTimeString(),
        message: lastComplete.message,
        type: 'success'
      };
      setLogs(prev => [...prev, newLog].slice(-100));
      setWsProgress(100);
    }
  }, [lastComplete]);

  const displayProgress = wsProgress || progress;
  const displayPhase = wsCurrentPhase || currentPhase;
  const displayTable = wsCurrentTable || currentTable;

  return (
    <Card className="border-none shadow-sm">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="text-xl">Migration Progress</CardTitle>
          <div className="flex items-center gap-2">
            {isConnected ? (
              <Badge variant="secondary" className="text-xs">
                <Wifi className="h-3 w-3 mr-1" />
                Connected
              </Badge>
            ) : (
              <Badge variant="destructive" className="text-xs">
                <WifiOff className="h-3 w-3 mr-1" />
                {connectionError ? 'Connection Error' : 'Disconnected'}
              </Badge>
            )}
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Status Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Card className="bg-muted/50">
            <CardContent className="pt-6">
              <div className="flex items-start justify-between">
                <div className="space-y-1">
                  <p className="text-sm text-muted-foreground">Current Phase</p>
                  <p className="text-lg font-semibold">{displayPhase}</p>
                </div>
                <Activity className="h-5 w-5 text-primary opacity-70" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-muted/50">
            <CardContent className="pt-6">
              <div className="flex items-start justify-between">
                <div className="space-y-1">
                  <p className="text-sm text-muted-foreground">Current Table</p>
                  <p className="text-lg font-semibold truncate">{displayTable}</p>
                </div>
                <Database className="h-5 w-5 text-primary opacity-70" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-muted/50">
            <CardContent className="pt-6">
              <div className="flex items-start justify-between">
                <div className="space-y-1">
                  <p className="text-sm text-muted-foreground">Progress</p>
                  <p className="text-lg font-semibold">{displayProgress}%</p>
                </div>
                <Percent className="h-5 w-5 text-primary opacity-70" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Progress Bar */}
        <div className="space-y-2">
          <Progress value={displayProgress} className="h-3" />
        </div>

        {/* Log Console */}
        <Card className="bg-foreground/5">
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-mono">Console Output</CardTitle>
          </CardHeader>
          <CardContent>
            <ScrollArea className="h-[200px] w-full rounded-md bg-card border p-4">
              <div className="space-y-2 font-mono text-xs">
                {logs.map((log) => (
                  <div 
                    key={log.id} 
                    className={`${
                      log.type === 'error' ? 'text-destructive' :
                      log.type === 'success' ? 'text-green-600' :
                      log.type === 'warning' ? 'text-yellow-600' :
                      'text-foreground'
                    }`}
                  >
                    <span className="text-muted-foreground">[{log.timestamp}]</span>{" "}
                    {log.message}
                  </div>
                ))}
              </div>
            </ScrollArea>
          </CardContent>
        </Card>
      </CardContent>
    </Card>
  );
};

export default ProgressSection;
