import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Activity, Database, Percent, Wifi, WifiOff, FileText, Download } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useWebSocket } from "@/hooks/use-websocket";
import { useLocation } from "react-router-dom";

interface ProgressSectionProps {
  currentPhase: string;
  currentTable: string;
  progress: number;
  reportType?: 'migration' | 'normalization';
}

interface LogEntry {
  id: string;
  timestamp: string;
  message: string;
  type: 'info' | 'error' | 'success' | 'warning';
}

const ProgressSection = ({ currentPhase, currentTable, progress, reportType }: ProgressSectionProps) => {
  const { isConnected, lastProgress, lastError, lastComplete, connectionError } = useWebSocket();
  const [logs, setLogs] = useState<LogEntry[]>([
    {
      id: '1',
      timestamp: new Date().toLocaleTimeString(),
      message: 'Ready to start...',
      type: 'info'
    }
  ]);

  // Report State
  const [isReportOpen, setIsReportOpen] = useState(false);
  const [reportContent, setReportContent] = useState("");
  const [isLoadingReport, setIsLoadingReport] = useState(false);

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

  const location = useLocation();

  // Use prop if provided, otherwise detect from URL
  const actualReportType = reportType || (location.pathname === '/' ? 'migration' : 'normalization');

  const handleViewReport = async () => {
    console.log('Viewing report actual type:', actualReportType);
    setIsLoadingReport(true);
    setIsReportOpen(true);
    try {
      const response = await fetch(`http://localhost:5000/api/report?type=${actualReportType}`);
      const data = await response.json();
      if (data.content) {
        setReportContent(data.content);
      } else {
        setReportContent("Failed to load report.");
      }
    } catch (error) {
      setReportContent("Error loading report. Please check connection.");
    } finally {
      setIsLoadingReport(false);
    }
  };

  const handleDownloadReport = () => {
    window.location.href = `http://localhost:5000/api/report/download?type=${actualReportType}`;
  };

  const displayProgress = wsProgress || progress;
  const displayPhase = wsCurrentPhase || currentPhase;
  const displayTable = wsCurrentTable || currentTable;

  return (
    <>
      <Card className="border-none shadow-sm">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <CardTitle className="text-xl">Migration Progress</CardTitle>
              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  className="h-8 gap-2"
                  onClick={handleViewReport}
                >
                  <FileText className="h-4 w-4" />
                  View Report
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  className="h-8 gap-2"
                  onClick={handleDownloadReport}
                >
                  <Download className="h-4 w-4" />
                  Download
                </Button>
              </div>
            </div>
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
                      className={`${log.type === 'error' ? 'text-destructive' :
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

      <Dialog open={isReportOpen} onOpenChange={setIsReportOpen}>
        <DialogContent className="max-w-4xl max-h-[90vh] flex flex-col">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <FileText className="h-5 w-5 text-primary" />
              {actualReportType === 'normalization' ? 'Normalization' : 'Migration'} Validation Report
            </DialogTitle>
            <DialogDescription>
              Technical details and data integrity check results.
            </DialogDescription>
          </DialogHeader>
          <ScrollArea className="flex-1 min-h-[400px] rounded-md border bg-muted p-4">
            <div className="font-mono text-xs leading-relaxed">
              {isLoadingReport ? (
                <div className="flex items-center justify-center p-8">Loading report...</div>
              ) : (
                <pre className="whitespace-pre-wrap break-all">{reportContent}</pre>
              )}
            </div>
          </ScrollArea>
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => setIsReportOpen(false)}>Close</Button>
            <Button onClick={handleDownloadReport}>Download</Button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
};

export default ProgressSection;
