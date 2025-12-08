"""
Migration reporting system for generating comprehensive migration reports.
"""
import logging
import json
from typing import Dict, List, Any, Optional
from datetime import datetime
from dataclasses import dataclass, asdict

logger = logging.getLogger(__name__)


@dataclass
class TableMigrationStats:
    """Statistics for a single table migration."""
    table_name: str
    source_rows: int = 0
    target_rows: int = 0
    columns_migrated: int = 0
    new_columns_added: int = 0
    transformations_applied: int = 0
    migration_time_seconds: float = 0.0
    success: bool = True
    error_message: str = ""


@dataclass
class MigrationReport:
    """Complete migration report."""
    migration_id: str
    start_time: datetime
    end_time: Optional[datetime] = None
    total_tables: int = 0
    successful_tables: int = 0
    failed_tables: int = 0
    total_rows_migrated: int = 0
    total_duration_seconds: float = 0.0
    config_profile: str = ""
    schemas_migrated: List[str] = None
    table_stats: List[TableMigrationStats] = None
    validation_issues: List[str] = None
    normalization_scripts: List[str] = None

    def __post_init__(self):
        if self.schemas_migrated is None:
            self.schemas_migrated = []
        if self.table_stats is None:
            self.table_stats = []
        if self.validation_issues is None:
            self.validation_issues = []
        if self.normalization_scripts is None:
            self.normalization_scripts = []


