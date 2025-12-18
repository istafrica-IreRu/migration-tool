import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import MigrationPhaseOne from "@/components/MigrationPhaseOne";
import MigrationPhaseTwo from "@/components/MigrationPhaseTwo";
import ProgressSection from "@/components/ProgressSection";
import { useWebSocket } from "@/hooks/use-websocket";

const Index = () => {
  const [isMigrating, setIsMigrating] = useState(false);
  const [progress, setProgress] = useState(0);
  const [currentPhase, setCurrentPhase] = useState("-");
  const [currentTable, setCurrentTable] = useState("-");
  const [activeTab, setActiveTab] = useState("phase1");

  const { lastProgress, lastComplete, lastError } = useWebSocket();

  // Update migration state based on WebSocket events
  useEffect(() => {
    if (lastProgress) {
      setProgress(lastProgress.progress);
      setCurrentPhase(lastProgress.phase);
      setCurrentTable(lastProgress.current_table || "-");
      setIsMigrating(true);
    }
  }, [lastProgress]);

  useEffect(() => {
    if (lastComplete) {
      setIsMigrating(false);
      setProgress(100);
    }
  }, [lastComplete]);

  useEffect(() => {
    if (lastError) {
      setIsMigrating(false);
    }
  }, [lastError]);

  return (
    <div className="min-h-screen bg-background p-4 md:p-8">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Header */}
        <Card className="border-none shadow-sm">
          <CardHeader className="text-center space-y-2 pb-8">
            <CardTitle className="text-4xl md:text-5xl font-bold tracking-tight">
              WinSchool Migration Tool
            </CardTitle>
            <CardDescription className="text-lg">
              Database Structure Analysis & Module Migration
            </CardDescription>
          </CardHeader>
        </Card>

        {/* Main Content */}
        <Card className="border-none shadow-sm">
          <CardContent className="pt-6">
            <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
              <TabsList className="grid w-full grid-cols-2 h-auto p-1">
                <TabsTrigger
                  value="phase1"
                  className="data-[state=active]:bg-primary data-[state=active]:text-primary-foreground py-3"
                >
                  <div className="flex flex-col items-center gap-1">
                    <span className="font-semibold">Phase 1</span>
                    <span className="text-xs opacity-90">Raw Migration</span>
                  </div>
                </TabsTrigger>
                <TabsTrigger
                  value="phase2"
                  className="data-[state=active]:bg-primary data-[state=active]:text-primary-foreground py-3"
                >
                  <div className="flex flex-col items-center gap-1">
                    <span className="font-semibold">Phase 2</span>
                    <span className="text-xs opacity-90">Modules Migration</span>
                  </div>
                </TabsTrigger>
              </TabsList>

              <TabsContent value="phase1" className="space-y-6 mt-6">
                <MigrationPhaseOne
                  isMigrating={isMigrating}
                  setIsMigrating={setIsMigrating}
                />
              </TabsContent>

              <TabsContent value="phase2" className="space-y-6 mt-6">
                <MigrationPhaseTwo
                  isMigrating={isMigrating}
                  setIsMigrating={setIsMigrating}
                />
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>

        {/* Progress Section */}
        {(() => {
          const reportType = activeTab === "phase1" ? "migration" : "normalization";
          console.log('Rendering ProgressSection with activeTab:', activeTab, 'reportType:', reportType);
          return (
            <ProgressSection
              key={activeTab}
              currentPhase={currentPhase}
              currentTable={currentTable}
              progress={progress}
              reportType={reportType}
            />
          );
        })()}
      </div>
    </div>
  );
};

export default Index;
