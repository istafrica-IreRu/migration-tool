import { useState, useEffect } from "react";
import MigrationPhaseOne from "@/components/MigrationPhaseOne";
import ProgressSection from "@/components/ProgressSection";
import { useWebSocket } from "@/hooks/use-websocket";

const PhaseOne = () => {
    const [isMigrating, setIsMigrating] = useState(false);
    const [progress, setProgress] = useState(0);
    const [currentPhase, setCurrentPhase] = useState("-");
    const [currentTable, setCurrentTable] = useState("-");

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
        <div className="space-y-6">
            <MigrationPhaseOne
                isMigrating={isMigrating}
                setIsMigrating={setIsMigrating}
            />
            <ProgressSection
                currentPhase={currentPhase}
                currentTable={currentTable}
                progress={progress}
            />
        </div>
    );
};

export default PhaseOne;
