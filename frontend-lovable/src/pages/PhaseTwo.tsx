import { useState, useEffect } from "react";
import MigrationPhaseTwo from "@/components/MigrationPhaseTwo";
import ProgressSection from "@/components/ProgressSection";
import { useWebSocket } from "@/hooks/use-websocket";

import { useMigration } from "@/contexts/MigrationContext";

const PhaseTwo = () => {
    const [isMigrating, setIsMigrating] = useState(false);
    const [progress, setProgress] = useState(0);
    const [currentPhase, setCurrentPhase] = useState("-");
    const [currentTable, setCurrentTable] = useState("-");
    const { addHistoryEntry } = useMigration();

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
            addHistoryEntry({
                type: 'normalization',
                description: 'Module Migration Completed',
                status: 'success',
                details: 'Successfully processed and normalized migration modules.'
            });
        }
    }, [lastComplete, addHistoryEntry]);

    useEffect(() => {
        if (lastError) {
            setIsMigrating(false);
            addHistoryEntry({
                type: 'normalization',
                description: 'Module Migration Failed',
                status: 'error',
                details: lastError.error
            });
        }
    }, [lastError, addHistoryEntry]);

    return (
        <div className="space-y-6">
            <MigrationPhaseTwo
                isMigrating={isMigrating}
                setIsMigrating={setIsMigrating}
            />
            <ProgressSection
                currentPhase={currentPhase}
                currentTable={currentTable}
                progress={progress}
                reportType="normalization"
            />
        </div>
    );
};

export default PhaseTwo;
