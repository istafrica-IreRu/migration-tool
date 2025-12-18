import { Link, useLocation } from "react-router-dom";
import { Database, GitBranch, Settings, FileText } from "lucide-react";
import { useState } from "react";
import {
    Sidebar,
    SidebarContent,
    SidebarGroup,
    SidebarGroupContent,
    SidebarGroupLabel,
    SidebarHeader,
    SidebarInset,
    SidebarMenu,
    SidebarMenuButton,
    SidebarMenuItem,
    SidebarProvider,
    SidebarTrigger,
} from "@/components/ui/sidebar";
import { Separator } from "@/components/ui/separator";
import { Button } from "@/components/ui/button";
import ConnectionDialog from "./ConnectionDialog";

interface DashboardLayoutProps {
    children: React.ReactNode;
}

const DashboardLayout = ({ children }: DashboardLayoutProps) => {
    const location = useLocation();
    const [connectionDialogOpen, setConnectionDialogOpen] = useState(false);

    const navItems = [
        {
            title: "Reading Database Structure",
            url: "/",
            icon: Database,
            description: "MSSQL → PostgreSQL",
        },
        {
            title: "Modules Migration",
            url: "/phase-2",
            icon: GitBranch,
            description: "Module-based Migration",
        },
        {
            title: "Reports & History",
            url: "/reports",
            icon: FileText,
            description: "Logs and Activity",
        },
    ];

    return (
        <SidebarProvider>
            <Sidebar>
                <SidebarHeader className="border-b border-sidebar-border">
                    <div className="flex flex-col gap-2 py-2 px-4">
                        <h1 className="text-lg font-semibold tracking-tight">
                            WinSchool Migration
                        </h1>
                        <p className="text-xs text-muted-foreground">
                            Database Migration Tool
                        </p>
                    </div>
                </SidebarHeader>
                <SidebarContent>
                    <SidebarGroup>
                        <SidebarGroupLabel>Migration Phases</SidebarGroupLabel>
                        <SidebarGroupContent>
                            <SidebarMenu>
                                {navItems.map((item) => {
                                    const isActive = location.pathname === item.url;
                                    return (
                                        <SidebarMenuItem key={item.title}>
                                            <SidebarMenuButton asChild isActive={isActive}>
                                                <Link to={item.url}>
                                                    <item.icon className="h-4 w-4" />
                                                    <div className="flex flex-col">
                                                        <span className="text-sm font-medium">
                                                            {item.title}
                                                        </span>
                                                        <span className="text-xs text-muted-foreground">
                                                            {item.description}
                                                        </span>
                                                    </div>
                                                </Link>
                                            </SidebarMenuButton>
                                        </SidebarMenuItem>
                                    );
                                })}
                            </SidebarMenu>
                        </SidebarGroupContent>
                    </SidebarGroup>
                </SidebarContent>
            </Sidebar>
            <SidebarInset>
                <header className="sticky top-0 z-10 flex h-16 shrink-0 items-center gap-2 border-b bg-background px-4">
                    <SidebarTrigger className="-ml-1" />
                    <Separator orientation="vertical" className="mr-2 h-4" />
                    <div className="flex items-center gap-2 flex-1">
                        <h2 className="text-lg font-semibold">
                            {navItems.find((item) => item.url === location.pathname)?.title ||
                                "Dashboard"}
                        </h2>
                    </div>
                    <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setConnectionDialogOpen(true)}
                    >
                        <Settings className="h-4 w-4 mr-2" />
                        Connection Settings
                    </Button>
                </header>
                <div className="flex flex-1 flex-col gap-4 p-4 md:p-6">{children}</div>
            </SidebarInset>

            <ConnectionDialog
                open={connectionDialogOpen}
                onOpenChange={setConnectionDialogOpen}
            />
        </SidebarProvider>
    );
};

export default DashboardLayout;
