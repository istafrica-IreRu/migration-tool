import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Play, X, Loader2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { apiService, Module } from "@/lib/api";
import { useToast } from "@/hooks/use-toast";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

interface MigrationPhaseTwoProps {
  isMigrating: boolean;
  setIsMigrating: (value: boolean) => void;
}

const MigrationPhaseTwo = ({ isMigrating, setIsMigrating }: MigrationPhaseTwoProps) => {
  const [migrationModules, setMigrationModules] = useState<Module[]>([]);
  const [isLoadingModules, setIsLoadingModules] = useState(true);
  const [selectedModules, setSelectedModules] = useState<Set<string>>(new Set());
  const { toast } = useToast();

  useEffect(() => {
    const loadModules = async () => {
      setIsLoadingModules(true);
      try {
        const result = await apiService.fetchModules();
        if (result.error) {
          toast({
            title: "Failed to load modules",
            description: result.error,
            variant: "destructive",
          });
        } else {
          setMigrationModules(result.modules);
        }
      } catch (err) {
        toast({
          title: "Failed to load modules",
          description: "An unexpected error occurred",
          variant: "destructive",
        });
      } finally {
        setIsLoadingModules(false);
      }
    };

    loadModules();
  }, [toast]);

  const handleSelectModule = (value: string) => {
    const newSelected = new Set(selectedModules);
    if (newSelected.has(value)) {
      newSelected.delete(value);
    } else {
      newSelected.add(value);
    }
    setSelectedModules(newSelected);
  };

  const removeModule = (moduleKey: string) => {
    const newSelected = new Set(selectedModules);
    newSelected.delete(moduleKey);
    setSelectedModules(newSelected);
  };

  const startModuleMigration = async () => {
    if (selectedModules.size === 0) {
      toast({
        title: "No modules selected",
        description: "Please select at least one migration module",
        variant: "destructive",
      });
      return;
    }

    setIsMigrating(true);

    try {
      // Find selected module objects and sort by version
      const selectedModuleInfo = migrationModules
        .filter(m => selectedModules.has(m.id))
        .sort((a, b) => a.order - b.order);

      const modulesArray = selectedModuleInfo.map(m => m.id);

      const result = await apiService.startNormalization(modulesArray);

      if (result.error) {
        toast({
          title: "Module migration failed to start",
          description: result.error,
          variant: "destructive",
        });
        setIsMigrating(false);
      } else {
        toast({
          title: "Module migration started",
          description: `Running ${selectedModules.size} module${selectedModules.size > 1 ? 's' : ''}`,
        });
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to start module migration';
      toast({
        title: "Module migration failed to start",
        description: errorMessage,
        variant: "destructive",
      });
      setIsMigrating(false);
    }
  };

  // Get available modules that haven't been selected
  const availableModules = migrationModules.filter(
    (m) => !selectedModules.has(m.id)
  );

  const selectedModulesOrdered = migrationModules
    .filter(m => selectedModules.has(m.id))
    .sort((a, b) => a.order - b.order);

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Select Migration Modules</CardTitle>
          <CardDescription>
            Migrate data by module to PostgreSQL
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="space-y-3">
            <label className="text-sm font-medium">Migration Modules</label>

            {isLoadingModules ? (
              <div className="flex items-center gap-2 p-3 border rounded-lg bg-muted/50 text-sm text-muted-foreground italic">
                <Loader2 className="h-4 w-4 animate-spin" />
                Searching for modules in reference folder...
              </div>
            ) : (
              <>
                {/* Selected modules display */}
                {selectedModules.size > 0 && (
                  <div className="flex flex-wrap gap-2 p-3 border rounded-lg bg-muted/50">
                    {selectedModulesOrdered.map((module) => (
                      <Badge key={module.id} variant="secondary" className="gap-1">
                        {module.title}
                        <button
                          onClick={() => removeModule(module.id)}
                          disabled={isMigrating}
                          className="ml-1 hover:bg-secondary-foreground/20 rounded-full"
                        >
                          <X className="h-3 w-3" />
                        </button>
                      </Badge>
                    ))}
                  </div>
                )}

                {/* Multi-select dropdown */}
                <Select
                  value=""
                  onValueChange={handleSelectModule}
                  disabled={isMigrating || availableModules.length === 0}
                >
                  <SelectTrigger>
                    <SelectValue
                      placeholder={
                        selectedModules.size === 0
                          ? "Select modules..."
                          : availableModules.length === 0
                            ? "All modules selected"
                            : "Select more modules..."
                      }
                    />
                  </SelectTrigger>
                  <SelectContent>
                    {availableModules.map((module) => (
                      <SelectItem key={module.id} value={module.id}>
                        {module.title}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </>
            )}
          </div>

          {!isLoadingModules && selectedModules.size > 0 && (
            <div className="rounded-lg border bg-muted/50 p-4">
              <p className="text-sm font-medium mb-2">
                Selected: {selectedModules.size} module{selectedModules.size > 1 ? 's' : ''}
              </p>
              <div className="space-y-2">
                {selectedModulesOrdered.map((module) => (
                  <div key={module.id} className="text-sm">
                    <p className="font-medium">{module.title}</p>
                    <p className="text-muted-foreground text-xs">{module.description}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          <Button
            onClick={startModuleMigration}
            disabled={isMigrating || selectedModules.size === 0 || isLoadingModules}
            className="w-full"
            size="lg"
          >
            <Play className="h-4 w-4 mr-2" />
            Start Migration {selectedModules.size > 0 && `(${selectedModules.size} module${selectedModules.size > 1 ? 's' : ''})`}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
};

export default MigrationPhaseTwo;
