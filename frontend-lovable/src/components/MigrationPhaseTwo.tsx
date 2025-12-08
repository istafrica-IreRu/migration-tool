import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Play, X } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { apiService } from "@/lib/api";
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

const migrationModules = {
  users: {
    title: "Users Tables (V000)",
    description: "Creates the foundational Nr_Users table for personal information (students, teachers, guardians, applicants).",
    file: "reference/V000__create_normalized_users_table.sql",
    order: 1,
  },
  enrollment: {
    title: "Enrollment/Applicant Tables (V001)",
    description: "Normalizes applicant data, including addresses, guardians, and application info.",
    file: "reference/V001__create_normalized_enrollment_tables.sql",
    order: 2,
  },
  guardians: {
    title: "Guardians Tables (V002)",
    description: "Normalizes guardian data and links it to students.",
    file: "reference/V002__create_normalized_guardian_tables.sql",
    order: 3,
  },
  academic: {
    title: "Academic Tables (V003)",
    description: "Normalizes academic data like subjects, courses, and grades.",
    file: "reference/V003__create_normalized_academic_tables.sql",
    order: 4,
  },
};

const MigrationPhaseTwo = ({ isMigrating, setIsMigrating }: MigrationPhaseTwoProps) => {
  const [selectedModules, setSelectedModules] = useState<Set<string>>(new Set());
  const { toast } = useToast();

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
      // Convert Set to Array and sort by order
      const modulesArray = Array.from(selectedModules).sort((a, b) => {
        const orderA = migrationModules[a as keyof typeof migrationModules].order;
        const orderB = migrationModules[b as keyof typeof migrationModules].order;
        return orderA - orderB;
      });

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
  const availableModules = Object.entries(migrationModules).filter(
    ([key]) => !selectedModules.has(key)
  );

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

            {/* Selected modules display */}
            {selectedModules.size > 0 && (
              <div className="flex flex-wrap gap-2 p-3 border rounded-lg bg-muted/50">
                {Array.from(selectedModules)
                  .sort((a, b) => {
                    const orderA = migrationModules[a as keyof typeof migrationModules].order;
                    const orderB = migrationModules[b as keyof typeof migrationModules].order;
                    return orderA - orderB;
                  })
                  .map((key) => (
                    <Badge key={key} variant="secondary" className="gap-1">
                      {migrationModules[key as keyof typeof migrationModules].title}
                      <button
                        onClick={() => removeModule(key)}
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
                {availableModules.map(([key, module]) => (
                  <SelectItem key={key} value={key}>
                    {module.title}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {selectedModules.size > 0 && (
            <div className="rounded-lg border bg-muted/50 p-4">
              <p className="text-sm font-medium mb-2">
                Selected: {selectedModules.size} module{selectedModules.size > 1 ? 's' : ''}
              </p>
              <div className="space-y-2">
                {Array.from(selectedModules)
                  .sort((a, b) => {
                    const orderA = migrationModules[a as keyof typeof migrationModules].order;
                    const orderB = migrationModules[b as keyof typeof migrationModules].order;
                    return orderA - orderB;
                  })
                  .map((key) => {
                    const module = migrationModules[key as keyof typeof migrationModules];
                    return (
                      <div key={key} className="text-sm">
                        <p className="font-medium">{module.title}</p>
                        <p className="text-muted-foreground text-xs">{module.description}</p>
                      </div>
                    );
                  })}
              </div>
            </div>
          )}

          <Button
            onClick={startModuleMigration}
            disabled={isMigrating || selectedModules.size === 0}
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
