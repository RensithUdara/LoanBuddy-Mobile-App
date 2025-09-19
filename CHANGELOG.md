# Changelog

All notable changes to the LoanBuddy Mobile App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-09-19

### Added
- Export/Import data functionality
  - Export loans and payments to CSV files
  - Import data from CSV files
  - UI for data backup and restore operations
- Advanced analytics dashboard
  - Payment trends visualization
  - Loan status distribution charts
  - Top borrowers tracking
  - Time range filtering options
- Custom reminder scheduling
  - Per-loan notification settings
  - Configurable reminder days before due date
  - Enable/disable toggles for each loan
- App drawer for easier navigation between features
- Improved UI components and error handling

### Fixed
- Fixed notification service implementation
- Improved error handling for database operations
- Enhanced UI responsiveness for various screen sizes

### Changed
- Updated app navigation to use drawer instead of bottom tabs for advanced features
- Enhanced loan card UI with better visual indicators
- Optimized database queries for better performance

## [1.0.0] - 2025-07-15

### Added
- Initial release of LoanBuddy Mobile App
- Core loan management functionality
  - Create, edit, delete loans
  - Record payments for loans
  - Track loan status (active, completed)
- Dashboard with loan overview
- WhatsApp integration for contacting borrowers
- Settings page with theme toggle
- Basic database operations with SQLite