class ReportGenerator:
    """Generates migration reports in various formats."""

    def __init__(self):
        """Initialize report generator."""
        self.report = MigrationReport(
            migration_id=datetime.now().strftime("%Y%m%d_%H%M%S"),
            start_time=datetime.now()
        )

    def set_config_info(self, profile: str, schemas: List[str]) -> None:
        """Set configuration information."""
        self.report.config_profile = profile
        self.report.schemas_migrated = schemas

    def add_table_stats(self, stats: TableMigrationStats) -> None:
        """Add statistics for a migrated table."""
        self.report.table_stats.append(stats)
        self.report.total_tables += 1
        
        if stats.success:
            self.report.successful_tables += 1
            self.report.total_rows_migrated += stats.target_rows
        else:
            self.report.failed_tables += 1

    def add_validation_issue(self, issue: str) -> None:
        """Add a validation issue to the report."""
        self.report.validation_issues.append(issue)

    def add_normalization_script(self, script_name: str) -> None:
        """Add a normalization script to the report."""
        self.report.normalization_scripts.append(script_name)

    def finalize(self) -> None:
        """Finalize the report with end time and duration."""
        self.report.end_time = datetime.now()
        self.report.total_duration_seconds = (
            self.report.end_time - self.report.start_time
        ).total_seconds()

    def to_json(self, file_path: Optional[str] = None) -> str:
        """
        Generate JSON report.
        
        Args:
            file_path: Optional path to save JSON file
            
        Returns:
            JSON string
        """
        # Convert dataclasses to dict
        report_dict = asdict(self.report)
        
        # Convert datetime objects to strings
        report_dict['start_time'] = self.report.start_time.isoformat()
        if self.report.end_time:
            report_dict['end_time'] = self.report.end_time.isoformat()
        
        json_str = json.dumps(report_dict, indent=2)
        
        if file_path:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(json_str)
            logger.info(f"JSON report saved to {file_path}")
        
        return json_str

    def to_markdown(self, file_path: Optional[str] = None) -> str:
        """
        Generate Markdown report.
        
        Args:
            file_path: Optional path to save Markdown file
            
        Returns:
            Markdown string
        """
        lines = [
            f"# Migration Report",
            f"",
            f"**Migration ID:** {self.report.migration_id}  ",
            f"**Start Time:** {self.report.start_time.strftime('%Y-%m-%d %H:%M:%S')}  ",
        ]
        
        if self.report.end_time:
            lines.append(f"**End Time:** {self.report.end_time.strftime('%Y-%m-%d %H:%M:%S')}  ")
            lines.append(f"**Duration:** {self.report.total_duration_seconds:.2f} seconds  ")
        
        lines.extend([
            f"**Config Profile:** {self.report.config_profile}  ",
            f"**Schemas:** {', '.join(self.report.schemas_migrated)}  ",
            "",
            "## Summary",
            "",
            f"- **Total Tables:** {self.report.total_tables}",
            f"- **Successful:** {self.report.successful_tables}",
            f"- **Failed:** {self.report.failed_tables}",
            f"- **Total Rows Migrated:** {self.report.total_rows_migrated:,}",
            "",
        ])
        
        # Table statistics
        if self.report.table_stats:
            lines.extend([
                "## Table Migration Details",
                "",
                "| Table | Source Rows | Target Rows | New Columns | Transformations | Time (s) | Status |",
                "|-------|-------------|-------------|-------------|-----------------|----------|--------|"
            ])
            
            for stats in self.report.table_stats:
                status = "✅" if stats.success else "❌"
                lines.append(
                    f"| {stats.table_name} | {stats.source_rows:,} | {stats.target_rows:,} | "
                    f"{stats.new_columns_added} | {stats.transformations_applied} | "
                    f"{stats.migration_time_seconds:.2f} | {status} |"
                )
            
            lines.append("")
        
        # Validation issues
        if self.report.validation_issues:
            lines.extend([
                "## Validation Issues",
                "",
            ])
            for issue in self.report.validation_issues:
                lines.append(f"- {issue}")
            lines.append("")
        
        # Normalization scripts
        if self.report.normalization_scripts:
            lines.extend([
                "## Normalization Scripts Applied",
                "",
            ])
            for script in self.report.normalization_scripts:
                lines.append(f"- {script}")
            lines.append("")
        
        # Failed tables
        failed = [s for s in self.report.table_stats if not s.success]
        if failed:
            lines.extend([
                "## Failed Tables",
                "",
            ])
            for stats in failed:
                lines.append(f"### {stats.table_name}")
                lines.append(f"**Error:** {stats.error_message}")
                lines.append("")
        
        markdown = "\n".join(lines)
        
        if file_path:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(markdown)
            logger.info(f"Markdown report saved to {file_path}")
        
        return markdown

    def to_console(self) -> str:
        """
        Generate console-friendly report.
        
        Returns:
            Formatted string for console output
        """
        lines = [
            "",
            "=" * 70,
            "MIGRATION REPORT",
            "=" * 70,
            f"Migration ID: {self.report.migration_id}",
            f"Start Time:   {self.report.start_time.strftime('%Y-%m-%d %H:%M:%S')}",
        ]
        
        if self.report.end_time:
            lines.append(f"End Time:     {self.report.end_time.strftime('%Y-%m-%d %H:%M:%S')}")
            lines.append(f"Duration:     {self.report.total_duration_seconds:.2f} seconds")
        
        lines.extend([
            f"Profile:      {self.report.config_profile}",
            f"Schemas:      {', '.join(self.report.schemas_migrated)}",
            "",
            "-" * 70,
            "SUMMARY",
            "-" * 70,
            f"Total Tables:     {self.report.total_tables}",
            f"Successful:       {self.report.successful_tables}",
            f"Failed:           {self.report.failed_tables}",
            f"Rows Migrated:    {self.report.total_rows_migrated:,}",
            "",
        ])
        
        if self.report.validation_issues:
            lines.extend([
                "-" * 70,
                f"VALIDATION ISSUES ({len(self.report.validation_issues)})",
                "-" * 70,
            ])
            for issue in self.report.validation_issues[:10]:  # Show first 10
                lines.append(f"  • {issue}")
            if len(self.report.validation_issues) > 10:
                lines.append(f"  ... and {len(self.report.validation_issues) - 10} more")
            lines.append("")
        
        if self.report.failed_tables > 0:
            lines.extend([
                "-" * 70,
                f"FAILED TABLES ({self.report.failed_tables})",
                "-" * 70,
            ])
            failed = [s for s in self.report.table_stats if not s.success]
            for stats in failed:
                lines.append(f"  • {stats.table_name}: {stats.error_message}")
            lines.append("")
        
        lines.append("=" * 70)
        
        return "\n".join(lines)
