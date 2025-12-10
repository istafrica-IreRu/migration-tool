import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { Loader2 } from "lucide-react";

interface ConnectionDialogProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
}

interface ConnectionFormData {
    mssql: {
        server: string;
        database: string;
        username: string;
        password: string;
    };
    postgresql: {
        host: string;
        port: string;
        database: string;
        user: string;
        password: string;
    };
}

const ConnectionDialog = ({ open, onOpenChange }: ConnectionDialogProps) => {
    const { toast } = useToast();
    const [isLoading, setIsLoading] = useState(false);
    const [formData, setFormData] = useState<ConnectionFormData>({
        mssql: {
            server: "",
            database: "",
            username: "",
            password: "",
        },
        postgresql: {
            host: "localhost",
            port: "5432",
            database: "",
            user: "postgres",
            password: "",
        },
    });

    const handleInputChange = (
        db: "mssql" | "postgresql",
        field: string,
        value: string
    ) => {
        setFormData((prev) => ({
            ...prev,
            [db]: {
                ...prev[db],
                [field]: value,
            },
        }));
    };

    const handleSave = async () => {
        setIsLoading(true);
        try {
            const response = await fetch("http://localhost:5000/api/connect", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify(formData),
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.error || "Connection failed");
            }

            toast({
                title: "Success",
                description: "Database connections configured successfully. Refreshing...",
            });

            // Close dialog and reload page to fetch tables with new credentials
            onOpenChange(false);
            setTimeout(() => {
                window.location.reload();
            }, 500);
        } catch (error) {
            toast({
                title: "Connection Failed",
                description: error instanceof Error ? error.message : "Unknown error",
                variant: "destructive",
            });
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                    <DialogTitle>Database Connection Settings</DialogTitle>
                    <DialogDescription>
                        Configure your MSSQL and PostgreSQL database connections
                    </DialogDescription>
                </DialogHeader>

                <div className="grid gap-6 py-4">
                    {/* MSSQL Section */}
                    <div className="space-y-4">
                        <h3 className="text-sm font-semibold text-foreground">
                            MSSQL (Source Database)
                        </h3>
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Label htmlFor="mssql-server">Server</Label>
                                <Input
                                    id="mssql-server"
                                    placeholder="localhost"
                                    value={formData.mssql.server}
                                    onChange={(e) =>
                                        handleInputChange("mssql", "server", e.target.value)
                                    }
                                />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="mssql-database">Database</Label>
                                <Input
                                    id="mssql-database"
                                    placeholder="wsdata"
                                    value={formData.mssql.database}
                                    onChange={(e) =>
                                        handleInputChange("mssql", "database", e.target.value)
                                    }
                                />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="mssql-username">Username</Label>
                                <Input
                                    id="mssql-username"
                                    placeholder="sa"
                                    value={formData.mssql.username}
                                    onChange={(e) =>
                                        handleInputChange("mssql", "username", e.target.value)
                                    }
                                />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="mssql-password">Password</Label>
                                <Input
                                    id="mssql-password"
                                    type="password"
                                    value={formData.mssql.password}
                                    onChange={(e) =>
                                        handleInputChange("mssql", "password", e.target.value)
                                    }
                                />
                            </div>
                        </div>
                    </div>

                    {/* PostgreSQL Section */}
                    <div className="space-y-4">
                        <h3 className="text-sm font-semibold text-foreground">
                            PostgreSQL (Target Database)
                        </h3>
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Label htmlFor="pg-host">Host</Label>
                                <Input
                                    id="pg-host"
                                    placeholder="localhost"
                                    value={formData.postgresql.host}
                                    onChange={(e) =>
                                        handleInputChange("postgresql", "host", e.target.value)
                                    }
                                />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="pg-port">Port</Label>
                                <Input
                                    id="pg-port"
                                    placeholder="5432"
                                    value={formData.postgresql.port}
                                    onChange={(e) =>
                                        handleInputChange("postgresql", "port", e.target.value)
                                    }
                                />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="pg-database">Database</Label>
                                <Input
                                    id="pg-database"
                                    placeholder="wsdata_v4"
                                    value={formData.postgresql.database}
                                    onChange={(e) =>
                                        handleInputChange("postgresql", "database", e.target.value)
                                    }
                                />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="pg-user">User</Label>
                                <Input
                                    id="pg-user"
                                    placeholder="postgres"
                                    value={formData.postgresql.user}
                                    onChange={(e) =>
                                        handleInputChange("postgresql", "user", e.target.value)
                                    }
                                />
                            </div>
                            <div className="space-y-2 col-span-2">
                                <Label htmlFor="pg-password">Password</Label>
                                <Input
                                    id="pg-password"
                                    type="password"
                                    value={formData.postgresql.password}
                                    onChange={(e) =>
                                        handleInputChange("postgresql", "password", e.target.value)
                                    }
                                />
                            </div>
                        </div>
                    </div>
                </div>

                <DialogFooter>
                    <Button variant="outline" onClick={() => onOpenChange(false)}>
                        Cancel
                    </Button>
                    <Button onClick={handleSave} disabled={isLoading}>
                        {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Test & Save
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
};

export default ConnectionDialog;
