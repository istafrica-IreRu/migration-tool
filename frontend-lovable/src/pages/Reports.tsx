import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useMigration } from "@/contexts/MigrationContext";
import { FileText, Download, CheckCircle2, XCircle, Clock, Database, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ScrollArea } from "@/components/ui/scroll-area";
import { format } from "date-fns";
import DashboardLayout from "@/components/DashboardLayout";

const Reports = () => {
    const { history, connectionInfo, clearHistory } = useMigration();

    const handleDownload = (type: 'migration' | 'normalization') => {
        window.location.href = `http://localhost:5000/api/report/download?type=${type}`;
    };

    return (
        <DashboardLayout>
            <div className="space-y-6">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Reports & History</h1>
                    <p className="text-muted-foreground">
                        View migration logs, validation reports, and activity history.
                    </p>
                </div>

                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    <Card>
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                            <CardTitle className="text-sm font-medium">Raw Migration Report</CardTitle>
                            <FileText className="h-4 w-4 text-muted-foreground" />
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold">Phase 1</div>
                            <p className="text-xs text-muted-foreground">MSSQL to PostgreSQL structure & data</p>
                            <Button
                                variant="outline"
                                size="sm"
                                className="mt-4 w-full gap-2"
                                onClick={() => handleDownload('migration')}
                            >
                                <Download className="h-4 w-4" />
                                Download CSV
                            </Button>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                            <CardTitle className="text-sm font-medium">Normalization Report</CardTitle>
                            <FileText className="h-4 w-4 text-muted-foreground" />
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold">Phase 2</div>
                            <p className="text-xs text-muted-foreground">PostgreSQL to Normalized Module Schema</p>
                            <Button
                                variant="outline"
                                size="sm"
                                className="mt-4 w-full gap-2"
                                onClick={() => handleDownload('normalization')}
                            >
                                <Download className="h-4 w-4" />
                                Download CSV
                            </Button>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                            <CardTitle className="text-sm font-medium">Connection Summary</CardTitle>
                            <Database className="h-4 w-4 text-muted-foreground" />
                        </CardHeader>
                        <CardContent>
                            <div className="text-sm space-y-1">
                                <div className="flex justify-between">
                                    <span className="text-muted-foreground mr-2">MSSQL:</span>
                                    <span className="font-medium truncate text-right">
                                        {connectionInfo.mssql || 'Not Configured'}
                                    </span>
                                </div>
                                <div className="flex justify-between">
                                    <span className="text-muted-foreground mr-2">PG:</span>
                                    <span className="font-medium truncate text-right">
                                        {connectionInfo.postgresql || 'Not Configured'}
                                    </span>
                                </div>
                            </div>
                            <p className="text-[10px] text-muted-foreground mt-2 italic">
                                {connectionInfo.mssql ? `Active: ${format(new Date(connectionInfo.lastConnected!), 'HH:mm:ss')}` : 'Configure settings to start'}
                            </p>
                        </CardContent>
                    </Card>
                </div>

                <Card>
                    <CardHeader className="flex flex-row items-center justify-between">
                        <div>
                            <CardTitle>Migration Activity History</CardTitle>
                            <CardDescription>Records of recent migration runs and system changes.</CardDescription>
                        </div>
                        <Button variant="ghost" size="sm" onClick={clearHistory} className="text-destructive hover:text-destructive">
                            <Trash2 className="h-4 w-4 mr-2" />
                            Clear History
                        </Button>
                    </CardHeader>
                    <CardContent>
                        <ScrollArea className="h-[400px] pr-4">
                            <div className="space-y-4">
                                {history.length === 0 ? (
                                    <div className="flex flex-col items-center justify-center py-10 text-muted-foreground">
                                        <Clock className="h-10 w-10 mb-2 opacity-20" />
                                        <p>No activity recorded yet.</p>
                                    </div>
                                ) : (
                                    history.map((entry) => (
                                        <div key={entry.id} className="flex items-start gap-4 border-b pb-4 last:border-0">
                                            <div className="mt-1">
                                                {entry.status === 'success' ? (
                                                    <CheckCircle2 className="h-5 w-5 text-green-500" />
                                                ) : entry.status === 'running' ? (
                                                    <Clock className="h-5 w-5 text-amber-500 animate-pulse" />
                                                ) : (
                                                    <XCircle className="h-5 w-5 text-destructive" />
                                                )}
                                            </div>
                                            <div className="flex-1 space-y-1">
                                                <div className="flex items-center justify-between">
                                                    <p className="text-sm font-medium leading-none">{entry.description}</p>
                                                    <time className="text-xs text-muted-foreground">
                                                        {format(new Date(entry.timestamp), 'MMM d, HH:mm:ss')}
                                                    </time>
                                                </div>
                                                <p className="text-xs text-muted-foreground">{entry.details}</p>
                                                <Badge variant="outline" className="text-[10px] py-0 h-4 capitalize">
                                                    {entry.type}
                                                </Badge>
                                            </div>
                                        </div>
                                    ))
                                )}
                            </div>
                        </ScrollArea>
                    </CardContent>
                </Card>
            </div>
        </DashboardLayout>
    );
};

export default Reports;
