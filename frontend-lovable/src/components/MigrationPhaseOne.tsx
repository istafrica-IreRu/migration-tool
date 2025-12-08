import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Database, Play, Square, AlertCircle } from "lucide-react";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { apiService, Table } from "@/lib/api";
import { useToast } from "@/hooks/use-toast";

interface MigrationPhaseOneProps {
  isMigrating: boolean;
  setIsMigrating: (value: boolean) => void;
}

const MigrationPhaseOne = ({
  isMigrating,
  setIsMigrating
}: MigrationPhaseOneProps) => {
  const [tables, setTables] = useState<Table[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { toast } = useToast();

  // Fetch tables from API
  useEffect(() => {
    const fetchTables = async () => {
      setLoading(true);
      setError(null);

      try {
        const result = await apiService.fetchTables();

        if (result.error) {
          setError(result.error);
          setTables([]);
        } else {
          setTables(result.tables);
        }
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Failed to fetch tables';
        setError(errorMessage);
        setTables([]);
      } finally {
        setLoading(false);
      }
    };

    fetchTables();
  }, []);

  const startMigration = async () => {
    if (tables.length === 0) {
      toast({
        title: "No tables found",
        description: "Cannot start migration without tables",
        variant: "destructive",
      });
      return;
    }

    setIsMigrating(true);

    try {
      // Migrate all tables
      const allTableKeys = tables.map(t => t.key);
      const result = await apiService.startMigration(allTableKeys);

      if (result.error) {
        toast({
          title: "Migration failed to start",
          description: result.error,
          variant: "destructive",
        });
        setIsMigrating(false);
      } else {
        toast({
          title: "Reading started",
          description: `Analyzing structure of ${tables.length} tables`,
        });
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to start migration';
      toast({
        title: "Migration failed to start",
        description: errorMessage,
        variant: "destructive",
      });
      setIsMigrating(false);
    }
  };

  const stopMigration = async () => {
    try {
      const result = await apiService.stopMigration();

      if (result.error) {
        toast({
          title: "Failed to stop migration",
          description: result.error,
          variant: "destructive",
        });
      } else {
        toast({
          title: "Migration stopped",
          description: result.message,
        });
        setIsMigrating(false);
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to stop migration';
      toast({
        title: "Failed to stop migration",
        description: errorMessage,
        variant: "destructive",
      });
    }
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <CardTitle className="flex items-center gap-2">
                <Database className="h-5 w-5 text-primary" />
                Reading Database Structure
              </CardTitle>
              <CardDescription>
                Analyzing MSSQL database schema and tables
              </CardDescription>
            </div>
            {!loading && !error && (
              <Badge variant="secondary" className="text-sm">
                {tables.length} tables
              </Badge>
            )}
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {error && (
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>
                {error}
              </AlertDescription>
            </Alert>
          )}

          {loading ? (
            <div className="flex items-center justify-center py-8 text-muted-foreground">
              Loading database information...
            </div>
          ) : error ? (
            <div className="flex items-center justify-center py-8 text-destructive">
              Failed to load database information
            </div>
          ) : tables.length === 0 ? (
            <div className="flex items-center justify-center py-8 text-muted-foreground">
              No tables found in database
            </div>
          ) : (
            <div className="rounded-lg border bg-muted/50 p-4">
              <p className="text-sm text-muted-foreground">
                This will analyze the structure of all <span className="font-semibold text-foreground">{tables.length} tables</span> in the MSSQL database and prepare them for migration.
              </p>
            </div>
          )}

          <div className="flex gap-3 pt-2">
            <Button
              onClick={startMigration}
              disabled={isMigrating || loading || tables.length === 0}
              className="flex-1"
              size="lg"
            >
              <Play className="h-4 w-4 mr-2" />
              Start Reading
            </Button>
            <Button
              variant="outline"
              onClick={stopMigration}
              disabled={!isMigrating}
              size="lg"
            >
              <Square className="h-4 w-4 mr-2" />
              Stop
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default MigrationPhaseOne;

